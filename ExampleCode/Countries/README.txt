This is a sample Max OS X Xcode 8.x project that builds a simple application that 
utilizes the ARJDatabase Framework.

There are a few things that this assumes about the deployment environment.

 1) You are using Xcode 8.0 or higher
 2) There is a running instance of MySQL that can be accessed via 
    TCP or Socket from your computer.
 3) You have created a database in that server using the provided data in
    sampleeDatabase.sql
 4) You have configured the eomodel to use YOUR database credentials
 5) The ARJDatabase frameworks EOControl and EOAccess have been compiled and 
    installed in /Library/Frameworks.
 6) The ARJDatabase Database Adaptor for MySQL has been compiled and installed in
    "/Library/Database Adaptors"


MySQL Preparations:

 Assuming the application would be connecting over socket to the localhost:
 Create a new database and give the name 'ajrtest'
 create a mysql user named dp with password rrs
 grant all privileges for this user to the ajrtest database
 Import the database sample into the MySQL database you just created

That should do it.

If you need different connection parameters the easiest thing to do is to 
simple edit the file 'index.eomodeld' which in inside the riemer.eomodeld wrapper.
This is a simple property list, and you would want to edit the 'connectionDictionary' 
property.

Here is an example of a TCP connection:

<key>connectionDictionary</key>
<dict>
  <key>databaseName</key>
  <string>ajrtest </string>
  <key>hostName</key>
  <string>mysql.riemer.com</string>
  <key>password</key>
  <string>rrs</string>
  <key>port</key>
  <string></string>
  <key>protocol</key>
  <string>TCP</string>
  <key>userName</key>
  <string>dp</string>
</dict>

and here is an example of a socket connection:

<key>connectionDictionary</key>
<dict>
  <key>databaseName</key>
  <string>ajrtest</string>
  <key>hostName</key>
  <string>localhost</string>
  <key>password</key>
  <string>rrs</string>
  <key>port</key>
  <string></string>
  <key>userName</key>
  <string>dp</string>
</dict>




