# Copyright (c) 2020 Atomic Spuds <AtomicSpudsGame@gmail.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package API::WWW;

use strict;
use warnings;

use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;

sub new {
	my ($class) = @_;

	my $me = { };

	$me->{ua} = LWP::UserAgent->new();

	$me->{ua}->agent( "Eve Echoes API Archiver/0.0 " . $me->{ua}->agent() );
	$me->{ua}->env_proxy(1);
	$me->{ua}->timeout(60);

	my $cookies = $ENV{'http_cookies'};
	if (defined($cookies)) {
        	if (-f $cookies) {
			$me->{ua}->cookie_jar(HTTP::Cookies::Netscape->new(file => $cookies));
			printf STDERR "Set cookies to %s",$cookies;
		}
	}

	bless $me,$class;
}

sub get {
	my ($me, $URL) = @_;

	my $req = HTTP::Request->new(GET => $URL);

	my $res = $me->{ua}->request( $req );

	return $res->content;
}

sub head {
	my ($me, $URL) = @_;

	my $req = HTTP::Request->new(HEAD => $URL);

	my $res = $me->{ua}->request( $req );

	return $res;
}

1;
