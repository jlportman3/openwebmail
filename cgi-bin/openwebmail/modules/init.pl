package ow::init;

use strict;
use warnings FATAL => 'all';

our @EXPORT_OK = qw(init);

sub init {
    my $caller = caller;
    my $SCRIPT_DIR;

    if (-f '/etc/openwebmail_path.conf') {
        my $pathconf = '/etc/openwebmail_path.conf';
        open(my $fh, '<', $pathconf) or die "Cannot open $pathconf: $!";
        my $pathinfo = <$fh>;
        close($fh) or die "Cannot close $pathconf: $!";
        ($SCRIPT_DIR) = $pathinfo =~ m#^(\S*)#;
    } else {
        ($SCRIPT_DIR) = $0 =~ m#^(\S*)/[\w\d\-\.]+\.pl#;
    }

    die 'SCRIPT_DIR cannot be set' if !$SCRIPT_DIR;

    {
        no strict 'refs';
        ${$caller . '::SCRIPT_DIR'} = $SCRIPT_DIR;
    }

    push(@INC, $SCRIPT_DIR);
    push(@INC, "$SCRIPT_DIR/lib");

    delete $ENV{$_} for qw(ENV BASH_ENV CDPATH IFS TERM);
    $ENV{PATH} = '/bin:/usr/bin';

    umask(0002);

    require "modules/dbm.pl";
    require "modules/suid.pl";
    require "modules/filelock.pl";
    require "modules/tool.pl";
    require "modules/datetime.pl";
    require "modules/lang.pl";
    require "modules/htmltext.pl";
    require "modules/mime.pl";
    require "modules/mailparse.pl";

    return $SCRIPT_DIR;
}

1;
