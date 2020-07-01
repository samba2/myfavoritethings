FROM httpd:2.4.43

RUN apt-get update && \
    apt-get -y install curl

COPY cgi/ /usr/local/apache2/cgi-bin/MyFavoriteThings/cgi
COPY html/ /usr/local/apache2/cgi-bin/MyFavoriteThings/html/
COPY lib/ /usr/local/apache2/cgi-bin/MyFavoriteThings/lib/
COPY myfavCss/ /usr/local/apache2/cgi-bin/MyFavoriteThings/myfavCss/

COPY dockerize/httpd.conf /usr/local/apache2/conf/httpd.conf

RUN chmod u+x /usr/local/apache2/cgi-bin/MyFavoriteThings/cgi/*

HEALTHCHECK --interval=2s --timeout=2s --retries=3 \
  CMD curl --silent --fail localhost || exit 1
