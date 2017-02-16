#!/opt/InCharge9410/SAM/smarts/bin/sm_perl -I /opt/InCharge9410/SAM/smarts/perl/5.16.2/

use InCharge::session;
use InCharge::object;
use Data::Dumper;

$SMARTS_broker  = "smartsa01.stc.com.sa:426";
$SMARTS_domain  = "STC-SAM-AGG";
$SMARTS_username= "admin";
$SMARTS_password= "changeme";


if ($ARGV[0] && $ARGV[1] && $ARGV[2]) {
	update_smarts( $ARGV[0], $ARGV[1], $ARGV[2]);
} else {
	print "usage: m_chnagenotif.pl <SM_OBJ_Name> <TroubleTicketID> <Text To Update UserDefined4>";
}

sub update_smarts {

		my ($ob, $ticketno, $text) = @_;

		$ob =~ s/&lt;/</ig;
		$ob =~ s/&gt;/>/ig;


		if ($text eq "create") {$text = "Ticket Opened on BMC Remedy"};
		if ($text eq "reopen") {$text = "Ticket Re-Opened on BMC Remedy"};
		if ($text eq "close") {$text = "Ticket Closed on BMC Remedy"};
		if ($text eq "resolve") {$text = "Ticket Resolved on BMC Remedy"};

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
		$notification->put( "UserDefined4", $text );
		$notification->put( "TroubleTicketID", $ticketno );
		$notification->changed();
		#print Dumper($notification);
}
