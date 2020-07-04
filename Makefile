PERL_VERSION=perl-5.30.3

CURRENT_DIR = $(shell pwd)
export PERLBREW_ROOT=${CURRENT_DIR}/build/perlbrew
PERL_DISTRIBUTION_DIR=${PERLBREW_ROOT}/perls/${PERL_VERSION}
PERLBREW=${PERLBREW_ROOT}/bin/perlbrew
CPANM=${PERLBREW_ROOT}/bin/cpanm

container:
	docker build -t myfavoritethings-test . 

# https://metacpan.org/pod/Test::Class
test:
	test/installer_test.sh

${PERLBREW}:
	curl -L http://install.perlbrew.pl | bash

${CPANM}: ${PERLBREW}
	${PERLBREW} install-cpanm

${PERL_DISTRIBUTION_DIR}: ${PERLBREW}
	${PERLBREW} -j 9 --notest install ${PERL_VERSION}

install_modules: ${PERL_DISTRIBUTION_DIR} ${CPANM}
	${PERLBREW} exec -q --with ${PERL_VERSION} ${CPANM} --notest --installdeps .
	




download_libs2:
	curl -L http://cpanmin.us | perl - --notest --pureperl --self-contained -L lib2 \
	https://cpan.metacpan.org/authors/id/T/TI/TIMB/DBI-1.643.tar.gz

download_libs:
	curl -L http://cpanmin.us | perl - --notest --pureperl --self-contained -L lib2 \
	CGI::Carp \
	https://cpan.metacpan.org/authors/id/T/TI/TIMB/DBI-1.643.tar.gz \
	https://cpan.metacpan.org/authors/id/R/RE/REHSACK/DBD-AnyData-0.110.tar.gz \
	https://cpan.metacpan.org/authors/id/X/XS/XSAWYERX/Data-Dumper-2.173.tar.gz

clean:
	# rm -rf lib2
	rm -rf build

.PHONY: test container	