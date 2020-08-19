PERL_VERSION=perl-5.30.3
PERL_VERSION_MODULE_DIR=5.30.3

PERLBREW_ROOT=${PWD}/build/perlbrew

# heading in green
define log_heading
    echo "\n\e[32m-= $(1) =-\n\e[0m"
endef

# TODO we need this version homehow installed https://metacpan.org/source/OALDERS/URI-1.76/lib/URI/Escape.pm
#  |
#  +--> still relevant?
# TODO continue here, use created perl_distribution to run tests
myfav_perl_distribution:
	$(call log_heading, Building My Favourite Things Perl Distribution Image)
	cd myfav_perl_distribution && \
	docker build \
	    --build-arg PERL_VERSION=${PERL_VERSION} \
		--build-arg PERL_VERSION_MODULE_DIR=${PERL_VERSION_MODULE_DIR} \
		--tag myfav_perl_distribution .

# we build our own Perl distribution to ship it with My Favourite Things.
# To work around issues on older server (too older glibc) we use an accient 
# Ubuntu distribution to compile Perl and the modules.
# myfav_perl_distribution: myfav_perl_distribution_build_image
# 	mkdir -p build/perlbrew
# 	#
# 	docker run \
# 	--env PERL_VERSION=${PERL_VERSION} \
# 	--env PERLBREW_ROOT=/mnt/build/perlbrew \
#     --volume ${PERLBREW_ROOT}:/mnt/build/perlbrew \
#     --volume ${PWD}/myfav_perl_distribution:/mnt/myfav_perl_distribution \
#     --rm \
# 	myfav_perl_distribution_builder \
# 	/bin/bash -c "cd /mnt/myfav_perl_distribution; make"
#     #
# 	# we need to sudo due to docker uid mapping
# 	sudo rm -rf build/perl5 
# 	cp -r ${PERLBREW_ROOT}/perls/${PERL_VERSION} build/perl5
# 	# rename module dir from e.g. "lib/5.30.3/" to "lib/provided_version/"
# 	# this allows stable module paths in the cgi scripts
# 	find build/perl5 -depth -type d -name '*${PERL_VERSION_MODULE_DIR}*' \
# 	    -execdir bash -c 'mv "$$1" "$${1/${PERL_VERSION_MODULE_DIR}/provided_version}"' -- {} \;
	
# 	# make module work with DBD::AnyData
# 	patch `find build/perl5/ -wholename "*/CGI/Application/Plugin/RateLimit.pm"` myfav_perl_distribution/CGI_Application_Plugin_RateLimit.patch		


myfav:
	docker build --tag myfav --file test/Dockerfile.myfav .

test: build_test_runner execute_test_runner

build_test_runner:
	$(call log_heading, Building Test Runner Image)
	cd test && \
	docker build --tag myfav_test_runner --file Dockerfile.testrunner .

# runs tests inside the myfav-test-runner image.
# due to --network='host' a Linux system is probably required
execute_test_runner: 
	$(call log_heading, Executing Test Runner) && \
	docker run \
		--network='host' \
	    -v /var/run/docker.sock:/var/run/docker.sock \
		-v /usr/bin/docker:/usr/bin/docker \
        myfav_test_runner

# TODO check what images are still relevant
clean:
	sudo rm -rf build
	docker rm $(shell docker ps -a -q) || true
	docker rmi $(shell docker images -f "dangling=true" -q) || true 
	docker rmi --force myfav_test_runner
	docker rmi --force myfav_perl_distribution_builder
	docker rmi --force myfav_perl_distribution_builder2
	docker rmi --force myfav_perl_distribution

.PHONY: test myfav_perl_distribution