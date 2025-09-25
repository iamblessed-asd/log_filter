FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    perl \
    apache2 \
    libapache2-mod-perl2 \
    default-mysql-client \
    libdbi-perl \
    libdbd-mysql-perl \
    curl \
    dos2unix \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    gcc \
    libperl-dev \
    cpanminus \
 && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest CGI CGI::Carp JSON Time::Piece

RUN apt-get purge -y build-essential make gcc libperl-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /root/.cpanm/

RUN a2enmod cgi && a2enmod perl && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

COPY apache_app.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /usr/src/app

COPY entrypoint.sh /usr/src/app/
RUN dos2unix /usr/src/app/entrypoint.sh && \
    chmod +x /usr/src/app/entrypoint.sh

COPY read_log.pl /usr/src/app/
RUN dos2unix /usr/src/app/read_log.pl

COPY html/ /var/www/html/

COPY cgi-bin/ /usr/lib/cgi-bin/
RUN chmod +x /usr/lib/cgi-bin/*.pl && \
    find /usr/lib/cgi-bin -type f -name '*.pl' -exec dos2unix {} \;

CMD ["/usr/src/app/entrypoint.sh"]
