FROM ubuntu:14.04

SHELL ["/bin/bash", "-c"]

ARG PERL_VERSION
ARG PERL_VERSION_MODULE_DIR

RUN apt-get update; apt-get -y install build-essential curl

# install perlbrew + cpanm
RUN curl -L http://install.perlbrew.pl | bash
RUN source ~/perl5/perlbrew/etc/bashrc && perlbrew install-cpanm

# install desired perl version
RUN source ~/perl5/perlbrew/etc/bashrc && perlbrew -j 9 --notest install ${PERL_VERSION}

# install dependencies
COPY cpanfile /tmp/myfav/cpanfile
WORKDIR /tmp/myfav
RUN source ~/perl5/perlbrew/etc/bashrc && \
    perlbrew use ${PERL_VERSION} && \
    cpanm --notest --installdeps .

# prepare distribution folder
RUN cp -r ~/perl5/perlbrew/perls/${PERL_VERSION} /tmp/myfav_perl_distribution

# rename module dir from e.g. "lib/5.30.3/" to "lib/provided_version/"
# this allows stable module paths in the cgi scripts
RUN find /tmp/myfav_perl_distribution -depth -type d -name "*${PERL_VERSION_MODULE_DIR}*" \
    -exec bash -c 'mv "$1" "${1/${PERL_VERSION_MODULE_DIR}/provided_version}"' -- {} \;

# make module work with DBD::AnyData
COPY CGI_Application_Plugin_RateLimit.patch /tmp/myfav/CGI_Application_Plugin_RateLimit.patch
RUN patch $(find /tmp/myfav_perl_distribution -wholename "*/CGI/Application/Plugin/RateLimit.pm") /tmp/myfav/CGI_Application_Plugin_RateLimit.patch		
