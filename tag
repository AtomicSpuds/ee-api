#!/usr/bin/perl

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

use strict;
use warnings;

use Config::Tiny;
use Data::Dumper;
use Date::Manip;
use Getopt::Std;
use JSON;
use POSIX qw{strftime};
use Sys::Syslog qw(:standard :macros);

use Common::Db;

STDERR->autoflush(1);
STDOUT->autoflush(1);

our $opt_v = 0;
our $opt_s;
our $opt_c;

$opt_c = $ENV{'HOME'}."/.ee-api.conf";

getopts('v');

if (!defined($opt_v)) {
	$opt_v = 0;
}

if (! -f $opt_c) {
	die "config file '$opt_c' does not exist";
}

our $config = Config::Tiny->read( $opt_c );

my $cdb = Common::Db->new(
	'config' => $config,
);
$cdb->init;


# syslog bits
my $fac = "daemon";
our $prio = LOG_INFO;
my $proc = "ee-tag";

openlog($proc, "ndelay", $fac);

if (!defined($ARGV[0])) {
	print STDERR "$0: <name pattern> [<tag>]\n";
	exit(1);
}

my $pattern = $ARGV[0];
my $tag = $ARGV[1];

add_tag($cdb, $pattern,$tag);

exit(0);

# db interaction routines

sub add_tag {
	my ($cdb, $matchpattern, $tag) = @_;

	my $tagstr = $tag;
	if (!defined($tag)) {
		$tagstr = "<undef>";
	}
	
	my $q = "SELECT id,name from ee_api_names where name like ?";

	my $ret = $cdb->cached_execute($q, $matchpattern);

	if (defined($ret->{errstr})) {
		$ret->{sth}->finish;
		$cdb->dbdie($ret,"add_tag(cdb, $matchpattern, $tagstr)","SELECT");
	}

	my (@ret) = $ret->{sth}->fetchrow_array;
	if ($#ret < 0 || !defined($ret[0])) {
		print "add_tag(cdb, $matchpattern, $tagstr): no match, bailing\n";
		exit(1);
	}

	my $tagid;
	if (defined($tag)) {
		$tagid = get_tag_id($cdb, $tag);
	}

	handle_match($cdb, $tagid, @ret);

	while ( @ret = $ret->{sth}->fetchrow_array ) {
		handle_match($cdb, $tagid, @ret);
	}

	$ret->{sth}->finish;
}

sub handle_match {
	my ($cdb, $tagid, @ret) = @_;

	print "Found match: ".$ret[0]." - ".$ret[1]."\n";
	
	if (defined($tagid)) {	
		add_tagem($cdb, $tagid, $ret[0]);
	} else {
		if ($opt_v>0) {
			print "handle_match: tagid = <undef>\n";
		}
	}
}
	

sub get_tag_id {
	my ($cdb, $tag) = @_;

	if ($opt_v>0) {
		print "get_tag_id(cdb, $tag): start\n";
	}

	my $q = "SELECT id from ee_api_tags where tag = ?";

	my $ret = $cdb->cached_execute($q, $tag);

	if (defined($ret->{errstr})) {
		print "get_tag_id(cdb, $tag): SELECT rv is a ".ref($ret->{rv})." and contains ";
		print Dumper($ret->{rv})."\n";
		print "ret: ";
		print Dumper($ret)."\n";
		print "...bailing\n";
		exit(1);
	}
	my (@ret) = $ret->{sth}->fetchrow_array;
	$ret->{sth}->finish;
	if ($#ret < 0 || !defined($ret[0])) {
		if ($opt_v>0) {
			print "get_tag_id(cdb, $tag): id not found\n";
		}
		$q = "INSERT into ee_api_tags (tag) values (?)";
		$ret = $cdb->cached_execute($q, $tag);
		if (defined($ret->{errstr})) {
			print "get_tag_id(cdb, $tag): INSERT rv is a ".ref($ret->{rv})." and contains ";
			print Dumper($ret->{rv})."\n";
			exit(1);
		}
		
		return get_tag_id($cdb, $tag);
	}

	return $ret[0];
}

sub add_tagem {
	my ($cdb, $tagid, $nameid) = @_;

	if ($opt_v>0) {
		print "add_tagem(cdb, $tagid, $nameid): start\n";
	}

	my $q = "SELECT id from ee_api_tagem where tagid = ? and nameid = ?";

	my $ret = $cdb->cached_execute($q, $tagid, $nameid);

	if (defined($ret->{errstr})) {
		$cdb->dbdie($ret, "add_tagem(cdb, $tagid, $nameid)", "SELECT");
	}

	my (@ret) = $ret->{sth}->fetchrow_array;
	$ret->{sth}->finish;
	if ($#ret < 0 || !defined($ret[0])) {
		if ($opt_v>0) {
			print "add_tagem(cdb, $tagid, $nameid): not found\n";
		}
		$q = "INSERT into ee_api_tagem (tagid, nameid) values (?,?)";
		$ret = $cdb->cached_execute($q, $tagid, $nameid);
		if (defined($ret->{errstr})) {
			$cdb->dbdie($ret, "add_tagem(cdb, $tagid, $nameid)", "INSERT");
		}
		return add_tagem($cdb, $tagid, $nameid);
	}
	return $ret[0];
}
1;
