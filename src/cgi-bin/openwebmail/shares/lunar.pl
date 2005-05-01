#
# lunar.pl - convert solar calendar to chinese lunar calendar
#
# 2002/11/15 tung.AT.turtle.ee.ncku.edu.tw
#

use strict;
use vars qw(%config);
use Fcntl qw(:DEFAULT :flock);

sub mkdb_lunar {
   my %LUNAR;
   my $lunardb=ow::tool::untaint("$config{'ow_mapsdir'}/lunar");

   ow::dbm::open(\%LUNAR, $lunardb, LOCK_EX, 0644) or return -1;
   sysopen(T, $config{'lunar_map'}, O_RDONLY);
   $_=<T>; $_=<T>;
   while (<T>) {
      s/\s//g;
      my @a=split(/,/, $_, 2);
      $LUNAR{$a[0]}=$a[1];
   }
   close(T);
   ow::dbm::close(\%LUNAR, $lunardb);

   return 0;
}

sub solar2lunar {
   my ($year, $mon, $day)=@_;
   my ($lyear, $lmon, $lday);

   my $lunardb=ow::tool::untaint("$config{'ow_mapsdir'}/lunar");
   if (ow::dbm::exist($lunardb)) {
      my %LUNAR;
      my $date=sprintf("%04d%02d%02d", $year, $mon, $day);
      ow::dbm::open(\%LUNAR, $lunardb, LOCK_SH);
      ($lyear, $lmon, $lday)=split(/,/, $LUNAR{$date});
      ow::dbm::close(\%LUNAR, $lunardb);
   }

   return($lyear, $lmon, $lday);
}

sub lunar2big5str {
   my ($lmon, $lday)=@_;
   return ($lmon.$lday) if ($lmon!~/\d/ || $lday!~/\d/);

   my @lmonstr=('', '����', '�G��', '�T��', '�|��', '����', '����',
                    '�C��', '�K��', '�E��', '�Q��', '����', 'þ��');
   my @ldaystr=('', '��@', '��G', '��T', '��|', '�줭',
                    '�줻', '��C', '��K', '��E', '��Q',
                    '�Q�@', '�Q�G', '�Q�T', '�Q�|', '�Q��',
                    '�Q��', '�Q�C', '�Q�K', '�Q�E', '�G�Q',
                    '�ܤ@', '�ܤG', '�ܤT', '�ܥ|', '�ܤ�',
                    '�ܤ�', '�ܤC', '�ܤK', '�ܤE', '�T�Q');

   if ($lmon=~/^\+(\d+)/) {
      return "�|".$lmonstr[$1].$ldaystr[$lday];
   } else {
      return $lmonstr[$lmon].$ldaystr[$lday];
   }
}

1;
