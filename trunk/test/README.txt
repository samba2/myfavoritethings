currently tests are executed by http accessing a local web server.
the config for the setup is in MainTest.t (URLs + paths)

to simple run the tests WITHOUT changing the paths do the following:
  - apt-get install libtest-www-mechanize-perl
  - install cgi capable web server
  - directly link the working copy to /var/www/cgi-bin/ (no separete subdir)
  - root@adminuser-VirtualBox:/var/www# ln -s /home/adminuser/myfav/trunk/ /var/www/cgi-bin
  - disable read write permissions
  - chmod -R a+rwx /var/www/cgi-bin/
  - make shure that user www-data can access
    - "data" dir (read write)
    - "session" dir (read write)

now execute AS ROOT !! "MainTest.t"

