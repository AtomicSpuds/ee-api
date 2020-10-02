# Copyright (c) 2020 AtomicSpuds <AtomicSpudsGame@gmail.com>
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

package Common::Db;

use strict;
use warnings;

use feature 'say';
my $VERSION = '0.0';
use Moo;
#use strictures 2;

use namespace::clean;

use Data::Dumper;
use DBI qw(:sql_types);
use DBI::Const::GetInfoType qw(%GetInfoType);
use Module::Load;
use POSIX qw{getpid};

has config => ( is => 'ro' );

sub init {
	my $me = shift;
	print "init in a ".ref($me)." package\n";
	print "me->config is a ".ref($me->config)."\n";

	if (!defined($me->{dbh})) {
		$me->init_db;
	}
}


sub init_db {
	my $me = shift;
	my $config = $me->config;
	my $sc = $config->{sql};

	if (!defined($sc)) {
		print STDERR "config requires a [sql] section\n";
		return;
	}

	# calling init_db by definition means re-connecting
	my $dbh;
	my $driver = $sc->{driver};
	my $user = $sc->{user};
	my $pass = $sc->{pass};
	my $db = $sc->{db};

	my $class = "DBD::${driver}";
	#print "init_db: about to load $class\n";
	if ($driver eq "Pg") {
		eval {
			load $class, ':pg_types';
		};
	} else {
		eval {
			load $class;
		};
	}
	if ($@) {
		print "Error loading $class .. $@\n";
		exit(1);
	}
	#print "init_db: past loading $class\n";
	
	if (!defined($dbh)) {
		eval {
		$dbh = DBI->connect("dbi:${driver}:dbname=$db",$user,$pass,
			{RaiseError => 1, AutoCommit => 1});
		};
		if ($@) {
			print STDERR "DBI->connect('dbi:${driver}:dbname=${db}',$user,pass,..) ...\n";
			print STDERR " returned a _";
			print STDERR ref($dbh);
			printf STDERR "_ with value '%s'\n", Dumper($dbh);
			print STDERR " error: $@\n";
			exit(1);
		}
		if (!defined($dbh)) {
			print STDERR "DBI->connect failed, returned undef\n";
			exit(1);
		}
		exit(0);
	}

	my $dbmsname = $dbh->get_info( $GetInfoType{SQL_DBMS_NAME} );
	my $dbmsver  = $dbh->get_info( $GetInfoType{SQL_DBMS_VER} );

	my $dbinfo = { };
	if ($dbmsname eq "PostgreSQL") {
		# XXX fix bLOB bits
		$dbinfo->{'serialtype'}     = "SERIAL UNIQUE";
		$dbinfo->{'blobtype'}      = "bytea";
		#'$dbinfo->{blob_bind_type'} = { pg_type => PG_BYTEA };
		$dbinfo->{'tablere'}        = '\\.%name%$';
		$dbinfo->{'ind_crea_re'}   = "CREATE INDEX %NAME% ON %TABLE% using btree ( %PARAMS% )";
		$dbinfo->{'pgsz'}          = 1;
		$dbinfo->{'get_dbsz'}      = "SELECT pg_database_size(datname) db_size FROM pg_database where datname = '$db' ORDER BY db_size";
		# XXX make a function call??
		$dbh->do("SET application_name = 'ee_api/".getpid()."'");
	} elsif ($dbmsname eq 'SQLite') {
		my $q = "pragma page_size";
		# XXX fixme
		my $pgsz = $dbh->query($q);
		$dbinfo->{'serialtype'}    = "integer PRIMARY KEY AUTOINCREMENT";
		$dbinfo->{'blobtype'}      = "oops_fixme";
		$dbinfo->{'blob_bind_type'}= SQL_BLOB;
		$dbinfo->{'tablere'}       = '"%name%"';
		$dbinfo->{'pgsz'}          = $pgsz;
		$dbinfo->{'get_dbsz'}      = "pragma page_count";
	} else {
		printf STDERR "Unknown dbmsname and version: %s %s\n", $dbmsname, $dbmsver;
		return;
	}
			
	$dbinfo->{dbmsname} = $dbmsname;
	$dbinfo->{dbmsver}  = $dbmsver;
	$dbinfo->{pgct} = $dbh->do($dbinfo->{get_dbsz});

	$me->{dbh} = $dbh;
	$me->{dbinfo} = $dbinfo;


	my @tables = $dbh->tables();
	my %tablefound;
	foreach my $tname (@tables) {
		foreach my $tn (('ee_api_names','ee_api_summary','ee_api_data')) {
			my $tre = $dbinfo->{tablere};
			$tre =~ s/%name%/$tn/g;
			if ($tname =~ m/$tre/) {
				$tablefound{$tn} = 1;
			}
		}
	}

	if (!defined($tablefound{'ee_api_names'})) {
		my $q = "CREATE TABLE ee_api_names (";
		$q .=   "id int UNIQUE, ";
		$q .=   "name varchar, ";
		$q .=   "created timestamp without time zone default now() ";
		$q .=   ")";
		#print "$q\n";
		my $rv = $dbh->do($q);
		printf STDERR "dbh->do(%s) returned a %s ('%s')\n", $q, ref($rv), Dumper($rv);
		#$me->mkidx('ee_api_names_ididx', 'ee_api_names', 'id');
		$me->mkidx('ee_api_names_nameidx', 'ee_api_names', 'name');
	}
	if (!defined($tablefound{'ee_api_summary'})) {
		my $q = "CREATE TABLE ee_api_summary (";
		$q .=   "id int UNIQUE, ";
		$q .=   "tradetime timestamp, ";
		$q .=   "sell numeric(15,2), ";
		$q .=   "buy numeric(15,2), ";
		$q .=	"lowest_sell numeric(15,2), ";
		$q .=	"highest_buy numeric(15,2), ";
		$q .=   "created timestamp without time zone default now() ";
		$q .=   ")";
		my $rv = $dbh->do($q);
		$me->mkidx('ee_api_summary_timeidx','ee_api_summary', 'tradetime');
	}
	if (!defined($tablefound{'ee_api_data'})) {
		my $q = "CREATE TABLE ee_api_data (";
		$q .= "id int UNIQUE, ";
		$q .= "tradetime timestamp, ";
		$q .= "sell numeric(15,2), ";
		$q .= "buy numeric(15,2), ";
		$q .= "lowest_sell numeric(15,2), ";
		$q .= "highest_buy numeric(15,2), ";
		$q .= "entered timestamp without time zone default now() ";
		$q .= ")";
		my $rv = $dbh->do($q);
		$me->mkidx('ee_api_data_time','ee_api_data','tradetime');
	}
	print "Pausing 30s...\n";
	sleep(30);
}

sub mkidx {
	my ($me, $name, $table, $params) = @_;

	my $q = $me->{dbinfo}->{ind_crea_re};
	$q =~ s/%NAME%/$name/;
	$q =~ s/%TABLE%/$table/;
	$q =~ s/%PARAMS%/$params/;
	my $rv = $me->{dbh}->do($q);
	printf STDERR "dbh->do(%s) returned a %s ('%s')\n", $q, ref($rv), Dumper($rv);
}

1;

