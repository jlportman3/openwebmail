use v5.36;
use strict;
use warnings FATAL => 'all';
use lib 'cgi-bin/openwebmail';
use Test::More tests => 3;
require 'modules/mailparse.pl';

my $header = "From: Example <example\@example.com>\nSubject: Test\nMessage-ID: <msg1>\n\n";
my %msg;
ow::mailparse::parse_header(\$header, \%msg);

ok(exists $msg{'from'}, 'from parsed');
ok(exists $msg{'subject'}, 'subject parsed');

is($msg{'message-id'}, '<msg1>', 'message-id parsed');
