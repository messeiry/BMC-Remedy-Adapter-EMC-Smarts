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
#require 'sm_tnot.pl';
#use SOAP::Lite +trace => "debug";

# CONFIGURATIONS
$execPATHperl = "/opt/InCharge9410/SAM/smarts/local/actions/server/m_changenotif.pl";
$username = "emcuser";
$password = "password\@123";
$timeZone = "";
$close_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_CloseTKT";
# TICKETS DEFAULT CONFIGURATION
$Assignee = "EMC NMS Integration";
$Assignee_Login_ID = "emcuser";
$Status_Reason = "Automated Resolution Reported";
$Resolution_Code ="EMC RCA";
$Cause_Code = "EMC RCA";

my @logininfo = (
    SOAP::Header->name('userName' => $username)->type(''),
    SOAP::Header->name('password' => $password)->type(''),
    SOAP::Header->name('timeZone' => $timeZone)->type('')
);
my $header = SOAP::Header->name('AuthenticationInfo' => \SOAP::Header->value(@logininfo));

if ($ENV{'SM_OBJ_Name'} ) {
	my $OBJ = $ENV{'SM_OBJ_Name'};
	$OBJ =~ s/</&lt;/ig;
	$OBJ =~ s/>/&gt;/ig;

	if ($ENV{'SM_OBJ_TroubleTicketID'} eq "") {
		print "there is no ticket assigned to this notification, close function will not work";
	} else {
		if ($ENV{'SM_OBJ_UserDefined4'} eq "Ticket Closed on BMC Remedy") {
			print "The Ticket No# $ENV{'SM_OBJ_TroubleTicketID'} is already closed on BMC Remedy";
		} else {
			print "Ticket No# $ENV{'SM_OBJ_TroubleTicketID'} Closed on BMC Remedy" . onbmc_close($ENV{'SM_OBJ_TroubleTicketID'}, "Resolved by System Admin", "Closed");
			print `$execPATHperl "$OBJ" $ENV{'SM_OBJ_TroubleTicketID'} close`;
		}
	}

} else {
	print "Cannot Read Notification Objects, This Adapter is Only Intended to EMC Smarts Console Notifications, it shall be used as a Server or Automated Smarts Tool. \n";
}

# ON BMC REMEDY ACTIONS
# ----------------------------------------------------------

# ($ticketno, $Resolution, $status)
sub onbmc_close {
	my ($ticketno, $Resolution, $status)= @_;

	my @data = (
  	SOAP::Data->name(Incident_Number => $ticketno)->type('xsd:string'),
  	SOAP::Data->name(Assignee => $Assignee)->type('xsd:string'),
  	SOAP::Data->name(Assignee_Login_ID => $Assignee_Login_ID)->type('xsd:string'),
  	SOAP::Data->name(Status_Reason => $Status_Reason)->type('xsd:string'),
  	SOAP::Data->name(Resolution => $Resolution)->type('xsd:string'),
  	SOAP::Data->name(Resolution_Code => $Resolution_Code)->type('xsd:string'),
  	SOAP::Data->name(Cause_Code => $Cause_Code)->type('xsd:string'),
  	SOAP::Data->name(Status => $status)->type('xsd:string')
	);

	my $soap = new SOAP::Lite proxy=>$close_proxy;
	my $result=$soap->Set($header, @data);

	if ($result->fault) {
	    print "faultcode=" . $result->fault->{'faultcode'} . "\n";
	    print "faultstring=" . $result->fault->{'faultstring'} . "\n";
	    print "detail=" . $result->fault->{'detail'} . "\n";
	}

	if ($result->body && $result->body->{'SetResponse'}) {
	    my %keyHash = %{ $result->body->{'SetResponse'} };

	    $out = "";
	    foreach my $k (keys %keyHash) {
	    	if ($keyHash{$k} ne ""){
		    	$out = $out .  "$k: $keyHash{$k}\n";
	    	}
	    }
	    return $out;
	}

}
