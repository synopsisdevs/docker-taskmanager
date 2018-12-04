FROM php:7.1-apache

RUN a2enmod rewrite

ENV DEPENDENCIES="libpq-dev libmcrypt-dev python sudo cron zlib1g-dev supervisor"
ENV TZ Europe/Prague

RUN sed -i  "s/http:\/\/httpredir\.debian\.org\/debian/ftp:\/\/ftp\.debian\.org\/debian/g" /etc/apt/sources.list

RUN apt-get clean \
    && apt-get update \
    && apt-get install -y $DEPENDENCIES \
    && apt-get autoremove -y \
    && apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# db driver
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/postgresql \
    && docker-php-ext-configure bcmath \
    && docker-php-ext-install -j$(nproc) pdo pdo_pgsql pgsql bcmath mcrypt zip

#crons
RUN touch /var/log/cron.log
ADD crontab /etc/cron.d/task-manager
RUN chmod 0644 /etc/cron.d/task-manager
RUN crontab /etc/cron.d/task-manager

# supervisor.conf
RUN mkdir -p /var/log/supervisor
COPY supervisordocker.conf /etc/supervisor/conf.d/000-supervisord.conf

EXPOSE 80 443 9001

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]