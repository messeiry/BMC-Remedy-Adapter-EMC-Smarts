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
$getbyid_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_Search_By_TKTNumber";

$resolve_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_ResolveTKT";
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

	my $Severity = "Unknown";
	if ($ENV{'SM_OBJ_Severity'} == "1") { $Severity = "Critical"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "2") { $Severity = "Major"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "3") { $Severity = "Minor"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "4") { $Severity = "Unknown"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "5") { $Severity = "Normal"; }
	else { $Severity = "Unknown"; }

	if ($ENV{'SM_OBJ_TroubleTicketID'} eq "") {
		print "No Ticket Placed here to resolve";
	} else {
		# there is a ticket already opened in remedy
		# the policy comply reopen only if the ticket status is marked as resolved.
		my $status = onbmc_checkstatus($ENV{'SM_OBJ_TroubleTicketID'});

		if ( $status eq "Resolved") {
			print "Ticket is already Resolved on BMC Remedy";
		} elsif ($status eq "Closed") {
			print "the Ticket is already closed on BMC Remedy";
		} else {
			print "Ticket Resolved on BMC Remedy" . "\n" . onbmc_resolve($ENV{'SM_OBJ_TroubleTicketID'},"Resolved by Admin", "Resolved");
			print `$execPATHperl "$OBJ" $ENV{'SM_OBJ_TroubleTicketID'} resolve`;
		}
	}

} else {
	print "Cannot Read Notification Objects, This Adapter is Only Intended to EMC Smarts Console Notifications, it shall be used as a Server or Automated Smarts Tool. \n";
}

# ON BMC REMEDY ACTIONS
# ----------------------------------------------------------


sub onbmc_checkstatus {
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

	    foreach my $k (keys %keyHash) {
			if ($k eq "Status") {
		    	return $keyHash{$k};
		    	last;
			}

	    }


	}
}


# ($ticketno, $Resolution, $status)
sub onbmc_resolve{
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

	my $soap = new SOAP::Lite proxy=>$resolve_proxy;
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
	    	if ($keyHash{$k} ne ""){
		    	$out = $out .  "$k: $keyHash{$k}\n";
	    	}
	    }
	    return $out;

	}

}
