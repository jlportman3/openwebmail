# $Id: Parser.pm 116 2006-01-10 16:41:53Z chronos $
package BBCode::Parser;
use BBCode::Util qw(:parse :tag);
use BBCode::TagSet;
use BBCode::Tag;
use BBCode::Body;
use Carp qw(croak);
use strict;
use warnings;

our $VERSION = '0.22';

=head1 NAME

BBCode::Parser - Parses BBCode tags

=head1 DESCRIPTION

BBCode is a simplified markup language used in several online forums
and bulletin boards.  It originated with phpBB, and remains most popular
among applications written in PHP.  Generally, users author their posts in
BBCode, and the forum converts it to a permitted subset of well-formed HTML.

C<BBCode::Parser> is a proper recursive parser for BBCode-formatted text.

=head1 OVERVIEW

A C<BBCode::Parser> object represents various settings that affect the parsing
process.  Simple settings are typically set when the parser is created using
L</new>, but they can be queried using L</get> and altered using L</set>.

See L</SETTINGS> for more information.

In addition to the simple settings, specific BBCode tags (or classes of tags)
can be permitted or forbidden, using L</permit> and L</forbid>
respectively.  By default, the only forbidden tag is C<[HTML]>, which is
normally a security violation if permitted.

See L</CLASSES> for a list of tag classes.

Once the parser has been configured appropriately, parse trees can be created
using the L</parse> method.  The parse tree will consist of objects derived
from L<BBCode::Tag>; the root of the tree will be a L<BBCode::Body>.

Converting the parse tree to HTML is quite simple: call L<toHTML()|BBCode::Tag/toHTML>
on the root of the tree.  Likewise, the parse tree can be converted back to
BBCode by calling L<toBBCode()|BBCode::Tag/toBBCode>.  See L<BBCode::Tag/METHODS>
to find out what other output methods are available.

=head1 SETTINGS

The following settings can be manipulated using L</get> and L</set>.

=over

=item css_prefix

(Type: String; Default: "bbcode-")

Many BBCode tags will add CSS classes as style hooks in the output HTML, such
as C<< <div class="bbcode-quote">...</div> >>.  This setting allows you to
override the naming scheme for those hooks.  At the moment, more direct control
of the CSS class names is not available.

=item css_direct_styles

(Type: Boolean; Default: FALSE)

Certain style-related BBCode tags, such as [U] (underline) and [S]
(strike-through) don't have a direct equivalent in modern XHTML 1.0 Strict.
If this value is TRUE, then the generated HTML will use a C<style> attribute
on a C<E<lt>spanE<gt>> tag to simulate the effects.  If this value is FALSE,
then the style attribute will be omitted.  In either case, a C<class> attribute
is provided for use as a hook by external CSS stylesheets (not provided).

=item follow_links

(Type: Boolean; Default: FALSE)

To prevent blog spam and the like, many search engines now allow HTML authors
to indicate that specific URLs on a page should not be indexed.  If this value
is TRUE, then there will be nothing special about the URL (meaning that search
engines are encouraged to follow the link).  If this value is FALSE, then a
C<rel="nofollow"> attribute will be added wherever it makes sense (warning
search engines that the link might be spam).

Whether or not to set this value to TRUE will depend on what you're using
C<BBCode::Parser> for.  If you're implementing a forum or bulletin board, TRUE
might be reserved for senior, more trusted members.  If you're implementing a
blog, the value might be TRUE for the blog owner but FALSE for visitors.

For more information, see L<http://www.google.com/webmasters/bot.html#www>.

=item follow_override

(Type: Boolean; Default: FALSE)

This BBCode implementation allows a user to override L<the follow_links setting|/follow_links>
using a BBCode extension, C<FOLLOW=1>.  If this value is TRUE, the user can
override C<follow_links>; otherwise, the user must abide by C<follow_links>.

The same considerations that apply to C<follow_links> also apply to this
setting.

=item allow_image_bullets

(Type: Boolean; Default: TRUE)

This setting allows you to restrict users from creating lists with custom
bullets.

=back

=head1 CLASSES

FIXME: Add documentation on tag classes.

=head1 METHODS

=cut

sub parseCSSPrefix($) {
	if(defined $_[0] and $_[0] =~ /^([\w-]*)$/) {
		return $1;
	} else {
		return undef;
	}
}

my @SETTINGS;
my %SETTINGS;

BEGIN {
	no strict 'refs';

	@SETTINGS = (
		[ 'css_prefix',				\&parseCSSPrefix,	'bbcode-'	],
		[ 'css_direct_styles',		\&parseBool,		0			],
		[ 'follow_links',			\&parseBool,		0			],
		[ 'follow_override',		\&parseBool,		0			],
		[ 'allow_image_bullets',	\&parseBool,		1			],
	);
	%SETTINGS = map { $_->[0] => $_ } @SETTINGS;

	foreach(@SETTINGS) {
		my $attr = $_->[0];
		*$attr = sub($;$):method {
			my $this = shift;
			if(@_) {
				return $this->set($attr, @_);
			} else {
				return $this->get($attr);
			}
		};
	}
}

sub _canonize($) {
	local $_ = $_[0];
	s/([[:upper:]]+)([[:upper:]][[:lower:]]+)/$1.'_'.lc($2)/eg;
	s/([[:lower:]])([[:upper:]]+)/$1.'_'.lc($2)/eg;
	s/([[:upper:]]+)/lc($1)/eg;
	return $_;
}

=head2 DEFAULT

	my $tree = DEFAULT->parse($code);

C<DEFAULT> returns the default parser.  If you change the default parser, all
future parsers created with L</new> will incorporate your changes.  However,
all existing parsers will be unaffected.

=cut

my $DEFAULT;
INIT {
	$DEFAULT = bless {};
	$DEFAULT->{_permit} = BBCode::TagSet->new;
	$DEFAULT->{_forbid} = BBCode::TagSet->new;
	foreach(@SETTINGS) {
		$DEFAULT->{$_->[0]} = $_->[2];
	}
	$DEFAULT->permit(':ALL');
	$DEFAULT->forbid('HTML');
}
sub DEFAULT() {
	return $DEFAULT;
}

=head2 clone

	my $parser = BBCode::Parser->new(follow_links => 1);
	my $clone = $parser->clone;
	$clone->forbid('IMG');
	printf "[IMG] is%s OK\n", ($parser->isPermitted('IMG') ? "" : " not");
	# Prints "[IMG] is OK", since forbid('IMG') applies only to the clone.

C<clone> creates a new parser that copies the settings of an existing parser.
After cloning, the two parsers are completely independent; changing settings
in one does not affect the other.

If any arguments are given, they are handed off to L<the set() method|/set>.

=cut

sub clone($%):method {
	my $this = shift;
	$this = $this->DEFAULT if not ref $this;
	my $that = bless {}, ref($this);
	$that->{_permit} = $this->{_permit}->clone;
	$that->{_forbid} = $this->{_forbid}->clone;
	foreach(map { $_->[0] } @SETTINGS) {
		$that->{$_} = $this->get($_);
	}
	$that->set(@_) if @_;
	return $that;
}

=head2 new

	my $parser = BBCode::Parser->new(%args);

C<new> creates a new C<BBCode::Parser>.  Any arguments
are handed off to L<the set() method|/set>.

=cut

sub new($%):method {
	return shift->DEFAULT->clone(@_);
}

=head2 get

	if($parser->get('follow_override')) {
		# [URL FOLLOW] permitted
	} else {
		# [URL FOLLOW] forbidden
	}

C<get> fetches the current settings for the given parser.  See L</SETTINGS>
for a list of available settings.

=cut

sub get($@):method {
	my $this = shift;
	my @ret;
	while(@_) {
		my $key = _canonize shift;
		croak qq(Unknown setting "$key") unless exists $SETTINGS{$key};
		warn qq(BUG: Setting $key does not exist) unless exists $this->{$key};
		push @ret, $this->{$key};
	}
	return @ret if wantarray;
	return $ret[0] if @ret == 1;
	return \@ret;
}

=head2 set

	$parser->set(follow_override => 1);

C<set> alters the settings for the given parser. See L</SETTINGS> for a list
of available settings.

=cut

sub set($%):method {
	my $this = shift;
	while(@_) {
		my $key = _canonize shift;
		my $val = shift;
		croak qq(Unknown setting "$key") unless exists $SETTINGS{$key};
		$val = $SETTINGS{$key}->[1]->($val);
		$val = $SETTINGS{$key}->[2] if not defined $val;
		$this->{$key} = $val;
	}
	return $this;
}

=head2 permit

	$parser->permit(qw(:INLINE !:LINK));

C<permit> adds TAGs and :CLASSes to the list of permitted tags.  Use '!' in
front of a tag or class to negate the meaning.

=cut

sub permit($@):method {
	my $this = shift;
	my $set = BBCode::TagSet->new(@_);
	$this->{_permit}->add($set);
	$this->{_forbid}->remove($set);
	return $this;
}

=head2 forbid

	$parser->forbid(qw(:ALL !:TEXT));

C<forbid> adds TAGs and :CLASSes to the list of forbidden tags.  Use '!' in
front of a tag or class to negate the meaning.

=cut

sub forbid($@):method {
	my $this = shift;
	my $set = BBCode::TagSet->new(@_);
	$this->{_forbid}->add($set);
	$this->{_permit}->remove($set);
	return $this;
}

=head2 isPermitted

	if($parser->isPermitted('IMG')) {
		# Yay, [IMG] tags
	} else {
		# Darn, no [IMG] tags
	}

C<isPermitted> checks if a tag is permitted by the current settings.

=cut

sub isPermitted($$):method {
	my($this,$tag) = @_;
	foreach(tagHierarchy($tag)) {
		return 0 if $this->{_forbid}->contains($_);
		return 1 if $this->{_permit}->contains($_);
	}
	return 0;
}

sub _args(\$) {
	my $ref = shift;
	my $ok = 0;
	my $arg = 0;
	my $k = undef;
	my $v = '';
	my @args;

	while(length $$ref > 0) {
		if($$ref =~ s/^\\//) {
			croak qq(Invalid BBCode: Backslash at end of text) unless $$ref =~ s/^(.)//s;
			$v .= $1 unless $1 eq "\n";
			next;
		}

		if(not defined $k and $$ref =~ s/^\s*=\s*//) {
			if($arg) {
				$k = uc $v;
			} else {
				$arg = 1;
				$k = '';
			}
			$v = '';
			next;
		}

		if($$ref =~ s/^(["'])//) {
			my $q = $1;
			my $qok = 0;
			while(length $$ref > 0) {
				$qok++, last if $$ref =~ s/^\Q$q\E//;
				if($$ref =~ s/^\\//) {
					croak qq(Invalid BBCode: Backslash at end of text) unless $$ref =~ s/^(.)//s;
					$v .= $1 unless $1 eq "\n";
					next;
				}
				$$ref =~ s/^(.)//s;
				$v .= $1 eq "\n" ? " " : $1;
			}
			croak qq(Invalid BBCode: Quoted string never ends) unless $qok;
			$arg = 1;
			next;
		}

		if($$ref =~ s/^\s*\]//) {
			push @args, [ $k, $v ] if $arg;
			$ok++;
			last;
		}

		if($$ref =~ s/^(\s+|\s*,\s*)//) {
			push @args, [ $k, $v ] if $arg;
			$arg = 0;
			$k = undef;
			$v = '';
			next;
		}

		$$ref =~ s/^(.)//;
		$arg = 1;
		$v .= $1;
	}

	croak qq(Invalid BBCode: Unterminated tag) unless $ok;
	return @args if wantarray;
	return \@args;
}

sub _tokenize($$) {
	my($this,$ref) = @_;
	my(@tokens);

	while(length $$ref > 0) {
		if($$ref =~ s/^ ([^\[<&]+) //x) {
			push @tokens, [ 'TEXT', [ undef, $1 ] ];
			next;
		}

		if($$ref =~ s/^ \[ \s* \] //x) {
			push @tokens, [ 'TEXT', [ undef, '[' ] ];
			next;
		}

		# Special case
		if($$ref =~ s/^ \[ \s* HTML \s* \] //xi) {
			$$ref =~ s/^ (.*?) \[ \s* \/ \s* HTML \s* \] //xis;
			push @tokens, [ 'HTML', [ undef, $1 ] ];
			next;
		}

		# Special case
		if($$ref =~ s/^ \[ \s* (\/?) \s* \* \s* \] //x) {
			push @tokens, [ $1.'LI' ];
			next;
		}

		# Special case
		if($$ref =~ s/^ \[ \s* ( URL | EMAIL | IMG ) \s* \] //xi) {
			push @tokens, [ '_'.uc($1) ];
			next;
		}

		if($$ref =~ s/^ \[ ( \s* \/? \s* \w+ \s* ) \] //x) {
			my $tag = uc($1);
			$tag =~ s/\s+//g;
			if(tagExists($tag)) {
				push @tokens, [ $tag ];
			} else {
				push @tokens, [ 'TEXT', [ undef, "[$1]" ] ];
			}
			next;
		}

		if($$ref =~ s/^ \[ ( \s* \w+ \s* ) (?= \s | , | = | \] )//x) {
			my $str = $1;
			my $tag = uc($str);
			$tag =~ s/\s+//g;
			if(tagExists($tag)) {
				push @tokens, [ $tag, _args($$ref) ];
			} else {
				push @tokens, [ 'TEXT', [ undef, "[$str" ] ];
			}
			next;
		}

		if($$ref =~ s/^ <URL: ([^<>]*) > //x) {
			my $text = $1;
			my $url;
			if(defined($url = parseURL($text))) {
				push @tokens, [ 'URL', [ undef, $url->as_string ] ];
				push @tokens, [ 'TEXT', [ undef, $text ] ];
				push @tokens, [ '/URL' ];
			} elsif(defined($url = parseMailURL($text))) {
				push @tokens, [ 'EMAIL', [ undef, $url->as_string ] ];
				push @tokens, [ 'TEXT', [ undef, $text ] ];
				push @tokens, [ '/EMAIL' ];
			} else {
				push @tokens, [ 'TEXT', [ undef, "<URL:$text>" ] ];
			}
			next;
		}

		if($$ref =~ s/^ & ( \#? [w+-]+ ) ; //x) {
			if(defined parseEntity($1)) {
				push @tokens, [ 'ENT', [ undef, $1 ] ];
			} else {
				push @tokens, [ 'TEXT', [ undef, "&$1;" ] ];
			}
			next;
		}

		$$ref =~ s/^ (.) //x;
		push @tokens, [ 'TEXT', [ undef, $1 ] ];
	}

	return \@tokens;
}

sub _top(\@) {
	my $stack = shift;
	return $$stack[$#$stack];
}

sub _parse($$$) {
	my($this,$root,$ref) = @_;
	my @st = ($root);

TOKEN:while(@$ref) {
		my $token = shift @$ref;

		if($token->[0] =~ s#^/##) {
			my @old = @st;
			while(@st) {
				if($token->[0] eq pop(@st)->Tag) {
					next TOKEN;
				}
			}
			croak 'Illegal close tag: expected [/'._top(@old)->Tag.'], got [/'.$token->[0].']';
		}

		my $tag = BBCode::Tag->new($this, @$token);

		while(@st) {
			eval {
				_top(@st)->pushBody($tag);
			};
			last if not $@;
			croak $@ if not $@ =~ /^Invalid tag nesting/;
			pop(@st);
		}
		croak qq(Invalid tag nesting) if not @st;

		push @st, $tag if $tag->BodyPermitted;
	}
}

=head2 parse

	my $tree = $parser->parse('[b]BBCode[/b] text.');

C<parse> creates a parse tree for the given BBCode.  The result is a
tree of L<BBCode::Tag> objects.  The most common use of the parse tree is
to convert it to HTML using L<BBCode::Tag-E<gt>toHTML()|BBCode::Tag/"toHTML">:

	my $html = $tree->toHTML;

=cut

sub parse($@):method {
	croak qq(EBCDIC platforms not supported) unless "A" eq "\x41";

	my $this = shift;
	$this = $this->new() unless ref $this;

	my $text = join "\n", @_;
	$text =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]+//;
	$text =~ s/(?:\r\n|\r|\n)/\n/g;

	my $tokens = $this->_tokenize(\$text);
	my $body = BBCode::Body->new($this);
	$this->_parse($body, $tokens);

	return $body->replaceBody;
}

1;

=head1 SEE ALSO

L<BBCode::Tag>

L<svn://chronos-tachyon.net/projects/BBCode-Parser>

=head1 AUTHOR

Donald King E<lt>dlking@cpan.orgE<gt>

=cut
