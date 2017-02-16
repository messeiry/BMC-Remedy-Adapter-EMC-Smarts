my $string = "<->";

$string =~ s/</&lt/ig;
$string =~ s/>/&gt/ig;

print $string;
