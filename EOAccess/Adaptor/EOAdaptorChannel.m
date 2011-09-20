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

#import "EOAdaptorChannel.h"

#import "EOAdaptor.h"
#import "EOAdaptorContext.h"
#import "EOAdaptorContextP.h"
#import "EOAdaptorOperationP.h"
#import "EOAttribute.h"
#import "EODatabase.h"
#import "EOEntity.h"
#import "EOModel.h"
#import "EOSQLExpression.h"

#import <EOControl/EOControl.h>

NSString *EOAdaptorOperationsKey = @"EOAdaptorOperationsKey";
NSString *EOFailedAdaptorOperationKey = @"EOFailedAdaptorOperationKey";
NSString *EOAdaptorFailureKey = @"EOAdaptorFailureKey";
NSString *EOAdaptorOptimisticLockingFailure = @"EOAdaptorOptimisticLockingFailure";
NSString *EOGenericAdaptorException = @"EOGenericAdaptorException";

@implementation EOAdaptorChannel : NSObject

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{
	// we retain the context, but the context does not retain us.
	// this way there is no retain cycle, and you only need to hang on
	// to the channel.
	adaptorContext = [aContext retain];
	connected = NO;
	[self setDelegate:[aContext delegate]];
	debug = [adaptorContext isDebugEnabled];
	return self;
}

- (void)dealloc
{
   // And don't free ourself if we're still connected...
   if ([self isOpen]) {
      [self closeChannel];
   }
   
   // Make sure the adaptor context stops referencing us...
   [(NSMutableArray *)[adaptorContext channels] removeObjectIdenticalTo:self];
   [adaptorContext release];

   [super dealloc];
}


- (EOAdaptorContext *)adaptorContext
{
   return adaptorContext;
}

- (void)openChannel
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (void)closeChannel
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (BOOL)isOpen
{
   return connected;
}

- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (void)updateValues:(NSDictionary *)row inRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
	unsigned int	rows;
	// mont_rothstein @ yahoo.com 2005-06-26
	// As per the API changed this to call updateValues:inRowsDescribedByQualifier:entity:
	// and raise an exception if exactly one row wasn't updated.  In order to determine if
	// exactly one row was updated the _rowsAffected private method was added.  This
	// method is implemented in the subclass.
//   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
	rows = [self updateValues: row inRowsDescribedByQualifier: qualifier entity: entity];
	if (rows != 1)
	{
		[[NSException exceptionWithName: EOGenericAdaptorException 
								 reason: [NSString stringWithFormat: @"Update of single row failed.  Instead %d row(s) were updated.", rows]
							   userInfo: [NSDictionary dictionaryWithObject: EOAdaptorOptimisticLockingFailure forKey: EOAdaptorFailureKey]] raise];
	}
}

- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
   return 0;
}

- (void)deleteRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
	unsigned int	rows;
	// mont_rothstein @ yahoo.com 2005-06-26
	// As per the API changed this to call deleteRowsDescribedByQualifier:entity:
	// and raise an exception if exactly one row wasn't deleted.  In order to determine if
	// exactly one row was deleted the _rowsUpdated private method was added.  This
	// method is implemented in the subclass.
//	[NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
	rows = [self deleteRowsDescribedByQualifier: qualifier entity: entity];
	if (rows != 1)
	{
		[[NSException exceptionWithName: EOGenericAdaptorException 
								 reason: [NSString stringWithFormat: @"Delete of single row failed.  Instead %d row(s) were deleted.", rows]
							   userInfo: [NSDictionary dictionaryWithObject: EOAdaptorOptimisticLockingFailure forKey: EOAdaptorFailureKey]] raise];
	}
}

- (unsigned int)deleteRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
   return 0;
}

- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity;
{
	[NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (void)selectAttributes:(NSArray *)attributes withFetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity
{
	[self selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity];
}

- (NSArray *)describeResults
{
	return [self attributesToFetch];
}

- (void)setAttributesToFetch:(NSArray *)someAttributes
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (NSArray *)attributesToFetch
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
	return nil;
}

- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)zone
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
	return nil;
}

- (NSMutableDictionary *)dictionaryWithObjects:(id *)objects forAttributes:(NSArray *)attributes zone:(NSZone *)zone
{
	NSMutableDictionary	*dictionary = [[NSMutableDictionary allocWithZone:zone] init];
	int						x;
	int numAttributes;
	
	numAttributes = [attributes count];
	for (x = 0; x < numAttributes; x++) {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  
		//[dictionary takeValue:objects[x] forKey:[[attributes objectAtIndex:x] name]];
		[dictionary setValue:objects[x] forKey:[[attributes objectAtIndex:x] name]];
	}
	
	return dictionary;
}

- (void)cancelFetch
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (BOOL)isFetchInProgress
{
   return fetchEntity != nil;
}

- (void)executeStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (NSDictionary *)returnValuesForLastStoredProcedureInvocation
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
	return nil;
}

- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
	return nil;
}

- (NSDictionary *)primaryKeyForNewRowWithEntity:(EOEntity *)entity
{
	NSArray *anArray = [self primaryKeysForNewRowsWithEntity:entity count:1];
	if ([anArray count])
		return [anArray objectAtIndex:0];
	return nil;
}

- (void)evaluateExpression:(EOSQLExpression *)anExpression
{
   [NSException raise:EODatabaseException format:@"Subclasses of %@ must implement %@.", NSStringFromClass([EOAdaptorChannel class]), NSStringFromSelector(_cmd)];
}

- (void)performAdaptorOperation:(EOAdaptorOperation *)adaptorOperation
{
	switch ([adaptorOperation adaptorOperator]) {
		case EOAdaptorLockOperator:
			[EOLog logWarningWithFormat:@"Adaptor level locking not yet supported."];
			break;
		case EOAdaptorInsertOperator:
			[self insertRow:[adaptorOperation changedValues] forEntity:[adaptorOperation entity]];
			break;
		case EOAdaptorUpdateOperator:
			[self updateValues:[adaptorOperation changedValues] inRowDescribedByQualifier:[adaptorOperation qualifier] entity:[adaptorOperation entity]];
			break;
		case EOAdaptorDeleteOperator:
			[self deleteRowDescribedByQualifier:[adaptorOperation qualifier] entity:[adaptorOperation entity]];
			break;
		case EOAdaptorStoredProcedureOperator:
			[self executeStoredProcedure:[adaptorOperation storedProcedure] withValues:[adaptorOperation changedValues]];
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Adaptor %@ asked to perform an unkown operator %d", self, [adaptorOperation adaptorOperator]];
	}
}

- (void)performAdaptorOperations:(NSArray *)adaptorOperations
{
	int						x;
	int numAdaptorOperations;
	NSException				*exception;
	EOAdaptorOperation	*failedOperation;
	
	// Finally, perform the operations!
	exception = nil;
	numAdaptorOperations = [adaptorOperations count];
	for (x = 0; x < numAdaptorOperations && exception == nil; x++) {
		failedOperation = [[adaptorOperations objectAtIndex:x] retain];
		NS_DURING
			[self performAdaptorOperation:failedOperation];
		NS_HANDLER
			exception = [localException retain];
		NS_ENDHANDLER
		if (exception == nil) [failedOperation release];
	}
	
	// If an exception occured, add some data to the exception's user info and raise it.
	if (exception != nil) {
		// mont_rothstein @ yahoo.com 2005-06-26
		// Some times a user info dictionary hasn't been set, plus when it has the 
		// exception seems to make a non-mutable copy (go figure).  So, we
		// re-create the exception.
		NSString *name;
		NSString *reason;
		NSMutableDictionary	*info;
		NSException *newException;
		
		name = [exception name];
		reason = [exception reason];
		info = [[exception userInfo] mutableCopy];
		
		if (!info) info = [NSMutableDictionary dictionary];
		[info setObject:adaptorOperations forKey:EOAdaptorOperationsKey];
		[info setObject:failedOperation forKey:EOFailedAdaptorOperationKey];

		newException = [NSException exceptionWithName: name reason: reason userInfo: info];
		[newException raise];
	}
}

- (NSArray *)describeTableNames
{
	return nil;
}

- (NSArray *)describeStoredProcedureNames
{
	return nil;
}

- (void)addStoredProceduresNamed:(NSArray *)storedProcedureNames toModel:(EOModel *)model
{
}

- (EOModel *)describeModelWithTableNames:(NSArray *)tableNames
{
	return nil;
}

- (void)setDebugEnabled:(BOOL)flag
{
	debug = flag;
	if (flag)
	{
		// It does not hurt to turn on the logger no matter what
		// as logging is REALLY controlled by flags at higer levels
		[EOLogger setLogDebug:flag];
		[EOLogger setLogInfo:flag];
	}
}

- (BOOL)isDebugEnabled
{
	return debug;
}

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
	
	// determine what the delegate responds to
	// memset always scares me.
	memset(&_delegateRespondsTo,0,sizeof(_delegateRespondsTo));
	if (delegate)
	{
		if ([delegate respondsToSelector:@selector(adaptorChannel:willPerformOperations:)])
			_delegateRespondsTo.willPerformOperations = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannel:didPerformOperations:exception:)])
			_delegateRespondsTo.didPerformOperations = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannel:shouldSelectAttributes:fetchSpecification:lock:entity:)])
			_delegateRespondsTo.shouldSelectAttributes = 1;	
		if ([delegate respondsToSelector:@selector(adaptorChannel:didSelectAttributes:fetchSpecification:lock:entity:)])
			_delegateRespondsTo.didSelectAttributes = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannelWillFetchRow:)])
			_delegateRespondsTo.willFetchRow = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannel:didFetchRow:)])
			_delegateRespondsTo.didFetchRow = 1;				
		if ([delegate respondsToSelector:@selector(adaptorChannelDidChangeResultSet:)])
			_delegateRespondsTo.didChangeResultSet = 1;	
		if ([delegate respondsToSelector:@selector(adaptorChannelDidFinishFetching:)])
			_delegateRespondsTo.didFinishFetching = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannel:shouldEvaluateExpression:)])
			_delegateRespondsTo.shouldEvaluateExpression = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannel:didEvaluateExpression:)])
			_delegateRespondsTo.didEvaluateExpression = 1;	
		if ([delegate respondsToSelector:@selector(adaptorChannel:shouldExecuteStoredProcedure:withValues:)])
			_delegateRespondsTo.shouldExecuteStoredProcedure = 1;
		if ([delegate respondsToSelector:@selector(adaptorChannel:didExecuteStoredProcedure:withValues:)])
			_delegateRespondsTo.didExecuteStoredProcedure = 1;	
		if ([delegate respondsToSelector:@selector(adaptorChannelShouldConstructStoredProcedureReturnValues:)])
			_delegateRespondsTo.shouldConstructStoredProcedureReturnValues = 1;		
		if ([delegate respondsToSelector:@selector(adaptorChannel:shouldReturnValuesForStoredProcedure:)])
			_delegateRespondsTo.shouldReturnValuesForStoredProcedure = 1;																													
	}
}

@end


@implementation EOAdaptorChannel (EOExtensions)

- (id)valueForSQLFunction:(NSString *)sqlFunction attributeNamed:(NSString *)attributeName withFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity
{
   NSMutableString      *sqlString;
   EOSQLExpression      *expression;
   NSDictionary			*row;
   NSString					*error = nil;
   id							value = nil;
   NSArray					*results;
   NSMutableArray			*values = [NSMutableArray array];
   NSString *selectOn;

   // Next, start an expression. We'll use this to build up our string.
   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:YES];
   // This just makes things happen for us that aren't really well documented, or aren't documented at all. We're going to mostly ignore the direct results and just use the information to reassemble a valid expression.
   if (attributeName) {
	   // mont_rothstein @ yahoo.com 2005-06-23
	   // Modified to pass in lock parameter
      [expression prepareSelectExpressionWithAttributes: [entity attributes] 
												   lock: [fetch locksObjects]
									 fetchSpecification: fetch];
   } else {
	   // mont_rothstein @ yahoo.com 2005-06-23
	   // Modified to pass in lock parameter
      [expression prepareSelectExpressionWithAttributes: [NSArray arrayWithObject:[entity attributeNamed:attributeName]] 
												   lock: [fetch locksObjects]
									 fetchSpecification: fetch];
   }

   // mont_rothstein @ yahoo.com 2005-09-14
   // Added handling of usesDistinct
   if ([attributeName isEqualToString:@"*"]) selectOn = @"*";
   else
   {
	   selectOn = [NSString stringWithFormat: @"%@ %@", ([fetch usesDistinct]) ? @"DISTINCT" : @"", [expression sqlStringForAttributeNamed:attributeName]];
   }
	   
   sqlString = [NSMutableString stringWithFormat:@"SELECT %@(%@) FROM %@", sqlFunction,  selectOn, [expression tableClause]];

   if ([expression whereClauseString]) {
      [sqlString appendString:@" WHERE "];
      [sqlString appendString:[expression whereClauseString]];
   }

   [expression setStatement:sqlString];

   NS_DURING

      [self evaluateExpression:expression];
      results = [self describeResults];
      
      while ((row = [self fetchRowWithZone:NULL])) {
         value = [row valueForKey:[[results objectAtIndex:0] name]];
         [values addObject:value];
      }
      
   NS_HANDLER
      error = [localException description];
   NS_ENDHANDLER

   [expression release];

   if ([self isFetchInProgress]) {
      [self cancelFetch];
   }

   if (error) {
      return nil;
   }

   if ([values count] > 1) {
      return values;
   } else {
      return [values lastObject];
   }
}

- (int)countOfObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity
{
	// mont_rothstein @ yahoo.com 2005-05-14
	// Modified to handle distinct for counts.  To do a count on distinct * can't be used, an attribute name must be used.  This takes the first attribute of the PK and uses it.
	/*! @todo Make the distinct option work for multi-attribute PKs */
	if (![fetch usesDistinct])
	{
		return [[self valueForSQLFunction:@"count" attributeNamed:@"*" withFetchSpecification:fetch entity:entity] intValue];
	}
	else
	{
		NSString *primaryKeyName;
		
		primaryKeyName = [[entity primaryKeyAttributeNames] objectAtIndex: 0];
		return [[self valueForSQLFunction:@"count" attributeNamed: primaryKeyName withFetchSpecification:fetch entity:entity] intValue];
	}
}

- (id)maxValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity
{
   return [self valueForSQLFunction:@"max" attributeNamed:attributeName withFetchSpecification:fetch entity:entity];
}

- (id)minValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity
{
   return [self valueForSQLFunction:@"min" attributeNamed:attributeName withFetchSpecification:fetch entity:entity];
}

- (id)sumOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity
{
   return [self valueForSQLFunction:@"sum" attributeNamed:attributeName withFetchSpecification:fetch entity:entity];
}

- (id)averageOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity
{
   return [self valueForSQLFunction:@"avg" attributeNamed:attributeName withFetchSpecification:fetch entity:entity];
}

@end
