package SQL::Statement::Term;

our $VERSION = '1.26';

use Scalar::Util qw(weaken);

=pod

=head1 NAME

SQL::Statement::Term - base class for all terms

=head1 SYNOPSIS

  # create a term with an SQL::Statement object as owner
  my $term = SQL::Statement::Term->new( $owner );
  # access the value of that term
  $term->value( $eval );

=head1 DESCRIPTION

SQL::Statement::Term is an abstract base class providing the interface
for all terms.

=head1 INHERITANCE

  SQL::Statement::Term

=head1 METHODS

=head2 new

Instantiates new term and stores a weak reference to the owner.

=head2 value

I<Abstract> method which will return the value of the term. Must be
overridden by derived classes.

=head2 DESTROY

Destroys the term and undefines the weak reference to the owner.

=cut

sub new
{
    my ( $class, $owner ) = @_;

    my %instance = ( OWNER => $owner );

    my $self = bless( \%instance, $class );
    weaken( $self->{OWNER} );

    return $self;
}

sub DESTROY
{
    my $self = $_[0];
    undef $self->{OWNER};
}

sub value($) { Carp::confess( sprintf( q{pure virtual function '%s->value' called}, ref( $_[0] ) || __PACKAGE__ ) ); }

package SQL::Statement::ConstantTerm;

use vars qw(@ISA);
@ISA = qw(SQL::Statement::Term);

=pod

=head1 NAME

SQL::Statement::ConstantTerm - term for constant values

=head1 SYNOPSIS

  # create a term with an SQL::Statement object as owner
  my $term = SQL::Statement::ConstantTerm->new( $owner, 'foo' );
  # access the value of that term - returns 'foo'
  $term->value( $eval );

=head1 DESCRIPTION

SQL::Statement::ConstantTerm implements a term which will always return the
same constant value.

=head1 INHERITANCE

  SQL::Statement::ConstantTerm
  ISA SQL::Statement::Term

=head1 METHODS

=head2 new

Instantiates new term and stores the constant to deliver and a weak
reference to the owner.

=head2 value

Returns the specified constant.

=cut

sub new
{
    my ( $class, $owner, $value ) = @_;

    my $self = $class->SUPER::new($owner);
    $self->{VALUE} = $value;

    return $self;
}

sub value($$) { return $_[0]->{VALUE}; }

package SQL::Statement::ColumnValue;

use vars qw(@ISA);
@ISA = qw(SQL::Statement::Term);

use Params::Util qw(_INSTANCE);

=pod

=head1 NAME

SQL::Statement::ColumnValue - term for column values

=head1 SYNOPSIS

  # create a term with an SQL::Statement object as owner
  my $term = SQL::Statement::ColumnValue->new( $owner, 'id' );
  # access the value of that term - returns the value of the column 'id'
  # of the currently active row in $eval
  $term->value( $eval );

=head1 DESCRIPTION

SQL::Statement::ColumnValue implements a term which will return the specified
column of the active row.

=head1 INHERITANCE

  SQL::Statement::ColumnValue
  ISA SQL::Statement::Term

=head1 METHODS

=head2 new

Instantiates new term and stores the column name to deliver and a weak
reference to the owner.

=head2 value

Returns the specified column value.

=cut

sub new
{
    my ( $class, $owner, $value ) = @_;

    my $self = $class->SUPER::new($owner);
    $self->{VALUE} = $value;

    return $self;
}

sub value($)
{
    my $self = $_[0];
    my $eval = $_[1];
    unless ( defined( $self->{TMPVAL} ) )
    {
        my ( $tbl, $col ) = $self->{OWNER}->full_qualified_column_name( $self->{VALUE} );
        $self->{TMPVAL}      = $tbl . $self->{OWNER}->{dlm} . $col;
        $self->{TABLE_NAME}  = $tbl;
        $self->{COLUMN_NAME} = $col;
    }

    # with TempEval: return $eval->column($self->{TABLE_NAME}, $self->{COLUMN_NAME});

    if ( _INSTANCE( $eval, 'SQL::Eval' ) )
    {
        my $table = $eval->{tables}->{ $self->{TABLE_NAME} };
        return $table->column( $self->{COLUMN_NAME} );

        # return $line->[ $table->{col_nums}->{ $self->{COLUMN_NAME} } ];
    }
    else
    {
        return undef unless ( defined( $eval->{rowpos} ) );
        my $line = $eval->{table}->[ $eval->{rowpos} - 1 ];

        return $line->[ $eval->{col_nums}->{ $self->{TMPVAL} } ];
    }
}

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2009,2010 by Jens Rehsack: rehsackATcpan.org

All rights reserved.

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut

1;
