#!/usr/bin/perl -w

# BMC Remedy Perl Adapter for EMC Smarts
# Developed by: Mohamed ELMesseiry, EMC ASD, Solution Architect.
# mohamed.elmesseiry@emc.com
# version 1.0
# Notes :: the script need to be called from a shell script and pass the parameters as per USAGE Guide.

use SOAP::Lite;
use XML::Writer;
use XML::Writer::String;
#use SOAP::Lite +trace => "debug";

# CONFIGURATIONS
$username = "emcuser";
$password = "password\@123";
$timeZone = "";
$getbyid_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_Search_By_TKTNumber";
$create_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_Create_TKT_New";
$close_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_CloseTKT";
$reopen_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_ReOpen_TKT";
$resolve_proxy	= "http://172.20.150.218:8088/arsys/services/ARService?server=remedy-test&webService=XYZ:DME:EMC_ResolveTKT";

# TICKETS DEFAULT CONFIGURATION
$First_Name	=	"EMC";
$Last_Name	=	"NMS Integration";
$Direct_Contact_First_Name	=	"EMC";
$Direct_Contact_Last_Name	=	"NMS Integration";
$Impact = "4-Minor/Localized";
$Reported_Source = "Other";
$Service_Type	=	"User Service Request";
$Summary	= "Just Text to explain";
$Notes = "[Detailed Description for the issue]";
$Urgency = 	"4-Low";
$ServiceCI = "Mobile iGate";
$Assigned_Support_Company = "XYZ";
$Assigned_Support_Organization = "IT Support";
$Assigned_Group = "Data Network";
$Categorization_Tier_1 = "Data Network";
$Assignee = "EMC NMS Integration";
$Assignee_Login_ID = "emcuser";

# USED FOR THE CLOSE:
$Status_Reason = "Automated Resolution Reported";
$Resolution_Code ="EMC RCA";
$Cause_Code = "EMC RCA";

my @logininfo = (
    SOAP::Header->name('userName' => $username)->type(''),
    SOAP::Header->name('password' => $password)->type(''),
    SOAP::Header->name('timeZone' => $timeZone)->type('')
);
my $header = SOAP::Header->name('AuthenticationInfo' => \SOAP::Header->value(@logininfo));



# START
$num_args = $#ARGV + 1;
if (! $num_args >= 1) {
	print "EMC2 Perl Remedy Adapter: \n";
	print "Usage: remedy_adapter.pl <create|reopen|close>";
} else {
	my $action = $ARGV[0];

	if ($action eq "create"){
		print "creating ticket on BMC remedy .... \n";
		print "reading Notification Details ....";

		if ($ENV{'SM_OBJ_Name'}) {
			# $ENV{'SM_OBJ_ElementName'} && $ENV{'SM_OBJ_InstanceName'} && $ENV{'SM_OBJ_EventName'} && $ENV{'SM_OBJ_EVENTTEXT'}
			# ($Action, $Status, $EMC_Element_Name, $EMC_Event_Name, $EMC_Instance_Name, $EMC_Smarts_Severity)
			my $Severity = "Unknown";

			if ($ENV{'SM_OBJ_Severity'} == "1") { $Severity = "Critical"; }
			elsif ($ENV{'SM_OBJ_Severity'} == "2") { $Severity = "Major"; }
			elsif ($ENV{'SM_OBJ_Severity'} == "3") { $Severity = "Minor"; }
			elsif ($ENV{'SM_OBJ_Severity'} == "4") { $Severity = "Unknown"; }
			elsif ($ENV{'SM_OBJ_Severity'} == "5") { $Severity = "Normal"; }
			else { $Severity = "Unknown"; }

			my $ticketno = onbmc_create("CREATE","NEW", $ENV{'SM_OBJ_ElementName'}, $ENV{'SM_OBJ_Name'}, $ENV{'SM_OBJ_InstanceName'}, $Severity );
			print "$ticketno" . "\n" . onbmc_getbyid($ticketno);

		} else {
			print "Cannot Read Notification Objects, This Adapter is Only Intended to EMC Smarts Console Notifications, it shall be used as a Server or Automated Smarts Tool. \n";
		}

	}
	elsif ($action eq "getbyid"){
		if ($ARGV[1]) {
			my $details = onbmc_getbyid("$ARGV[1]");
			print 	"Details for TicketNo:  $ARGV[1] \n". "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \n" . $details;
		} else {
			print "ERROR: please provide the ticket no as the second argument: \n Example: perl remedy_adapter.pl getbyid INC000000589008";
		}
	}
	elsif ($action eq "reopen"){
		if ($ARGV[1]) {
			my $details = onbmc_reopen("$ARGV[1]","Assigned");
			print 	"Reopening TicketNo:  $ARGV[1] \n" . "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \n" . $details;
		} else {
			print "ERROR: please provide the ticket no as the second argument: \n Example: perl remedy_adapter.pl reopen INC000000589008";
		}
	}
	elsif ($action eq "close"){
		if ($ARGV[1]) {
			my $details = onbmc_close("$ARGV[1]","Alarm Cleared", "Closed");
			print 	"Closing TicketNo:  $ARGV[1] \n". "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \n" . $details;
		} else {
			print "ERROR: please provide the ticket no as the second argument: \n Example: perl remedy_adapter.pl close INC000000589008";
		}

	}
	elsif ($action eq "resolve"){
		if ($ARGV[1]) {
			my $details = onbmc_resolve("$ARGV[1]","Resolved by Admin", "Resolved");
			print 	"Resolving TicketNo:  $ARGV[1] \n". "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \n" . $details;
		} else {
			print "ERROR: please provide the ticket no as the second argument: \n Example: perl remedy_adapter.pl resolve INC000000589008";
		}

	}
	elsif ($action eq "env"){
		foreach (sort keys %ENV) {
		  #print "$_  =  $ENV{$_}\n";
		}
		print "$ENV{'SM_OBJ_Name'}";

	}
	else {
		print "ERROR: unknown argument sent to remedy adapter \n";
		print "USAGE: remedy_adapter.pl < create | getbyid | reopen | resolve | close >  < Incident_No > \n ";
	}

	# end of else
}


# ON BMC REMEDY ACTIONS
# ($Action, $Status, $EMC_Element_Name, $EMC_Event_Name, $EMC_Instance_Name, $EMC_Smarts_Severity)
sub onbmc_create {
	my ($Action, $Status, $EMC_Element_Name, $EMC_Event_Name, $EMC_Instance_Name, $EMC_Smarts_Severity) = @_;

	my @data = (
		# DEFAULT VALUES
	  	SOAP::Data->name(Assigned_Group => $Assigned_Group)->type('xsd:string'),
	  	SOAP::Data->name(Assigned_Support_Company => $Assigned_Support_Company)->type('xsd:string'),
	 	SOAP::Data->name(Assigned_Support_Organization => $Assigned_Support_Organization)->type('xsd:string'),
	 	SOAP::Data->name(Categorization_Tier_1 => $Categorization_Tier_1)->type('xsd:string'),
	 	SOAP::Data->name(First_Name => $First_Name)->type('xsd:string'),
	 	SOAP::Data->name(Impact => $Impact)->type('xsd:string'),
	 	SOAP::Data->name(Last_Name => $Last_Name)->type('xsd:string'),
	 	SOAP::Data->name(Reported_Source => $Reported_Source)->type('xsd:string'),
	 	SOAP::Data->name(Service_Type => $Service_Type)->type('xsd:string'),
	 	SOAP::Data->name(Status => $Status)->type('xsd:string'),
	 	SOAP::Data->name(Action => $Action)->type('xsd:string'),
	 	SOAP::Data->name(Summary => $Summary)->type('xsd:string'),
	 	SOAP::Data->name(Notes => $Notes)->type('xsd:string'),
	 	SOAP::Data->name(Urgency => $Urgency)->type('xsd:string'),
	 	SOAP::Data->name(Direct_Contact_First_Name => $Direct_Contact_First_Name)->type('xsd:string'),
	 	SOAP::Data->name(Direct_Contact_Last_Name => $Direct_Contact_Last_Name)->type('xsd:string'),
	 	SOAP::Data->name(ServiceCI => $ServiceCI)->type('xsd:string'),
	 	# NON DEFAULT VALUES
	 	SOAP::Data->name(EMC_Element_Name => $EMC_Element_Name)->type('xsd:string'),
	 	SOAP::Data->name(EMC_Event_Name => $EMC_Event_Name)->type('xsd:string'),
	 	SOAP::Data->name(EMC_Instance_Name => $EMC_Instance_Name)->type('xsd:string'),
	 	SOAP::Data->name(EMC_Smarts_Severity => $EMC_Smarts_Severity)->type('xsd:string')
	);

	  my $soap = new SOAP::Lite proxy=>$create_proxy;
	  my $result=$soap->HelpDesk_Submit_Service($header, @data);

	  if ($result->fault) {
	    print "faultcode=" . $result->fault->{'faultcode'} . "\n";
	    print "faultstring=" . $result->fault->{'faultstring'} . "\n";
	    print "detail=" . $result->fault->{'detail'} . "\n";
	  }

	  if ($result->body && $result->body->{'HelpDesk_Submit_ServiceResponse'}) {
	    my %keyHash = %{ $result->body->{'HelpDesk_Submit_ServiceResponse'} };
	    foreach my $k (keys %keyHash) {
	    	# RETURN TICKET NO CREATED
	        return $keyHash{$k};
	    }
	  }

}

# ($ticketno, $status)
sub onbmc_reopen {
	my ($ticketno, $status)= @_;

	my @data = (
  	SOAP::Data->name(Incident_Number => $ticketno)->type('xsd:string'),
  	SOAP::Data->name(Assignee => $Assignee)->type('xsd:string'),
  	SOAP::Data->name(Assignee_Login_ID => $Assignee_Login_ID)->type('xsd:string'),
  	SOAP::Data->name(Status => $status)->type('xsd:string')
	);

	my $soap = new SOAP::Lite proxy=>$reopen_proxy;
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
