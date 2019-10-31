ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm-alpine AS base

COPY --from=forumone/f1-ext-install:latest \
  /f1-ext-install \
  /usr/bin/f1-ext-install

RUN set -ex \
  && f1-ext-install \
    builtin:gd \
    builtin:opcache \
    builtin:pdo_mysql \
    builtin:zip \
  # Settings taken from the Docker library's Drupal image
  && { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

FROM base AS xdebug

# XDebug gets a special image for itself: since all of our projects use XDebug for local
# debugging, this will save a decent amount of time per project since the user only
# needs to download an extra image layer instead of wait for the extension to compile.
#
# This step exists in the same image in order to be more aggressive with the Docker build
# cache - the same build job can move from the base target to xdebug and avoid rebuilding
# the above steps.
#
# It also ensures that this build will only produce a single extra layer, minimizing both
# the size and amount of layers developers need to download.

ARG XDEBUG_VERSION
RUN f1-ext-install pecl:xdebug@${XDEBUG_VERSION}
