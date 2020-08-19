PERL_VERSION=perl-5.30.3
PERL_VERSION_MODULE_DIR=5.30.3

# heading in green
define log_heading
    echo "\n\e[32m-= $(1) =-\n\e[0m"
endef

# we build our own custom perl distribution which is shipped with MyFav.
# To be backward compatible we build on an accient Ubuntu version
myfav_perl_distribution:
	$(call log_heading, Building My Favourite Things Perl Distribution Image)
	cd myfav_perl_distribution && \
	docker build \
	    --build-arg PERL_VERSION=${PERL_VERSION} \
		--build-arg PERL_VERSION_MODULE_DIR=${PERL_VERSION_MODULE_DIR} \
		--tag myfav_perl_distribution .

# an image containing a freshly installed MyFav installation.
# start manually via: docker run -p 80:80 -it myfav
# access installer: http://localhost/cgi-bin/MyFavoriteThings/cgi/install.cgi 
myfav:
	$(call log_heading, Building My Favourite Things Image)
	docker build --tag myfav --file test/Dockerfile.myfav .

# build a test runner and then execute the integration tests.
test: build_test_runner execute_test_runner

build_test_runner:
	$(call log_heading, Building Test Runner Image)
	cd test && \
	docker build --tag myfav_test_runner --file Dockerfile.testrunner .

# runs tests inside the myfav_test_runner image.
# the application is run via the "myfav" container.
# due to --network='host' a Linux system is probably required
execute_test_runner: 
	$(call log_heading, Executing Tests) && \
	docker run \
		--network='host' \
	    -v /var/run/docker.sock:/var/run/docker.sock \
		-v /usr/bin/docker:/usr/bin/docker \
        myfav_test_runner

clean:
	docker rm $(shell docker ps -a -q) || true
	docker rmi $(shell docker images -f "dangling=true" -q) || true 
	docker rmi --force myfav
	docker rmi --force myfav_test_runner
	docker rmi --force myfav_perl_distribution

.PHONY: test myfav_perl_distribution