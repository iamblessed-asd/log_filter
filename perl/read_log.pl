#!/usr/bin/perl
use lib '/usr/local/lib/perl5/site_perl/5.34.3/x86_64-linux-gnu';
use lib '/usr/share/perl5/vendor_perl';
use lib '/usr/share/perl5';

use strict;
use warnings;
use DBI;
use CGI;
use JSON;
use Time::HiRes qw(time);
use Getopt::Long;

my $logfile = $ENV{LOG_FILE} || "/usr/src/app/logs/out";

my $dsn = $ENV{MYSQL_DSN} || "DBI:mysql:database=$ENV{MYSQL_DATABASE};host=$ENV{MYSQL_HOST};port=3306";
my $db_user = $ENV{MYSQL_USER} || "user";
my $db_password = $ENV{MYSQL_PASSWORD} || "userpass";

my $force = 0;
my $help = 0;

GetOptions(
    "force" => \$force,
    "help" => \$help
) or die "Ошибка в аргументах командной строки. Используйте --help для справки.\n";

if ($help) {
    print <<"HELP";
Использование: $0 [OPTIONS]

Опции:
    --force    Принудительная запись в БД, даже если данные уже загружены
    --help     Показать эту справку

Переменные окружения:
    LOG_FILE           Путь к лог-файлу (по умолчанию: /usr/src/app/logs/out)
    MYSQL_DSN          DSN для подключения к MySQL
    MYSQL_HOST         Хост БД
    MYSQL_DATABASE     Имя базы данных
    MYSQL_USER         Пользователь БД
    MYSQL_PASSWORD     Пароль БД

HELP
    exit 0;
}

my $dbh = DBI->connect($dsn, $db_user, $db_password, { 
    RaiseError => 1, 
    mysql_enable_utf8 => 1,
    AutoCommit => 0
});

# Функция для проверки нужно ли загружать данные в БД
sub should_load_data {
    return 1 if $force;
    
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM log");
    $sth->execute();
    my ($count) = $sth->fetchrow_array();
    
    if ($count > 0) {
        print "В БД уже есть данные ($count записей). Используйте --force для принудительной загрузки.\n";
        return 0;
    }
    
    return 1;
}

sub load_log {
    unless (should_load_data()) {
        return (0, 0);
    }
    
    print "Выполнение записи в БД из файла $logfile\n";
    
    unless (-f $logfile) {
        die "Лог-файл $logfile не найден\n";
    }
    
    open(my $fh, "<", $logfile) or die "Не удалось открыть $logfile: $!";
    my $start_time = time();
    my $count_msg = 0;
    my $count_log = 0;

    my $sth_msg = $dbh->prepare(
        "INSERT IGNORE INTO message (created, id, int_id, str, status) VALUES (?, ?, ?, ?, ?)"
    );
    my $sth_log = $dbh->prepare(
        "INSERT INTO log (created, int_id, str, address) VALUES (?, ?, ?, ?)"
    );

    while (my $line = <$fh>) {
        chomp $line;
        next unless $line;

        my ($date, $time, $int_id, $maybe_flag, $rest) = split(/\s+/, $line, 5);
        my $created = "$date $time";

        my ($flag, $str, $address) = (undef, "", undef);

        # Проверка на то, что четвёртое поле действительно флаг
        if (defined $maybe_flag && $maybe_flag =~ /^(<=|=>|->|\*\*|==)$/) {
            $flag = $maybe_flag;
        } else {
            # Если флага нет, то вся строка после int_id = rest
            $rest = join(" ", $maybe_flag, $rest) if defined $maybe_flag && defined $rest;
            $rest = $maybe_flag unless defined $rest;
            $maybe_flag = undef;
        }

        if (defined $flag && $flag eq '<=') {
            my $id = ($rest && $rest =~ /id=([^\s]+)/) ? $1 : $int_id;
            $str = $rest // '';
            $sth_msg->execute($created, $id, $int_id, $str, 1);
            $count_msg++;
        } elsif (defined $flag) {
            if (defined $rest && length $rest) {
                # Паттерны для извлечения адреса
                if ($rest =~ /^(.*?)\s+<([^>]+)>\s*(.*)$/) {
                    # Адрес в <...> после произвольного текста
                    $address = $2;
                    $str = join(' ', grep { defined && length } ($1, $3));
                } elsif ($rest =~ /^<([^>]+)>\s+(.*)$/) {
                    # Адрес в <...> в начале строки
                    $address = $1;
                    $str = $2;
                } elsif ($rest =~ /^([^\s<>]+@[^\s>:]+):?\s+(.*)$/) {
                    # Адрес без <> в начале строки
                    $address = $1;
                    $str = $2;
                } else {
                    $str = $rest;
                    $address = undef;
                }
            } else {
                $str = '';
                $address = undef;
            }
            $sth_log->execute($created, $int_id, $str, $address);
            $count_log++;
        } else {
            # Строки с общей инфой
            $str = $rest // '';
            $address = undef;
            $sth_log->execute($created, $int_id, $str, $address);
            $count_log++;
        }
        
        if (($count_msg + $count_log) % 1000 == 0) {
            $dbh->commit;
            $dbh->{AutoCommit} = 0;
        }
    }

    close($fh);

    $dbh->commit;

    my $end_time = time();
    my $elapsed = sprintf("%.3f", $end_time - $start_time);
    print "Время выполнения записи в БД: $elapsed секунд\n";

    return ($count_msg, $count_log);
}

my ($msg_count, $log_count) = load_log();

if ($msg_count == 0 && $log_count == 0 && !$force) {
    print "Данные не были загружены (используйте --force для принудительной загрузки)\n";
} else {
    print "Загружено: $msg_count в message, $log_count в log\n";
}

$dbh->disconnect;