package MyFav::DB::ConfigDB;

use strict;
use CGI::Carp qw ( fatalsToBrowser );  

use base 'MyFav::DB::General';


sub createConfigDataBase {
	my $self = shift;
	my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("CREATE TABLE $dataBaseName (project TEXT, keyVal TEXT, dataVal TEXT)");
}

sub fillWithConfigDefaults {
	my $self = shift;
	my $dataBaseName = $self->getDataBaseName();
    
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'adminPassword', 'riuFDStrPbGp6x/wr+conA')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'versionId', 'My Favorite Things 0.5')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'releaseNameLength', '40')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'releaseIdLength', '20')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'codeCountLength', '6')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'expirationTimer', '3600')");
    # 1 minute, has to be in seconds for delete method
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'rateLimiterTimeFrame', '60s')"); 
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'rateLimiterMaxHits', '30')"); # max. 30x in 1 minute
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'maximumUploadFileSize', '209715200')"); # 200 MB
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'downloadCgiPath', '')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'forwarderDir', '')");
    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'loginCgiPath', '')");
	$self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'downloadDefaultPath', '')");
	$self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'webLibBaseUrl', '')");
	$self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'labelHeader', 'Thank you for buying this vinyl record.You have now the opportunity to download MP3 audio files of the entire recording. To do so, please follow this link and enter the download code.')");
	$self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'labelFooter', 'Please note: This is a One-Time download only.')");
	$self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('GLOBAL', 'labelAd', 'Download powered by')");	
}

sub insertConfigValue {
	my $self = shift;
	my $projectId = shift;
	my $key = shift;
	my $value = shift;
	my $dataBaseName = $self->getDataBaseName();	

	$self->writeToDataBase("INSERT INTO $dataBaseName (project, keyVal, dataVal) VALUES ('$projectId','$key','$value')");
}

sub releaseExistsInConfigDb {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT COUNT(*) FROM config WHERE project='$releaseId'");
	return $result;
}

sub getReleaseName {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' AND keyVal='releaseName'");
	return $result;
}

sub getDownloadUrl {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' AND keyVal='downloadUrl'");
	return $result;
}

sub getReleaseCgiUrl {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' AND keyVal='releaseCgiUrl'");
	return $result;
}

sub getReleaseDbPath {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' AND keyVal='releaseDbPath'");
	return $result;
}

sub getUploadFilePath {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' AND keyVal='uploadFilePath'");
	return $result;
}


sub getStatus {
    my $self = shift;
    my $releaseId = shift;
    
    my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' AND keyVal='status'");
    return $result;
}


sub getReleaseIdByReleaseHash {
	my $self = shift;
	my $releaseIdHash = shift;
	
	my $result = $self->selectSingleValue("SELECT project FROM config WHERE dataVal='$releaseIdHash' AND keyVal='releaseIdHash'");
	return $result;
}


sub getVersionId {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='versionId'");
	return $result;
}

sub getReleaseNameLength {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='releaseNameLength'");
	return $result;
}

sub getReleaseIdLength {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='releaseIdLength'");
	return $result;
}

sub getCodeCountLength {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='codeCountLength'");
	return $result;
}

sub getExpirationTimer {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='expirationTimer'");
	return $result;
}

sub getRateLimiterTimeFrame {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='rateLimiterTimeFrame'");
	return $result;
}

sub getRateLimiterMaxHits {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='rateLimiterMaxHits'");
	return $result;
}

sub getMaximumUploadFileSize {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' AND keyVal='maximumUploadFileSize'");
	return $result;
}

sub getDownloadCgiPath {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='downloadCgiPath'");
	return $result;
}

sub getForwarderDir {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='forwarderDir'");
	return $result;
}


sub getLoginCgiPath {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='loginCgiPath'");
	return $result;
}


sub getDownloadDefaultPath {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='downloadDefaultPath'");
	return $result;
}

sub getPathIndexHtmlDir {
	my $self = shift;
	my $releaseId = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='$releaseId' and keyVal='pathIndexHtmlDir'");
	return $result;
}

sub getWebLibBaseUrl {
	my $self = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='webLibBaseUrl'");
	return $result;
}

sub getListOfAllReleaseNames {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	my %releaseNames = $self->selectHashSimple("SELECT project, dataVal from $dataBaseName WHERE keyVal='releaseName' AND project <> 'GLOBAL'");
	return %releaseNames;
}

sub deleteRelease {
	my $self         = shift;
	my $releaseId = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	$self->writeToDataBase("DELETE FROM $dataBaseName WHERE project='$releaseId'");
}

sub getAdminPassword {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM config WHERE project='GLOBAL' and keyVal='adminPassword'");
	return $result;
}

sub updatePassword {
	my $self         = shift;
	my $newPassword  = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$newPassword' WHERE project='GLOBAL' AND keyVal='adminPassword'");
}

sub getLabelHeader {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM $dataBaseName WHERE project='GLOBAL' and keyVal='labelHeader'");
	return $result;
}

sub getLabelFooter {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM $dataBaseName WHERE project='GLOBAL' and keyVal='labelFooter'");
	return $result;
}

sub getLabelAd {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM $dataBaseName WHERE project='GLOBAL' and keyVal='labelAd'");
	return $result;
}

sub getReleaseLabelHeader {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();
    
    my $result = $self->selectSingleValue("SELECT dataVal FROM $dataBaseName WHERE project='$releaseId' and keyVal='labelHeader'");
    return $result;
}

sub getReleaseLabelFooter {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();
    
    my $result = $self->selectSingleValue("SELECT dataVal FROM $dataBaseName WHERE project='$releaseId' and keyVal='labelFooter'");
    return $result;
}

sub getActiveLabelHeader {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();
    
    my $globalLabelHeader = $self->getLabelHeader($releaseId);
    my $releaseLabelHeader = $self->getReleaseLabelHeader($releaseId);
    
    if ( $releaseLabelHeader) {
        return $releaseLabelHeader;
    }
    else {
        return $globalLabelHeader;
    }
}

sub getActiveLabelFooter {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();
    
    my $globalLabelFooter = $self->getLabelFooter($releaseId);
    my $releaseLabelFooter = $self->getReleaseLabelFooter($releaseId);
    
    if ( $releaseLabelFooter) {
        return $releaseLabelFooter;
    }
    else {
        return $globalLabelFooter;
    }
}

sub isVoucherHeaderDisabled {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();
    
    my $result = $self->selectSingleValue("SELECT COUNT(*) FROM $dataBaseName WHERE project='$releaseId' and keyVal='voucherHeaderDisabled'");
    return $result;
}

sub isVoucherFooterDisabled {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();
    
    my $result = $self->selectSingleValue("SELECT COUNT(*) FROM $dataBaseName WHERE project='$releaseId' and keyVal='voucherFooterDisabled'");
    return $result;
}


# only for first time installation
sub updateDownloadCgiPath {
	my $self         = shift;
	my $downloadCgiPath  = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$downloadCgiPath' WHERE project='GLOBAL' AND keyVal='downloadCgiPath'");
}

sub updateLoginCgiPath {
	my $self         = shift;
	my $loginCgiPath  = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$loginCgiPath' WHERE project='GLOBAL' AND keyVal='loginCgiPath'");
}

sub updateForwarderDir {
	my $self         = shift;
	my $forwarderDir  = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$forwarderDir' WHERE project='GLOBAL' AND keyVal='forwarderDir'");
}

sub updateDownloadDefaultPath {
	my $self         = shift;
	my $downloadDefaultPath  = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$downloadDefaultPath' WHERE project='GLOBAL' AND keyVal='downloadDefaultPath'");
}

sub updateWebLibBaseUrl {
	my $self         = shift;
	my $webLibBaseUrl  = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$webLibBaseUrl' WHERE project='GLOBAL' AND keyVal='webLibBaseUrl'");
}

sub updateUploadFilePath {
    my $self         = shift;
    my $releaseId = shift;
    my $uploadFilePath  = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$uploadFilePath' WHERE project='$releaseId' AND keyVal='uploadFilePath'");
}

sub updateStatus {
    my $self         = shift;
    my $releaseId = shift;
    my $newStatus  = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$newStatus' WHERE project='$releaseId' AND keyVal='status'");
}

sub insertReleaseVoucherHeader {
    my $self         = shift;
    my $releaseId = shift;
    my $newHeaderText = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('$releaseId', 'labelHeader', '$newHeaderText')");
}

sub updateReleaseVoucherHeader {
    my $self         = shift;
    my $releaseId = shift;
    my $newHeaderText = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$newHeaderText' WHERE project='$releaseId' AND keyVal='labelHeader'");
}

sub deleteReleaseVoucherHeader {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("DELETE FROM $dataBaseName WHERE project='$releaseId' AND keyVal='labelHeader'");
}

sub insertReleaseVoucherFooter {
    my $self         = shift;
    my $releaseId = shift;
    my $newHeaderText = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('$releaseId', 'labelFooter', '$newHeaderText')");
}

sub updateReleaseVoucherFooter {
    my $self         = shift;
    my $releaseId = shift;
    my $newHeaderText = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("UPDATE $dataBaseName SET dataVal='$newHeaderText' WHERE project='$releaseId' AND keyVal='labelFooter'");
}

sub deleteReleaseVoucherFooter {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("DELETE FROM $dataBaseName WHERE project='$releaseId' AND keyVal='labelFooter'");
}

sub insertVoucherHeaderDisabled {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('$releaseId', 'voucherHeaderDisabled', '1')");
}

sub deleteVoucherHeaderDisabled {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("DELETE FROM $dataBaseName WHERE project='$releaseId' AND keyVal='voucherHeaderDisabled'");
}

sub insertVoucherFooterDisabled {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("INSERT INTO $dataBaseName VALUES ('$releaseId', 'voucherFooterDisabled', '1')");
}

sub deleteVoucherFooterDisabled {
    my $self         = shift;
    my $releaseId = shift;
    my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("DELETE FROM $dataBaseName WHERE project='$releaseId' AND keyVal='voucherFooterDisabled'");
}


1;
