container:
	docker build -t myfavoritethings-test . 

test:
	test/installer_test.sh

.PHONY: test container	