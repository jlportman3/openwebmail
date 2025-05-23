# OpenWebMail File Structures
$Id: files.txt 349 2009-04-27 07:26:53Z ateslik $

There are mainly 4 groups of files used in openwebmail.

1. cgi-bin/openwebmail/         cgi scripts/configurations/languages/templates
2. data/openwebmail/            background/icons/image/sounds
3. ~user/mail/                  user folder files/indexes
4. /etc/mail/virtusertable      virtual user mapping table


data/openwebmail/               mapping to url http://your_site/openwebmail/
------------------------------
doc/                            text document for openwebmail
help/				openwebmail tutorial of various languages
images/                         runtime image/background/icons
javascript/			runtime javascripts
sounds/                         various YouHaveMail sound files
applet/                         directory for runtime javaapplet
openwebmail.html
redirect.html
index.html -> openwebmail.html

javascript/htmlarea			HTMLArea editor 3.0
javascript/htmlarea.openwebmail		HTMLArea editor 3.0 customized for oepnwebmail
javascript/htmlarea.openwebmail/popups	lang and html file of popup windows in
					htmlarea editor for different languages


cgi-bin/openwebmail/            mapping to url http://your_site/cgi-bin/openwebmail
------------------------------
etc/                            configuraation, template, language, holidays, maps, temporary files
auth/				place for auth_xxx.pl modules
				routines/variables in these files belong to ow::auth_xxx::
quota/				place for quota_xxx.pl modules
				routines/variables in these files belong to ow::quota_xxx::
modules/			place for module files
				routines/variables in these files belong to packages other than main::
shares/				place for shared routines files
				routines/variables in these files belong to main::
misc/                           mkrelease uty, test script, patches, tools for adm

openwebmail-abook.pl            CGI programs of openwebmail
openwebmail-advsearch.pl
openwebmail-cal.pl
openwebmail-folder.pl
openwebmail-main.pl
openwebmail-prefs.pl
openwebmail-read.pl
openwebmail-send.pl
openwebmail-spell.pl
openwebmail-vdomain.pl
openwebmail-viewatt.pl
openwebmail-webdisk.pl
openwebmail.pl

openwebmail-tool.pl             command tool of openwebmail
preload.pl                      preload uty for both CGI and command line
userstat.pl			user status utility for static html pages
vacation.pl                     vacation utility for auto reply


/usr/local/www/cgi-bin/etc/
------------------------------
openwebmail.conf                customized configuration file
openwebmail.conf.help           help for default configuration file

smtpauth.conf                   file to store username/passwd for SMTP auth
auth_xxx.conf			customized config file for auth_xxx.pl

defaults/			default conf files for openwebmail and other modules
styles/                         various CSS files
lang/                           translation files for various languages
templates/                      template files for various languages
holidays/                       holidays calendar for various languages
maps/				b2g, g2b, lunar maps and db of maps
sites.conf/                     configuration file for different virtual domain
users.conf/                     configuration file for different user
users/                          user directories (used only if use_syshomedir disabled)
sessions/                       directory to store temporary session files

address.book                    global address book
calendar.book                   global calendar book
filter.book                     global filter book


for each USER
------------------------------
~USER/.openwebmail/             store openwebmail internal files
   openwebmailrc                openwebmail user preference
   release.date                 the release date of openwebmail which user used
   history.log                  openwebmail user log file

~USER/.openwebmail/db/		location for mail folder index db and messageid cache file
   (for each foldername...)
   foldername.db                the index db of the folder file
   foldername.cache             messageid cache

~USER/.openwebmail/webmail/	location for webmail internal file
   signature                    signature file if ~USER/.signature doesn't exist
   from.book                    from address book
   address.book                 address book
   stationery.book              stationery book
   filter.book                  personal filter rule book
   filter.book.db               db to store filtering count/date of filter rules
   filter.check                 file that marked the last INBOX filting dat
   trash.check                  file that marked the last trash-cleaning date
   search.cache                 cache file to store last search result

~USER/.openwebmail/webcal/	location for webmail internal file
   calendar.book                calendar book
   notify.check                 file that marked the last calendar email notification check date

~USER/.openwebmail/webdisk/	location for webdisk internal file
   webdisk.cache                cache file to store last webdisk search result

~USER/.openwebmail/pop3/	location for pop3 book and uidl database
   authpop3.book                pop3 book for pop3 auth server
   pop3.book                    pop3 book
   pop3.check                   file that marked the last pop3 retrieval date

~USER/.forward                  mail forwarding file
~USER/.vacation.msg             text for auto reply
~USER/.vacation.db              db for autoreply history log
~USER/.signature                signature file
~USER/.ispell_words             personal dict for ispell
~USER/.aspell.en.xxx            personal dict for aspell


other files accessed by openwebmail
-----------------------------------
/etc/mail/virtusertable         virtual user mapping file
/var/mail/USER                  INBOX for the USER
/var/log/openwebmail.log        openwebmail system log file
