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

@class EOAdaptorContext, EOAttribute, EOConnectionPane, EOEntity, EOLoginPanel, EOModel, EOSchemaGeneration, EOSQLFormatter;

typedef enum _eoAdaptorValueType {
	EOAdaptorNumberType,
	EOAdaptorCharactersType,
	EOAdaptorBytesType,
	EOAdaptorDateType,
} EOAdaptorValueType;

@interface EOAdaptor : NSObject
{
	NSString				*name;
    NSDictionary		*connectionDictionary;
	NSMutableArray		*adaptorContexts;
	id						delegate;
	
	BOOL					delegateRespondsToFetchedValue:1;
}

// Creating an EOAdaptor
+ (id)adaptorWithName:(NSString *)aName;
+ (id)adaptorWithModel:(EOModel *)aModel;
- (id)initWithName:(NSString *)aName;

// Accessing an adaptor's name
- (NSString *)name;

// Accessing the names of all available adaptors
+ (NSArray *)availableAdaptorNames;

// Accessing connection information
- (void)assertConnectionDictionaryIsValid;
- (NSDictionary *)connectionDictionary;
- (void)setConnectionDictionary:(NSDictionary *)aDictionary;
- (NSStringEncoding)databaseEncoding;

// Accessing an adaptor's login panel
+ (EOLoginPanel *)sharedLoginPanelInstance;
- (BOOL)runLoginPanelAndValidateConnectionDictionary;
- (NSDictionary *)runLoginPanel;

// Connection interface
+ (Class)connectionPaneClass;
+ (EOConnectionPane *)sharedConnectionPane;

// Performing database-specific transformations on values
/*! @todo EOAdaptor: need to call into the fetchValue... methods. */
- (id)fetchedValueForValue:(id)value attribute:(EOAttribute *)attribute;
- (NSData *)fetchedValueForDataValue:(NSData *)value attribute:(EOAttribute *)attribute;
- (NSCalendarDate *)fetchedValueForDateValue:(NSCalendarDate *)value attribute:(EOAttribute *)attribute;
- (NSNumber *)fetchedValueForNumberValue:(NSNumber *)value attribute:(EOAttribute *)attribute;
- (NSString *)fetchedValueForStringValue:(NSString *)string attribute:(EOAttribute *)attribute;

// Servicing models
/*! @todo EOAdaptor: implement the various database introspection methods on subclasses */
- (BOOL)canServiceModel:(EOModel *)model;
+ (NSString *)internalTypeForExternalType:(NSString *)type model:(EOModel *)model;
+ (NSArray *)externalTypesWithModel:(EOModel *)model;
+ (void)assignExternalInfoForEntireModel:(EOModel *)model;
+ (void)assignExternalInfoForEntity:(EOEntity *)entity;
+ (void)assignExternalInfoForAttribute:(EOAttribute *)attribute;
- (BOOL)isValidQualifierTypeIn:(NSString *)type model:(EOModel *)model;

// Creating adaptor contexts
- (EOAdaptorContext *)createAdaptorContext;
- (NSArray *)contexts;

// Checking connection status
- (BOOL)hasOpenChannels;

// Accessing a default expression class
+ (void)setExpressionClassName:(NSString *)expressionName adaptorClassName:(NSString *)adaptorName;
- (Class)expressionClass;
- (Class)defaultExpressionClass;

// Accessing the delegate
- (id)delegate;
- (void)setDelegate:(id)aDelegate;
	
// Other
- (void)createDatabaseWithAdministrativeConnectionDictionary:(NSDictionary *)connectionDictionary;
- (void)dropDatabaseWithAdministrativeConnectionDictionary:(NSDictionary *)connectionDictionary;
- (NSArray *)prototypeAttributes;
- (EOSchemaGeneration *)synchronizationFactory;

@end


@interface NSObject (EOAdaptorDelegate)

- (id)adaptor:(EOAdaptor *)adaptor fetchedValueForValue:(id)value attribute:(EOAttribute *)attribute;

@end
