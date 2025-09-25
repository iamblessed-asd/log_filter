#!/usr/bin/env perl
use strict;
use warnings;
use CGI;
use DBI;
use JSON;

my $cgi = CGI->new;
print $cgi->header(-type => "application/json", -charset => "utf-8");

my $address = $cgi->param("address") || "";
my $limit   = $cgi->param("limit")   || 100;

my $dsn = "DBI:mysql:database=mydb;host=db;port=3306";
my $dbh = DBI->connect($dsn, "user", "userpass", { RaiseError => 1, mysql_enable_utf8 => 1 });

my $sql = qq{
    SELECT created, id, int_id, str, status, NULL AS address, 'message' AS type
    FROM message
    %s
    UNION ALL
    SELECT created, NULL AS id, int_id, str, NULL AS status, address, 'log' AS type
    FROM log
    %s
    ORDER BY int_id, created DESC
    LIMIT ?
};

my ($where_msg, $where_log, @params);

# Поставил "LIKE" для человеческого фактора - мб не нужно обязательно полностью вводить адрес, а только его часть
if ($address) {
    $where_msg = "WHERE str LIKE ?";
    $where_log = "WHERE address LIKE ?";
    push @params, "%$address%", "%$address%", $limit + 1;
} else {
    $where_msg = "";
    $where_log = "";
    push @params, $limit;
}

my $sth = $dbh->prepare(sprintf($sql, $where_msg, $where_log));
$sth->execute(@params);

my @rows;
while (my $row = $sth->fetchrow_hashref) {
    push @rows, $row;
}
$sth->finish;
$dbh->disconnect;

# проверка на то, превышают ли записи лимит
my $more = 0;
if (@rows > $limit) {
    $more = 1;
    @rows = @rows[0 .. $limit - 1];
}

my %response = (
    more => $more,
    results => \@rows,
);

print encode_json(\%response);