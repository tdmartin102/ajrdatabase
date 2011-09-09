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

@class EOAdaptorContext, EOAdaptorOperation, EODatabase, EOEntity, EOFetchSpecification, EOModel, EOQualifier, EOSQLExpression, EOStoredProcedure;

extern NSString *EOAdaptorOperationsKey;
extern NSString *EOFailedAdaptorOperationKey;
extern NSString *EOAdaptorFailureKey;
extern NSString *EOAdaptorOptimisticLockingFailure;
extern NSString *EOGenericAdaptorException;

@interface EOAdaptorChannel : NSObject
{
   EOAdaptorContext	*adaptorContext;
	
	id						delegate;

    BOOL					connected:1;
	BOOL					debug:1;

   // These are all used during the fetch.
   EOEntity				*fetchEntity;

	struct {
        unsigned willPerformOperations:1;
        unsigned didPerformOperations:1;
        unsigned shouldSelectAttributes:1;
		unsigned didSelectAttributes:1;
		unsigned willFetchRow:1;
		unsigned didFetchRow:1;
		unsigned didChangeResultSet:1;
		unsigned didFinishFetching:1;
		unsigned shouldEvaluateExpression:1;
        unsigned didEvaluateExpression:1;
        unsigned shouldExecuteStoredProcedure:1;
        unsigned didExecuteStoredProcedure:1;
        unsigned shouldConstructStoredProcedureReturnValues:1;
        unsigned shouldReturnValuesForStoredProcedure:1;
    } _delegateRespondsTo;                  
}

// Creating an EOAdaptorChannel
- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext;

// Accessing the adaptor context
- (EOAdaptorContext *)adaptorContext;

// Opening and closing a channel
- (void)openChannel;
- (void)closeChannel;
- (BOOL)isOpen;

//	Modifying rows
- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity;
- (void)updateValues:(NSDictionary *)row inRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity;
- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity;
- (void)deleteRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity;
- (unsigned int)deleteRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity;

// Fetching rows
- (void)selectAttributes:(NSArray *)attributes withFetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity;  // ajr API
- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity;
- (NSArray *)describeResults;
- (void)setAttributesToFetch:(NSArray *)someAttributes;
- (NSArray *)attributesToFetch;
- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)zone;
- (NSMutableDictionary *)dictionaryWithObjects:(id *)objects forAttributes:(NSArray *)attributes zone:(NSZone *)zone;
- (void)cancelFetch;
- (BOOL)isFetchInProgress;

// Invoking stored procedures
- (void)executeStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values;
- (NSDictionary *)returnValuesForLastStoredProcedureInvocation;

// Assigning primary keys (not EOF API)
- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count;
// EOF API method simplay calls primaryKeysForNewRowsWithEntity:count: with count of 1
- (NSDictionary *)primaryKeyForNewRowWithEntity:(EOEntity *)entity;

// Sending SQL to the server
- (void)evaluateExpression:(EOSQLExpression *)anExpression;

// Batch processing operation
- (void)performAdaptorOperation:(EOAdaptorOperation *)adaptorOperation;
- (void)performAdaptorOperations:(NSArray *)adaptorOperations;

// Accessing schema information
- (NSArray *)describeTableNames;
- (NSArray *)describeStoredProcedureNames;
- (void)addStoredProceduresNamed:(NSArray *)storedProcedureNames toModel:(EOModel *)model;
- (EOModel *)describeModelWithTableNames:(NSArray *)tableNames;

// Debugging
- (void)setDebugEnabled:(BOOL)flag;
- (BOOL)isDebugEnabled;
	
// Accessing the delegate
- (id)delegate;
- (void)setDelegate:(id)aDelegate;

@end

@interface NSObject (EOAdaptorChannelDelegation)

- (NSArray *)adaptorChannel:channel
    willPerformOperations:(NSArray *)operations;
    // Invoked from -performAdaptorOperations. The delegate may return a the same
    // or different NSArray to continue the method or nil to cause the method to
    // return immediately.

- (NSException *)adaptorChannel:channel
    didPerformOperations:(NSArray *)operations
    exception:(NSException *)exception;
    // Invoked from -performAdaptorOperations. The exception will be nil if no
    // exception was raised during while performing the operations. Otherwise, the
    // raised exception will be passed to the delegate. The delegate can return the
    // the same or a different exception which will then be re-raised by the method
    // or they can return nil to supress the raising of the exception.

- (BOOL)adaptorChannel:channel
    shouldSelectAttributes:(NSArray *)attributes
    fetchSpecification:(EOFetchSpecification *)fetchSpecification
    lock:(BOOL)flag entity:(EOEntity *)entity;
    // Invoked from -selectAttributes:fetchSpecification:lock:entity:
    // to ask the delegate whether a select operation should be performed.
    // The delegate should not modify the fetchSpecification.  Instead,
    // if the delegate wants to perform a different select it should call
    // selectAttributes:... itself with the new fetchSpec and return NO
    // (indicating that the adaptor channel should not perform the select itself).

- (void)adaptorChannel:channel
    didSelectAttributes:(NSArray *)attributes
    fetchSpecification:(EOFetchSpecification *)fetchSpecification
    lock:(BOOL)flag entity:(EOEntity *)entity;
    // Invoked from -selectAttributes:fetchSpecification:lock:entity:
    // to tell the delegate that some rows have been selected. The delegate
    // may take whatever action it needs based on this information.

- (void)adaptorChannelWillFetchRow:channel;
    // Invoked from -fetchRowWithZone: to tell the delegate that a
    // single row will be fetched. Delegates can get and reset the attributes
    // used in the fetch through the -attributesToFetch and the
    // -setAttributesToFetch: methods.
    // the adaptor channel perfoms the fetch itself.

- (void)adaptorChannel:channel didFetchRow:(NSMutableDictionary *)row;
    // Invoked at the end of -fetchRowWithZone: whenever a row is successfully
    // fetched. This method is not invoked if an exception occurs during the
    // fetch or if the end of the fetch set is reached. Delegates can change
    // the row dictionary.

- (void)adaptorChannelDidChangeResultSet:channel;
    // Invoked from -fetchRowWithZone: to tell the delegate that
    // fetching will start for the next result set, when a select operation
    // resulted in multiple result sets.  This method is invoked just after a
    // -fetchRowWithZone: returns nil when there are still result sets
    // left to fetch.

- (void)adaptorChannelDidFinishFetching:channel;
    // Invoked from -fetchRowWithZone: to tell the delegate that
    // fetching is finished for the current select operation.  This method is
    // invoked when a fetch ends in -fetchRowWithZone: because there
    // are no more result sets.

- (BOOL)adaptorChannel:channel
    shouldEvaluateExpression:(EOSQLExpression *)expression;
    // Invoked from -evaluateExpression: to ask the delegate whether to
    // send an expression to the database server. If the delegate returns YES,
    // then evaluateExpression: method will continue. If the delegate
    // returns NO, evaluateExression: will return immediately and the adaptor
    // channel will expect that the implementor of the delegate has done the
    // work that evaluateExpression: would otherwise have done.

- (void)adaptorChannel:channel
    didEvaluateExpression:(EOSQLExpression *)expression;
    // Invoked from -evaluateExpression: to tell the delegate that a query
    // language expression has been evaluated by the database server. The
    // delegate may take whatever action it needs based on this information.

- (NSDictionary *)adaptorChannel:channel
    shouldExecuteStoredProcedure:(EOStoredProcedure *)procedure
    withValues:(NSDictionary *)values;
    // Invoked from -executeStoredProcedure:withArguments:
    // If the delegate returns a value other than nil, that returned dictionary
    // will will be used as the arguments to the stored procedure

- (void)adaptorChannel:channel
    didExecuteStoredProcedure:(EOStoredProcedure *)procedure
    withValues:(NSDictionary *)values;
    // Invoked from -executeStoredProcedure:withValues: after the execution
    // has succeeded.

- (NSDictionary *)adaptorChannelShouldConstructStoredProcedureReturnValues:channel;
    // Invoked from -returnValuesForLastStoredProcedureInvocation.
    // If the delegate returns a value other than nil, that value will be
    // returned immediately to the calling method.

- (NSDictionary *)adaptorChannel:channel shouldReturnValuesForStoredProcedure:(NSDictionary *)returnValues;
    // Invoked from -returnValuesForLastStoredProcedureInvocation
    // If the delegate returns a dictionary, that dictionary will be returned to the
    // calling method.
@end                               

@interface EOAdaptorChannel (EOExtensions)

/*! @todo EOAdaptorChannel: delegate methods */
- (id)valueForSQLFunction:(NSString *)sqlFunction attributeNamed:(NSString *)attributeName withFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity;
- (int)countOfObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity;
- (id)maxValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity;
- (id)minValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity;
- (id)sumOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity;
- (id)averageOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch entity:(EOEntity *)entity;

@end
