package MyFav::PdfGenerator;

# creates two collumn pdf, with autosizing, taking into account the page dimensions of %dimensions and
# the choosen layout of %labelLayout

use strict;
use CGI::Carp qw ( fatalsToBrowser );
use Text::Wrap;  # core
use PDF::Create;  # local
use FileHandle;  # core

my %dimensions = (
	A4 => {
		xStart => 40,
		yStart => 790,
		xEnd   => 550,
		yEnd   => 40,
		xSpace => 40
	}
);

my %labelLayout = (
	Default => {
		Header => {
			Font        => "Helvetica",
			Size        => 10,
			LineSpacing => 15
		},
		URL => {
			Font        => "Courier",
			Size        => 10,
			LineSpacing => 15
		},
		Code => {
			Font  => "Helvetica-Bold",
			Size  => 10,
			Align => "Center"
		},
		Footer => {
			Font        => "Helvetica",
			Size        => 10,
			LineSpacing => 15
		},
		Ad => {
			Font        => "Helvetica",
			Size        => 6,
			LineSpacing => 6,
			Align => "Center"
		},
		SectionSpacer => {
			Small  => 13,
			Medium => 20,
			Large  => 40
		}
	}
);

# class variables
my $pdf;
my $page;
my $xAxis;
my $yAxis;
my $baseClass;

sub new {
	my $class = shift;

	croak "Illegal parameter list has odd number of values"
	  if @_ % 2;

	my (%params) = @_;

	$baseClass = MyFav::Base->new();

	bless {
		"size"   => $params{"size"},
		"layout" => $params{"layout"}
	}, $class;
}

sub createPdf {
	my $self      = shift;
	my $releaseId = shift;
	my $size      = $self->getSize();

	my $configDb = MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);

	my $labelHeader = $configDb->getActiveLabelHeader($releaseId);
	my $labelFooter = $configDb->getActiveLabelFooter($releaseId);
	
    my $voucherHeaderDisabled = $configDb->isVoucherHeaderDisabled($releaseId);
    my $voucherFooterDisabled = $configDb->isVoucherFooterDisabled($releaseId);

	my $versionId   = $configDb->getVersionId();
	my $labelAd     = $configDb->getLabelAd() . " " . $versionId;
	my $downloadUrl = $configDb->getDownloadUrl($releaseId);

	my $releaseDbName = $baseClass->getReleaseDbPrefix() . $releaseId;
	my $releaseDb     = MyFav::DB::ReleaseDB->new(
		"dataBaseName" => $releaseDbName,
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);

	my @codes = $releaseDb->getAllCodes();

	my $fh = *STDOUT;

	$pdf = PDF::Create->new(
		'fh'           => $fh,
		'Author'       => "$versionId",
		'Title'        => "Download Codes of $releaseId",
		'CreationDate' => [localtime],
	);

	my $mediaBox = $pdf->new_page( 'MediaBox' => $pdf->get_page_size($size) );

	# wrap the string into an array considering string length on the printed pdf
	my @headerArray = $self->wrapTextToArray( 'Header', $labelHeader );
	my @urlArray    = $self->wrapUrlToArray($downloadUrl);
	my @footerArray = $self->wrapTextToArray( 'Footer', $labelFooter );
	my @adArray     = $self->wrapTextToArray( 'Ad', $labelAd );

	# calculate height of one label
	# height of one section is elements of array (lines -1) * lineSpacing
	# no 'code' here since it is only one line
	# (no seperate LineSpacing for 'Code' existing)
	my $labelHeight = "";
	
	if ( ! $voucherHeaderDisabled) {
	   $labelHeight = ($#headerArray) * $self->getLineSpacing('Header');    
       $labelHeight += $self->getSectionSpacer('Medium');
	}
	$labelHeight += ($#urlArray) * $self->getLineSpacing('URL');
	$labelHeight += $self->getSectionSpacer('Medium');
    
    if ( ! $voucherFooterDisabled ) {
        $labelHeight += $self->getSectionSpacer('Medium');
        $labelHeight += ($#footerArray) * $self->getLineSpacing('Footer');
        $labelHeight += $self->getSectionSpacer('Medium');
    }

	$labelHeight += ($#adArray) * $self->getLineSpacing('Ad');

	# lets start printing
	my $startOfPage = 1;

	# initialise x + y position
	$self->setXAxisPosition( $self->getPageXStart() );
	$self->setYAxisPosition( $self->getPageYStart() );

	$page = $mediaBox->new_page;

	foreach my $downloadCode (@codes) {

		# handle new collumn/ new page
		if ( $self->notEnoughSpaceForNextLabelOnThisCollumn($labelHeight) ) {

			# move Y-axis back to the top
			$self->setYAxisPosition( $self->getPageYStart() );
			$startOfPage = 1;

			# if this is left collumn, set X-axis to the right collumn
			if ( $self->getXAxisPosition() == $self->getPageXStart() ) {
				$self->setXAxisPosition( $self->getPageXStart() +
					  $self->getPdfCollumnWidth() +
					  $self->getPageXSpace() );
			}
			else {

				# insert new page and reset X-axis to left side
				$page = $mediaBox->new_page;
				$self->setXAxisPosition( $self->getPageXStart() );
			}
		}

		# no extra space at the beginning of the page
		if ($startOfPage) {
			$startOfPage = 0;
		}
		else {

			# space between the labels on one page
			$self->insertSectionSpacer('Large');
		}

        if ( ! $voucherHeaderDisabled ) {   
    	    # main text
    	    $self->printElement( 'Header', @headerArray );
    
    	    # space
    	    $self->insertSectionSpacer('Medium');
        }
		# url
		$self->printElement( 'URL', @urlArray );

		# space
		$self->insertSectionSpacer('Medium');

		# code
		$self->printElement( 'Code', $downloadCode );
		
        if ( ! $voucherFooterDisabled ) {
		    # space
		    $self->insertSectionSpacer('Medium');

		    # footers
   	        $self->printElement( 'Footer', @footerArray );
        }

		# space
		$self->insertSectionSpacer('Small');

		# advertisment
		$self->printElement( 'Ad', @adArray );
	}

	$pdf->close;
}

sub notEnoughSpaceForNextLabelOnThisCollumn {
	my $self        = shift;
	my $labelHeight = shift;

	if ( $self->getYAxisPosition() -
		$self->getSectionSpacer('Large') -
		$labelHeight < $self->getPageYEnd() )
	{
		return 1;
	}
	else {
		return 0;
	}
}

# central print method
sub printElement {
	my $self        = shift;
	my $elementName = shift;
	my @text        = @_;
	my $xOffset = 0;    # for aligning text to center (or right in the future)

	my $xAxis  = $self->getXAxisPosition();
	my $yAxis  = $self->getYAxisPosition();
	my $layout = $self->getLayout();
	my $pdf    = $self->getPdf();
	my $page   = $self->getPage();

	my $fontName      = $self->getFontName($elementName);
	my $fontSize      = $self->getFontSize($elementName);
	my $lineSpacing   = $self->getLineSpacing($elementName);
	my $fontAlignment = $self->getFontAlignment($elementName);

	my $font = $pdf->font( 'BaseFont' => $fontName );

	my $cnt = 0;
	foreach my $line (@text) {
		$yAxis = $self->getYAxisPosition();    # get fresh position data

		if ( $fontAlignment eq "Center" ) {
			$xOffset =
			  $self->getOffsetForCenterAlignment( $line, $fontName, $fontSize );
		}

		$page->string( $font, $fontSize, $xAxis + $xOffset, $yAxis, $line );

		# only insert line spacing between lines
		if ( $cnt != $#text ) {
			$self->setYAxisPosition( $yAxis - $lineSpacing );
		}
		$cnt++;
	}
}

sub insertSectionSpacer {
	my $self       = shift;
	my $spacerSize = shift;

	my $yAxis        = $self->getYAxisPosition();
	my $spacerHeight = $self->getSectionSpacer($spacerSize);

	$self->setYAxisPosition( $yAxis - $spacerHeight );
}

sub wrapTextToArray {
	my $self        = shift;
	my $elementName = shift;
	my $text        = shift;
	my $fontName    = $self->getFontName($elementName);
	my $fontSize    = $self->getFontSize($elementName);

	# start value, too wide for A4 or letter. will be count down here
	my $textCollumnWidth = 100;
	my $pdfCollumnWidth  = $self->getPdfCollumnWidth();

	while ( $textCollumnWidth > 5 ) {
		my @wrappedText = $self->getWrappedText( $text, $textCollumnWidth );
		my $longestLine = $self->getLongestLine(@wrappedText);

		my $pdfStringWidth =
		  $self->getPdfStringWidth( $longestLine, $fontName, $fontSize );

		if ( $pdfStringWidth < $pdfCollumnWidth ) {
			return @wrappedText;
		}
		$textCollumnWidth--;
	}
	return "render error";
}

sub wrapUrlToArray {
	my $self     = shift;
	my $text     = shift;
	my $fontName = $self->getFontName('URL');
	my $fontSize = $self->getFontSize('URL');

	# start value, too wide for A4 or letter. will be count down here
	my $textCollumnWidth = 100;
	my $pdfCollumnWidth  = $self->getPdfCollumnWidth();

	while ( $textCollumnWidth > 5 ) {
		my @wrappedUrl = $self->getWrappedUrl( $text, $textCollumnWidth );
		my $longestLine = $self->getLongestLine(@wrappedUrl);

		my $pdfStringWidth =
		  $self->getPdfStringWidth( $longestLine, $fontName, $fontSize );

		if ( $pdfStringWidth < $pdfCollumnWidth ) {
			return @wrappedUrl;
		}
		$textCollumnWidth--;
	}
	return "render error";
}

sub getWrappedUrl {
	my $self     = shift;
	my $url      = shift;
	my $maxWidth = shift;
	my $maxWidthReduced =
	  $maxWidth - 1;    # shorten by one char to make space for search char

	$url =~ s{(
           .{0,$maxWidth}\Z|           # if line end is within $maxWidth > break
           .{8,$maxWidthReduced}(/|\.|-|\?)| # match if between 8 and $max_width_reduced
                                                # the chars "/" "." "-" or "?" are present, has to start with "8"
                                                # since url beginning "http://" would be on seperate line
           .{0,$maxWidth})}            # if none of the previous is matching line break after $max_width chars
         {$1\n}igx;

	my @wrappedArray = split /\n/, $url;

	return @wrappedArray;
}

sub getPdfStringWidth {
	my $self     = shift;
	my $text     = shift;
	my $fontName = shift;
	my $fontSize = shift;
	my $pageSize = $self->getSize();

	my $testPdf = PDF::Create->new();
	my $mediaBox =
	  $testPdf->new_page( 'MediaBox' => $testPdf->get_page_size($pageSize) );
	my $page = $mediaBox->new_page;
	my $testFont = $testPdf->font( 'BaseFont' => $fontName );

	my $stringWidth = ( $page->string_width( $testFont, $text ) ) * $fontSize;

	return $stringWidth;
}

sub getWrappedText {
	my $self             = shift;
	my $text             = shift;
	my $textCollumnWidth = shift;

	local ($Text::Wrap::columns) = $textCollumnWidth;
	my $wrappedText = wrap( '', '', $text );
	my @wrappedArray = split /\n/, $wrappedText;

	return @wrappedArray;
}

sub getLongestLine {
	my $self         = shift;
	my @wrappedArray = @_;

	my @tempSortArray = sort { length $b <=> length $a } @wrappedArray;
	my $longestLine = $tempSortArray[0];

	return $longestLine;
}

sub getPdfCollumnWidth {
	my $self = shift;

	return (
		$self->getPageXEnd() - $self->getPageXStart() - $self->getPageXSpace() )
	  / 2;
}

sub getOffsetForCenterAlignment {
	my $self     = shift;
	my $line     = shift;
	my $fontName = shift;
	my $fontSize = shift;

	my $pdfCollumnWidth = $self->getPdfCollumnWidth();
	my $pdfStringWidth =
	  $self->getPdfStringWidth( $line, $fontName, $fontSize );
	return ( $pdfCollumnWidth - $pdfStringWidth ) / 2;
}

sub getSize {
	my $self = shift;
	return $self->{size};
}

sub getLayout {
	my $self = shift;
	return $self->{layout};
}

sub getXAxisPosition {
	return $xAxis;
}

sub getYAxisPosition {
	return $yAxis;
}

sub getPdf {
	return $pdf;
}

sub getPage {
	return $page;
}

sub getFontName {
	my $self        = shift;
	my $elementName = shift;
	my $layout      = $self->getLayout();

	return $labelLayout{$layout}{$elementName}{'Font'};
}

sub getFontSize {
	my $self        = shift;
	my $elementName = shift;
	my $layout      = $self->getLayout();

	return $labelLayout{$layout}{$elementName}{'Size'};
}

sub getFontAlignment {
	my $self        = shift;
	my $elementName = shift;
	my $layout      = $self->getLayout();

	if ($labelLayout{$layout}{$elementName}{'Align'}) {
		return $labelLayout{$layout}{$elementName}{'Align'};
	}
	else {
		return ""
	}
}

sub getLineSpacing {
	my $self        = shift;
	my $elementName = shift;
	my $layout      = $self->getLayout();

	return $labelLayout{$layout}{$elementName}{'LineSpacing'};
}

sub getSectionSpacer {
	my $self       = shift;
	my $spacerSize = shift;
	my $layout     = $self->getLayout();

	return $labelLayout{$layout}{'SectionSpacer'}{$spacerSize};
}

sub setXAxisPosition {
	my $self  = shift;
	my $value = shift;

	$xAxis = $value;
}

sub setYAxisPosition {
	my $self  = shift;
	my $value = shift;

	$yAxis = $value;
}

sub getPageXStart {
	my $self = shift;
	my $size = $self->getSize();

	return $dimensions{$size}{'xStart'};
}

sub getPageYStart {
	my $self = shift;
	my $size = $self->getSize();

	return $dimensions{$size}{'yStart'};
}

sub getPageXEnd {
	my $self = shift;
	my $size = $self->getSize();

	return $dimensions{$size}{'xEnd'};
}

sub getPageYEnd {
	my $self = shift;
	my $size = $self->getSize();

	return $dimensions{$size}{'yEnd'};
}

sub getPageXSpace {
	my $self = shift;
	my $size = $self->getSize();

	return $dimensions{$size}{'xSpace'};
}

1;
