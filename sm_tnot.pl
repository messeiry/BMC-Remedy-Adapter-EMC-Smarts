#!/opt/InCharge9410/SAM/smarts/bin/sm_perl -I /opt/InCharge9410/SAM/smarts/perl/5.16.2/ -I /usr/bin/perl

use InCharge::session;
use InCharge::object;

$SMARTS_broker  = "smartsa01.XYZ.com.sa:426";
$SMARTS_domain  = "XYZ-SAM-AGG";
$SMARTS_username= "admin";
$SMARTS_password= "changeme";

sub update_smarts {
	my ($ob, $ticketno) = @_;

	$session = InCharge::session->new(
		broker=>"$SMARTS_broker",
		domain=>"$SMARTS_domain",
		username=>"$SMARTS_username",
		password=>"$SMARTS_password",
		traceServer => 1
	);

	# Sample Notification object : NOTIFICATION-Switch_SF30421F00N00N20_Down;
	# #$notification->{UserDefined2} = "messeiry"; # this can be used as well.
	$notification = $session->object("ICS_Notification", $ob);
	$notification->put( "UserDefined4", "Ticket Created on BMC Remedy" );
	$notification->put( "TroubleTicketID", $ticketno );
	$notification->changed();
	print Dumper($notification);

}
1;
