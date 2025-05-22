package ow::auth_imap;
# auth_imap.pl - authenticate user with IMAP server

use strict;
use warnings FATAL => 'all';

use IO::Socket;

require "modules/tool.pl";

my %conf;
if (($_=ow::tool::find_configfile('etc/auth_imap.conf', 'etc/defaults/auth_imap.conf')) ne '') {
   my ($ret, $err)=ow::tool::load_configfile($_, \%conf);
   die $err if $ret<0;
}

my $effectiveuser=$conf{'effectiveuser'} || 'nobody';

sub get_userinfo {
   my ($r_config, $user)=@_;
   return (-2, 'User is null') if $user eq '';

   my ($uid,$gid,$realname,$homedir)=(getpwnam($effectiveuser))[2,3,6,7];
   return(-4, "User $user doesn't exist") if $uid eq '';

   while (my @gr=getgrent()) {
      $gid .= ' '.$gr[2] if ($gr[3]=~/\b$effectiveuser\b/ && $gid!~/\b$gr[2]\b/);
   }
   $realname=(split(/,/, $realname))[0];
   $homedir="/export$homedir" if (-d "/export$homedir");

   return(0, '', $realname, $uid, $gid, $homedir);
}

sub get_userlist {
   my $r_config=$_[0];
   return(-1, 'userlist() is not available in auth_imap.pl');
}

sub check_userpassword {
   my ($r_config, $user, $password)=@_;
   return (-2, 'User or password is null') if $user eq '' || $password eq '';

   my ($server,$port,$usessl)=(ow::tool::untaint(${$r_config}{'authimap_server'}),
                               ow::tool::untaint(${$r_config}{'authimap_port'}),
                               ${$r_config}{'authimap_usessl'});

   my $socket;
   eval {
      alarm 30; local $SIG{ALRM}=sub{die "alarm\n"};
      if ($usessl && ow::tool::has_module('IO/Socket/SSL.pm')) {
         $socket=IO::Socket::SSL->new(PeerAddr=>$server, PeerPort=>$port, Proto=>'tcp');
      } else {
         $port=143 if $usessl && $port==993;
         $socket=IO::Socket::INET->new(PeerAddr=>$server, PeerPort=>$port, Proto=>'tcp');
      }
      alarm 0;
   };
   return (-3, "imap server $server:$port connect error") if $@ or !$socket;

   eval {
      alarm 10; local $SIG{ALRM}=sub{die "alarm\n"};
      $socket->autoflush(1);
      $_=<$socket>;
      alarm 0;
   };
   return (-3, "imap server $server:$port server not ready") if $@ or !/^\* OK/;

   my @result;
   my $tag='A0001';
   return (-4, "imap server $server:$port bad login")
      unless sendcmd($socket, "$tag LOGIN $user $password\r\n", \@result)
             && $result[0] =~ /^$tag/ && $result[1] =~ /^OK/i;

   sendcmd($socket, "$tag LOGOUT\r\n", \@result);
   close $socket;
   return (0,'');
}

sub change_userpassword {
   my ($r_config, $user, $oldpassword, $newpassword)=@_;
   return (-2, 'User or password is null') if $user eq '' || $oldpassword eq '' || $newpassword eq '';
   return (-1, 'change_password() is not available in auth_imap.pl');
}

sub sendcmd {
   my ($socket,$cmd,$r_result)=@_;
   print $socket $cmd;
   my $line=<$socket>;
   return 0 unless defined $line;
   @$r_result = split(/\s+/, $line);
   return 1;
}

1;
