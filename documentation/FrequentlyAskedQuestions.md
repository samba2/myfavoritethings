**Is there any warranty if something goes wrong?**

I gave my best to write a stable software. However, _My Favorite Things_ comes with no warranty at all. The software is free, you can use it, you can alter it, you can check the code yourself. Please let me know if you have found a bug.

**Can I use _My Favorite Things_ for commercial purposes?**

Sure you can. You can also make your own version of the software **as long as this new software stays open source as well**. See the General GNU Public License Version 3 under which _My Favorite Things_ is being released for details.

**For how long is a download code valid after it expires?**

When a customer enters the download code this code stays active for _one hour_. After that time the code expires.

**How can I change the text of the download voucher?**

In a future release there will be a possibility directly inside _My Favorite Things_. In the mean time you can do the following step. Attention, this should be only done if your a experienced with copying and editing web server/ unix data
  * login to your webspace and change to the `MyFavoriteThings/data` directory
  * copy the file "config.csv" to your computer, if you are using FTP make sure you are using **Binary** mode. This is important otherwise config.csv is getting currupted
  * on your computer copy "config.csv" to "config\_backup.csv". This is just in case something goes wrong.
  * open config.csv with a editor which is capable of handling Unix files. I recommend GVIM
  * look for a line starting with _GLOBAL,labelHeader,_
  * behind the last comma you will find the text which is printed by default onto your vouchers, change the text to your needs but don't use any special characters and make sure that you close the line with a `"`
  * copy "config.csv back to the `MyFavoriteThings/data` directory, overwrite the old version
  * Now the vouchers should contain your specific text.

**Can I change the name of the MyFavoriteThings directory?**

Yes, you can but leave the structure underneath untouched.

**Can I replace the uploaded zip file later on?**

If you want to create a new project to already create your vouchers but you don't have the music available so far you can use a trick: Simply pack a fake zip file with some content. It is important that this zip file has already the correct name. Than create your new project and upload the fake zip file.
Once you've got the music available pack a new zip file containing the music and name it exactly like the fake zip file. Connect then to your web server and look inside the "My Favorite Things" directory. There should be a subdirectory called "upload\_files" which contains your previously uploaded fake zip file. Now simple overwrite this file with your new zip file.

**Can I contribute?**

Oh yes, please do. At the moment it is only me developing the software, trying some (not very nice) web layout and maintain this project page. What I am looking for are possibly those roles:
  * Perl Developer
  * CSS Style Sheet designer

However, if you feel you want to contribute (also in different areas) just get in contact with me: maiktoepfer@googlemail.com

**I am missing a feature, what can I do?**

Please have a look if it is already on the FutureWork page. If not just drop me a line.

**Aren't you destroying someone else's business by giving away the software for free?**

No, I don't think so. _My Favorite Things_ was developed having small DIY labels in mind which invest a lot of their free time providing music lovers like me with fantastic undiscovered material.
Looking at my record collection over the past years I have bought a lot of music by these small labels myself. This is my kind of appreciation of their work.
But I admit there is also a very practical reason for spending 3 month free time for the first release of _My Favorite Things_: It still p...es me off buying records without download option having to do all the Audacity recording/ MP3 conversion my self. I hope _My Favorite Things_ will change this a little bit.

**Why is it called _My Favorite Things_?**

Well there are two reasons. Being a passionate vinyl lover my records are my (almost) favorite things. Secondly, when I was writing the very first version of the program (well, this was actually a different single script program serving the same purpose) I was listening to "My Favorite Things" by John Coltrane.

**So your a music lover as well, what kind of?**

Well, over the years the genres a getting more. Not sure if this is a good sign or not ;-)   The first love is indie pop, the classic or currently maybe the swedish way. No "big balls" heavy rock'n'roll but gently bubbling pop anthems. Good bands of the genre: The Field Mice (gone), The Acid House Kings (still there), The Pains of Being Pure At Heart (also new).

Second big interest is old soul music. Preferably mid/ late 60ies and early 70ies.  Northern soul, rare soul, soul nighters and soul weekenders - this is all important here. Like this English documentary once said "For 2 minutes 30 the whole world is magic." There is nothing to add.

And there is "everything else" which is: Listening Electronic, Jazz, Classical Music, Americana, Singer/ Songwriter and like I said - it is getting more and more...
