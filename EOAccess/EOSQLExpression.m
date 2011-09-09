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

#import "EOSQLExpression.h"

#import "EOAttribute.h"
#import "EODatabase.h"
#import "EODebug.h"
#import "EOEntity.h"
#import "EOEntityP.h"
#import "EOJoin.h"
#import "EOModelGroup.h"
#import "EOQualifier-EOAccess.h"
#import "EORelationship.h"

#import <EOControl/EOControl.h>

NSString *EOBindVariableNameKey = @"BindVariableName";
NSString *EOBindVariableAttributeKey = @"BindVariableAttribute";
NSString *EOBindVariableValueKey = @"BindVariableValue";
NSString *EOBindVariablePlaceHolderKey = @"BindVariablePlaceHolder";
NSString *EOBindVariableColumnKey = @"BindVariableColumn";

static BOOL _useBindVariables = NO;
static NSCharacterSet	*literalStartSet;
static NSCharacterSet	*literalSet;

@interface EOFetchSpecification (EOPrivate)

- (void)_setRootEntityName:(NSString *)rootEntityName;
- (NSString *)_rootEntityName;

@end

@implementation EOSQLExpression

//=======================================================================================================
//    Private Methods
//========================================================================================================
//---(Private)--- get the entity for a relationship path
- (EOEntity *)_entityForRelationshipPath:(NSString *)path rootEntity:(EOEntity *)anEntity
{
	NSArray			*attribPath;
			
	attribPath = [anEntity _attributesForKeyPath:path];
	return [(EORelationship *)[attribPath lastObject] destinationEntity];
}

//---(Private)--- clear out all the data ---------
- (void)_clearLists
{
	[statement release];
	[whereClause release];
	[tableClause release];
	[sortOrderingClause release];
	[bindings release];
	[listString release];
	[valueListString release];
	[joinString release];
	[orderByString release];
	
	[aliases release];
	[aliasesByRelationshipPath release];
	aliases = nil;
	aliasesByRelationshipPath = nil;

	statement = nil;
	whereClause = nil;
	tableClause = nil;
	sortOrderingClause = nil;
	bindings = nil;
	listString = nil;
	valueListString = nil;
	joinString = nil;
	orderByString = nil;
}

//---(Private)-- Prepare aliases storage for use.---------
- (void)_initAliases
{
	aliases = [[NSMutableDictionary allocWithZone:[self zone]] init];
	[aliases setObject:@"t0" forKey:[rootEntity name]];
	aliasesByRelationshipPath = [[NSMutableDictionary allocWithZone:[self zone]] initWithCapacity:10];
	[aliasesByRelationshipPath setObject:@"t0" forKey:@""];
}

//--(Private)-- Deal with converting a derived attribute to SQL
- (NSString *)_sqlStringForDerivedAttribute:(EOAttribute *)attribute
{
	NSString		*candidate;
	NSString		*attribSQL;
	NSMutableString	*sqlString;
	NSScanner		*scanner;
	
	// to identify an attribute name we will look for alpha characters
	// I think an attribute would begin with a character, contain letters
	// numbers, underscores AND periods.  Probably scanner is the best way
	// extract this type of thing.
	// any candidate string would be sent to sqlStringForAttributeNamed:
	// if we GET somthing then we replace it.	
	sqlString = [[attribute definition] mutableCopyWithZone:[self zone]];
	scanner = [[NSScanner allocWithZone:[self zone]] initWithString:[attribute definition]];
	while (! [scanner isAtEnd])
	{
		[scanner scanUpToCharactersFromSet:literalStartSet intoString:NULL];
		if (! [scanner isAtEnd])
		{
			[scanner scanCharactersFromSet:literalSet intoString:&candidate];
			attribSQL = [self sqlStringForAttributeNamed:candidate];
			if (attribSQL)
			{
				// replace the candidate with the SQL
				[sqlString replaceOccurrencesOfString:candidate withString:attribSQL 
					options:NSLiteralSearch range:NSMakeRange(0, [sqlString length])];
			}
		}
	}
	[scanner release];
	return [sqlString autorelease];
}  
                          
//=======================================================================================================
//    Public Methods
//========================================================================================================
+ (void)load
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSUserDefaults		*defaults;
	NSString			*value;
	
	// Check defaults
	defaults = [NSUserDefaults standardUserDefaults];
	value = [defaults stringForKey:@"EOAdaptorUseBindVariables"];
	if (value) 
	{
		if (([value caseInsensitiveCompare:@"yes"] == NSOrderedSame) ||
			([value caseInsensitiveCompare:@"true"] == NSOrderedSame))
			_useBindVariables = YES;
	}
	[pool release];
}

+ (void)initialize
{
	if (literalStartSet == nil)
	{
		literalStartSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"_"
			@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			@"abcdefghijklmnopqrstuvwxyz"] retain];

		literalSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"_"
			@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			@"abcdefghijklmnopqrstuvwxyz"
			@"0123456789."] retain];
	}
}

+ (EOSQLExpression *)expressionForString:(NSString *)string
{	
	return [[[[self class] alloc] initWithStatement:string] autorelease];
}

+ (EOSQLExpression *)insertStatementForRow:(NSDictionary *)row entity:(EOEntity *)entity
{
	EOSQLExpression *expression;
	
	expression = [[[self class] alloc] initWithRootEntity:entity];
	[expression setUseAliases:NO];
	[expression prepareInsertExpressionWithRow:row];
	return [expression autorelease];
}

+ (EOSQLExpression *)updateStatementForRow:(NSDictionary *)row qualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
	EOSQLExpression *expression;
	
	expression = [[[self class] alloc] initWithRootEntity:entity];
	[expression setUseAliases:NO];
	[expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
	return [expression autorelease];
}

+ (EOSQLExpression *)deleteStatementWithQualifier:(EOQualifier *)qualifier entity:entity
{
	EOSQLExpression *expression;
	
	expression = [[[self class] alloc] initWithRootEntity:entity];
	[expression setUseAliases:NO];
	[expression prepareDeleteExpressionForQualifier:qualifier];
	return [expression autorelease];
}

+ (EOSQLExpression *)selectStatementForAttributes:(NSArray *)attributes lock:(BOOL)yn
    fetchSpecification:(EOFetchSpecification *)fetchSpecification
    entity:(EOEntity *)entity
{
	EOSQLExpression *expression;
	
	expression = [[[self class] alloc] initWithRootEntity:entity];
	[expression setUseAliases:YES];
	[expression prepareSelectExpressionWithAttributes:attributes lock:yn
						   fetchSpecification:fetchSpecification];
	return [expression autorelease];
}


- (id)initWithRootEntity:(EOEntity *)aRootEntity
{
	[super init];
	
	rootEntity = [aRootEntity retain];
	usesAliases = NO;
	return self;
}

- (id)initWithEntity:(EOEntity *)anEntity
{
	return [self initWithRootEntity:anEntity];
}

- (id)initWithStatement:(NSString *)aStatement
{
   statement = [aStatement retain];

   return self;
}

- (void)dealloc
{
	[self _clearLists];
	[rootEntity release];
	[super dealloc];
}

- (EOEntity *)rootEntity
{
   return rootEntity;
}

- (EOEntity *)entity
{
	return [self rootEntity];
}

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
	lockClause:(NSString *)aLockClause
{
	NSMutableString	*string;
	
	string = [@"SELECT " mutableCopyWithZone:[self zone]];
	[string appendString:columnList];
	[string appendString:@" FROM "];
	[string appendString:aTableList];
	if ([aJoinClause length])
	{
		[string appendString:@" "];
		[string appendString:aJoinClause];
	}

	if ([aWhereClause length])
	{
		[string appendString:@" WHERE "];
		[string appendString:aWhereClause];
	}
	if ([aOrderByClause length])
	{
		[string appendString:@" ORDER BY "];
		[string appendString:aOrderByClause];
	}
	if ([aLockClause length])
	{
		[string appendString:@" "];
		[string appendString:aLockClause];
	}
	return [string autorelease];
}

// mont_rothstein @ yahoo.com 2005-06-23
// Added lock parameter to method as per API
- (void)prepareSelectExpressionWithAttributes:(NSArray *)attributes
										 lock:(BOOL)lock
						   fetchSpecification:(EOFetchSpecification *)fetch
{
	id					enumArray;
	EOAttribute			*attrib;
	EOQualifier			*qualifier;
	EOQualifier			*aQualifier;
	EOSortOrdering		*ordering;
	NSString			*aString;
	NSString			*lockClause;
	NSArray				*anArray;
	NSAutoreleasePool	*pool;
	
	// this does quite a big so lets put everything into a autorelease pool
	pool = [[NSAutoreleasePool allocWithZone:[self zone]] init];

	[rootEntity release];
	rootEntity = [[[EOModelGroup defaultModelGroup] entityNamed:[fetch _rootEntityName]] retain];
	
	[self _clearLists];
	if (usesAliases)
		[self _initAliases];
   

	// create where clause
	qualifier = [[fetch qualifier] retain];
	if (qualifier)
	{	
		// if there is a restricting qualifier we add that now.
		aQualifier = [rootEntity restrictingQualifier];
		if (aQualifier)
			qualifier = [[EOAndQualifier allocWithZone:[self zone]] initWithQualifiers:[fetch qualifier], aQualifier, nil];		
	}
	else
		qualifier = [[rootEntity restrictingQualifier] retain];
	// if there is no qualifier then we apply the external query if any. but I'm not going there.
	// It seems extremely flaky to me, and I seriously doubt that anyone would use it.
	if (qualifier)
	{
		whereClause = [[qualifier sqlStringForSQLExpression:self] mutableCopyWithZone:[self zone]];
		[qualifier release];
	}
	
	// create attribute list we need to do this SECOND because in the case of a flattened relationship
	// the select attributes are not the root entity.
	enumArray = [attributes objectEnumerator];
	while ((attrib = [enumArray nextObject]) != nil)
		[self addSelectListAttribute:attrib];


	// Add ordering clause
	anArray = [fetch sortOrderings];
	if ([anArray count])
	{
		orderByString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:200];
		enumArray = [anArray objectEnumerator];
		while ((ordering = [enumArray nextObject]) != nil)
			[self addOrderByAttributeOrdering:ordering];
	}
		
	// now that all the attributes have been delt with we can build the join
	// build the join clause
	[self joinExpression];
	
	// build the table Clause...  gee its only the entity
	tableClause = [[rootEntity externalName] mutableCopyWithZone:[self zone]];
	if (usesAliases)
	{
		aString = [aliases objectForKey:[rootEntity name]];
		if (aString)
		{
			[tableClause appendString:@" "];
			[tableClause appendString:aString];
		}
	}
	
	// build the lock clause
	lockClause = nil;
	if (lock)
		lockClause = [self lockClause];
	
	// we are done here, do the reet in the assemble
	statement = [[self assembleSelectStatementWithAttributes:attributes 
		lock:lock 
		qualifier:[fetch qualifier]
		fetchOrder:[fetch sortOrderings] 
		selectString:nil 
		columnList:listString 
		tableList:tableClause 
		whereClause:whereClause 
		joinClause:joinString 
		orderByClause:orderByString 
		lockClause:lockClause] mutableCopyWithZone:[self zone]];
	[pool release];
}

/*
// mont_rothstein @ yahoo.com 2005-06-23
// Added lock parameter to method as per API
- (void)prepareSelectExpressionWithAttributes:(NSArray *)attributes
										 lock:(BOOL)lock
						   fetchSpecification:(EOFetchSpecification *)fetch
{
   int					x, max;
   EOAttribute			*attribute;
   EOEntity				*workEntity;
   EOQualifier			*qualifier;
   NSString          *qualifierString = nil;
   NSString          *joinString = nil;
   NSArray				*sortOrderings;
   EOSortOrdering		*sortOrdering;
   EOEntity				*entity;

   entity = [[EOModelGroup defaultModelGroup] entityNamed:[fetch entityName]];
   [rootEntity release];
   rootEntity = [[[EOModelGroup defaultModelGroup] entityNamed:[fetch _rootEntityName]] retain];

   [statement release];
   statement = [@"SELECT " mutableCopyWithZone:[self zone]];
   if ([fetch usesDistinct]) [statement appendString:@"DISTINCT "];
   for (x = 0, max = [attributes count]; x < max; x++) {
      attribute = [attributes objectAtIndex:x];
      if (x > 0) {
         [statement appendString:@", "];
      }
      [statement appendString:[self sqlStringForAttributeNamed:[attribute name] inEntity:entity]]; 
   }

   qualifier = [fetch qualifier];
   if (qualifier != nil) {
      qualifierString = [qualifier sqlStringForSQLExpression:self];
      // See if the qualifier promoted a join to the top level. This happens
      // because some qualifiers promote their joings up, while other must
      // make them integral to their expression. For example, and 'AND' can
      // promote the join because 'AND' is communitive, and thus it doesn't
      // matter what order the join is AND'd to the expression, but an or
      // is not communitive, and therefore must AND the join to either it's
      // left or right expression.
      joinString = [qualifier sqlJoinForSQLExpression:self];
      // It did, so 'AND' it to our string.
      if (joinString != nil) {
         if (qualifierString == nil) {
            qualifierString = joinString;
         } else {
            NSMutableString		*sqlString;
            
            sqlString = [[NSMutableString allocWithZone:[self zone]] initWithString:qualifierString];

            [sqlString appendString:@" AND "];
            [sqlString appendString:joinString];
            qualifierString = [sqlString autorelease];
         }
      }
   }

   [statement appendString:@" FROM "];
   [tableClause release];
   tableClause = [[NSMutableString alloc] init];
   for (x = 0, max = [entities count]; x < max; x++) {
      workEntity = [entities objectAtIndex:x];
      if (x > 0) {
         [tableClause appendString:@", "];
      }
      [tableClause appendString:[workEntity externalName]];
      if (usesAliases) {
         [tableClause appendString:@" "];
         [tableClause appendString:[aliases objectForKey:[workEntity name]]];
      }
   }
   [statement appendString:tableClause];

   [whereClause release]; whereClause = nil;
   if (qualifierString != nil) {
      [statement appendString:@" WHERE "];
      whereClause = [qualifierString mutableCopyWithZone:[self zone]];
      [statement appendString:whereClause];
   }

   sortOrderings = [fetch sortOrderings];
   [sortOrderingClause release]; sortOrderingClause = nil;
   if (sortOrderings != nil && [sortOrderings count] > 0) {
      [statement appendString:@" ORDER BY "];
      sortOrderingClause = [[NSMutableString allocWithZone:[self zone]] init];
      for (x = 0, max = [sortOrderings count]; x < max; x++) {
         sortOrdering = [sortOrderings objectAtIndex:x];
         if (x > 0) {
            [sortOrderingClause appendString:@", "];
         }
		 // mont_rothstein @ yahoo.com 2004-12-20
		 // Sort ordings must be applied to the entity being fetched, not the root entity.
//         [sortOrderingClause appendString:[sortOrdering sqlStringForSQLExpression:self  inEntity:rootEntity]];
         [sortOrderingClause appendString:[sortOrdering sqlStringForSQLExpression:self  inEntity:entity]];
      }
      [statement appendString:sortOrderingClause];
   }

   // mont_rothstein @ yahoo.com 2005-06-23
   // Added code to append the lock clause if locking is turned on
   if (lock)
   {
	   [statement appendString: [self lockClause]];
   }
}
*/


- (NSString *)assembleUpdateStatementWithRow:(NSDictionary *)row 
	qualifier:(EOQualifier *)qualifier 
	tableList:(NSString *)aTableList 
	updateList:(NSString *)updateList
	whereClause:(NSString *)aWhereClause;
{
	NSMutableString	*string;
	
	string = [@"UPDATE " mutableCopyWithZone:[self zone]];
	[string appendString:aTableList];
	[string appendString:@" SET "];
	[string appendString:updateList];	
	if ([aWhereClause length])
	{
		[string appendString:@" WHERE "];
		[string appendString:aWhereClause];
	}
	return [string autorelease];	
}

- (void)prepareUpdateExpressionWithRow:(NSDictionary *)row qualifier:(EOQualifier *)qualifier
{
   EOAttribute			*attribute;
   NSEnumerator			*keys;
   NSString				*key;
   NSString				*sqlString;
   NSAutoreleasePool	*pool;
   NSString				*aString;

	// this does quite a big so lets put everything into a autorelease pool
	pool = [[NSAutoreleasePool allocWithZone:[self zone]] init];

	[self _clearLists];
	if (usesAliases)
		[self _initAliases];

	
	// entity HAS to be set at this point
	// create update list
	// documentation says no joins, so I'm not going to do any
	keys = [[row allKeys] objectEnumerator];
	while ((key = [keys nextObject]) != nil)
	{
		attribute = [rootEntity attributeNamed:key];
		if (attribute)
		{
			sqlString = [self sqlStringForValue:[row objectForKey:key] attribute:attribute];
			[self addUpdatetListAttribute:attribute value:sqlString];
		}
	}

	// build the table Clause...  gee its only the entity
	tableClause = [[rootEntity externalName] mutableCopyWithZone:[self zone]];
	if (usesAliases)
	{
		aString = [aliases objectForKey:[rootEntity name]];
		if (aString)
		{
			[tableClause appendString:@" "];
			[tableClause appendString:aString];
		}
	}
   
  	// create where clause
	if (qualifier)
		whereClause = [[qualifier sqlStringForSQLExpression:self] mutableCopyWithZone:[self zone]];
		
	// put it together
	statement = [[self assembleUpdateStatementWithRow:row 
		qualifier:qualifier 
		tableList:tableClause 
		updateList:listString
		whereClause:whereClause] mutableCopyWithZone:[self zone]];
	[pool release];
}
   
- (void)addUpdatetListAttribute:(EOAttribute *)attribute value:(NSString *)value
{
	NSMutableString		*sqlString;
	NSString			*aString;
	
	if (! listString)
		listString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:400];
		
	sqlString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:100];
	[sqlString appendString:[self sqlStringForAttribute:attribute]];
	[sqlString appendString:@" = "];
	
	// we need to deal with writeFormat here since this is the place where we know 
	// this is an update
	if ([[attribute writeFormat] length])
	{
		aString = [[self class] formatSQLString:value format:[attribute writeFormat]];
		[sqlString appendString:aString];
	}
	else
		[sqlString appendString:value];
		
	[self appendItem:sqlString toListString:listString];
}

/*
- (void)prepareUpdateExpressionWithRow:(NSDictionary *)row qualifier:(EOQualifier *)qualifier
{
   int					x;
   EOAttribute			*attribute;
   NSString				*qualifierString = nil;
   NSString				*joinString = nil;
   NSEnumerator		*keys;
   NSString				*key;

   [statement release];
   statement = [@"UPDATE " mutableCopyWithZone:[self zone]];

   // First, prep the qualifiers. This, as a side effect, makes sure all of
   // our tables are in the alias table and ready for output in the expression.
   if (qualifier != nil) {
      qualifierString = [qualifier sqlStringForSQLExpression:self];
      // See if the qualifier promoted a join to the top level. This happens
      // because some qualifiers promote their joings up, while other must
      // make them integral to their expression. For example, and 'AND' can
      // promote the join because 'AND' is communitive, and thus it doesn't
      // matter what order the join is AND'd to the expression, but an or
      // is not communitive, and therefore must AND the join to either it's
      // left or right expression.
      joinString = [qualifier sqlJoinForSQLExpression:self];
      // It did, so 'AND' it to our string.
      if (joinString != nil) {
         if (qualifierString == nil) {
            qualifierString = joinString;
         } else {
            NSMutableString	*sqlString = [joinString mutableCopyWithZone:[self zone]];

            [sqlString appendString:@" AND "];
            [sqlString appendString:qualifierString];
            qualifierString = [sqlString autorelease];
         }
      }
   }

   // Output the table name we're updating
   [statement appendString:[rootEntity externalName]];
   if (usesAliases) {
      [statement appendString:@" "];
      [statement appendString:[aliases objectForKey:[rootEntity name]]];
   }

   // Now, output the values we're updated.
   keys = [row keyEnumerator];
   x = 0;
   [statement appendString:@" SET "];
   while ((key = [keys nextObject])) {
      if (x > 0) {
         [statement appendString:@", "];
      }

      attribute = [rootEntity attributeNamed:key];
      if (attribute != nil) {
         [statement appendString:[self sqlStringForAttributeNamed:[attribute name] inEntity:rootEntity]];
         [statement appendString:@"="];
         [statement appendString:[attribute adaptorValueByConvertingAttributeValue:[row objectForKey:key]]];
      } else {
         EORelationship  *relationship = [rootEntity relationshipNamed:key];
		 */
		 
         /*! @todo Update relationships as part of UPDATE. */
		 
		 /*
         relationship = nil; // Shuts up a compiler warning.
      }
      x++;
   }

   // Now output the tables we'll be touching. Actually, we'll only touch the root table, but we might access other tables in the qualifier requires we do joints.
//   [statement appendString:@" FROM "];
//  [tableClause release];
// tableClause = [[NSMutableString alloc] init];
//   for (x = 0, max = [entities count]; x < max; x++) {
//      workEntity = [entities objectAtIndex:x];
//      if (x > 0) {
//         [tableClause appendString:@", "];
//      }
//      [tableClause appendString:[workEntity externalName]];
//      [tableClause appendString:@" "];
//      [tableClause appendString:[aliases objectForKey:[workEntity name]]];
//   }
//   [statement appendString:tableClause];

   // Finally, output the where clause.
   [whereClause release]; whereClause = nil;
   if (qualifierString != nil) {
      [statement appendString:@" WHERE "];
      whereClause = [qualifierString mutableCopyWithZone:[self zone]];
      [statement appendString:whereClause];
   }
}
*/

- (NSString *)assembleInsertStatementWithRow:(NSDictionary *)row 
	tableList:(NSString *)aTableList 
	columnList:(NSString *)aColumnList 
	valueList:(NSString *)valueList
{
	NSMutableString		*sqlString;

	sqlString = [@"INSERT INTO " mutableCopyWithZone:[self zone]];
	[sqlString appendString:aTableList];
	if (aColumnList)
	{
		[sqlString appendString:@" ("];
		[sqlString appendString:aColumnList];
		[sqlString appendString:@")"];
	}
	[sqlString appendString:@" VALUES ("];
	[sqlString appendString:valueList];
	[sqlString appendString:@")"];
	return [sqlString autorelease];
}	

- (void)prepareInsertExpressionWithRow:(NSDictionary *)row
{
	EOAttribute			*attribute;
	NSEnumerator		*keys;
	NSString			*key;
	NSAutoreleasePool	*pool;
	NSString			*sqlString;
	NSString			*aString;

	// this does quite a big so lets put everything into a autorelease pool
	pool = [[NSAutoreleasePool allocWithZone:[self zone]] init];

	[self _clearLists];
	if (usesAliases)
		[self _initAliases];

	// entity HAS to be set at this point
	// create insert list
	// documentation says no joins, so I'm not going to do any
	keys = [[row allKeys] objectEnumerator];
	while ((key = [keys nextObject]) != nil)
	{
		attribute = [rootEntity attributeNamed:key];
		if (attribute)
		{
			sqlString = [self sqlStringForValue:[row objectForKey:key] attribute:attribute];
			[self addInsertListAttribute:attribute value:sqlString];
		}
	}

	// build the table Clause...  gee its only the entity
	tableClause = [[rootEntity externalName] mutableCopyWithZone:[self zone]];
	if (usesAliases)
	{
		aString = [aliases objectForKey:[rootEntity name]];
		if (aString)
		{
			[tableClause appendString:@" "];
			[tableClause appendString:aString];
		}
	}

	
	// put it together
	statement = [[self assembleInsertStatementWithRow:row 
		tableList:tableClause 
		columnList:listString 
		valueList:valueListString] mutableCopyWithZone:[self zone]];
	[pool release];
}


- (void)addInsertListAttribute:(EOAttribute *)attribute value:(NSString *)value
{
	NSString			*aString;
	
	if (! listString)
		listString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:200];
	if (! valueListString)
		valueListString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:200];
		
	// we are building both the column list and the value list
	// The column list
	[self appendItem:[self sqlStringForAttribute:attribute] toListString:listString];
	
	// The valueList
	// we need to deal with writeFormat here since this is the place where we know 
	// this is an insert
	if ([[attribute writeFormat] length])
		aString = [[self class] formatSQLString:value format:[attribute writeFormat]];
	else
		aString = value;
	[self appendItem:aString toListString:valueListString];
}

/*
- (void)asInsertExpressionWithRow:(NSDictionary *)row
{
   int				x;
   EOAttribute		*attribute;
   NSEnumerator	*keys;
   NSString			*key;
   static int		count = 0;
   NSDictionary		*binding;

   if (EOAdaptorDebugEnabled) [EOLog logDebugWithFormat:@"SQL: Prepare insert count: %d\n", ++count];

   [statement release];
   statement = [@"INSERT INTO " mutableCopyWithZone:[self zone]];

   // Output the table name we're updating
   [statement appendString:[rootEntity externalName]];

   // Now, output the attributes we're inserting...
   keys = [row keyEnumerator];
   x = 0;
   [statement appendString:@" ("];
   while ((key = [keys nextObject])) {
      attribute = [rootEntity attributeNamed:key];
      if (attribute != nil) {
			if (x > 0) {
				[statement appendString:@", "];
			}
			else
				x = 1;
			[statement appendString:[attribute columnName]];
      }
   }
   [statement appendString:@")"];

   // Now, output the attributes we're inserting...
   keys = [row keyEnumerator];
   x = 0;
   [statement appendString:@" VALUES ("];
   while ((key = [keys nextObject])) {
      attribute = [rootEntity attributeNamed:key];
      if (attribute != nil) {
			if (x > 0) {
				[statement appendString:@", "];
			}
			#warning Implement bindings here
			if (bindings) {
				//binding = [bindings objectForKey:key];
			}
			else
				[statement appendString:[attribute adaptorValueByConvertingAttributeValue:[row objectForKey:key]]];
			x++;
      }
   }
   [statement appendString:@")"];
}
*/

- (NSString *)assembleDeleteStatementWithQualifier:(EOQualifier *)qualifier 
	tableList:(NSString *)aTableList 
	whereClause:(NSString *)aWhereClause
{

	NSMutableString	*sqlString;
	sqlString = [@"DELETE FROM " mutableCopyWithZone:[self zone]];
	[statement appendString:aTableList];
	if (aWhereClause)
	{
		[statement appendString:@" WHERE "];
		[statement appendString:aWhereClause];
   }
   return [sqlString autorelease];
}

- (void)prepareDeleteExpressionForQualifier:(EOQualifier *)qualifier;
{
	NSString				*aString;
	NSAutoreleasePool		*pool;

	pool = [[NSAutoreleasePool allocWithZone:[self zone]] init];
	[self _clearLists];
	if (usesAliases)
		[self _initAliases];

	// create where clause
	if (qualifier)
	{
		whereClause = [[qualifier sqlStringForSQLExpression:self] mutableCopyWithZone:[self zone]];
		[qualifier release];
	}	
	
	// no joins, sorry.
	
	// build the table Clause
	tableClause = [[rootEntity externalName] mutableCopyWithZone:[self zone]];
	if (usesAliases)
	{
		aString = [aliases objectForKey:[rootEntity name]];
		if (aString)
		{
			[tableClause appendString:@" "];
			[tableClause appendString:aString];
		}
	}
	
	// we are done here, do the reset in the assymble
	statement = [[self assembleDeleteStatementWithQualifier:qualifier 
		tableList:tableClause 
		whereClause:whereClause] mutableCopyWithZone:[self zone]];
	[pool release];
}

/*
- (void)prepareDeleteExpressionWithQualifier:(EOQualifier *)qualifier;
{
   int					x, max;
   EOEntity				*workEntity;
   NSString				*qualifierString = nil;
   NSString				*joinString = nil;

   [statement release];
   statement = [@"DELETE FROM " mutableCopyWithZone:[self zone]];

   // First, prep the qualifiers. This, as a side effect, makes sure all of
   // our tables are in the alias table and ready for output in the expression.
   if (qualifier != nil) {
      qualifierString = [qualifier sqlStringForSQLExpression:self];
      // See if the qualifier promoted a join to the top level. This happens
      // because some qualifiers promote their joings up, while other must
      // make them integral to their expression. For example, and 'AND' can
      // promote the join because 'AND' is communitive, and thus it doesn't
      // matter what order the join is AND'd to the expression, but an or
      // is not communitive, and therefore must AND the join to either it's
      // left or right expression.
      joinString = [qualifier sqlJoinForSQLExpression:self];
      // It did, so 'AND' it to our string.
      if (joinString != nil) {
         if (qualifierString == nil) {
            qualifierString = joinString;
         } else {
            NSMutableString	*sqlString = [joinString mutableCopyWithZone:[self zone]];

            [sqlString appendString:@" AND "];
            [sqlString appendString:qualifierString];
            qualifierString = [sqlString autorelease];
         }
      }
   }

   // Now output the tables we'll be touching. Actually, we'll only touch
   // the root table, but we might access other tables in the qualifier
   // requires we do joints.
   [tableClause release];
   tableClause = [[NSMutableString alloc] init];
   for (x = 0, max = [entities count]; x < max; x++) {
      workEntity = [entities objectAtIndex:x];
      if (x > 0) {
         [tableClause appendString:@", "];
      }
      [tableClause appendString:[workEntity externalName]];
      if (usesAliases) {
         [tableClause appendString:@" "];
         [tableClause appendString:[aliases objectForKey:[workEntity name]]];
      }
   }
   [statement appendString:tableClause];

   // Finally, output the where clause.
   if (qualifierString != nil) {
      [statement appendString:@" WHERE "];
      [statement appendString:qualifierString];
   }
}
*/

- (void)prepareStoredProcedure:(EOStoredProcedure *)procedure withValues:(NSDictionary *)values
{
	// Does nothing by default. This must be implemented by subclasses if they support stored procedures.
}

- (void)setStatement:(NSString *)aStatement
{
   if ((NSString *)statement != (NSString *)aStatement) {
      [statement release];
      statement = [aStatement retain];
   }
}

- (NSString *)statement
{
   return [statement description];
}

- (NSString *)whereClauseString
{
   return [whereClause description];
}

- (NSString *)tableClause
{
   return [tableClause description];
}

- (NSMutableString *)valueList
{
	return valueListString;
}

- (NSMutableString *)joinClauseString
{
	return joinString; 
}

- (NSMutableString *)listString
{
	return listString;
}


// This method should no longer be used that I can see.  With the new join semantic it is no longer needed.
// BUT it is part of the API and just maybe it would be needed by subclassers in which case it should do the
// right thing.
- (NSString *)tableListWithRootEntity:(EOEntity *)anEntity
{
	EOEntity	*relationshipEntity;
	id			enumArray;
	NSString	*relationshipPath;
	NSString	*tableAlias;
	
	[tableClause release];
	tableClause = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:10];
	if ([aliasesByRelationshipPath count] > 1)
	{
		enumArray = [[aliasesByRelationshipPath allKeys] objectEnumerator];
		while ((relationshipPath = [enumArray nextObject]) != nil)
		{
			tableAlias = [aliasesByRelationshipPath objectForKey:relationshipPath];
			if ([relationshipPath length])
				relationshipEntity = [self _entityForRelationshipPath:relationshipPath rootEntity:anEntity];
			else
				relationshipEntity = anEntity;
			if ([tableClause length])
				[tableClause appendString:@", "];
			[tableClause appendString:[anEntity externalName]];
			if (usesAliases)
				[tableClause appendString:tableAlias];
		}
	}
	else
	{
		[tableClause appendString:[anEntity externalName]];
		if (usesAliases)
			[tableClause appendString:@" t0"];
	}
	return tableClause;
}

- (NSString *)sortOrderingClause
{
   return [sortOrderingClause description];
}

// mont_rothstein @ yahoo.com 2005-06-23
// Added lockClause method for use in locking
- (NSString *)lockClause
{
	// Overridden in subclass to return a DB specific value
}

- (void)setUseAliases:(BOOL)flag
{
   usesAliases = flag;
   if (! aliases)
		[self _initAliases];
}

- (BOOL)usesAliaes
{
   return usesAliases;
}

- (BOOL)isEqualTo:(id)other
{
	return [other isKindOfClass:[EOSQLExpression class]] && [(NSString *)[self statement] isEqualTo:[other statement]];
}

- (BOOL)isEqual:(id)other
{
	return [other isKindOfClass:[EOSQLExpression class]] && [(NSString *)[self statement] isEqual:[other statement]];
}

- (int)compare:(id)other
{
	return [(NSString *)[self statement] compare:[other statement]];
}

- (NSString *)sqlPrefixForQualifierOperation:(EOQualifierOperation)op value:(id)value
{
   // Basically, the logic here is that if the value is not null, and we have
   // a case insensitive comparison, then we have to prepend a to-lower function
   // to the sql. Note, however, we don't do this when the value is null, because
   // if the value is null, then the comparison becomes a simple IS or IS NOT
   // operation.
   if (value != nil &&
       (op == EOQualifierCaseInsensitiveEqual ||
        op == EOQualifierCaseInsensitiveLike ||
        op == EOQualifierCaseInsensitiveNotEqual ||
        op == EOQualifierCaseInsensitiveNotLike)) {
      return @"LOWER(";
   }
   
   // Returning an empty string makes it easier for the method calling this
   // method.
   return @"";
}

- (NSString *)sqlStringForQualifierOperation:(EOQualifierOperation)op value:(id)value
{
   if (op == EOQualifierEquals ||
       op == EOQualifierCaseInsensitiveEqual) {
      // mont_rothstein@yahoo.com 2006-01-22
      // Added support for EOQualifierCaseInsensitiveEqual.  Note: This is an extension to the WO 4.5 API
      if (value == nil) return @"IS";
      return @"=";
   } else if (op == EOQualifierNotEquals ||
              op == EOQualifierCaseInsensitiveNotEqual) {
      // mont_rothstein@yahoo.com 2006-01-22
      // Added support for EOQualifierCaseInsensitiveNotEqual.  Note: This is an extension to the WO 4.5 API
      if (value == nil) return @"IS NOT";
      return @"!=";
   } else if (op == EOQualifierLessThan) {
      return @"<";
   } else if (op == EOQualifierLessThanOrEqual) {
      return @"<=";
   } else if (op == EOQualifierGreaterThan) {
      return @">";
   } else if (op == EOQualifierGreaterThanOrEqual) {
      return @">=";
   } else if (op == EOQualifierIn) {
      return @"IN";
   } else if (op == EOQualifierLike) {
      return @"LIKE";
   } else if (op == EOQualifierCaseInsensitiveLike) {
      return @"LIKE";
   } else if (op == EOQualifierNotLike ||
              op == EOQualifierCaseInsensitiveNotLike) {
      return @"NOT LIKE";
   }
   
   return @"NO-OP";
}

- (NSString *)sqlSuffixForQualifierOperation:(EOQualifierOperation)op value:(id)value
{
   // Basically, the logic here is that if the value is not null, and we have
   // a case insensitive comparison, then we have to prepend a to-lower function
   // to the sql. Note, however, we don't do this when the value is null, because
   // if the value is null, then the comparison becomes a simple IS or IS NOT
   // operation.
   if (value != nil &&
       (op == EOQualifierCaseInsensitiveEqual ||
        op == EOQualifierCaseInsensitiveLike ||
        op == EOQualifierCaseInsensitiveNotEqual ||
        op == EOQualifierCaseInsensitiveNotLike)) {
      return @")";
   }
   
   // Returning an empty string makes it easier for the method calling this
   // method.
   return @"";
}

- (NSString *)substringSearchOperator
{
   return @"%";
}

- (NSString *)characterSearchOperator
{
   return @"_";
}

+ (NSString *)sqlPatternFromShellPattern:(NSString *)pattern
{
	NSMutableString   *result = [[pattern mutableCopy] autorelease];
	
	// first escape any escapses
	[result replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	// now escape any SQL patterns that exist
	[result replaceOccurrencesOfString:@"%" withString:@"\\%" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"_" withString:@"\\_" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	// replace the shell pattern with SQL patterns
	[result replaceOccurrencesOfString:@"*" withString:@"%" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
	[result replaceOccurrencesOfString:@"?" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
   
   return result;
}

- (NSString *)sqlStringForValue:(id)value withQualifierOperation:(EOQualifierOperation)operation inAttribute:(EOAttribute *)attribute
{
   NSString *raw = [self formatValue:value forAttribute:attribute];
   NSString	*result;
   
   if (operation == EOQualifierLike ||
       operation == EOQualifierCaseInsensitiveLike ||
       operation == EOQualifierNotLike ||
       operation == EOQualifierCaseInsensitiveNotLike)
	{
		result = [[self class] sqlPatternFromShellPattern:raw];
	}
	else
		result = raw;
   return result;
}

//---- Get the SQL for a value
- (NSString *)sqlStringForValue:(id)value attribute:(EOAttribute *)attribute
{
	BOOL				doBind = NO;
	NSString			*result;
	NSMutableDictionary	*binding;
	
	// if the value is nil or a NSNull/EONull, then I am thinking without exception there would be no binding
	// needed.  
	if (value && (! [value isKindOfClass:[NSNull class]]))
	{
		// Handle binding
		if ([self mustUseBindVariableForAttribute:attribute])
			doBind = YES;
		else if ([[self class] useBindVariables])
		{
			if ([self shouldUseBindVariableForAttribute:attribute])
				doBind = YES;
		}
	}
	
	if (doBind)
	{
		binding = [self bindVariableDictionaryForAttribute:attribute value:value];
		[self addBindVariableDictionary:binding];
		result = [binding objectForKey:EOBindVariablePlaceHolderKey];
	}
	else
		result = [self formatValue:value forAttribute:attribute];
	return result;
}

- (NSString *)sqlStringForValue:(id)value attributeNamed:(NSString *)name
{
	NSRange		aRange;
	EOAttribute	*attrib = nil;

	// is this a path?
	aRange = [name rangeOfString:@"."];
	if (aRange.length > 0)
		attrib = [[rootEntity _attributesForKeyPath:name] lastObject];
	else
		attrib = [rootEntity attributeNamed:name];
	return [self sqlStringForValue:value attribute:attrib];
}

- (NSString *)formatValue:(id)value forAttribute:(EOAttribute *)attribute
{
	id primitiveValue;
	// first convert the value into a standard type
	primitiveValue = [attribute adaptorValueByConvertingAttributeValue:value];
	// convert primitive type to SQL
	return 	[attribute adaptorSqlStringForStandardValue:value];
}

- (NSMutableDictionary *)bindVariableDictionaryForAttribute:(EOAttribute *)attribute value:value
{
	[NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOSQLExpression class]), NSStringFromSelector(_cmd)];
}

- (BOOL)shouldUseBindVariableForAttribute:(EOAttribute *)att
{
	return NO;
}

- (BOOL)mustUseBindVariableForAttribute:(EOAttribute *)att
{
	return NO;
}

+ (BOOL)useBindVariables
{
	return _useBindVariables;
}

+ (void)setUseBindVariables:(BOOL)yn
{
	@synchronized(self) {
		_useBindVariables = yn;
	}
}

// Applications can override the user default by invoking this method.

- (NSArray *)bindVariableDictionaries
{
	return bindings;
}

- (void)addBindVariableDictionary:(NSMutableDictionary *)binding;
{
	if (! bindings)
		bindings = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
	[bindings addObject:binding];
}

// Building an attribute name
- (void)appendItem:(NSString *)itemString toListString:(NSMutableString *)aList
{
	if ([aList length])
		[aList appendString:@", "];
	[aList appendString:itemString];
}

// fix up the strings that use read or write formats
// Documentation says we use %P on read and %V on write.  Okay.
// I just don't understand why it was not simply %P for both, but fine.
// This is called by addSelectListAttribute:
+ (NSString *)formatSQLString:(NSString *)sqlString format:(NSString *)format
{
	// if there is nothing to do then do nothing.
	if ([format length] == 0)
		return sqlString;
		
	NSRange aRange = [format rangeOfString:@"%P" options:NSCaseInsensitiveSearch];
	if (aRange.length == 0)
		aRange = [format rangeOfString:@"%V"options:NSCaseInsensitiveSearch];
	if (aRange.length == 0)
		return sqlString;  // probably should throw and exception at this point
	return [NSString stringWithFormat:@"%@%@%@", [format substringToIndex:aRange.location], 
		sqlString, [format substringFromIndex:aRange.location + aRange.length]];
}

- (NSMutableDictionary *)aliasesByRelationshipPath
{
	return aliasesByRelationshipPath;
}
 
- (NSString *)sqlStringForAttributePath:(NSArray *)path
{
	EORelationship		*r;
	id					anObject;
	EOAttribute			*attrib;
	unsigned short		index, lastRelationship, nextTableNumber;
	NSString			*columnSQL;
	NSMutableString		*relationshipPath;
	NSString			*alias;
	NSString			*t;
		
	relationshipPath = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:[path count] * 20];
	index = 0;
	nextTableNumber = [aliasesByRelationshipPath count];
	lastRelationship = [path count];
	
	// build relationship paths  
	// Lets say the path is   office, department, location, city then I have three tables and 
	// I need three paths.
	// office = t1
	// office.department = t2
	// office.department.location = t3
	//
	// flatened relationships should already be expanded.
	attrib = nil;
	for (index = 0; index < lastRelationship; ++index)
	{
		anObject = [path objectAtIndex:index];
		if ([anObject isKindOfClass:[EORelationship class]])
		{
				r = (EORelationship *)anObject;
			if ([relationshipPath length] > 0)
				[relationshipPath appendString:@"."];
			[relationshipPath appendString:[r name]];
			// first check to see if it is already there
			if (! [aliasesByRelationshipPath objectForKey:relationshipPath])
			{
				alias = [NSString stringWithFormat:@"t%d", nextTableNumber++];
				[aliasesByRelationshipPath setObject:alias
						forKey:[[relationshipPath copy] autorelease]];
				// and set a mapping from entity name to the alias as well
				[aliases setObject:alias forKey:[[r destinationEntity] name]];
			}
		}
		else
			attrib = (EOAttribute *)anObject;
	}
	[relationshipPath release];
	if (! attrib)
		return @"";
	
	// get the columnName.  WE WILL NOT deal with a flattened path to a flattened path.
	// If someone tries to do that it will fail, and guess what, there is a work around
	// as they can re-define the path to go to the final attrib. 
	// that said it could be a path to a derived attrib and we can handle that
	if ([attrib isDerived])
		columnSQL =  [self _sqlStringForDerivedAttribute:attrib];	
	else
		columnSQL = [attrib columnName];
		
	// if we are not using aliases this WILL fail, as there will be no relationship path to
	// build the joins.  But just in case SOMEHOW I think of a way to make this work, I'll do 
	// a hail Mary here 	
	if (usesAliases)
		t = [aliases objectForKey:[[attrib entity] name]];
	if (! t)
		t = [[attrib entity] externalName];
	return [NSString stringWithFormat:@"%@.%@", t, columnSQL];
}

- (NSString *)sqlStringForAttribute:(EOAttribute *)attribute fullyQualified:(BOOL)qualified
{
	NSString	*t;
	// deal with normal and derived attributes,
	// Not flattened attributes or read and write formats

	// The caller did not think this was a path, but they could be wrong if this is a
	// flattened attribute.  Lets re-direct to the right place if that is the case.
	// in any case this is only called if the entity is the root entity.
	if ([attribute isFlattened])
		return [self sqlStringForAttributeNamed:[attribute definition]];
	
	// deal with derived attributes
	if ([attribute isDerived] && [[attribute definition] length])
		return [self _sqlStringForDerivedAttribute:attribute];
	
	// this is a normal attribute
	if (usesAliases)
		t = [aliases objectForKey:[[attribute entity] name]];
	else
		t = nil;
		
	if (! t && qualified)
		t = [[attribute entity] externalName];
	
	if (! t)
		return [attribute columnName];
		
	return [NSString stringWithFormat:@"%@.%@",t, [attribute columnName]]; 
}

- (NSString *)sqlStringForAttribute:(EOAttribute *)attribute
{
	return [self sqlStringForAttribute:(EOAttribute *)attribute fullyQualified:NO];
}

- (NSString *)sqlStringForAttributeNamed:(NSString *)name attribute:(EOAttribute **)lastAttrib
{
	EOAttribute		*attrib;
	NSString		*result;
	NSString		*aPath;
	NSRange			aRange;
	NSArray			*attribPath;
	
	result = nil;
	attrib = nil;
	aPath = nil;
	// is this a path?
	aRange = [name rangeOfString:@"."];
	if (aRange.length > 0)
		aPath = name;
	else
	{
		attrib = [rootEntity attributeNamed:name];
		if ([attrib isFlattened])
			aPath = [attrib definition];
	}
		
	if (aPath)
	{
		attribPath = [rootEntity _attributesForKeyPath:aPath];
		attrib = [attribPath lastObject];
		result = [self sqlStringForAttributePath:attribPath];
	}
	else if (attrib)
		result = [self sqlStringForAttribute:attrib];
	if (lastAttrib)
		*lastAttrib = attrib;
	return result;
}

- (NSString *)sqlStringForAttributeNamed:(NSString *)name
{
	return [self sqlStringForAttributeNamed:(NSString *)name attribute:NULL];
}

 - (void)addSelectListAttribute:(EOAttribute *)attribute
 {
	// we need to deal with readFormat here since this is the place where we know 
	// this is a select
	if (! listString)
		listString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:40];
		
	NSString *sqlString = [self sqlStringForAttribute:attribute];
	if ([[attribute readFormat] length])
		sqlString = [[self class] formatSQLString:sqlString format:[attribute readFormat]];
	[self appendItem:sqlString toListString:listString];
 }

//========== Building the Join
- (void)joinExpression;
{
	// 
	id				keyEnum;
	NSString		*path;
	NSString		*sourceAlias;
	NSString		*destAlias;
	NSString		*rootAlias;
	NSArray			*pathComponents;
	int				x, c;
	BOOL			valid;
	BOOL			first;
	EOEntity		*currentEntity;
	EORelationship	*relationship;
	id				joinEnum;
	EOJoin			*join;
	
	// every path represents one path to an entity
	// every path component is a relationship.
	// every relationship is expanded (not flattened)
	[joinString release];
	joinString = nil;
	
	// if there are no paths, other than root, then there are no joins
	if ([aliasesByRelationshipPath count] < 2)
		return;
	
	joinString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:200];
	
	// get the root alias
	rootAlias = [aliasesByRelationshipPath objectForKey:@""];	
	keyEnum = [aliasesByRelationshipPath keyEnumerator];
		
	while ((path = [keyEnum nextObject]) != nil)
	{
		// we do not need to deal with the root path
		if ([path length] == 0)
			continue;
			
		if ([joinString length])
			[joinString appendString:@" "];
		
		// get the destAlias
		destAlias = [aliasesByRelationshipPath objectForKey:path];
		pathComponents = [rootEntity _attributesForKeyPath:path];
		relationship = [pathComponents lastObject];

		// add the join semantic
		switch ([relationship joinSemantic])
		{
			case  EOInnerJoin:
				[joinString appendString:@"JOIN "];
				break;
			case  EOFullOuterJoin:
				[joinString appendString:@"FULL OUTER JOIN "];
				break;
			case  EOLeftOuterJoin:
				[joinString appendString:@"LEFT OUTER JOIN "];
				break;
			case  EORightOuterJoin:
				[joinString appendString:@"RIGHT OUTER JOIN "];
				break;
		}
		
		// add the destination entity
		[joinString appendString:[[relationship destinationEntity] externalName]];
		if (usesAliases)
		{
			[joinString appendString:@" "];
			[joinString appendString:destAlias];
			[joinString appendString:@" "];
		}
		
		// add the joins
		joinEnum = [[relationship joins] objectEnumerator];
		first = YES;
		while ((join = [joinEnum nextObject]) != nil)
		{
			if (first)
			{
				[joinString appendString:@"ON "];
				first = NO;
			}
			else
				[joinString appendString:@" AND "];		
			[joinString appendString:[self sqlStringForAttribute:[join sourceAttribute] fullyQualified:YES]];
			[joinString appendString:@" = "];
			[joinString appendString:[self sqlStringForAttribute:[join destinationAttribute] fullyQualified:YES]];
		}
	}
}

- (void)addOrderByAttributeOrdering:(EOSortOrdering *)sortOrdering
{
	SEL				selector = [sortOrdering selector];
	NSMutableString	*string = [[NSMutableString allocWithZone:[self zone]] init];
	NSString		*keySql;

	if (selector == EOCompareCaseInsensitiveAscending) {
		[string appendString:@"toupper("];
	} else if (selector == EOCompareCaseInsensitiveDescending) {
		[string appendString:@"toupper("];
	}
	
	keySql = [self sqlStringForAttributeNamed:[sortOrdering key]];
	[string appendString:keySql];
   

   if (selector == EOCompareAscending) {
		[string appendString:@" ASC"];
	} else if (selector == EOCompareDescending) {
		[string appendString:@" DESC"];
	} else if (selector == EOCompareCaseInsensitiveAscending) {
		[string appendString:@") ASC"];
	} else if (selector == EOCompareCaseInsensitiveDescending) {
		[string appendString:@") DESC"];
	}

	[self appendItem:string toListString:orderByString];

}

- (NSMutableString *)orderByString { return orderByString; }

@end
