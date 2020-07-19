PERL_VERSION=perl-5.30.3
PERL_VERSION_MODULE_DIR=5.30.3

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
	# rename module dir from e.g. "lib/5.30.3/" to "lib/provided_version/"
	# this allows stable module paths in the cgi scripts
	find build/perl5 -depth -type d -name '*${PERL_VERSION_MODULE_DIR}*' \
	    -execdir bash -c 'mv "$$1" "$${1/${PERL_VERSION_MODULE_DIR}/provided_version}"' -- {} \;
	
	# make module work with DBD::AnyData
	patch `find build/perl5/ -wholename "*/CGI/Application/Plugin/RateLimit.pm"` perl_distribution/CGI_Application_Plugin_RateLimit.patch		


container:
	docker build -t myfavoritethings-test . 

# runs tests inside the myfav-test-runner image.
# due to --network='host' a Linux system is probably required
test:
	cd test && \
	docker build --tag myfav-test-runner . && \
	docker run \
		--network='host' \
	    -v /var/run/docker.sock:/var/run/docker.sock \
		-v /usr/bin/docker:/usr/bin/docker \
        myfav-test-runner

clean:
	sudo rm -rf build

.PHONY: test container perl_distribution