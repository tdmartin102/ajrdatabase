/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

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

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import <Foundation/Foundation.h>

#import <EOAccess/EOAdaptor.h>
#import <EOAccess/EOPropertyListEncoding.h>

@class EOAdaptor, EOEntity, EOStoredProcedure;

typedef enum _eoFactoryMethodArgumentType {
	EOFactoryMethodArgumentIsNSData,
	EOFactoryMethodArgumentIsNSString,
	EOFactoryMethodArgumentIsBytes
} EOFactoryMethodArgumentType;

typedef enum _eoParameterDirection {
	EOVoid				= 0,
	EOInParameter		= 1,
	EOOutParameter		= 2,
	EOInOutParameter	= 3
} EOParameterDirection;

extern NSString *EOAttributeDidChangeNameNotification;

@interface EOAttribute : NSObject <EOPropertyListEncoding>
{
   id										parent;

   NSString								*name;
   NSString								*columnName;
   NSString								*externalType;
   NSString								*valueClassName;
   Class									valueClass;
   NSString								*valueType;
	NSTimeZone							*serverTimeZone;
	NSString								*definition;
	NSString								*valueFactoryMethodName;
	SEL									valueFactoryMethod;
	NSString								*adaptorValueConversionMethodName;
	SEL									adaptorValueConversionMethod;
	EOFactoryMethodArgumentType	factoryMethodArgumentType;
   int									scale;
   int									width;
   int									precision;
	NSString							*readFormat;
	NSString								*writeFormat;
	NSMutableDictionary				*userInfo;
	EOParameterDirection				parameterDirection;
   BOOL									allowsNull:1;
   BOOL									isClassProperty:1;
   BOOL									isPrimaryKey:1;
	BOOL									readOnly:1;
	BOOL								flattened:1;
	
}

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;

- (void)awakeWithPropertyList:(NSDictionary *)properties;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

// Accessing the entity
- (id)parent;
- (EOEntity *)entity;

// Accessing the name
- (void)setName:(NSString *)name;
- (NSString *)name;
- (NSException *)validateName:(NSString *)name;
/*! @todo EOAttribute: beautify name */
- (void)beautifyName;

// Accessing date information
- (NSTimeZone *)serverTimeZone;
- (void)setServerTimeZone:(NSTimeZone *)aTimeZone;

// Accessing external definitions
- (void)setColumnName:(NSString *)columnName;
- (NSString *)columnName;
/*! @todo EOAttribute: derived types */
- (void)setDefinition:(NSString *)definition;
- (NSString *)definition;
- (void)setExternalType:(NSString *)aType;
- (NSString *)externalType;

// Accessing value type information
- (void)setValueClassName:(NSString *)className;
- (NSString *)valueClassName;
- (void)setValueType:(NSString *)aType;
- (NSString *)valueType;
- (void)setAllowsNull:(BOOL)flag;
- (BOOL)allowsNull;
- (void)setPrecision:(int)aPrecision;
- (int)precision;
- (void)setScale:(int)aScale;
- (int)scale;
- (void)setWidth:(int)aWidth;
- (int)width;
/*! EOAttribute: validate value */
- (NSException *)validateValue:(id *)value;

// Converting to adaptor value types
// NON API ... convert an object into a SQL value suitablel for insertion.  value MUST be a standard value. 
// ie call adaptorValueByConvertingAttributeValue first. this method is called by EOSQLExpresion
// formatValue:forAttribute:.  This is handy here when an expression might not be available.
// this method calls the appropriate EOSQLFormatter given the adaptor and the data type.
- (NSString *)adaptorSqlStringForStandardValue:(id)value;
- (id)adaptorValueByConvertingAttributeValue:(id)value;
- (EOAdaptorValueType)adaptorValueType;

// Working with custom value types
/*! @todo EOAttribute: Custom data types */
- (void)setValueFactoryMethodName:(NSString *)aMethodName;
- (SEL)valueFactoryMethod;
- (NSString *)valueFactoryMethodName;
- (void)setFactoryMethodArgumentType:(EOFactoryMethodArgumentType)string;
- (EOFactoryMethodArgumentType)factoryMethodArgumentType;
- (void)setAdaptorValueConversionMethodName:(NSString *)aMethodName;
- (SEL)adaptorValueConversionMethod;
- (NSString *)adaptorValueConversionMethodName;

// Accessing attribute characteristics
- (void)setReadOnly:(BOOL)flag;
- (BOOL)isReadOnly;
- (BOOL)isDerived;
/*! @todo EOAttribute: flattened attributes 
    Tom Martin: 5/27/11 done */
- (BOOL)isFlattened;

// Accessing SQL statement formats
/*! @todo EOAttribute: read/write formats */
- (void)setReadFormat:(NSString *)aFormat;
- (NSString *)readFormat;
- (void)setWriteFormat:(NSString *)aFormat;
- (NSString *)writeFormat;

// Accessing the user dictionary
- (void)setUserInfo:(NSDictionary *)someInfo;
- (NSDictionary *)userInfo;

- (id)newValueForBytes:(const void *)bytes length:(int)length;
- (id)newValueForBytes:(const void *)bytes length:(int)length encoding:(NSStringEncoding)encoding;

// Working with stored procedures
- (void)setParameterDirection:(EOParameterDirection)aDirection;
- (EOParameterDirection)parameterDirection;
- (EOStoredProcedure *)storedProcedure;

/*! @todo EOAttribute: prototypes */

@end
