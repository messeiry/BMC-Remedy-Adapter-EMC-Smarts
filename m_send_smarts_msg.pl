#!/usr/bin/perl -w
# XYZ SMS System Integration with EMC Smarts.
# Developed by: Mohamed ELMesseiry, EMC ASD, Solution Architect.
# mohamed.elmesseiry@emc.com
# version 1.0

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;

my $mob = "966569008742";


sendSMS($mob,"SMS Text Goes here");


=comment
if ($ENV{'SM_OBJ_Name'} ) {

	my $Severity = "Unknown";
	if ($ENV{'SM_OBJ_Severity'} == "1") { $Severity = "Critical"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "2") { $Severity = "Major"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "3") { $Severity = "Minor"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "4") { $Severity = "Unknown"; }
	elsif ($ENV{'SM_OBJ_Severity'} == "5") { $Severity = "Normal"; }
	else { $Severity = "Unknown"; }

	my $OBJ = $ENV{'SM_OBJ_Name'};
	$OBJ =~ s/</&lt;/ig;
	$OBJ =~ s/>/&gt;/ig;
	my $ELEMENT = $ENV{'SM_OBJ_ElementName'};
	$ELEMENT =~ s/</&lt;/ig;
	$ELEMENT =~ s/>/&gt;/ig;
	my $INSTANCE = $ENV{'SM_OBJ_InstanceName'};
	$INSTANCE =~ s/</&lt;/ig;
	$INSTANCE =~ s/>/&gt;/ig;

	my $msgText = "EMC SMARTS($Severity-$ELEMENT-$INSTANCE): \n$OBJ";

	sendSMS('$mob','$msgText');
}
=cut

sub sendSMS {
	my ($mobileNumber, $msg) = @_;

	my $userAgent = LWP::UserAgent->new;
	sub LWP::UserAgent::get_basic_credentials {
	    my ($self, $realm, $url, $isproxy) = @_;
	    return 'NMS', 'NmS@Test';
	}
	my $message = "<soapenv:Envelope
	    xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
	    xmlns:sen=\"http://IS_Webmethod3.XYZ.com.sa/SMSGW/ws/provider/SendSingleSMS\">
	    <soapenv:Header/>
	    <soapenv:Body>
	        <sen:receiveSingleSMSRequest>
	            <receiveSingleSMSRequest>
	                <header>
	                    <username>NMS</username>
	                    <password>NmS\@Test</password>
	                    <systemName>NMS</systemName>
	                    <serviceName>sendSMS</serviceName>
	                </header>
	                <body>
	                    <sender>Test</sender>
	                    <mobileNumber>$mobileNumber</mobileNumber>
	                    <message>$msg</message>
	                    <messageType>text</messageType>
	                    <!--Optional:-->
	                    <referenceNumber>?</referenceNumber>
	                </body>
	            </receiveSingleSMSRequest>
	        </sen:receiveSingleSMSRequest>
	    </soapenv:Body>
	</soapenv:Envelope>";

	my $response =
		$userAgent->request(POST 'http://172.20.150.69:9000/ws/SMSGW.ws.provider:SendSingleSMS/SMSGW_ws_provider_SendSingleSMS_Port',
					Content_Type => 'text/xml',
					Content => $message);

	print $response->error_as_HTML unless $response->is_success;

	my $xmlString = $response->decoded_content;
	my $res = XMLin($xmlString);

	if ($response->is_success) {
		my $notes = $res->{'SOAP-ENV:Body'}->{'ser-root:receiveSingleSMSRequestResponse'}->{'receiveSingleSMSResponse'}->{notes};
		print "INFO:\t SMS to $mobileNumber\t status $notes\t MSG:$msg\n";
	} else {
		my $notes = $res->{'SOAP-ENV:Body'}->{'ser-root:receiveSingleSMSRequestResponse'}->{'errorDocument'};
		print "INFO:\t SMS to $mobileNumber\t status $notes\t MSG:$msg \n";
	}

}
