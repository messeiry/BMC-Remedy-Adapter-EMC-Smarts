#!/usr/bin/perl -w

# BMC Remedy Perl Adapter for EMC Smarts
# Developed by: Mohamed ELMesseiry, EMC ASD, Solution Architect.
# mohamed.elmesseiry@emc.com
# version 1.0
# Notes :: the script need to be called from a shell script and pass the parameters as per USAGE Guide.

use SOAP::Lite;
use XML::Writer;
use XML::Writer::String;
use Data::Dumper;
use Try::Tiny;

#use SOAP::Lite +trace => "debug";

# CONFIGURATIONS
$username = "emcuser";
$password = "password\@123";
$timeZone = "";
$getbyid_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_Search_By_TKTNumber";

my @logininfo = (
    SOAP::Header->name('userName' => $username)->type(''),
    SOAP::Header->name('password' => $password)->type(''),
    SOAP::Header->name('timeZone' => $timeZone)->type('')
);
my $header = SOAP::Header->name('AuthenticationInfo' => \SOAP::Header->value(@logininfo));

if ($ENV{'SM_OBJ_Name'} ) {
	if ($ENV{'SM_OBJ_TroubleTicketID'} eq "") {
		print "there no ticket created for this notification.";
	} else {
		print onbmc_getbyid($ENV{'SM_OBJ_TroubleTicketID'});
	}

} else {
	print "Cannot Read Notification Objects, This Adapter is Only Intended to EMC Smarts Console Notifications, it shall be used as a Server or Automated Smarts Tool. \n";
}


# OTHER SUBs:
#----------------------------------------------------------


# ON BMC REMEDY ACTIONS
# ----------------------------------------------------------
#($ticketno)
sub onbmc_getbyid{
	my ($ticketno)= @_;

	my @data = (
  	SOAP::Data->name(Incident_Number => $ticketno)->type('xsd:string')
	);

	my $soap = new SOAP::Lite proxy=>$getbyid_proxy;
	my $result=$soap->HelpDesk_Query_Service($header, @data);

	if ($result->fault) {
	    print "faultcode=" . $result->fault->{'faultcode'} . "\n";
	    print "faultstring=" . $result->fault->{'faultstring'} . "\n";
	    print "detail=" . $result->fault->{'detail'} . "\n";
	}

	if ($result->body && $result->body->{'HelpDesk_Query_ServiceResponse'}) {
	    my %keyHash = %{ $result->body->{'HelpDesk_Query_ServiceResponse'} };

	    $out = "";
	    foreach my $k (keys %keyHash) {
	    	try {
		    	if ($keyHash{$k} ne ""){
			    	$out = $out .  "$k: $keyHash{$k}\n";
		    	}
	    	}
	    }
	    return $out;

	}

}
