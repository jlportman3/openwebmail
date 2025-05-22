use v5.36;
use strict;
use warnings FATAL => 'all';
use File::Find;
use Test::More;

my @files;
find(
    sub {
        return unless /\.(?:pl|pm)$/;
        push @files, $File::Find::name;
    },
    'cgi-bin/openwebmail'
);

my %skip = map { $_ => 1 } qw(
  cgi-bin/openwebmail/misc/tools/rc/replacestr.pl
  cgi-bin/openwebmail/misc/test/jcode.pl
  cgi-bin/openwebmail/shares/filterbook.pl
);

plan tests => scalar(grep { !$skip{$_} } @files);

for my $file (@files) {
    next if $skip{$file};
    open my $fh, '<', $file or die $!;
    my $first = <$fh>;
    close $fh;
    my @cmd = ($^X);
    push @cmd, '-T' if defined $first && $first =~ /-T/;
    push @cmd, '-c', $file;
    my $output = qx{ @cmd 2>&1 };
    my $exit = $? >> 8;
    SKIP: {
        if ($exit && $output =~ /Can't locate (\S+)\.pm/) {
            skip "missing $1", 1;
        }
        ok($exit == 0, "$file compiles");
        diag $output if $exit != 0;
    }
}

