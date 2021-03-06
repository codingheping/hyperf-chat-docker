# hyperf/hyperf:7.4
#
# @link     https://www.hyperf.io
# @document https://doc.hyperf.io
# @contact  group@hyperf.io
# @license  https://github.com/hyperf/hyperf/blob/master/LICENSE

FROM hyperf/hyperf:7.4-alpine-v3.11-base

LABEL maintainer="Hyperf Developers group@hyperf.io" version="1.0" license="MIT"

ARG SW_VERSION
ARG COMPOSER_VERSION
ARG AMQP_VERSION

##
# ---------- env settings ----------
##
ENV SW_VERSION=${SW_VERSION:-"v4.6.1"} \
    COMPOSER_VERSION=${COMPOSER_VERSION:-"2.0.8"} \
    AMQP_VERSION=${AMQP_VERSION:-"v0.10.0"} \
    #  install and remove building packages
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev pcre2-dev zlib-dev curl-dev  libtool automake"
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# update
RUN set -ex \
    && apk update \
    # for swoole extension libaio linux-headers
    && apk add --no-cache libstdc++ openssl git bash wget cmake\
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev \
# download
    && cd /tmp \
    && curl -SL "https://github.com/swoole/swoole-src/archive/${SW_VERSION}.tar.gz" -o swoole.tar.gz \
    && ls -alh \
# php extension:swoole
    && cd /tmp \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && ln -s /usr/bin/phpize7 /usr/local/bin/phpize \
    && ln -s /usr/bin/php-config7 /usr/local/bin/php-config \
    && ( \
       cd swoole \
       && phpize \
       && ./configure --enable-mysqlnd --enable-openssl --enable-http2 --enable-swoole-json --enable-swoole-curl --enable-thread-context \
       && make -s -j$(nproc) && make install \
      ) \
    && echo "memory_limit=1G" > /etc/php7/conf.d/00_default.ini \
    && echo "opcache.enable_cli = 'On'" >> /etc/php7/conf.d/00_opcache.ini \
    && echo "extension=swoole.so" > /etc/php7/conf.d/50_swoole.ini \
    && echo "swoole.use_shortname = 'Off'" >> /etc/php7/conf.d/50_swoole.ini \
   # install composer
    && wget -nv -O /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x /usr/local/bin/composer
RUN cd /tmp \
    && pecl install redis \
    && echo "extension=redis.so" > /etc/php7/conf.d/redis.ini
RUN apk add --no-cache librdkafka-dev \
    && cd /tmp \
    && pecl install rdkafka \
    && echo "extension=rdkafka.so" > /etc/php7/conf.d/rdkafka.ini
RUN apk add --no-cache protobuf \
    && cd /tmp \
    && pecl install protobuf \
    && echo "extension=protobuf.so" > /etc/php7/conf.d/protobuf.ini
RUN apk add --no-cache rabbitmq-c-dev rabbitmq-c \
    && cd /tmp \
    && pecl install amqp \
    && echo "extension=amqp.so" > /etc/php7/conf.d/amqp.ini
    ## php info
RUN php -v \
    && php -m \
    && php --ri swoole \
    && php --ri amqp \
    && php --ri  rdkafka \
    && php --ri  protobuf \
    && composer \
    # ---------- clear works ----------
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/local/bin/php* \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"

