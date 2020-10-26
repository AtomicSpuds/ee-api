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
has appname => ( is => 'ro' );

sub init {
	my $me = shift;
	#print "init in a ".ref($me)." package\n";
	#print "me->config is a ".ref($me->config)."\n";

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
	my @tables = split(/,/,$sc->{tables});
	foreach my $t (@tables) {
		printf STDERR "config->sql->tables +%s\n",$t;
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
		my $appname = sprintf("%s/%d", $me->appname, getpid());
		#print STDERR "appname = ${appname}\n";
		$dbh->do("SET application_name = '${appname}'");
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


	my @dbtables = $dbh->tables();
	my %tablefound;
	foreach my $tname (@dbtables) {
		foreach my $tn (@tables) {
			my $tre = $dbinfo->{tablere};
			$tre =~ s/%name%/$tn/g;
			if ($tname =~ m/$tre/) {
				$tablefound{$tn} = 1;
			}
		}
	}

	foreach my $tn (@tables) {
		if (!defined($tablefound{$tn})) {
			my $i=0;
			my $create = "";
			while (1) {
				my $var="t$i";
				my $val = $config->{$tn}->{$var};
				if (!defined($val)) {
					last;
				}
				$create .= "${val} ";
				#printf STDERR "config table $var = '%s'\n",$val;
				$i++;
			}
			foreach my $vv (('serialtype','blobtype')) {
				my $val = $dbinfo->{$vv};
				$create =~ s/%${vv}%/${val}/g;
			}
			#printf STDERR "create = '%s'\n", $create;
			my $rv = $dbh->do($create);
			printf STDERR "dbh->do(%s) returned a %s ('%s')\n", $create, ref($rv), Dumper($rv);
			$i=0;
			while (1) {
				my $var="i$i";
				my $val = $config->{$tn}->{$var};
				if (!defined($val)) {
					last;
				}
				#printf STDERR "config table $var = '%s'\n",$val;
				my ($idxname, $idxvars) = split(/;/,$val);
				if (!defined($idxname) || !defined($idxvars)) {
					printf STDERR "config table $var    ... improper line, did ; get used as a separator?\n";
					last;
				}
				#printf STDERR "mkidx('%s', '%s', '%s')\n", $idxname, $tn, $idxvars;
				$me->mkidx($idxname, $tn, $idxvars);
				$i++;
			}
		}
	}
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

sub getdbh {
	my ($me) = @_;
	return $me->{dbh};
}

sub cached_execute {
	my ($me, $q, @values) = @_;

	my $ret = { };

	eval {
		$ret->{sth} = $me->{dbh}->prepare_cached($q);
	};
	if ($@) {
		$ret->{errstr} = $@;
		return $ret;
	}
	my @input;
	foreach my $v (@values) {
		if ($v ne "NULL") {
			push @input, $v;
		} else {
			push @input, undef;
		}
	}

	eval {
		$ret->{rv} = $ret->{sth}->execute(@input);
	};
	if ($@) {
		$ret->{errstr} = $@;
		return $ret;
	}
	return $ret;
}

sub get_dbsz {
	my ($me) = @_;
	my $ret = $me->cached_execute($me->{dbinfo}->{get_dbsz});
	if (defined($ret->{errstr})) {
		print STDERR "WARNING: ".$ret->{errstr}."\n";
		return -1;
	}
	my (@ret) = $ret->{sth}->fetchrow_array;
	$ret->{sth}->finish;
	if ($#ret < 0 || !defined($ret[0])) {
		print STDERR "WARNING: no dbsz result\n";
		return -1;
	}
	return $ret[0];
}

sub dbdie {
	my ($me, $ret, $func, $what) = @_;

	print STDERR $func;
	print STDERR ": ";
	print STDERR $ret->{errstr};
	print STDERR "\n";
	
	print STDERR $func;
	print STDERR ": ${what} rv is a ";
	print STDERR ref($ret->{rv});
	print STDERR " and contains ";
	print STDERR Dumper($ret->{rv});
	print STDERR "\n";

	print STDERR "ret: ";
	print STDERR Dumper($ret);
	print STDERR "\n";

	print STDERR "\n   ...goodby cruel world!\n\n";
	exit(1);
}

1;
