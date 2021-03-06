# Installation #
This page describes the installation of _My Favorite Things_ on a web server.

## Prerequisite ##
_My Favorite Things_ is running as good old Common Gateway Interface (CGI) application. This might seem a little bit old fashioned but the aim of the application was to run even on the cheapest web server. However, to use _My Favorite Things_ make sure your web hoster is supporting running CGI scripts.

_My Favorite Things_ is written in Perl. It requires an existing Perl 5 installation on the web server. This should hopefully be the case on almost every webserver. So you don't have to worry about it. If you are facing problems it is a good idea to ask your provider if "Perl" is supported and if the perl binary file is located under `/usr/bin/perl`. But as I said, this is pretty much standard so you should be safe here.

## Copying and Permissions ##
The whole `MyFavoriteThings` folder needs to be copied to the CGI area of your web site. In almost all cases this is inside the directory `cgi-bin` of your web server.
If you don't find such a directory in your web space, try to create `cgi-bin` and copy `MyFavoriteThings` inside it.

So you end up with something link `cgi-bin/MyFavoriteThings/`
If you are unsure about this cgi-bin business, contact your provider/ hoster and ask for the directory for cgi script files.

Inside the `MyFavoriteThings` folder is a directory called `cgi`. Go inside and you will find the following files
  * install.cgi
  * Releases.cgi
  * Wizard.cgi
  * DownloadFile.cgi
  * Login.cgi

Now add the _execute_ permission to all those cgi files. This is done by your FTP/ SFTP client program. If you don't know how to change this permission consult the help function of your FTP/ SFTP client. Apply `execute` to all three user groups: `user`, `group` and `others`

## Running the Installer ##
Now all the necessary preperations to run the install program are in place. The installer is one of the CGI scripts above and is located here:
`cgi-bin/MyFavoriteThings/cgi/install.cgi`

The `install.cgi` script is started with your browser. The trick is now to find the right web address of the script. So lets take an example:

If `cgi-bin` is located directly on the top level of your web server then the URL should be `http://your-domain.name/cgi-bin/MyFavoriteThings/cgi/install.cgi`

If your lucky the "My Favorite Things Installer" page is presented to you. From here just follow the instructions.

Good luck ;-)

## Additional Information ##
This page continues with some background information of _My Favorite Things_ which might be usefull for you as well.

**Perl is located somewhere else/ Running on Windows**

If your perl interpreter is not at `/usr/bin/perl` but somewhere else you have to alter the first line of all the cgi files inside the `cgi` directory.
If you are trying to install on Windows (is someone really doing that?!) change for all files
`#!/usr/bin/perl -w` to the path of your perl binary on the Windows system like `#!C:/Perl/bin/perl.exe -w`

**Understanding the Forwarder**

I admit I have been a little bit inconsistent while talking about the "central download path" or the "forwarder URL". It is all the same.
The actual user download is done by `DownloadFile.cgi` + some (quite long) parameters. So you end up with something like
`http://your-domain/cgi-bin/MyFavoriteThings/cgi/DownloadFile.cgi?r=DFnmd313fbs7nd463` which is not nice.

To overcome that a HTML forwarder (technically speaking a redirect) is created with a nicer URL which then sends your browser to the `DownloadFile.cgi` URL above.
In our example the nice URL could look like:
`http://your-domain/downloads/MyRelease`

The forwarder is placed inside the normal web root directory. For each release a new directory is created. Inside
the directory a `index.html` is written which contains the forward to the long URL above.

If you want to understand this concept better just create a release and have a look inside the forwarder directory.
You will find the index.html file - open it and you will see the redirect to the actual CGI program.

**Rate Limiter**

_My Favorite Things_ has a built in rate limiter. Currently a page can only be accessed 30 times in a minute. If someone exceeds that limit she has to wait until the access rate is under 30 hits per minute again. This was included to prevent people trying to break in by simply trying out all possible variants of your admin password (brute force).

The rate limiter also applies to the user download page so finding a valid download code by simply trying out is prevented as well.