FROM perl:5.30

# install test dependencies
COPY ./cpanfile /tmp/
WORKDIR /tmp/
RUN cpanm --notest --installdeps .

# copy test files
COPY ./ /tmp/test/
WORKDIR /tmp/test/

# create big fake zip next to test files for wizard test
RUN fallocate --length 201M /tmp/test/201MB.zip

CMD [ "perl", "Runner.t" ]