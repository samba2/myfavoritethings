FROM httpd:2.4.43

RUN apt-get update && \
    apt-get -y install curl

HEALTHCHECK --interval=2s --timeout=2s --retries=3 \
  CMD curl --silent --fail localhost || exit 1

COPY dockerize/httpd.conf /usr/local/apache2/conf/httpd.conf

COPY build/perl5/ /usr/local/apache2/cgi-bin/MyFavoriteThings/perl5/
COPY html/ /usr/local/apache2/cgi-bin/MyFavoriteThings/html/
COPY lib/MyFav /usr/local/apache2/cgi-bin/MyFavoriteThings/lib/MyFav/
COPY myfavCss/ /usr/local/apache2/cgi-bin/MyFavoriteThings/myfavCss/
COPY cgi/ /usr/local/apache2/cgi-bin/MyFavoriteThings/cgi

RUN chmod u+x /usr/local/apache2/cgi-bin/MyFavoriteThings/cgi/*