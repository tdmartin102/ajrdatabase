ajrdatabase - Introduction
=====================
JAEOF: "Just Another EOF"

[Latest info](http://wiki.github.com/tdmartin102/ajrdatabase/)

> Feel free to help out!  There's a long way to go...

This code is a fork of ajrdatabase written primarily by Alex J. Raftis  
and published on SourceForge.  The project there seems to be dead with no response
from the current admin.  Perhaps new life can be breathed into this
project over here on github.  An OpenSource implementation of Apple's 
Objective-C Enterprise Objects framework, arjdatabase is intended to 
be a plug-and-play replacement for Apple's EOF implementation.  A strong
attempt was made to make these frameworks adhere to the published EOF 4.5
API. 

Currently there are database adaptors for OpenBase, Oracle, Postgres and
SQLLite.


Status
------
* Much of the low level EOSQLExpression code has been re-worked
  and very likely may have broken the existing adaptors for
  Postgress, OpenBase and SQLLite.  These need to be tested
  to assure they still work.
* An Oracle adaptor was added and it is fully tested and working.
* Attribute binding is now working. 
* Changed joins to use newer Join syntax of 
  "(Join semantic) table on atrrib1 = attrib2".  This enables better 
  database engine optimization and eliminates the need for complex 
  code to place join clauses based upon qualifier semantics.
* EOInterface compiles, but I have no idea what it's status
  is.
* The EOModeler application code needs work, which is a 
  shame as apparently a ton of work went into it.  As of Jan 17th 2011
  it compiles and runs.  It is pre alpha at this point, but there is
  quite a bit that is working. I would
  love to get this working 100% again as anyone that wants to use
  this will need some sort of working EOModeler application.
  That said, the frameworks will work with any legacy EOModel
  file and most likely work with versions that are more current than
  4.5. 
* Some optimization has been done here and there, but a lot more
  could be done.  Because of the high level of abstraction that
  is going on, there are many issues with inefficiencies .  These
  could be overcome somewhat by the use of caching and various 
  other techniques.
* To-many relationships now are snapshoted as they are supposed to
  be.  Removing an object from a to-many EO relationship will
  result in that objects foriegn key being nulled or the object
  deleted as it should. Adding an object in a to-many does what
  it should even when there is no reverse relationships and all
  foreign key attributes are hidden.
* As of 8/8/2012 This framework has been in beta testing for
  3 or 4 weeks and at least for the simple case of using only
  a single editing context, it is working well with bug fixes
  as we go.  This is using the Oracle adaptor.


Why?
----

Because, for me at least, I have over 100 very database intensive 
applications that are stuck in Tiger because they rely upon Apple 
EOF 4.5.  Wouldn't it be great, if I could plug in a new framework
that replaces EOF and they just need minor tweaks to get them working
on the current Apple OS?  Further, EOF is rather amazing in many ways
and I know of nothing available that even comes close to the 
functionality that it provides. I realize there probably are very
few people like me that need an EOF replacement, but EOF is extremely
powerful and offers a high level of abstraction that makes creating
applications that need to work with databases a snap.


Background
==========
In 2000, WebObjects and EOF were state-of-the-art tools
for building advanced web applications.  Apple was in
a state of flux, and had signed a pact with the devil
to port WO/EOF to Java, and EOL the obj-c (& webscript)
version of these great tools. For all of us that built
enterprise software based upon the Objective-C version of
EOF/WebObjects we had to port to Java or look for some other
solution.   Alex J. Raftis created the ajrdatabaes Open
Source project around 2004 sometime and had many contributors
to the project.  I am uncertain how many people actually
used the frameworks, but my impression is that it was used
in production applications to some extent even though it was
never truly christened as being anything but beta.  It has
gathered some dust as of late on SourceForge and the amin
there seems to be absent.  In September of 2011 I forked the
SourceForge project so that I could contribute. This is
a fork of that original project, but in no way does this
represent a departure from the goal of the original project.
This is meant to continue that project, just to do so in a 
new environment under active administration.


DISCLAIMER
==========
There are many, many things that are only
partially implemented, or not implemented at all.  There are
API elements that do not conform to the published API.  The
functionality of EOF is huge and much of this code has not been
fully tested.  My intent is to get this framework to a point where
it can be used in a production environment.  It is not ready
for that at this point.  
                      
HELP
====
Any/all help would be greatly appreciated; If anyone out there 
is brave enough to give it a try, I'd be happy to help out.
I would love constructive criticism and welcome any help that
anyone would want to throw my way!  It needs a lot of work; clean-up,
optimization, I would love to see a MySQL adaptor, etc. etc.


-tm May 2012
