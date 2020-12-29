//
//  OracleAdaptor.h
//  ociTest
//
//  Created by Tom Martin on 4/11/10.
/*  Copyright (C) 2011 Riemer Reporting Service, Inc.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Tom Martin
24600 Detroit Road
Westlake, OH 44145
mailto:tom.martin@riemer.com
*/


// =================================
//    WHERE TO INSTALL ADAPTORS
//=================================
// It is not that obvious where to install an adaptor.
// The superclass will load adptors installed in:
//   <NSAllLibrariesDirectory>/Database Adaptors/
// which works out to being:
//     <current bundle>/Database Adaptors  
//     ~/Library/Database Adaptors
//     ~/Developer/Database Adaptors
//     /Library/Database Adaptors
//     /Developer/Database Adaptors
//     /Network/Library/Database Adaptors
//     /Network/Developer/Database Adaptors
//     /System/Library/Database Adaptors
//     /Developer/Database Adaptors
// My personal preference is to install them into /Library/Database Adaptors
//
//
// Oracle may use the TNS names mechanism to attach to a server.
// if the connection dictionary is of the type serverId, UserId, Password, then
// this is the method for connection.   The OCI Library MUST have an environment
// variable set for this to work.  This framework will override this behavior in
// in the following manner:
//
// The following will be checked in the following order
// 1) Check to see if a default is set for TNS_ADMIN
//     The user defaults key is com.ajr.OracleAdaptor.TNS_ADMIN
//     the value would be the directory in which to find tnsnames.ora
// 2) Check to see if the environment var TNS_ADMIN is already set,
//     If so, the value would be the directory in which to find
//     tnsnames.ora  This is the normal behavior of OCI
// 3) Check to see if the environment variable ORACLE_HOME is already
//     set.  If so, the value would be the directory for ORACLE_HOME
//     and the location for tnsnames.ora is assumed to be
//     ORACLE_HOME/network/admin/.  This is the normal behavior of
//     OCI.
// 4) If all of the above fail then the fall back is to look for
//    tnsnames.ora in /Library/Oracle/network/admin which is the
//    location that was used for the Apple distribution of EOF.
//
//====================================================
// 
//  This object represents a database definition, a connection dictionary. 
//  It can have any number of sessions.  Each session is an independent
//  connection to the database that uses the connection information defined
//  here.
//
//=============
// Connection Dictiornay
// These keys define the standard connection information for an Oracle logon.
//
// If there is no value for the HostMachineKey then the a connection string
// of the form "userName/password@serverId" is generated.
//
// If all the values except the one for serverId are absent, then the
// connection string will just be the value for serverId.
//
// KNOWN BUGS
// 1) describeResults does not detect the national chanracter types of NCHAR, NVARCHAR and NCLOB
// and will return CHAR VARCHAR and CLOB respecitively.
// 2) Unicode will NOT work correctly with the National character types unless the external type 
//    named in the corrasponding attribute is correct.  You will get undefined results if you use 
//    nataional character columns with the database character set external types.  This is true 
//    even if the characters are within the ASCII set.  It may work, it may not.

#define ServerIdKey @"serverId"
#define UserNameKey @"userName"
#define PasswordKey @"password"

#define ConnectionStringKey @"connectionString"
// If this key is present in the connection dictionary, then servierId is
// ignored and this string is passed for the server connection string.
// serverId is the TNS service name, or perhaps the TNS Global name, either one.
// connection string allows you to bypass TNS alltogether if you wish.
// There are three possible formats for the string.  One of which is not
// currently supported by this adaptor.
//  URL:  A SQL Conect string in the form of:
//   [//]host[:port][/service name]
//   for example  //databaseHost.company.com:1521/bjava1
//   mind you service name here is the TNS service name
// Oracle Net Descriptor:
//   for example:
//      (description=(address=(protocol=tcp)(host=databaseHost.company.com)(port=1521))(connect_data=(sid=bj1)))
//   Note that the OracleNet syntax robust and includes many possible ways to connect.  The
//   above is only one example.
// LDAP connection Name:
//   A connection name can be supplied that is resolved via LDAP.  Sorry.  Even though
//   OCI supports this, this adaptor does not.  Maybe someday.

// After the server attachment is complete the channel is opened using the
//   user name and password supplied.

// PLEASE NOTE:  this is a departure from the previous connection dictionary in
//               regards to the connectionString.  Also Host key was dropped as
//               that was not every actually used even in the older version of
//               this adaptor.  serverId, userName and password functionality 
//               remain unchanged and for most connection dictionaries 
//               created for previosu versions, this adaptor should work fine.

// If this key is present, it will be used as the setting to NLS_LANG
// used to specify the language and character set for server connections.
// On J systems this option defaults to japanese_japan.jeuc
#define NlsLangKey @"NLS_LANG"

// Exceptions that are raised due to Oracle OCI client library errors will
// have a userInfo dictionary with the error code.  The single key is the 
// OracleErrorKey defined below, and the object is an NSNumber with the error
// code as a positive intValue.
#define OracleErrorKey @"OracleError"

@class OracleContext;

#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>
#import <oci.h>

#define	SIMPLE_BUFFER_SIZE	259

typedef union _ociBufferValue {
	unsigned int	intValue;
	double			doubleValue;
	float			floatValue;
	unsigned char	*charPtr;       // for malloced buffer
	unsigned char	simplePtr[SIMPLE_BUFFER_SIZE];  // this can be used for DATE and for NUMBER String (1e-128 - 1e126)
} ociBufferValue;

@interface OracleAdaptor: EOAdaptor
{
	OCIEnv			*envhp;
	ub4				ociMode;
	sword			status;
}

// OCI Specific things
+ (ub4)ociMode;
+ (void)setOciMode:(ub4)value;
+ (NSDictionary *)dataTypes;

+ (id)convert:(id)value toValueClassNamed:(NSString *)aClassName;
// convert an object from one base type to another.  Does ONLY NSString, NSNumber, NSDecimalNumber,
// NSCalendarDate/NSDate, and NSData.  This is intended to convert internal adaptor objects to the 
// target value class (not custom classes) and also to convert values to be written into the database.
//  

+ (ub2)dataTypeForAttribute:(EOAttribute *)attrib useWidth:(BOOL *)useWidth nationalCharSet:(BOOL *)useNationalCharSet;
// return the internal OCI data type storage to use for an attribute based upon the external Oracle type
// useWith signifies that the width of the attribute should be used to determine buffer size.
// useNactionCharSet means that the data type is NCHAR, NVARCHAR or NCLOB and the national character set should be used.
- (NSString *)checkErr:(sword)aStatus inHandle:(OCIError *)anErrhp;
- (OCIEnv  *)envhp;

@end

@interface NSString (OracleAdaptor)

+ (int)unicodeLen:(unichar *)ptr;
// buffer 'ptr' is Oracle buffer and is assumed to be UTF16 big endian null terminated string.  This method
// returns the CHARACTER length of the string.

+ (NSString *)stringFromOCIText:(text *)value;
// buffer 'value' is Oracle buffer and is assumed to be UTF16 big endian, The first 4 bytes is the length (ub4) in BYTES

+ (NSString *)stringFromOCIText:(text *)value length:(ub4)len;
// buffer 'value' is Oracle buffer and is assumed to be UTF16 big endian, length is CHARACTERS not bytes.

+ (NSString *)stringFromVarLenOCIText:(text *)value;
// buffer 'value' is Oracle buffer and is assumed to be UTF16 big endian, The first 4 bytes is the length (ub4) in BYTES

- (unsigned int)ociTextZLength;
// returns the length of the OCI text buffer INCLUDING a null terminator

- (unsigned int)ociTextLength;
// returns the length of the OCI text buffer WITHOUT a null terminator

- (text *)ociText;
// This converts a NSString into a Oracle buffer of UTF16 big endian WITH a NULL TERMINATOR added.
// the buffer is autoreleased memory, so if you need it, then you need to copy it.

- (void)getOCIText:(text *)buffer;
// This converts a NSString into a Oracle buffer of UTF16 big endian WITH a NULL TERMINATOR added.
// YOU supply the buffer and are responsible for its deallocation.

@end
