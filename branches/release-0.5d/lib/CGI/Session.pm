package CGI::Session;
use strict;
use Carp;
use CGI::Session::ErrorHandler;

@CGI::Session::ISA      = qw( CGI::Session::ErrorHandler );
$CGI::Session::VERSION  = '4.48';
$CGI::Session::NAME     = 'CGISESSID';
$CGI::Session::IP_MATCH = 0;

sub STATUS_UNSET    () { 1 << 0 } # denotes session that's resetted
sub STATUS_NEW      () { 1 << 1 } # denotes session that's just created
sub STATUS_MODIFIED () { 1 << 2 } # denotes session that needs synchronization
sub STATUS_DELETED  () { 1 << 3 } # denotes session that needs deletion
sub STATUS_EXPIRED  () { 1 << 4 } # denotes session that was expired.

sub import {
    my ($class, @args) = @_;

    return unless @args;

  ARG:
    for my $arg (@args) {
        if ($arg eq '-ip_match') {
            $CGI::Session::IP_MATCH = 1;
            last ARG;
        }
    }
}

sub new {
    my ($class, @args) = @_;

    my $self;
    if (ref $class) {
        #
        # Called as an object method as in $session->new()...
        #
        $self  = bless { %$class }, ref( $class );
        $class = ref $class;
        $self->_reset_status();
        #
        # Object may still have public data associated with it, but we
        # don't care about that, since we want to leave that to the
        # client's disposal. However, if new() was requested on an
        # expired session, we already know that '_DATA' table is
        # empty, since it was the job of flush() to empty '_DATA'
        # after deleting. How do we know flush() was already called on
        # an expired session? Because load() - constructor always
        # calls flush() on all to-be expired sessions
        #
    }
    else {
        #
        # Called as a class method as in CGI::Session->new()
        #

        # Start fresh with error reporting. Errors in past objects shouldn't affect this one. 
        $class->set_error('');

        $self = $class->load( @args );
        if (not defined $self) {
            return $class->set_error( "new(): failed: " . $class->errstr );
        }
    }

    my $dataref = $self->{_DATA};
    unless ($dataref->{_SESSION_ID}) {
        #
        # Absence of '_SESSION_ID' can only signal:
        # * Expired session: Because load() - constructor is required to
        #                    empty contents of _DATA - table
        # * Unavailable session: Such sessions are the ones that don't
        #                    exist on datastore, but are requested by client
        # * New session: When no specific session is requested to be loaded
        #
        my $id = $self->_id_generator()->generate_id(
                                                     $self->{_DRIVER_ARGS},
                                                     $self->{_CLAIMED_ID}
                                                     );
        unless (defined $id) {
            return $self->set_error( "Couldn't generate new SESSION-ID" );
        }
        $dataref->{_SESSION_ID} = $id;
        $dataref->{_SESSION_CTIME} = $dataref->{_SESSION_ATIME} = time();
        $dataref->{_SESSION_REMOTE_ADDR} = $ENV{REMOTE_ADDR} || "";
        $self->_set_status( STATUS_NEW );
    }
    return $self;
}

sub DESTROY         {   $_[0]->flush()      }
sub close           {   $_[0]->flush()      }

*param_hashref      = \&dataref;
my $avoid_single_use_warning = *param_hashref;
sub dataref         { $_[0]->{_DATA}        }

sub is_empty        { !defined($_[0]->id)   }

sub is_expired      { $_[0]->_test_status( STATUS_EXPIRED ) }

sub is_new          { $_[0]->_test_status( STATUS_NEW ) }

sub id              { return defined($_[0]->dataref) ? $_[0]->dataref->{_SESSION_ID}    : undef }

# Last Access Time
sub atime           { return defined($_[0]->dataref) ? $_[0]->dataref->{_SESSION_ATIME} : undef }

# Creation Time
sub ctime           { return defined($_[0]->dataref) ? $_[0]->dataref->{_SESSION_CTIME} : undef }

sub _driver {
    my $self = shift;
    defined($self->{_OBJECTS}->{driver}) and return $self->{_OBJECTS}->{driver};
    my $pm = "CGI::Session::Driver::" . $self->{_DSN}->{driver};
    defined($self->{_OBJECTS}->{driver} = $pm->new( $self->{_DRIVER_ARGS} ))
        or die $pm->errstr();
    return $self->{_OBJECTS}->{driver};
}

sub _serializer     { 
    my $self = shift;
    defined($self->{_OBJECTS}->{serializer}) and return $self->{_OBJECTS}->{serializer};
    return $self->{_OBJECTS}->{serializer} = "CGI::Session::Serialize::" . $self->{_DSN}->{serializer};
}


sub _id_generator   { 
    my $self = shift;
    defined($self->{_OBJECTS}->{id}) and return $self->{_OBJECTS}->{id};
    return $self->{_OBJECTS}->{id} = "CGI::Session::ID::" . $self->{_DSN}->{id};
}

sub ip_matches {
  return ( $_[0]->{_DATA}->{_SESSION_REMOTE_ADDR} eq $ENV{REMOTE_ADDR} );
}


# parses the DSN string and returns it as a hash.
# Notably: Allows unique abbreviations of the keys: driver, serializer and 'id'.
# Also, keys and values of the returned hash are lower-cased.
sub parse_dsn {
    my $self = shift;
    my $dsn_str = shift;
    croak "parse_dsn(): usage error" unless $dsn_str;

    require Text::Abbrev;
    my $abbrev = Text::Abbrev::abbrev( "driver", "serializer", "id" );
    my %dsn_map = map { split /:/ } (split /;/, $dsn_str);
    my %dsn  = map { $abbrev->{lc $_}, lc $dsn_map{$_} } keys %dsn_map;
    return \%dsn;
}

sub query {
    my $self = shift;

    if ( $self->{_QUERY} ) {
        return $self->{_QUERY};
    }
#   require CGI::Session::Query;
#   return $self->{_QUERY} = CGI::Session::Query->new();
    require CGI;
    return $self->{_QUERY} = CGI->new();
}


sub name {
    my $self = shift;
    my $name = shift;
    
    if (ref $self) {
        unless ( defined $name ) {
            return $self->{_NAME} || $CGI::Session::NAME;
        }
        return $self->{_NAME} = $name;
    }
    
    $CGI::Session::NAME = $name if defined $name;
    return $CGI::Session::NAME;
}


sub dump {
    my $self = shift;

    require Data::Dumper;
    my $d = Data::Dumper->new([$self], [ref $self]);
    $d->Deepcopy(1);
    return $d->Dump();
}


sub _set_status {
    my $self    = shift;
    croak "_set_status(): usage error" unless @_;
    $self->{_STATUS} |= $_[0];
}


sub _unset_status {
    my $self = shift;
    croak "_unset_status(): usage error" unless @_;
    $self->{_STATUS} &= ~$_[0];
}


sub _reset_status {
    $_[0]->{_STATUS} = STATUS_UNSET;
}

sub _test_status {
    return $_[0]->{_STATUS} & $_[1];
}


sub flush {
    my $self = shift;

    # Would it be better to die or err if something very basic is wrong here? 
    # I'm trying to address the DESTROY related warning
    # from: http://rt.cpan.org/Ticket/Display.html?id=17541
    # return unless defined $self;

    return unless $self->id;            # <-- empty session
    
    # neither new, nor deleted nor modified
    return if !defined($self->{_STATUS}) or $self->{_STATUS} == STATUS_UNSET;

    if ( $self->_test_status(STATUS_NEW) && $self->_test_status(STATUS_DELETED) ) {
        $self->{_DATA} = {};
        return $self->_unset_status(STATUS_NEW | STATUS_DELETED);
    }

    my $driver      = $self->_driver();
    my $serializer  = $self->_serializer();

    if ( $self->_test_status(STATUS_DELETED) ) {
        defined($driver->remove($self->id)) or
            return $self->set_error( "flush(): couldn't remove session data: " . $driver->errstr );
        $self->{_DATA} = {};                        # <-- removing all the data, making sure
                                                    # it won't be accessible after flush()
        return $self->_unset_status(STATUS_DELETED);
    }

    if ( $self->_test_status(STATUS_NEW | STATUS_MODIFIED) ) {
        my $datastr = $serializer->freeze( $self->dataref );
        unless ( defined $datastr ) {
            return $self->set_error( "flush(): couldn't freeze data: " . $serializer->errstr );
        }
        defined( $driver->store($self->id, $datastr) ) or
            return $self->set_error( "flush(): couldn't store datastr: " . $driver->errstr);
        $self->_unset_status(STATUS_NEW | STATUS_MODIFIED);
    }
    return 1;
}

sub trace {}
sub tracemsg {}

sub param {
    my ($self, @args) = @_;

    if ($self->_test_status( STATUS_DELETED )) {
        carp "param(): attempt to read/write deleted session";
    }

    # USAGE: $s->param();
    # DESC:  Returns all the /public/ parameters
    if (@args == 0) {
        return grep { !/^_SESSION_/ } keys %{ $self->{_DATA} };
    }
    # USAGE: $s->param( $p );
    # DESC: returns a specific session parameter
    elsif (@args == 1) {
        return $self->{_DATA}->{ $args[0] }
    }


    # USAGE: $s->param( -name => $n, -value => $v );
    # DESC:  Updates session data using CGI.pm's 'named param' syntax.
    #        Only public records can be set!
    my %args = @args;
    my ($name, $value) = @args{ qw(-name -value) };
    if (defined $name && defined $value) {
        if ($name =~ m/^_SESSION_/) {

            carp "param(): attempt to write to private parameter";
            return undef;
        }
        $self->_set_status( STATUS_MODIFIED );
        return $self->{_DATA}->{ $name } = $value;
    }

    # USAGE: $s->param(-name=>$n);
    # DESC:  access to session data (public & private) using CGI.pm's 'named parameter' syntax.
    return $self->{_DATA}->{ $args{'-name'} } if defined $args{'-name'};

    # USAGE: $s->param($name, $value);
    # USAGE: $s->param($name1 => $value1, $name2 => $value2 [,...]);
    # DESC:  updates one or more **public** records using simple syntax
    if ((@args % 2) == 0) {
        my $modified_cnt = 0;
	ARG_PAIR:
        while (my ($name, $val) = each %args) {
            if ( $name =~ m/^_SESSION_/) {
                carp "param(): attempt to write to private parameter";
                next ARG_PAIR;
            }
            $self->{_DATA}->{ $name } = $val;
            ++$modified_cnt;
        }
        $self->_set_status(STATUS_MODIFIED);
        return $modified_cnt;
    }

    # If we reached this far none of the expected syntax were
    # detected. Syntax error
    croak "param(): usage error. Invalid syntax";
}



sub delete {    $_[0]->_set_status( STATUS_DELETED )    }


*header = \&http_header;
my $avoid_single_use_warning_again = *header;
sub http_header {
    my $self = shift;
    return $self->query->header(-cookie=>$self->cookie, -type=>'text/html', @_);
}

sub cookie {
    my $self = shift;

    my $query = $self->query();
    my $cookie= undef;

    if ( $self->is_expired ) {
        $cookie = $query->cookie( -name=>$self->name, -value=>$self->id, -expires=> '-1d', @_ );
    } 
    elsif ( my $t = $self->expire ) {
        $cookie = $query->cookie( -name=>$self->name, -value=>$self->id, -expires=> '+' . $t . 's', @_ );
    } 
    else {
        $cookie = $query->cookie( -name=>$self->name, -value=>$self->id, @_ );
    }
    return $cookie;
}





sub save_param {
    my $self = shift;
    my ($query, $params) = @_;

    $query  ||= $self->query();
    $params ||= [ $query->param ];

    for my $p ( @$params ) {
        my @values = $query->param($p) or next;
        if ( @values > 1 ) {
            $self->param($p, \@values);
        } else {
            $self->param($p, $values[0]);
        }
    }
    $self->_set_status( STATUS_MODIFIED );
}



sub load_param {
    my $self = shift;
    my ($query, $params) = @_;

    $query  ||= $self->query();
    $params ||= [ $self->param ];

    for ( @$params ) {
        $query->param(-name=>$_, -value=>$self->param($_));
    }
}


sub clear {
    my $self    = shift;
    my $params  = shift;
    #warn ref($params);
    if (defined $params) {
        $params =  [ $params ] unless ref $params;
    }
    else {
        $params = [ $self->param ];
    }

    for ( grep { ! /^_SESSION_/ } @$params ) {
        delete $self->{_DATA}->{$_};
    }
    $self->_set_status( STATUS_MODIFIED );
}


sub find {
    my $class       = shift;
    my ($dsn, $coderef, $dsn_args);

    # find( \%code )
    if ( @_ == 1 ) {
        $coderef = $_[0];
    } 
    # find( $dsn, \&code, \%dsn_args )
    else {
        ($dsn, $coderef, $dsn_args) = @_;
    }

    unless ( $coderef && ref($coderef) && (ref $coderef eq 'CODE') ) {
        croak "find(): usage error.";
    }

    my $driver;
    if ( $dsn ) {
        my $hashref = $class->parse_dsn( $dsn );
        $driver     = $hashref->{driver};
    }
    $driver ||= "file";
    my $pm = "CGI::Session::Driver::" . ($driver =~ /(.*)/)[0];
    eval "require $pm";
    if (my $errmsg = $@ ) {
        return $class->set_error( "find(): couldn't load driver." . $errmsg );
    }

    my $driver_obj = $pm->new( $dsn_args );
    unless ( $driver_obj ) {
        return $class->set_error( "find(): couldn't create driver object. " . $pm->errstr );
    }

    # Read-only isn't the perfect name here. In read-only mode, we skip the ip_match check,
    # and don't update the atime. We *do* still delete expired sessions and session params.
    my $read_only = 1;
    my $driver_coderef = sub {
        my ($sid) = @_;
        my $session = $class->load( $dsn, $sid, $dsn_args, $read_only );
        unless ( $session ) {
            return $class->set_error( "find(): couldn't load session '$sid'. " . $class->errstr );
        }
        $coderef->( $session );
    };

    defined($driver_obj->traverse( $driver_coderef ))
        or return $class->set_error( "find(): traverse seems to have failed. " . $driver_obj->errstr );
    return 1;
}

# $Id$

=pod

=head1 NAME

CGI::Session - persistent session data in CGI applications

=head1 SYNOPSIS

    # Object initialization:
    use CGI::Session;
    $session = CGI::Session->new();

    $CGISESSID = $session->id();

    # Send proper HTTP header with cookies:
    print $session->header();

    # Storing data in the session:
    $session->param('f_name', 'Sherzod');
    # or
    $session->param(-name=>'l_name', -value=>'Ruzmetov');

    # Flush the data from memory to the storage driver at least before your
    # program finishes since auto-flushing can be unreliable.
    $session->flush();

    # Retrieving data:
    my $f_name = $session->param('f_name');
    # or
    my $l_name = $session->param(-name=>'l_name');

    # Clearing a certain session parameter:
    $session->clear(["l_name", "f_name"]);

    # Expire '_is_logged_in' flag after 10 idle minutes:
    $session->expire('is_logged_in', '+10m')

    # Expire the session itself after 1 idle hour:
    $session->expire('+1h');

    # Delete the session for good:
    $session->delete();
    $session->flush(); # Recommended practice says use flush() after delete().

=head1 DESCRIPTION

CGI::Session provides an easy, reliable and modular session management system across HTTP requests.

=head1 METHODS

Following is the overview of all the available methods accessible via CGI::Session object.

=head2 new()

=head2 new( $sid )

=head2 new( $query )

=head2 new( $dsn, $query||$sid )

=head2 new( $dsn, $query||$sid, \%dsn_args )

=head2 new( $dsn, $query||$sid, \%dsn_args, \%session_params )

Constructor. Returns new session object, or undef on failure. Error message is accessible through L<errstr() - class method|CGI::Session::ErrorHandler/"errstr()">. If called on an already initialized session will re-initialize the session based on already configured object. This is only useful after a call to L<load()|/"load()">.

Can accept up to three arguments, $dsn - Data Source Name, $query||$sid - query object OR a string representing session id, and finally, \%dsn_args, arguments used by $dsn components.

If called without any arguments, $dsn defaults to I<driver:file;serializer:default;id:md5>, $query||$sid defaults to C<< CGI->new() >>, and C<\%dsn_args> defaults to I<undef>.

If called with a single argument, it will be treated either as C<$query> object, or C<$sid>, depending on its type. If argument is a string , C<new()> will treat it as session id and will attempt to retrieve the session from data store. If it fails, will create a new session id, which will be accessible through L<id() method|/"id">. If argument is an object, L<cookie()|CGI/cookie> and L<param()|CGI/param> methods will be called on that object to recover a potential C<$sid> and retrieve it from data store. If it fails, C<new()> will create a new session id, which will be accessible through L<id() method|/"id">. C<name()> will define the name of the query parameter and/or cookie name to be requested, defaults to I<CGISESSID>.

If called with two arguments first will be treated as $dsn, and second will be treated as $query or $sid or undef, depending on its type. Some examples of this syntax are:

    $s = CGI::Session->new("driver:mysql", undef);
    $s = CGI::Session->new("driver:sqlite", $sid);
    $s = CGI::Session->new("driver:db_file", $query);
    $s = CGI::Session->new("serializer:storable;id:incr", $sid);
    # etc...

Briefly, C<new()> will return an initialized session object with a valid id, whereas C<load()> may return
an empty session object with an undefined id.

Tests are provided (t/new_with_undef.t and t/load_with_undef.t) to clarify the result of calling C<new()> and C<load()>
with undef, or with an initialized CGI object with an undefined or fake CGISESSID.

You are strongly advised to run the old-fashioned 'make test TEST_FILES=t/new_with_undef.t TEST_VERBOSE=1'
or the new-fangled 'prove -v t/new_with_undef.t', for both new*.t and load*.t, and examine the output.

Following data source components are supported:

=over 4

=item *

B<driver> - CGI::Session driver. Available drivers are L<file|CGI::Session::Driver::file>, L<db_file|CGI::Session::Driver::db_file>, L<mysql|CGI::Session::Driver::mysql> and L<sqlite|CGI::Session::Driver::sqlite>. Third party drivers are welcome. For driver specs consider L<CGI::Session::Driver|CGI::Session::Driver>

=item *

B<serializer> - serializer to be used to encode the data structure before saving
in the disk. Available serializers are L<storable|CGI::Session::Serialize::storable>, L<freezethaw|CGI::Session::Serialize::freezethaw> and L<default|CGI::Session::Serialize::default>. Default serializer will use L<Data::Dumper|Data::Dumper>.

=item *

B<id> - ID generator to use when new session is to be created. Available ID generator is L<md5|CGI::Session::ID::md5>

=back

For example, to get CGI::Session store its data using DB_File and serialize data using FreezeThaw:

    $s = CGI::Session->new("driver:DB_File;serializer:FreezeThaw", undef);

If called with three arguments, first two will be treated as in the previous example, and third argument will be C<\%dsn_args>, which will be passed to C<$dsn> components (namely, driver, serializer and id generators) for initialization purposes. Since all the $dsn components must initialize to some default value, this third argument should not be required for most drivers to operate properly.

If called with four arguments, the first three match previous examples. The fourth argument must be a hash reference with parameters to be used by the CGI::Session object. (see \%session_params above )

The following is a list of the current keys:

=over

=item *

B<name> - Name to use for the cookie/query parameter name. This defaults to CGISESSID. This can be altered or accessed by the C<name> accessor.

=back

undef is acceptable as a valid placeholder to any of the above arguments, which will force default behavior.

=head2 load()

=head2 load( $query||$sid )

=head2 load( $dsn, $query||$sid )

=head2 load( $dsn, $query, \%dsn_args )

=head2 load( $dsn, $query, \%dsn_args, \%session_params )

Accepts the same arguments as new(), and also returns a new session object, or
undef on failure.  The difference is, L<new()|/"new()"> can create a new session if
it detects expired and non-existing sessions, but C<load()> does not.

C<load()> is useful to detect expired or non-existing sessions without forcing the library to create new sessions. So now you can do something like this:

    $s = CGI::Session->load() or die CGI::Session->errstr();
    if ( $s->is_expired ) {
        print $s->header(),
            $cgi->start_html(),
            $cgi->p("Your session timed out! Refresh the screen to start new session!")
            $cgi->end_html();
        exit(0);
    }

    if ( $s->is_empty ) {
        $s = $s->new() or die $s->errstr;
    }

Notice: All I<expired> sessions are empty, but not all I<empty> sessions are expired!

Briefly, C<new()> will return an initialized session object with a valid id, whereas C<load()> may return
an empty session object with an undefined id.

Tests are provided (t/new_with_undef.t and t/load_with_undef.t) to clarify the result of calling C<new()> and C<load()>
with undef, or with an initialized CGI object with an undefined or fake CGISESSID.

You are strongly advised to run the old-fashioned 'make test TEST_FILES=t/new_with_undef.t TEST_VERBOSE=1'
or the new-fangled 'prove -v t/new_with_undef.t', for both new*.t and load*.t, and examine the output.

=cut

# pass a true value as the fourth parameter if you want to skip the changing of
# access time This isn't documented more formally, because it only called by
# find().
sub load {
    my $class = shift;
    return $class->set_error( "called as instance method")    if ref $class;
    return $class->set_error( "Too many arguments provided to load()")  if @_ > 5;

    my $self = bless {
        _DATA       => {
            _SESSION_ID     => undef,
            _SESSION_CTIME  => undef,
            _SESSION_ATIME  => undef,
            _SESSION_REMOTE_ADDR => $ENV{REMOTE_ADDR} || "",
            #
            # Following two attributes may not exist in every single session, and declaring
            # them now will force these to get serialized into database, wasting space. But they
            # are here to remind the coder of their purpose
            #
#            _SESSION_ETIME  => undef,
#            _SESSION_EXPIRE_LIST => {}
        },          # session data
        _DSN        => {},          # parsed DSN params
        _OBJECTS    => {},          # keeps necessary objects
        _DRIVER_ARGS=> {},          # arguments to be passed to driver
        _CLAIMED_ID => undef,       # id **claimed** by client
        _STATUS     => STATUS_UNSET,# status of the session object
        _QUERY      => undef        # query object
    }, $class;

    my ($dsn,$query_or_sid,$dsn_args,$read_only,$params);
    # load($query||$sid)
    if ( @_ == 1 ) {
        $self->_set_query_or_sid($_[0]);
    }
    # Two or more args passed:
    # load($dsn, $query||$sid)
    elsif ( @_ > 1 ) {
        ($dsn, $query_or_sid, $dsn_args,$read_only) = @_;

        # Make it backwards-compatible (update_atime is an undocumented key in %$params).
        # In fact, update_atime as a key is not used anywhere in the code as yet.
        # This patch is part of the patch for RT#33437.
        if ( ref $read_only and ref $read_only eq 'HASH' ) {
            $params = {%$read_only};
            $read_only = $params->{'read_only'};

            if ($params->{'name'}) {
                $self->{_NAME} = $params->{'name'};
            }
        }

        # Since $read_only is not part of the public API
        # we ignore any value but the one we use internally: 1.
        if (defined $read_only and $read_only != '1') {
            return $class->set_error( "Too many arguments to load(). First extra argument was: $read_only");
         }

        if ( defined $dsn ) {      # <-- to avoid 'Uninitialized value...' warnings
            $self->{_DSN} = $self->parse_dsn($dsn);
        }
        $self->_set_query_or_sid($query_or_sid);

        # load($dsn, $query, \%dsn_args);

        $self->{_DRIVER_ARGS} = $dsn_args if defined $dsn_args;

    }

    $self->_load_pluggables();

    # Did load_pluggable fail? If so, return undef, just like $class->set_error() would
    return undef if $class->errstr;

    if (not defined $self->{_CLAIMED_ID}) {
        my $query = $self->query();
        eval {
            $self->{_CLAIMED_ID} = $query->cookie( $self->name ) || $query->param( $self->name );
        };
        if ( my $errmsg = $@ ) {
            return $class->set_error( "query object $query does not support cookie() and param() methods: " .  $errmsg );
        }
    }

    # No session is being requested. Just return an empty session
    return $self unless $self->{_CLAIMED_ID};

    # Attempting to load the session
    my $driver = $self->_driver();
    my $raw_data = $driver->retrieve( $self->{_CLAIMED_ID} );
    unless ( defined $raw_data ) {
        return $self->set_error( "load(): couldn't retrieve data: " . $driver->errstr );
    }
    
    # Requested session couldn't be retrieved
    return $self unless $raw_data;

    my $serializer = $self->_serializer();
    $self->{_DATA} = $serializer->thaw($raw_data);
    unless ( defined $self->{_DATA} ) {
        #die $raw_data . "\n";
        return $self->set_error( "load(): couldn't thaw() data using $serializer:" .
                                $serializer->errstr );
    }
    unless (defined($self->{_DATA}) && ref ($self->{_DATA}) && (ref $self->{_DATA} eq 'HASH') &&
            defined($self->{_DATA}->{_SESSION_ID}) ) {
        return $self->set_error( "Invalid data structure returned from thaw()" );
    }


    # checking for expiration ticker
    if ( $self->{_DATA}->{_SESSION_ETIME} ) {
        if ( ($self->{_DATA}->{_SESSION_ATIME} + $self->{_DATA}->{_SESSION_ETIME}) <= time() ) {
            $self->_set_status( STATUS_EXPIRED |    # <-- so client can detect expired sessions
                STATUS_DELETED );                   # <-- session should be removed from database
            $self->flush();                         # <-- flush() will do the actual removal!
            return $self;
        }
    }

    # checking expiration tickers of individuals parameters, if any:
    my @expired_params = ();
    if ( $self->{_DATA}->{_SESSION_EXPIRE_LIST} ) {
        while (my ($param, $max_exp_interval) = each %{ $self->{_DATA}->{_SESSION_EXPIRE_LIST} } ) {
            if ( ($self->{_DATA}->{_SESSION_ATIME} + $max_exp_interval) <= time() ) {
                push @expired_params, $param;
            }
        }
    }
    $self->clear(\@expired_params) if @expired_params;



    if (not defined $read_only) {
        # checking if previous session ip matches current ip
        if($CGI::Session::IP_MATCH) {
            unless($self->ip_matches) {
                $self->_set_status( STATUS_DELETED );
                $self->flush;
                return $self;
            }
        }

        $self->{_DATA}->{_SESSION_ATIME} = time();      # <-- updating access time
        $self->_set_status( STATUS_MODIFIED );          # <-- access time modified above
    }
    
    return $self;
}


# set the input as a query object or session ID, depending on what it looks like.  
sub _set_query_or_sid {
    my $self = shift;
    my $query_or_sid = shift;
    if ( ref $query_or_sid){ $self->{_QUERY}       = $query_or_sid  }
    else                   { $self->{_CLAIMED_ID}  = $query_or_sid  }
}


sub _load_pluggables {
    my ($self) = @_;

    my %DEFAULT_FOR = (
                       driver     => "file",
                       serializer => "default",
                       id         => "md5",
                       );
    my %SUBDIR_FOR  = (
                       driver     => "Driver",
                       serializer => "Serialize",
                       id         => "ID",
                       );
    my $dsn = $self->{_DSN};
    for my $plug (qw(driver serializer id)) {
        my $mod_name = $dsn->{ $plug };
        if (not defined $mod_name) {
            $mod_name = $DEFAULT_FOR{ $plug };
        }
        if ($mod_name =~ /^(\w+)$/) {

            # Looks good.  Put it into the dsn hash
            $dsn->{ $plug } = $mod_name = $1;

            # Put together the actual module name to load
            my $prefix = join '::', (__PACKAGE__, $SUBDIR_FOR{ $plug }, q{});
            $mod_name = $prefix . $mod_name;

            ## See if we can load load it
            eval "require $mod_name";
            if ($@) {
                my $msg = $@;
                return $self->set_error("couldn't load $mod_name: " . $msg);
            }
        }
        else {
            # do something here about bad name for a pluggable
        }
    }
    return;
}

=pod

=head2 id()

Returns effective ID for a session. Since effective ID and claimed ID can differ, valid session id should always
be retrieved using this method.

=head2 param($name)

=head2 param(-name=E<gt>$name)

Used in either of the above syntax returns a session parameter set to $name or undef if it doesn't exist. If it's called on a deleted method param() will issue a warning but return value is not defined.

=head2 param($name, $value)

=head2 param(-name=E<gt>$name, -value=E<gt>$value)

Used in either of the above syntax assigns a new value to $name parameter,
which can later be retrieved with previously introduced param() syntax. C<$value>
may be a scalar, arrayref or hashref.

Attempts to set parameter names that start with I<_SESSION_> will trigger
a warning and undef will be returned.

=head2 param_hashref()

B<Deprecated>. Use L<dataref()|/"dataref()"> instead.

=head2 dataref()

Returns reference to session's data table:

    $params = $s->dataref();
    $sid = $params->{_SESSION_ID};
    $name= $params->{name};
    # etc...

Useful for having all session data in a hashref, but too risky to update.

=head2 save_param()

=head2 save_param($query)

=head2 save_param($query, \@list)

Saves query parameters to session object. In other words, it's the same as calling L<param($name, $value)|/"param($name)"> for every single query parameter returned by C<< $query->param() >>. The first argument, if present, should be either CGI object or any object which can provide param() method. If it's undef, defaults to the return value of L<query()|/"query()">, which returns C<< CGI->new >>. If second argument is present and is a reference to an array, only those query parameters found in the array will be stored in the session. undef is a valid placeholder for any argument to force default behavior.

=head2 load_param()

=head2 load_param($query)

=head2 load_param($query, \@list)

Loads session parameters into a query object. The first argument, if present, should be query object, or any other object which can provide param() method. If second argument is present and is a reference to an array, only parameters found in that array will be loaded to the query object.

=head2 clear()

=head2 clear('field')

=head2 clear(\@list)

Clears parameters from the session object.

With no parameters, all fields are cleared. If passed a single parameter or a
reference to an array, only the named parameters are cleared.

=head2 flush()

Synchronizes data in memory with the copy serialized by the driver. Call flush()
if you need to access the session from outside the current session object. You should
call flush() sometime before your program exits.

As a last resort, CGI::Session will automatically call flush for you just
before the program terminates or session object goes out of scope. Automatic
flushing has proven to be unreliable, and in some cases is now required
in places that worked with CGI::Session 3.x.

Always explicitly calling C<flush()> on the session before the
program exits is recommended. For extra safety, call it immediately after
every important session update.

Also see L<A Warning about Auto-flushing>

=head2 atime()

Read-only method. Returns the last access time of the session in seconds from epoch. This time is used internally while
auto-expiring sessions and/or session parameters.

=head2 ctime()

Read-only method. Returns the time when the session was first created in seconds from epoch.

=head2 expire()

=head2 expire($time)

=head2 expire($param, $time)

Sets expiration interval relative to L<atime()|/"atime()">.

If used with no arguments, returns the expiration interval if it was ever set. If no expiration was ever set, returns undef. For backwards compatibility, a method named C<etime()> does the same thing.

Second form sets an expiration time. This value is checked when previously stored session is asked to be retrieved, and if its expiration interval has passed, it will be expunged from the disk immediately. Passing 0 cancels expiration.

By using the third syntax you can set the expiration interval for a particular
session parameter, say I<~logged-in>. This would cause the library call clear()
on the parameter when its time is up. Note it only makes sense to set this value to 
something I<earlier> than when the whole session expires.  Passing 0 cancels expiration.

All the time values should be given in the form of seconds. Following keywords are also supported for your convenience:

    +-----------+---------------+
    |   alias   |   meaning     |
    +-----------+---------------+
    |     s     |   Second      |
    |     m     |   Minute      |
    |     h     |   Hour        |
    |     d     |   Day         |
    |     w     |   Week        |
    |     M     |   Month       |
    |     y     |   Year        |
    +-----------+---------------+

Examples:

    $session->expire("2h");                # expires in two hours
    $session->expire(0);                   # cancel expiration
    $session->expire("~logged-in", "10m"); # expires '~logged-in' parameter after 10 idle minutes

Note: all the expiration times are relative to session's last access time, not to its creation time. To expire a session immediately, call L<delete()|/"delete">. To expire a specific session parameter immediately, call L<clear([$name])|/"clear">.

=cut

*expires = \&expire;
my $prevent_warning = \&expires;
sub etime           { $_[0]->expire()  }
sub expire {
    my $self = shift;

    # no params, just return the expiration time.
    if (not @_) {
        return $self->{_DATA}->{_SESSION_ETIME};
    }
    # We have just a time
    elsif ( @_ == 1 ) {
        my $time = $_[0];
        # If 0 is passed, cancel expiration
        if ( defined $time && ($time =~ m/^\d$/) && ($time == 0) ) {
            $self->{_DATA}->{_SESSION_ETIME} = undef;
            $self->_set_status( STATUS_MODIFIED );
        }
        # set the expiration to this time
        else {
            $self->{_DATA}->{_SESSION_ETIME} = $self->_str2seconds( $time );
            $self->_set_status( STATUS_MODIFIED );
        }
    }
    # If we get this far, we expect expire($param,$time)
    # ( This would be a great use of a Perl6 multi sub! )
    else {
        my ($param, $time) = @_;
        if ( ($time =~ m/^\d$/) && ($time == 0) ) {
            delete $self->{_DATA}->{_SESSION_EXPIRE_LIST}->{ $param };
            $self->_set_status( STATUS_MODIFIED );
        } else {
            $self->{_DATA}->{_SESSION_EXPIRE_LIST}->{ $param } = $self->_str2seconds( $time );
            $self->_set_status( STATUS_MODIFIED );
        }
    }
    return 1;
}

# =head2 _str2seconds()
#
# my $secs = $self->_str2seconds('1d')
#
# Takes a CGI.pm-style time representation and returns an equivalent number
# of seconds.
#
# See the docs of expire() for more detail.
#
# =cut

sub _str2seconds {
    my $self = shift;
    my ($str) = @_;

    return unless defined $str;
    return $str if $str =~ m/^[-+]?\d+$/;

    my %_map = (
        s       => 1,
        m       => 60,
        h       => 3600,
        d       => 86400,
        w       => 604800,
        M       => 2592000,
        y       => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;
    unless ( defined($koef) && defined($d) ) {
        die "_str2seconds(): couldn't parse '$str' into \$koef and \$d parts. Possible invalid syntax";
    }
    return $koef * $_map{ $d };
}


=pod

=head2 is_new()

Returns true only for a brand new session.

=head2 is_expired()

Tests whether session initialized using L<load()|/"load"> is to be expired. This method works only on sessions initialized with load():

    $s = CGI::Session->load() or die CGI::Session->errstr;
    if ( $s->is_expired ) {
        die "Your session expired. Please refresh";
    }
    if ( $s->is_empty ) {
        $s = $s->new() or die $s->errstr;
    }


=head2 is_empty()

Returns true for sessions that are empty. It's preferred way of testing whether requested session was loaded successfully or not:

    $s = CGI::Session->load($sid);
    if ( $s->is_empty ) {
        $s = $s->new();
    }

Actually, the above code is nothing but waste. The same effect could've been achieved by saying:

    $s = CGI::Session->new( $sid );

L<is_empty()|/"is_empty"> is useful only if you wanted to catch requests for expired sessions, and create new session afterwards. See L<is_expired()|/"is_expired"> for an example.

=head2 ip_match()

Returns true if $ENV{REMOTE_ADDR} matches the remote address stored in the session.

If you have an application where you are sure your users' IPs are constant
during a session, you can consider enabling an option to make this check:

    use CGI::Session '-ip_match';

Usually you don't call ip_match() directly, but by using the above method. It is useful
only if you want to call it inside of coderef passed to the L<find()|/"find( \&code )"> method. 

=head2 delete()

Sets the objects status to be "deleted".  Subsequent read/write requests on the
same object will fail.  To physically delete it from the data store you need to call L<flush()|/"flush()">.
CGI::Session attempts to do this automatically when the object is being destroyed (usually as
the script exits), but see L<A Warning about Auto-flushing>.

=head2 find( \&code )

=head2 find( $dsn, \&code )

=head2 find( $dsn, \&code, \%dsn_args )

Experimental feature. Executes \&code for every session object stored in disk, passing initialized CGI::Session object as the first argument of \&code. Useful for housekeeping purposes, such as for removing expired sessions. Following line, for instance, will remove sessions already expired, but are still in disk:

The following line, for instance, will remove sessions already expired, but which are still on disk:

    CGI::Session->find( sub {} );

Notice, above \&code didn't have to do anything, because load(), which is called to initialize sessions inside L<find()|/"find( \&code )">, will automatically remove expired sessions. Following example will remove all the objects that are 10+ days old:

    CGI::Session->find( \&purge );
    sub purge {
        my ($session) = @_;
        next if $session->is_empty;    # <-- already expired?!
        if ( ($session->ctime + 3600*240) <= time() ) {
            $session->delete();
            $session->flush(); # Recommended practice says use flush() after delete().
        }
    }

B<Note>: find will not change the modification or access times on the sessions it returns.

Explanation of the 3 parameters to C<find()>:

=over 4

=item $dsn

This is the DSN (Data Source Name) used by CGI::Session to control what type of
sessions you previously created and what type of sessions you now wish method
C<find()> to pass to your callback.

The default value is defined above, in the docs for method C<new()>, and is
'driver:file;serializer:default;id:md5'.

Do not confuse this DSN with the DSN arguments mentioned just below, under \%dsn_args.

=item \&code

This is the callback provided by you (i.e. the caller of method C<find()>)
which is called by CGI::Session once for each session found by method C<find()>
which matches the given $dsn.

There is no default value for this coderef.

When your callback is actually called, the only parameter is a session. If you
want to call a subroutine you already have with more parameters, you can
achieve this by creating an anonymous subroutine that calls your subroutine
with the parameters you want. For example:

    CGI::Session->find($dsn, sub { my_subroutine( @_, 'param 1', 'param 2' ) } );
    CGI::Session->find($dsn, sub { $coderef->( @_, $extra_arg ) } );
    
Or if you wish, you can define a sub generator as such:

    sub coderef_with_args {
        my ( $coderef, @params ) = @_;
        return sub { $coderef->( @_, @params ) };
    }
    
    CGI::Session->find($dsn, coderef_with_args( $coderef, 'param 1', 'param 2' ) );

=item \%dsn_args

If your $dsn uses file-based storage, then this hashref might contain keys such as:

    {
        Directory => Value 1,
        NoFlock   => Value 2,
        UMask     => Value 3
    }

If your $dsn uses db-based storage, then this hashref contains (up to) 3 keys, and looks like:

    {
        DataSource => Value 1,
        User       => Value 2,
        Password   => Value 3
    }

These 3 form the DSN, username and password used by DBI to control access to your database server,
and hence are only relevant when using db-based sessions.

The default value of this hashref is undef.

=back

B<Note:> find() is meant to be convenient, not necessarily efficient. It's best suited in cron scripts.

=head2 name($new_name)

The $new_name parameter is optional. If supplied it sets the query or cookie parameter name to be used.

It defaults to I<$CGI::Session::NAME>, which defaults to I<CGISESSID>.

You are strongly discouraged from using the global variable I<$CGI::Session::NAME>, since it is
deprecated (as are all global variables) and will be removed in a future version of this module.

Return value: The current query or cookie parameter name.

=head1 MISCELLANEOUS METHODS

=head2 remote_addr()

Returns the remote address of the user who created the session for the first time. Returns undef if variable REMOTE_ADDR wasn't present in the environment when the session was created.

=cut

sub remote_addr {   return $_[0]->{_DATA}->{_SESSION_REMOTE_ADDR}   }

=pod

=head2 errstr()

Class method. Returns last error message from the library.

=head2 dump()

Returns a dump of the session object. Useful for debugging purposes only.

=head2 header()

A wrapper for C<CGI>'s header() method. Calling this method
is equivalent to something like this:

    $cookie = CGI::Cookie->new(-name=>$session->name, -value=>$session->id);
    print $cgi->header(-cookie=>$cookie, @_);

You can minimize the above into:

    print $session->header();

It will retrieve the name of the session cookie from C<$session->name()> which defaults to C<$CGI::Session::NAME>. If you want to use a different name for your session cookie, do something like this before creating session object:

    CGI::Session->name("MY_SID");
    $session = CGI::Session->new(undef, $cgi, \%attrs);

Now, $session->header() uses "MY_SID" as the name for the session cookie. For all additional options that can
be passed, see the C<header()> docs in C<CGI>.

=head2 query()

Returns query object associated with current session object. Default query object class is C<CGI>.

=head2 DEPRECATED METHODS

These methods exist solely for for compatibility with CGI::Session 3.x.

=head3 close()

Closes the session. Using flush() is recommended instead, since that's exactly what a call
to close() does now.

=head1 DISTRIBUTION

CGI::Session consists of several components such as L<drivers|"DRIVERS">, L<serializers|"SERIALIZERS"> and L<id generators|"ID GENERATORS">. This section lists what is available.

=head2 DRIVERS

The following drivers are included in the standard distribution:

=over 4

=item *

L<file|CGI::Session::Driver::file> - default driver for storing session data in plain files. Full name: B<CGI::Session::Driver::file>

=item *

L<db_file|CGI::Session::Driver::db_file> - for storing session data in BerkelyDB. Requires: L<DB_File>.
Full name: B<CGI::Session::Driver::db_file>

=item *

L<mysql|CGI::Session::Driver::mysql> - for storing session data in MySQL tables. Requires L<DBI|DBI> and L<DBD::mysql|DBD::mysql>.
Full name: B<CGI::Session::Driver::mysql>

=item *

L<sqlite|CGI::Session::Driver::sqlite> - for storing session data in SQLite. Requires L<DBI|DBI> and L<DBD::SQLite|DBD::SQLite>.
Full name: B<CGI::Session::Driver::sqlite>

=back

Other drivers are available from CPAN.

=head2 SERIALIZERS

=over 4

=item *

L<default|CGI::Session::Serialize::default> - default data serializer. Uses standard L<Data::Dumper|Data::Dumper>.
Full name: B<CGI::Session::Serialize::default>.

=item *

L<storable|CGI::Session::Serialize::storable> - serializes data using L<Storable>. Requires L<Storable>.
Full name: B<CGI::Session::Serialize::storable>.

=item *

L<freezethaw|CGI::Session::Serialize::freezethaw> - serializes data using L<FreezeThaw>. Requires L<FreezeThaw>.
Full name: B<CGI::Session::Serialize::freezethaw>

=item *

L<yaml|CGI::Session::Serialize::yaml> - serializes data using YAML. Requires L<YAML> or L<YAML::Syck>.
Full name: B<CGI::Session::Serialize::yaml>

=back

=head2 ID GENERATORS

The following ID generators are included in the standard distribution.

=over 4

=item *

L<md5|CGI::Session::ID::md5> - generates 32 character long hexadecimal string. Requires L<Digest::MD5|Digest::MD5>.
Full name: B<CGI::Session::ID::md5>.

=item *

L<incr|CGI::Session::ID::incr> - generates incremental session ids.

=item *

L<static|CGI::Session::ID::static> - generates static session ids. B<CGI::Session::ID::static>

=back

=head1 A Warning about Auto-flushing

Auto-flushing can be unreliable for the following reasons. Explicit flushing
after key session updates is recommended. 

=over 4

=item If the C<DBI> handle goes out of scope before the session variable

For database-stored sessions, if the C<DBI> handle has gone out of scope before
the auto-flushing happens, auto-flushing will fail.

=item Circular references

If the calling code contains a circular reference, it's possible that your
C<CGI::Session> object will not be destroyed until it is too late for
auto-flushing to work. You can find circular references with a tool like
L<Devel::Cycle>.

In particular, these modules are known to contain circular references which
lead to this problem:

=over 4

=item CGI::Application::Plugin::DebugScreen V 0.06

=item CGI::Application::Plugin::ErrorPage before version 1.20

=back

=item Signal handlers

If your application may receive signals, there is an increased chance that the
signal will arrive after the session was updated but before it is auto-flushed
at object destruction time.

=back

=head1 A Warning about UTF8

You are strongly encouraged to refer to, at least, the first of these articles, for help with UTF8.

L<http://en.wikibooks.org/wiki/Perl_Programming/Unicode_UTF-8>

L<http://perl.bristolbath.org/blog/lyle/2008/12/giving-cgiapplication-internationalization-i18n.html>

L<http://metsankulma.homelinux.net/cgi-bin/l10n_example_4/main.cgi>

L<http://rassie.org/archives/247>

L<http://www.di-mgt.com.au/cryptoInternational2.html>

Briefly, these are the issues:

=over 4

=item The file containing the source code of your program

Consider "use utf8;" or "use encoding 'utf8';".

=item Influencing the encoding of the program's input

Use:

    binmode STDIN, ":encoding(utf8)";.

    Of course, the program can get input from other sources, e.g. HTML template files, not just STDIN.

=item Influencing the encoding of the program's output

Use:

    binmode STDOUT, ":encoding(utf8)";

    When using CGI.pm, you can use $q->charset('UTF-8'). This is the same as passing 'UTF-8' to CGI's C<header()> method.

    Alternately, when using CGI::Session, you can use $session->header(charset => 'utf-8'), which will be
    passed to the query object's C<header()> method. Clearly this is preferable when the query object might not be
    of type CGI.

    See L</header()> for a fuller discussion of the use of the C<header()> method in conjunction with cookies.

=back

=head1 TRANSLATIONS

This document is also available in Japanese.

=over 4

=item o

Translation based on 4.14: http://digit.que.ne.jp/work/index.cgi?Perldoc/ja

=item o

Translation based on 3.11, including Cookbook and Tutorial: http://perldoc.jp/docs/modules/CGI-Session-3.11/

=back

=head1 CREDITS

CGI::Session evolved to what it is today with the help of following developers. The list doesn't follow any strict order, but somewhat chronological. Specifics can be found in F<Changes> file

=over 4

=item Andy Lester

=item Brian King E<lt>mrbbking@mac.comE<gt>

=item Olivier Dragon E<lt>dragon@shadnet.shad.caE<gt>

=item Adam Jacob E<lt>adam@sysadminsith.orgE<gt>

=item Igor Plisco E<lt>igor@plisco.ruE<gt>

=item Mark Stosberg

=item Matt LeBlanc E<lt>mleblanc@cpan.orgE<gt>

=item Shawn Sorichetti

=item Ron Savage

=item Rhesa Rozendaal

He suggested Devel::Cycle to help debugging.

=back

Also, many people on the CGI::Application and CGI::Session mailing lists have contributed ideas and
suggestions, and battled publicly with bugs, all of which has helped.

=head1 COPYRIGHT

Copyright (C) 2001-2005 Sherzod Ruzmetov E<lt>sherzodr@cpan.orgE<gt>. All rights reserved.
This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=head1 PUBLIC CODE REPOSITORY

You can see what the developers have been up to since the last release by
checking out the code repository. You can browse the git repository from here:

 http://github.com/cromedome/cgi-session/tree/master

Or check out the code with:

 git clone git://github.com/cromedome/cgi-session.git

=head1 SUPPORT

If you need help using CGI::Session, ask on the mailing list. You can ask the
list by sending your questions to cgi-session-user@lists.sourceforge.net .

You can subscribe to the mailing list at https://lists.sourceforge.net/lists/listinfo/cgi-session-user .

Bug reports can be submitted at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Session

=head1 AUTHOR

Sherzod Ruzmetov C<sherzodr@cpan.org>

Mark Stosberg became a co-maintainer during the development of 4.0. C<markstos@cpan.org>.

Ron Savage became a co-maintainer during the development of 4.30. C<rsavage@cpan.org>.

If you would like support, ask on the mailing list as describe above. The
maintainers and other users are subscribed to it. 

=head1 SEE ALSO 

To learn more both about the philosophy and CGI::Session programming style,
consider the following:

=over 4

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual. Also includes library architecture and driver specifications.

=item *

We also provide mailing lists for CGI::Session users. To subscribe to the list
or browse the archives visit
https://lists.sourceforge.net/lists/listinfo/cgi-session-user

=item * B<RFC 2109> - The primary spec for cookie handing in use, defining the  "Cookie:" and "Set-Cookie:" HTTP headers.
Available at L<http://www.ietf.org/rfc/rfc2109.txt>. A newer spec, RFC 2965 is meant to obsolete it with "Set-Cookie2" 
and "Cookie2" headers, but even of 2008, the newer spec is not widely supported. See L<http://www.ietf.org/rfc/rfc2965.txt>

=item *

L<Apache::Session|Apache::Session> - an alternative to CGI::Session.

=back

=cut

1;

