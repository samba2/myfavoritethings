All build steps for myfavouritethings are controlled by Docker containers. The central starter is the `Makefile` in the project root.

Important targets are:
* `make release`
    * build own Perl distribution
    * assembles a runnable myfavouritethings container
    * prepares release
    
* `make tests` 
    * build own Perl distribution
    * assembles a runnable myfavouritethings container
    * builds test runner
    * executes tests
