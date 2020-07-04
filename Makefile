PERL_VERSION=perl-5.30.3
PERLBREW_ROOT=${PWD}/build/perlbrew

perl_distribution_build_image:
	cd perl_distribution && \
	docker build -t myfav-build .

# uses an accient Ubuntu distribution to compile Perl.
# This is works around issues when Perl was compiled
# on a too new machine and the target web server does not have
# a recent glibc version.
perl_distribution: perl_distribution_build_image
	mkdir -p build/perlbrew
	#
	docker run \
	--env PERL_VERSION=${PERL_VERSION} \
	--env PERLBREW_ROOT=/mnt/build/perlbrew \
    --volume ${PERLBREW_ROOT}:/mnt/build/perlbrew \
    --volume ${PWD}/perl_distribution:/mnt/perl_distribution \
    --rm \
	myfav-build \
	/bin/bash -c "cd /mnt/perl_distribution; make"
    #
	# we need to sudo due to docker uid mapping
	sudo rm -rf build/perl5 
	cp -r ${PERLBREW_ROOT}/perls/${PERL_VERSION} build/perl5

container:
	docker build -t myfavoritethings-test . 

# https://metacpan.org/pod/Test::Class
test:
	test/installer_test.sh

clean:
	sudo rm -rf build

.PHONY: test container perl_distribution