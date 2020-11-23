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

package API::Cache;

use strict;
use warnings;

use IO::Compress::Xz; # qw(xz $XzError);
use IO::Uncompress::UnXz; # qw(unxz $UnXzError);

sub new {
	my ($class, $appname) = @_;

	my $me = { };

	$me->{V} = 0;

	my $ret = bless $me, $class;

	$me->cache_setup($appname);

	return $ret;
}


# XXX sync with git/sw/mm/mm

# cache($ciits)
#
#  my $ciits = { };
#  $ciits->{key} = "unique lookup key";
#  $ciits->{data} = $data;
#  $ciits->{ttl} = 86000; # seconds till cache entry expires

sub cache {
	my ($me, $ci) = @_;

	my $ri = { };

	my $key = $ci->{key};
	my $hash = $me->cache_str2hash($key);

	my $cdir = $me->{cdir};
	my $hfile = "$cdir/$hash";
	my $mdfile = "${hfile}.md";

	if (!defined($ci->{data})) {
		if ($me->{V} > 0) {
			print STDERR "cache read: ".$ci->{key}." from $hash\n";
		}

		if (! -f "$cdir/$hash") {
			if ($me->{V} > 0) {
				print STDERR "cache read: ENOTFOUND\n";
			}
			return undef;
		}


		if (-f $mdfile) {
			open(M,"<",$mdfile);
			while(<M>) {
				chomp($ri->{key} = $_);
			}
			close(M);
		}
		if (!defined($ri->{key})) {
			$ri->{key} = $ci->{key};
		}

		my $str;
		my $status;
		my $data;
		my $uz = IO::Uncompress::UnXz->new("$cdir/$hash");
		$ri->{data} = "";	
		while (1) {
			$status = $uz->read(\$str);
			if ($status < 1) {
				last;
			}
			$ri->{data} .= $str;
		}
		$uz->close();
		undef($uz);
		
		if ($me->{V} > 0) {
			printf STDERR "cache read: %d bytes\n", length($ri->{data});
		}
		return $ri;
	}

	if ($me->{V} > 0) {
		print STDERR "cache write: ".$ci->{key}." to $hash\n";
	}

	# XXX temp for M, check for errors
	open(M, ">", ${mdfile});
	print M $ci->{key}."\n";
	close(M);

	#open(H,"|xz -9e>$cdir/.${hash}");
	#print H $ci->{data};
	#close(H);

	my $xz = IO::Compress::Xz->new("$cdir/.${hash}", Preset => 9, Extreme => 1);
	$xz->print($ci->{data});
	$xz->close;

	rename("$cdir/.${hash}", "$cdir/$hash");

	if ($me->{V} > 0) {
		printf STDERR "cache write: %d bytes\n", length($ci->{data});
	}

	$ri = { };
	$ri->{key} = $ci->{key};
	$ri->{data} = $ci->{data};

	return $ri;
}

sub cache_str2hash {
	my ($me, $str) = @_;

	$me->{hash}->add($str);
	my $res = $me->{hash}->hexdigest;
	$me->{hash}->reset;

	return $res;
}

sub cache_setup {
	my ($me,$appname) = @_;

	use Crypt::Digest::SHA256;

	my $HOME=$ENV{'HOME'};
	my $cdir = "${HOME}/.cache/${appname}";
	if (! -d "${HOME}/.cache") {
		mkdir("${HOME}/.cache") || die
	}
	if (! -d $cdir) {
		mkdir($cdir);
	}

	$me->{cdir} = $cdir;

	$me->{hash} = Crypt::Digest::SHA256->new();
}

1;
