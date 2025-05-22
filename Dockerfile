FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-perl2 perl \
        libcgi-pm-perl libmime-base64-perl libnet-perl \
        libdigest-perl libdigest-md5-perl libtext-iconv-perl \
        ispell libauthen-pam-perl libnet-ssleay-perl \
        build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/www/cgi-bin /usr/local/www/data
COPY --chown=www-data:www-data cgi-bin/openwebmail /usr/local/www/cgi-bin/openwebmail
COPY --chown=www-data:www-data data/openwebmail /usr/local/www/data/openwebmail
COPY data/openwebmail/redirect.html /var/www/html/index.html

# Ensure dbm configuration matches the DB_File modules shipped with Ubuntu
# Without this adjustment, `openwebmail-tool.pl --init` fails asking for a
# change from `.db` to `.pag`.
RUN sed -i 's/^dbm_ext.*/dbm_ext                 .pag/' \
        /usr/local/www/cgi-bin/openwebmail/etc/defaults/dbm.conf

RUN a2enmod cgid
RUN echo 'ScriptAlias /cgi-bin/ /usr/local/www/cgi-bin/' > /etc/apache2/conf-available/openwebmail.conf && \
    echo '<Directory "/usr/local/www/cgi-bin">' >> /etc/apache2/conf-available/openwebmail.conf && \
    echo '    Options +ExecCGI' >> /etc/apache2/conf-available/openwebmail.conf && \
    echo '    AddHandler cgi-script .pl' >> /etc/apache2/conf-available/openwebmail.conf && \
    echo '</Directory>' >> /etc/apache2/conf-available/openwebmail.conf && \
    a2enconf openwebmail

RUN /usr/local/www/cgi-bin/openwebmail/openwebmail-tool.pl --init --no

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
