#
# PDF::Create::Page - PDF pages tree for PDF::Create
#
# Author: Fabien Tassin
#
# Copyright 1999-2001 Fabien Tassin
# Copyright 2007-     Markus Baertschi <markus@markus.org>
# Copyright 2010      Gary Lieberman
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Please do not use any of the methods here directly. You will be
# punished with your application no longer working after an upgrade !
#

package PDF::Create::Page;

use strict;
use vars qw(@ISA @EXPORT $VERSION $DEBUG);
use Exporter;
use Carp;
use FileHandle;
use Data::Dumper;

@ISA     = qw(Exporter);
@EXPORT  = qw();
$VERSION = 1.05;
$DEBUG   = 0;

my $font_widths = &init_widths;

my $ptext = "";    # Global variable for text function

sub new
{
	my $this  = shift;
	my $class = ref($this) || $this;
	my $self  = {};
	bless $self, $class;
	$self->{'Kids'}    = [];
	$self->{'Content'} = [];
	$self;
}

sub add
{
	my $self = shift;
	my $page = new PDF::Create::Page();
	$page->{'pdf'}    = $self->{'pdf'};
	$page->{'Parent'} = $self;
	$page->{'id'}     = shift;
	$page->{'name'}   = shift;
	push @{ $self->{'Kids'} }, $page;
	$page;
}

sub count
{
	my $self = shift;

	my $c = 0;
	$c++ unless scalar @{ $self->{'Kids'} };
	for my $page ( @{ $self->{'Kids'} } ) {
		$c += $page->count;
	}
	$c;
}

sub kids
{
	my $self = shift;

	my $t = [];
	map { push @$t, $_->{'id'} } @{ $self->{'Kids'} };
	$t;
}

sub list
{
	my $self = shift;
	my @l;
	for my $e ( @{ $self->{'Kids'} } ) {
		my @t = $e->list;
		push @l, $e;
		push @l, @t if scalar @t;
	}
	@l;
}

sub new_page
{
	my $self = shift;

	$self->{'pdf'}->new_page( 'Parent' => $self, @_ );
}

#######################################################################
# Drawing functions
#
# x y m: moves the current point to (x, y), omitting any connecting line
#        segment
sub moveto
{
	my $self = shift;
	my ( $x, $y ) = @_;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$x $y m");
}

# x y l: appends a straight line segment from the current point to (x, y).
#        The current point is (x, y).
sub lineto
{
	my $self = shift;
	my ( $x, $y ) = @_;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$x $y l");
}

# x1 y1 x2 y2 x3 y3 c: appends a Bezier curve to the path. The curve extends
#       from the current point to (x3 ,y3) using (x1 ,y1) and (x2 ,y2)
#       as the Bezier control points. The new current point is (x3 ,y3).
sub curveto
{
	my $self = shift;
	my ( $x1, $y1, $x2, $y2, $x3, $y3 ) = @_;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$x1 $y1 $x2 $y2 $x3 $y3 c");
}

# omit 'v' and 'y'

# x y w h re: adds a rectangle to the current path
sub rectangle
{
	my $self = shift;
	my ( $x, $y, $w, $h ) = @_;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$x $y $w $h re");
}

# h: closes the current subpath by appending a straight line segment
#    from the current point to the starting point of the subpath.
sub closepath
{
	my $self = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("h");
}

# n: ends the path without filling or stroking it
sub newpath
{
	my $self = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("n");
}

# S: strokes the path
sub stroke
{
	my $self = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("S");
}

# s: closes and strokes the path
sub closestroke
{
	my $self = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("s");
}

# f: fills the path using the non-zero winding number rule
sub fill
{
	my $self = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("f");
}

# f*: fills the path using the even-odd rule
sub fill2
{
	my $self = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("f*");
}

# combined moveto/lineto/stroke command
sub line
{
	my $self = shift;
	my ( $x1, $y1, $x2, $y2 ) = @_;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$x1 $y1 m $x2 $y2 l S");
}

sub set_width
{
	my $self = shift;
	my $w    = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$w w");
}

#######################################################################
# Color functions
#

# g: Sets the color space to DeviceGray and sets the gray tint to use
# for filling paths. [0, 1]
sub setgray
{
	my $self = shift;
	my $val  = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$val g");
}

# G: Sets the color space to DeviceGray and sets the gray tint to use
# for stroking paths. [0, 1]
sub setgraystroke
{
	my $self = shift;
	my $val  = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$val G");
}

# rg: Sets the color space to DeviceRGB and sets the color to use for
# filling paths. [0, 1] * 3.
sub setrgbcolor
{
	my $self = shift;
	my $r    = shift;
	my $g    = shift;
	my $b    = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$r $g $b rg");
}

# rg: Sets the color space to DeviceRGB and sets the color to use for
# stroking paths. [0, 1] * 3.
sub setrgbcolorstroke
{
	my $self = shift;
	my $r    = shift;
	my $g    = shift;
	my $b    = shift;

	croak "Error setting colors, need three values" if !defined $b;
	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->add("$r $g $b RG");
}

#######################################################################
#
# Text functions

#######################################################################
# experimental text function with functionality aligned with the PDF structure
#

my $pi = atan2( 1, 1 ) * 4;
my $piover180 = $pi / 180;

sub text
{
	my $self   = shift;
	my %params = @_;

	PDF::Create::debug( 2, "text(%params):" );

	if ( defined $params{'start'} ) { $ptext = "BT "; }
	if ( defined $params{'Ts'} ) { $ptext .= " $params{'Ts'} Ts "; }    # Text Rise (Super/Subscript)
	if ( defined $params{'Tr'} ) { $ptext .= " $params{'Tr'} Tr "; }    # Rendering Mode
	if ( defined $params{'TL'} ) { $ptext .= " $params{'TL'} TL "; }    # Text Leading
	if ( defined $params{'Tc'} ) { $ptext .= " $params{'Tc'} Tc "; }    # Character spacing
	if ( defined $params{'Tw'} ) { $ptext .= " $params{'Tw'} Tw "; }    # Word Spacing
	if ( defined $params{'Tz'} ) { $ptext .= " $params{'Tz'} Tz "; }    # Horizontal Scaling
	if ( defined $params{'rot'} ) {                                     # Moveto and rotate
		my ( $r, $x, $y ) = split( /\s+/, $params{'rot'}, 3 );
		$x = 0 unless ( $x > 0 );
		$y = 0 unless ( $y > 0 );
		my $cos = cos( $r * $piover180 );
		my $sin = sin( $r * $piover180 );
		$ptext .= sprintf( " %.5f %.5f -%.5f %.5f %s %s Tm ", $cos, $sin, $sin, $cos, $x, $y );
	}
	if ( defined $params{'Tf'} ) { $ptext .= "/F$params{'Tf'} Tf "; }    # Font size
	if ( defined $params{'Td'} ) { $ptext .= " $params{'Td'} Td "; }     # Moveto
	if ( defined $params{'TD'} ) { $ptext .= " $params{'TD'} TD "; }     # Moveto and set TL
	if ( defined $params{'T*'} ) { $ptext .= " T* "; }                   # New line
	if ( defined $params{'text'} ) {
		$params{'text'} =~ s|([()])|\\$1|g;
		$ptext .= "($params{'text'}) Tj ";
	}
	if ( defined $params{'end'} ) {
		$ptext .= " ET";
		$self->{'pdf'}->page_stream($self);
		$self->{'pdf'}->add("$ptext");
	}
	PDF::Create::debug( 3, "text(): $ptext" );
	1;
}

sub string
{
	my $self  = shift;
	my $font  = shift;
	my $size  = shift;
	my $x     = shift;
	my $y     = shift;
	my $s     = shift;
	my $align = shift || 'L';

	if ( uc($align) eq "R" ) {
		$x -= $size * $self->string_width( $font, $s );
	} elsif ( uc($align) eq "C" ) {
		$x -= $size * $self->string_width( $font, $s ) / 2;
	}

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->uses_font( $self, $font );
	$s =~ s|([()])|\\$1|g;
	$self->{'pdf'}->add("BT /F$font $size Tf $x $y Td ($s) Tj ET");
}

sub string_underline
{
	my $self   = shift;
	my $font   = shift;
	my $size   = shift;
	my $x      = shift;
	my $y      = shift;
	my $string = shift;
	my $align  = shift || 'L';

	my $len = $self->string_width( $font, $string ) * $size;
	my $len2 = $len / 2;
	if ( uc($align) eq "R" ) {
		$self->line( $x - $len, $y - 1, $x, $y - 1 );
	} elsif ( uc($align) eq "C" ) {
		$self->line( $x - $len2, $y - 1, $x + $len2, $y - 1 );
	} else {
		$self->line( $x, $y - 1, $x + $len, $y - 1 );
	}
	return $len;
}

sub stringl
{
	my $self = shift;
	my $font = shift;
	my $size = shift;
	my $x    = shift;
	my $y    = shift;
	my $s    = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->uses_font( $self, $font );
	$s =~ s|([()])|\\$1|g;
	$self->{'pdf'}->add("BT /F$font $size Tf $x $y Td ($s) Tj ET");
}

sub stringr
{
	my $self = shift;
	my $font = shift;
	my $size = shift;
	my $x    = shift;
	my $y    = shift;
	my $s    = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->uses_font( $self, $font );
	$x -= $size * $self->string_width( $font, $s );
	$s =~ s|([()])|\\$1|g;
	$self->{'pdf'}->add(" BT /F$font $size Tf $x $y Td ($s) Tj ET");
}

sub stringc
{
	my $self = shift;
	my $font = shift;
	my $size = shift;
	my $x    = shift;
	my $y    = shift;
	my $s    = shift;

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->uses_font( $self, $font );
	$x -= $size * $self->string_width( $font, $s ) / 2;
	$s =~ s|([()])|\\$1|g;
	$self->{'pdf'}->add(" BT /F$font $size Tf $x $y Td ($s) Tj ET");
}

sub string_width
{
	my $self   = shift;
	my $font   = shift;
	my $string = shift;

	croak 'No string given' unless defined $string;

	my $fname = $self->{'pdf'}{'fonts'}{$font}{'BaseFont'}[1];
	my $w     = 0;
	for my $c ( split '', $string ) {
		$w += $$font_widths{$fname}[ ord $c ];
	}
	$w / 1000;
}

sub printnl
{
	my $self = shift;
	my $s    = shift;
	my $font = shift;
	my $size = shift;
	my $x    = shift;
	my $y    = shift;

	# set up current_x/y used in stringml
	$self->{'current_y'} = $y if defined $y;
	carp 'No starting position given, using 800' if !defined $self->{'current_y'};
	$self->{'current_y'}    = 800   if !defined $self->{'current_y'};
	$self->{'current_x'}    = $x    if defined $x;
	$self->{'current_x'}    = 20    if !defined $self->{'current_x'};
	$self->{'current_size'} = $size if defined $size;
	$self->{'current_size'} = 12    if !defined $self->{'current_size'};
	$self->{'current_font'} = $font if defined $font;
	croak 'No font found !' if !defined $self->{'current_font'};

	# print the line(s)
	my $n = 0;
	for my $line ( split '\n', $s ) {
		$n++;
		$self->string( $self->{'current_font'}, $self->{'current_size'}, $self->{'current_x'}, $self->{'current_y'}, $line );
		$self->{'current_y'} = $self->{'current_y'} - $self->{'current_size'};
	}
	return $n;
}

#######################################################################
# Place an image on the current page
#
sub image
{
	my $self   = shift;
	my %params = @_;

	my $img    = $params{'image'} || "1.2";
	my $image  = $img->{num};
	my $xpos   = $params{'xpos'} || 0;
	my $ypos   = $params{'ypos'} || 0;
	my $xalign = $params{'xalign'} || 0;
	my $yalign = $params{'yalign'} || 0;
	my $xscale = $params{'xscale'} || 1;
	my $yscale = $params{'yscale'} || 1;
	my $rotate = $params{'rotate'} || 0;
	my $xskew  = $params{'xskew'} || 0;
	my $yskew  = $params{'yskew'} || 0;

	$xscale *= $img->{width};
	$yscale *= $img->{height};

	if ( $xalign == 1 ) {
		$xpos -= $xscale / 2;
	} elsif ( $xalign == 2 ) {
		$xpos -= $xscale;
	}

	if ( $yalign == 1 ) {
		$ypos -= $yscale / 2;
	} elsif ( $yalign == 2 ) {
		$ypos -= $yscale;
	}

	$self->{'pdf'}->page_stream($self);
	$self->{'pdf'}->uses_xobject( $self, $image );
	$self->{'pdf'}->add("q\n");

	# TODO: image: Merge position with rotate
	$self->{'pdf'}->add("1 0 0 1 $xpos $ypos cm\n") if ( $xpos || $ypos );
	if ($rotate) {
		my $sinth = sin($rotate);
		my $costh = cos($rotate);
		$self->{'pdf'}->add("$costh $sinth -$sinth $costh 0 0 cm\n");
	}
	if ( $xscale || $yscale ) {
		$self->{'pdf'}->add("$xscale 0 0 $yscale 0 0 cm\n");
	}
	if ( $xskew || $yskew ) {
		my $tana = sin($xskew) / cos($xskew);
		my $tanb = sin($yskew) / cos($xskew);
		$self->{'pdf'}->add("1 $tana $tanb 1 0 0 cm\n");
	}
	$self->{'pdf'}->add("/Image$image Do\n");
	$self->{'pdf'}->add("Q\n");
}

#######################################################################
# Table with font widths for the supported fonts
#
sub init_widths
{
	{  'Courier' => [ 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
					  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599
					],
	   'Courier-Bold' => [ 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
						   599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599
						 ],
	   'Courier-BoldOblique' => [ 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
								  599, 599, 599, 599
								],
	   'Courier-Oblique' => [ 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599,
							  599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599, 599
							],
	   'Helvetica' => [ 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277, 277, 277, 277, 277, 277, 277,
						277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277, 277, 277, 277, 277, 354, 555,
						555, 888, 666, 220, 332, 332, 388, 583, 277, 332, 277,  277, 555, 555, 555, 555, 555, 555,
						555, 555, 555, 555, 277, 277, 583, 583, 583, 555, 1014, 666, 666, 721, 721, 666, 610, 777,
						721, 277, 499, 666, 555, 832, 721, 777, 666, 777, 721,  666, 610, 721, 666, 943, 666, 666,
						610, 277, 277, 277, 468, 555, 221, 555, 555, 499, 555,  555, 277, 555, 555, 221, 221, 499,
						221, 832, 555, 555, 555, 555, 332, 499, 277, 555, 499,  721, 499, 499, 499, 333, 259, 333,
						583, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277, 277, 277, 277, 277, 277, 277,
						277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277, 277, 277, 277, 277, 277, 332,
						555, 555, 166, 555, 555, 555, 555, 190, 332, 555, 332,  332, 499, 499, 277, 555, 555, 555,
						277, 277, 536, 349, 221, 332, 332, 555, 999, 999, 277,  610, 277, 332, 332, 332, 332, 332,
						332, 332, 332, 277, 332, 332, 277, 332, 332, 332, 999,  277, 277, 277, 277, 277, 277, 277,
						277, 277, 277, 277, 277, 277, 277, 277, 277, 999, 277,  369, 277, 277, 277, 277, 555, 777,
						999, 364, 277, 277, 277, 277, 277, 888, 277, 277, 277,  277, 277, 277, 221, 610, 943, 610,
						277, 277, 277, 277
					  ],
	   'Helvetica-Bold' => [ 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,
							 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 332, 473, 555, 555, 888, 721, 277,
							 332, 332, 388, 583, 277, 332, 277, 277, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 332, 332,
							 583, 583, 583, 610, 974, 721, 721, 721, 721, 666, 610, 777, 721, 277, 555, 721, 610, 832, 721, 777,
							 666, 777, 721, 666, 610, 721, 666, 943, 666, 666, 610, 332, 277, 332, 583, 555, 277, 555, 610, 555,
							 610, 555, 332, 610, 610, 277, 277, 555, 277, 888, 610, 610, 610, 610, 388, 555, 332, 610, 555, 777,
							 555, 555, 499, 388, 279, 388, 583, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,
							 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,
							 277, 332, 555, 555, 166, 555, 555, 555, 555, 237, 499, 555, 332, 332, 610, 610, 277, 555, 555, 555,
							 277, 277, 555, 349, 277, 499, 499, 555, 999, 999, 277, 610, 277, 332, 332, 332, 332, 332, 332, 332,
							 332, 277, 332, 332, 277, 332, 332, 332, 999, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,
							 277, 277, 277, 277, 277, 999, 277, 369, 277, 277, 277, 277, 610, 777, 999, 364, 277, 277, 277, 277,
							 277, 888, 277, 277, 277, 277, 277, 277, 277, 610, 943, 610, 277, 277, 277, 277
						   ],
	   'Helvetica-BoldOblique' => [ 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,
									277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 332, 473, 555,
									555, 888, 721, 277, 332, 332, 388, 583, 277, 332, 277, 277, 555, 555, 555, 555, 555, 555,
									555, 555, 555, 555, 332, 332, 583, 583, 583, 610, 974, 721, 721, 721, 721, 666, 610, 777,
									721, 277, 555, 721, 610, 832, 721, 777, 666, 777, 721, 666, 610, 721, 666, 943, 666, 666,
									610, 332, 277, 332, 583, 555, 277, 555, 610, 555, 610, 555, 332, 610, 610, 277, 277, 555,
									277, 888, 610, 610, 610, 610, 388, 555, 332, 610, 555, 777, 555, 555, 499, 388, 279, 388,
									583, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277,
									277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 332,
									555, 555, 166, 555, 555, 555, 555, 237, 499, 555, 332, 332, 610, 610, 277, 555, 555, 555,
									277, 277, 555, 349, 277, 499, 499, 555, 999, 999, 277, 610, 277, 332, 332, 332, 332, 332,
									332, 332, 332, 277, 332, 332, 277, 332, 332, 332, 999, 277, 277, 277, 277, 277, 277, 277,
									277, 277, 277, 277, 277, 277, 277, 277, 277, 999, 277, 369, 277, 277, 277, 277, 610, 777,
									999, 364, 277, 277, 277, 277, 277, 888, 277, 277, 277, 277, 277, 277, 277, 610, 943, 610,
									277, 277, 277, 277
								  ],
	   'Helvetica-Oblique' => [
		   277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277,
		   277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277,
		   277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277,
		   277, 354, 555, 555, 888, 666, 221, 332, 332, 388,  583,
		   277, 332, 277, 277, 555, 555, 555, 555, 555, 555,  555,
		   555, 555, 555, 277, 277, 583, 583, 583, 555, 1014, 666,
		   666, 721, 721, 666, 610, 777, 721, 277, 499, 666,  555,
		   832, 721, 777, 666, 777, 721, 666, 610, 721, 666,  943,
		   666, 666, 610, 277, 277, 277, 468, 555, 221, 555,  555,
		   499, 555, 555, 277, 555, 555, 221, 221, 499, 221,  832,
		   555, 555, 555, 555, 332, 499, 277, 555, 499, 721,  499,
		   499, 499, 333, 259, 333, 583, 277, 277, 277, 277,  277,
		   277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277,
		   277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277,
		   277, 277, 277, 277, 277, 277, 277, 332, 555, 555,  166,
		   555, 555, 555, 555, 190, 332, 555, 332, 332, 499,  499,
		   277, 555, 555, 555, 277, 277, 536, 349, 221, 332,  332,
		   555, 999, 999, 277, 610, 277, 332, 332, 332, 332,  332,
		   332, 332, 332, 277, 332, 332, 277, 332, 332, 332,  999,
		   277, 277, 277, 277, 277, 277, 277, 277, 277, 277,  277,
		   277, 277, 277, 277, 277, 999, 277, 369, 277, 277,  277,
		   277, 555, 777, 999, 364, 277, 277, 277, 277, 277,  888,
		   277, 277, 277, 277, 277, 277, 221, 610, 943, 610,  277,
		   277, 277, 277

							  ],
	   'Times-Bold' => [ 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 332, 554, 499, 499, 999, 832, 332,
						 332, 332, 499, 569, 249, 332, 249, 277, 499, 499, 499, 499, 499, 499, 499, 499, 499, 499, 332, 332,
						 569, 569, 569, 499, 929, 721, 666, 721, 721, 666, 610, 777, 777, 388, 499, 777, 666, 943, 721, 777,
						 610, 777, 721, 555, 666, 721, 721, 999, 721, 721, 666, 332, 277, 332, 580, 499, 332, 499, 555, 443,
						 555, 443, 332, 499, 555, 277, 332, 555, 277, 832, 555, 499, 555, 555, 443, 388, 332, 555, 499, 721,
						 499, 499, 443, 393, 219, 393, 519, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						 249, 332, 499, 499, 166, 499, 499, 499, 499, 277, 499, 499, 332, 332, 555, 555, 249, 499, 499, 499,
						 249, 249, 539, 349, 332, 499, 499, 499, 999, 999, 249, 499, 249, 332, 332, 332, 332, 332, 332, 332,
						 332, 249, 332, 332, 249, 332, 332, 332, 999, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						 249, 249, 249, 249, 249, 999, 249, 299, 249, 249, 249, 249, 666, 777, 999, 329, 249, 249, 249, 249,
						 249, 721, 249, 249, 249, 277, 249, 249, 277, 499, 721, 555, 249, 249, 249, 249
					   ],
	   'Times-BoldItalic' => [ 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
							   249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 388, 554, 499, 499, 832, 777, 332,
							   332, 332, 499, 569, 249, 332, 249, 277, 499, 499, 499, 499, 499, 499, 499, 499, 499, 499, 332, 332,
							   569, 569, 569, 499, 831, 666, 666, 666, 721, 666, 666, 721, 777, 388, 499, 666, 610, 888, 721, 721,
							   610, 721, 666, 555, 610, 721, 666, 888, 666, 610, 610, 332, 277, 332, 569, 499, 332, 499, 499, 443,
							   499, 443, 332, 499, 555, 277, 277, 499, 277, 777, 555, 499, 499, 499, 388, 388, 277, 555, 443, 666,
							   499, 443, 388, 347, 219, 347, 569, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
							   249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
							   249, 388, 499, 499, 166, 499, 499, 499, 499, 277, 499, 499, 332, 332, 555, 555, 249, 499, 499, 499,
							   249, 249, 499, 349, 332, 499, 499, 499, 999, 999, 249, 499, 249, 332, 332, 332, 332, 332, 332, 332,
							   332, 249, 332, 332, 249, 332, 332, 332, 999, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
							   249, 249, 249, 249, 249, 943, 249, 265, 249, 249, 249, 249, 610, 721, 943, 299, 249, 249, 249, 249,
							   249, 721, 249, 249, 249, 277, 249, 249, 277, 499, 721, 499, 249, 249, 249, 249
							 ],
	   'Times-Italic' => [ 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						   249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 332, 419, 499, 499, 832, 777, 332,
						   332, 332, 499, 674, 249, 332, 249, 277, 499, 499, 499, 499, 499, 499, 499, 499, 499, 499, 332, 332,
						   674, 674, 674, 499, 919, 610, 610, 666, 721, 610, 610, 721, 721, 332, 443, 666, 555, 832, 666, 721,
						   610, 721, 610, 499, 555, 721, 610, 832, 610, 555, 555, 388, 277, 388, 421, 499, 332, 499, 499, 443,
						   499, 443, 277, 499, 499, 277, 277, 443, 277, 721, 499, 499, 499, 499, 388, 388, 277, 499, 443, 666,
						   443, 443, 388, 399, 274, 399, 540, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						   249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						   249, 388, 499, 499, 166, 499, 499, 499, 499, 213, 555, 499, 332, 332, 499, 499, 249, 499, 499, 499,
						   249, 249, 522, 349, 332, 555, 555, 499, 888, 999, 249, 499, 249, 332, 332, 332, 332, 332, 332, 332,
						   332, 249, 332, 332, 249, 332, 332, 332, 888, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						   249, 249, 249, 249, 249, 888, 249, 275, 249, 249, 249, 249, 555, 721, 943, 309, 249, 249, 249, 249,
						   249, 666, 249, 249, 249, 277, 249, 249, 277, 499, 666, 499, 249, 249, 249, 249
						 ],
	   'Times-Roman' => [ 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						  249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 332, 407, 499, 499, 832, 777, 332,
						  332, 332, 499, 563, 249, 332, 249, 277, 499, 499, 499, 499, 499, 499, 499, 499, 499, 499, 277, 277,
						  563, 563, 563, 443, 920, 721, 666, 666, 721, 610, 555, 721, 721, 332, 388, 721, 610, 888, 721, 721,
						  555, 721, 666, 555, 610, 721, 721, 943, 721, 721, 610, 332, 277, 332, 468, 499, 332, 443, 499, 443,
						  499, 443, 332, 499, 499, 277, 277, 499, 277, 777, 499, 499, 499, 499, 332, 388, 277, 499, 499, 721,
						  499, 499, 443, 479, 199, 479, 540, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						  249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						  249, 332, 499, 499, 166, 499, 499, 499, 499, 179, 443, 499, 332, 332, 555, 555, 249, 499, 499, 499,
						  249, 249, 452, 349, 332, 443, 443, 499, 999, 999, 249, 443, 249, 332, 332, 332, 332, 332, 332, 332,
						  332, 249, 332, 332, 249, 332, 332, 332, 999, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249, 249,
						  249, 249, 249, 249, 249, 888, 249, 275, 249, 249, 249, 249, 610, 721, 888, 309, 249, 249, 249, 249,
						  249, 666, 249, 249, 249, 277, 249, 249, 277, 499, 721, 499, 249, 249, 249, 249
						],
	};
}

1;