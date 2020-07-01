container:
	docker build -t myfavoritethings-test . 

test:
	test/installer_test.sh

# TODO continue here
# https://metacpan.org/pod/distribution/App-perlbrew/script/perlbrew
# export PERLBREW_ROOT=/opt/perl5
# curl -L http://install.perlbrew.pl | bash
# After doing this, the perlbrew executable is installed as /opt/perl5/bin/perlbrew
#
# https://gist.github.com/jkeroes/5759286
build_perl:
	#myperl/bin/perlbrew -j 9 --notest install 5.26.0


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
	rm -rf lib2

.PHONY: test container	