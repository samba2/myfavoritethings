FROM httpd:2.4.43

RUN apt-get update && \
    apt-get -y install curl
    # apt-get -y install libcgi-session-perl liburi-escape-xs-perl gettext-base

COPY cgi/ /usr/local/apache2/cgi-bin/MyFavoriteThings/cgi
COPY html/ /usr/local/apache2/cgi-bin/MyFavoriteThings/html/
COPY lib/ /usr/local/apache2/cgi-bin/MyFavoriteThings/lib/
COPY myfavCss/ /usr/local/apache2/cgi-bin/MyFavoriteThings/myfavCss/

# mount points
# RUN mkdir /usr/local/apache2/cgi-bin/MyFavoriteThings/data/
# RUN mkdir /usr/local/apache2/cgi-bin/MyFavoriteThings/upload_files/
# RUN mkdir /usr/local/apache2/cgi-bin/MyFavoriteThings/sessions/

COPY dockerize/httpd.conf /usr/local/apache2/conf/httpd.conf

RUN chmod u+x /usr/local/apache2/cgi-bin/MyFavoriteThings/cgi/*

HEALTHCHECK --interval=2s --timeout=2s --retries=3 \
  CMD curl --silent --fail localhost || exit 1

# ENV DOCKER_INTERNAL_HTTP_PORT=80

# EXPOSE 80

# # make sure writeable directories are owned by UID of the host.
# # also httpd runs with that HOST_UID
# CMD id --user ${HOST_UID} || useradd --uid ${HOST_UID} --shell /usr/sbin/nologin myfav && \
#     chown ${HOST_UID} /usr/local/apache2/cgi-bin/MyFavoriteThings/data/ && \
#     chown ${HOST_UID} /usr/local/apache2/cgi-bin/MyFavoriteThings/upload_files/ && \
#     chown ${HOST_UID} /usr/local/apache2/cgi-bin/MyFavoriteThings/sessions/ && \
#     chown ${HOST_UID} /usr/local/apache2/htdocs/* && \
#     httpd-foreground