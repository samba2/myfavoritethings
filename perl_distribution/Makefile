# builds a Perl distribution for My Favourite Things.
# This Makefile runs inside an (old) Ubuntu container
# to create a portable perl binary (no too new GLIBC issues)
#
# Environment vars: 
#
# PERL_VERSION - environment variable with the Perl version to be build. 
#                Has to be found by perlbrew. see 'perlbrew available'
# PERLBREW_ROOT - root dir for perlbrew

PERL_DISTRIBUTION_DIR=${PERLBREW_ROOT}/perls/${PERL_VERSION}
PERLBREW=${PERLBREW_ROOT}/bin/perlbrew
CPANM=${PERLBREW_ROOT}/bin/cpanm

# default target
all: install_modules

${PERLBREW}:
	curl -L http://install.perlbrew.pl | bash

${CPANM}: ${PERLBREW}
	${PERLBREW} install-cpanm

${PERL_DISTRIBUTION_DIR}: ${PERLBREW}
	${PERLBREW} -j 9 --notest install ${PERL_VERSION}

install_modules: ${PERL_DISTRIBUTION_DIR} ${CPANM}
	${PERLBREW} exec -q --with ${PERL_VERSION} ${CPANM} --notest --installdeps .
	${PERLBREW} exec -q --with ${PERL_VERSION} cpan -l
	
.PHONY: installdeps perl_distribution