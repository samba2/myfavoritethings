# User Guide #
This page will show you how to use _My Favorite Things_ . We will login, create a new release and eventually print out the download vouchers. For all this _My Favorite Things_ needs to be installed which is described under [Installation](Installation.md).

## Logging In ##
If you have finished the [Installation](Installation.md) just replace the `install.cgi` part of the installer web address with `Releases.cgi`

**You login to the admin menu via the address
`http://your-domain.name/cgi-bin/MyFavoriteThings/cgi/Releases.cgi`**

After entering the admin password you have chosen during install, you get presented the main admin screen. Lets add a new release (= download code project).

## Creating a new release ##
Generally creating a new release consists out of the following steps:
  * Entering release title and release code
  * Specify the amount of download codes needed
  * Define the public download web address of your release
  * Uploading the Zip file containing the download codes
Click on "Add New Release". From their on you will be guided by the software. There are additional explainations for each step, written in _italic_ at the buttom of each page.

## Printing PDF ##
If you have successfully created a new release, it is now possible to print out the download vouchers which _My Favorite Things_ sends to you as PDF file via your web browser. To do so, click on "Manage Releases", select the release you are interessted in and then click on "Export Download-Vouchers". Your browser should inform you that it is receiving a PDF file. Download that file and open it. It contains auto-formated two-collumn A4 pages with your download vouchers. See ScreenShots for an example.
Now you only have to print them out, cut the pages into single vouchers and add them to your records.

## Export CSV-File ##
If you want to design your own vouchers you can get a copy of the whole _My Favorite Things_ database of your selected release. This copy comes as comma seperated value (csv) file. Once you've downloaded that file you can try the serial letter function of MS Word/ Openoffice Writer to build your own.
If this is to complicated (it certainly can be) choose the ready made layout of "Export Download-Vouchers"

## Code Status/ Resetting Code Status ##
If a user had trouble downloading the zip file and its code has now expired it is possible to reset the code to "unused" to give the custumer a new chance.
Just open your release and click "Code Status". If the code is "used" _My Favorite Things_ offers you to reset it tu "unused".

## Deleting a release ##
If you open a release inside "Manage Releases" there is also a link to delete this release. This will remove ALL traces of this record inside _My Favorite Things_. There is no download possibility left afterwards! Please think twice before removing!