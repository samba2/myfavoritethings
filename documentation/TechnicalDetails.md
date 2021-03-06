# TechnicalDetails #

This page gives you some inside view of _My Favorite Things_. It helps you to understand the
(simple) architecture of the application and should be helpful if your planning to volunteer.

## Why Perl ##

At the time deciding to invest the next weeks to write _My Favorite Things_ I was actually looking
for a project to train my Java skills. However, a simple web hoster won't provide you with
a Java runtime and an application server. Hence, Java had been ruled out.

An average web hoster will quite certainly offer you a CGI interface so you should be
able to run simple CGI programs. For that reason I was looking for a language to write
a CGI application in an object oriented manner (to train OO-style programming).

Having talked to more professional friends of mine, Ruby (which was my first thought) is not
always present on (again) average, cheap web hosting sites. This cut my options down to
two languages: PHP and Perl. Both are more or less standard CGI languages. PHP as become
more popular in the Web area. However, I have a 10 years background of Perl coding and I was
not interested in learning an other (similar) scripting language just for this project. So
the winner was Perl.

## Framework ##

_My Favorite Things_ uses the CGI::Application framework to organize the application. If you are
planning to contribute see the CPAN documentation of CGI::Application. During the development I
did also use some of the many plugins of the framework:
  * Redirect
  * Session (very nice session management)
  * Rate Limit (restrict number of times a page can be accessed, prevents brute force attacks)

## Local Libraries ##

The application should run with just a core Perl installation. This means the Perl interpreter + the
defined core modules. I used this list: `http://perldoc.perl.org/index-modules-A.html`
If I needed a different functionality I searched CPAN for a simple, Perl only (without any C compiling)
module which would suit my needs. All those libraries where copied inside the `lib` folder of _My Favorite Things_.

## Model View Controller ##

As I previously said this programing is also an exercise for me. Some month ago a friend of mine was
talking about Model-View-Controller (MVC) web apps and I had no idea what he was talking about.
I went home, asked google and the result is that also _My Favorite Things_ is trying to follow this pattern.
For me this basically means:
  * seperate HTML code and program code
  * seperate database logic and program code
  * communication between the web parts and the database is always running via the controller

The CGI::Application framework more or less pushes you towards this MVC pattern. There is a template
mechanism which I also use. All HTML code is inside the `html` directory. The database access is
handled inside the `lib/MyFav/DB/` classes.

## Database ##

I like the flexibility of SQL so data storage is done via SQL statements. Since portability is important I could not assume a running MySql server. Sqlite would be perfect but is platform dependent
and requires compilation. I ended up using DBD::Anydata which stores the database tables in simple
comma seperated value (csv) files. Those files are located under `data`.

There are different types of database csv files:
  * config.csv - the general config data, contains all global configurations and the details about all releases
  * codes\_for\_xyz.csv - contains the download codes and their status for release ID _xyz_
  * temp.csv - temporary storage of data while adding a new release with Wizard.cgi
  * rateLimiter.csv - data storage for the rate limiter plugin

In terms of classes there is the main database class MyFav::DB::General.pm. It contains the common functionality
of database access. If somewhen in the future the underlying database might change, this class has to
be modified.
The classes MyFav::DB::ReleasesDB.pm, MyFav::DB::ConfigDB.pm ... provide the methods of accessing the
specific database data.

## Small Applications build a Big One ##

_My Favorite Things_ consists out of small Cgi::Application based CGI programs. Those small programs build
the actual _My Favorite Things_ application by HTML links inside the menu.
The following single application exists:
  * Releases.cgi - main admin screen, contains "Release Status", password change and deleting of a release.
  * Wizard.cgi - create new release, menu item "Add new release"
  * Login.cgi - If Releases.cgi or Wizard.cgi find out that there is no authenticated session, the browser is forwarded to this program. This let the admin enter the password and redirects back to the origin page.
  * DownloadFile.cgi - the CGI program the end user entering its code is forwarded to. If called with the correct parameters it provides the "Please enter your code" screen and the download file streaming.

## Code Style ##

The perl code you find in _My Favorite Things_ is hopefully far away from the famous perl onliners. While
developing I read the book "Clean Code" by Robert C. Martin. I tried to follow his guidelines by finding
self explaining names for the methods, let methods do only one thing (well, I found this quite hard) and
cluster methods of one type in an own package/ class file.
Compared to standard, quick perl you might find the code blown up - I like it though ;-)