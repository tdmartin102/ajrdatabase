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

#import <EOControl/EOQualifier.h>
#import <EOControl/EOSortOrdering.h>

// Keys for use in the bindVariableDictionary
extern NSString *EOBindVariableNameKey;
extern NSString *EOBindVariableAttributeKey;
extern NSString *EOBindVariableValueKey;
extern NSString *EOBindVariablePlaceHolderKey;
extern NSString *EOBindVariableColumnKey;       

@class EOEntity, EOAttribute, EOFetchSpecification, EOQualifier, EOStoredProcedure;

@interface EOSQLExpression : NSObject
{
	EOEntity      			*rootEntity;
	NSMutableDictionary		*aliases;
	NSMutableDictionary		*aliasesByRelationshipPath;
	NSMutableString			*statement;
	NSMutableString			*whereClause;
	NSMutableString			*tableClause;
	NSMutableString			*sortOrderingClause;
	NSMutableArray			*bindings;
	NSMutableString			*listString;
	NSMutableString			*valueListString;
	NSMutableString			*joinString;
	NSMutableString			*orderByString;

   BOOL						usesAliases:1;
   BOOL						usesDistinct:1;
}

- (id)initWithRootEntity:(EOEntity *)aRootEntity;
// Added for API adherence
- (id)initWithEntity:(EOEntity *)anEntity;

- (EOEntity *)rootEntity;
// Added for API adherence
- (EOEntity *)entity;

//- (void)addEntity:(EOEntity *)entity;

// Tom.Martin @ Riemer.com 2011-05-12
// Added methods as per API
+ (EOSQLExpression *)expressionForString:(NSString *)string;

//======== Select methods ============
+ (EOSQLExpression *)selectStatementForAttributes:(NSArray *)attributes lock:(BOOL)yn
    fetchSpecification:(EOFetchSpecification *)fetchSpecification
    entity:(EOEntity *)entity;
- (NSString *)assembleSelectStatementWithAttributes:(NSArray *)attributes 
	lock:(BOOL)lock 
	qualifier:(EOQualifier *)qualifier
	fetchOrder:(NSArray *)fetchOrder 
	selectString:(NSString *)selectString 
	columnList:(NSString *)columnList 
	tableList:(NSString *)aTableList 
	whereClause:(NSString *)aWhereClause 
	joinClause:(NSString *)aJoinClause 
	orderByClause:(NSString *)aOrderByClause 
	lockClause:(NSString *)aLockClause;
// mont_rothstein @ yahoo.com 2005-06-23
// Added lock parameter to method as per API
- (void)prepareSelectExpressionWithAttributes:(NSArray *)attributes
										 lock:(BOOL)lock
						   fetchSpecification:(EOFetchSpecification *)fetch;
- (void)addSelectListAttribute:(EOAttribute *)attribute;

// ============= Update Methods
+ (EOSQLExpression *)updateStatementForRow:(NSDictionary *)row qualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity;
- (NSString *)assembleUpdateStatementWithRow:(NSDictionary *)row 
	qualifier:(EOQualifier *)qualifier 
	tableList:(NSString *)aTableList 
	updateList:(NSString *)updateList
	whereClause:(NSString *)aWhereClause;
- (void)prepareUpdateExpressionWithRow:(NSDictionary *)row qualifier:(EOQualifier *)qualifier;
- (void)addUpdatetListAttribute:(EOAttribute *)attribute value:(NSString *)value;

//============== Insert Methods
+ (EOSQLExpression *)insertStatementForRow:(NSDictionary *)row entity:(EOEntity *)entity;
- (NSString *)assembleInsertStatementWithRow:(NSDictionary *)row 
	tableList:(NSString *)tableList 
	columnList:(NSString *)columnList 
	valueList:(NSString *)valueList;
- (void)prepareInsertExpressionWithRow:(NSDictionary *)row;
- (void)addInsertListAttribute:(EOAttribute *)attribute value:(NSString *)value;

//============== Delete Methods
+ (EOSQLExpression *)deleteStatementWithQualifier:(EOQualifier *)qualifier entity:entity;
- (NSString *)assembleDeleteStatementWithQualifier:(EOQualifier *)qualifier 
	tableList:(NSString *)aTableList 
	whereClause:(NSString *)aWhereClause;
- (void)prepareDeleteExpressionForQualifier:(EOQualifier *)qualifier;

//============== Stored Procedure Methods
- (void)prepareStoredProcedure:(EOStoredProcedure *)procedure withValues:(NSDictionary *)values;

//============= Statement methods
- (id)initWithStatement:(NSString *)statement;
- (void)setStatement:(NSString *)aStatement;
- (NSString *)statement;

// NON api method that also returns the attribute.
- (NSString *)sqlStringForAttributeNamed:(NSString *)name attribute:(EOAttribute **)attrib;

//- (NSString *)sqlStringForAttributeNamed:(NSString *)attributeName inEntity:(EOEntity *)entity;


//========== Strings used to assemble statements
- (NSString *)whereClauseString;
- (NSString *)tableClause; // NON API
- (NSString *)tableListWithRootEntity:(EOEntity *)entity;
- (NSString *)sortOrderingClause; // NON API
// mont_rothstein @ yahoo.com 2005-06-23
// Added lockClause method for use in locking
- (NSString *)lockClause;
- (NSMutableString *)joinClauseString;
- (NSMutableString *)listString;
- (NSMutableString *)orderByString;
- (NSMutableString *)valueList;

- (void)setUseAliases:(BOOL)flag;
- (BOOL)usesAliaes;

//========== Building SQL for attributes
- (void)appendItem:(NSString *)itemString toListString:(NSMutableString *)listString;
+ (NSString *)formatSQLString:(NSString *)sqlString format:(NSString *)format;
- (NSMutableDictionary *)aliasesByRelationshipPath;
- (NSString *)sqlStringForAttributePath:(NSArray *)path;
- (NSString *)sqlStringForAttribute:(EOAttribute *)attribute;
- (NSString *)sqlStringForAttributeNamed:(NSString *)name;

//========== Builing SQL for table names  NON API
- (NSString *)sqlStringForTableNameForEntity:(EOEntity *)anEntity;

//========== Building the Join
- (void)joinExpression;

//========== Building sort Order
- (void)addOrderByAttributeOrdering:(EOSortOrdering *)sortOrdering;

// 2006-10-14 AJR
// These methods are semi-private. You should never need to call these methods directly,
// they're here as they're used by the qualifiers to build SQL and over ridden by 
// the SQL Expression for adaptor specific behavior.
- (NSString *)sqlPrefixForQualifierOperation:(EOQualifierOperation)op value:(id)value;
- (NSString *)sqlStringForQualifierOperation:(EOQualifierOperation)op value:(id)value;
- (NSString *)sqlSuffixForQualifierOperation:(EOQualifierOperation)op value:(id)value;

- (NSString *)substringSearchOperator;
- (NSString *)characterSearchOperator;
- (NSString *)likeEscapeClause;

- (NSString *)sqlStringForValue:(id)value withQualifierOperation:(EOQualifierOperation)operation inAttribute:(EOAttribute *)attribute;


//======== Working with values
+ (NSString *)sqlPatternFromShellPattern:(NSString *)pattern;
// Non API but if you have the attribute, this saves resoving the attribute from the name/path
- (NSString *)sqlStringForValue:(id)value attribute:(EOAttribute *)attrib;
- (NSString *)sqlStringForValue:(id)value attributeNamed:(NSString *)name;
- (NSString *)formatValue:(id)value forAttribute:(EOAttribute *)attribute;

// Tom.Martin @ Riemer.com 2011-05-12
// Added use bind variable methods as per API
// These methods are useful for adaptor writers that want or need to use bind variables
// with their client library. If there is no need for an adaptor to use bind variable
// then no action need be taken on the part of the adaptor writer. If bind variables
// are needed the following 3 methods must be implemented in the subclass.

- (NSMutableDictionary *)bindVariableDictionaryForAttribute:(EOAttribute *)attribute value:value;
    // Returns a dictionary to be stored in the EOSQLExpression that contains
    // whatever adaptor specific information is necessary to bind the values.
    // This following keys must have values in the binding dictionary because their
    // values are used by the superclasss: EOBindVariableNameKey, EOBindVariableValueKey,
    // EOBindVariablePlaceHolderKey, and EOBindVariableAttributeKey.

- (BOOL)shouldUseBindVariableForAttribute:(EOAttribute *)att;
    // Returns YES if the the adaptor provides bind variable capability for attributes
    // of this type, no otherwise. Bind variables won't be used for values associated
    // with this attribute when -useBindVariable returns NO. This method should return
    // YES for any attribute that must use bind variables also.

- (BOOL)mustUseBindVariableForAttribute:(EOAttribute *)att;
    // Returns YES if the the adaptor must use bind variable capability for attributes
    // of this type, no otherwise. Overrides useBindVariables.

+ (BOOL)useBindVariables;
    // Returns YES if the application is currently using bind variables, NO otherwise.
    // This can be set to YES or NO with the user default named 'EOAdaptorUseBindVariables'
    // in the NSGlobalDomain.

+ (void)setUseBindVariables:(BOOL)yn;
    // Applications can override the user default by invoking this method.

- (NSArray *)bindVariableDictionaries;
    // Returns the current array of binding variable dictionaries.

- (void)addBindVariableDictionary:(NSMutableDictionary *)binding;
    // Add a new BindVariableDictionary to the list maintained by the SQL expression.    
@end
