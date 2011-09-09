//
//  EOAdaptorOperation.h
//  EOAccess/
//
//  Created by Alex Raftis on Tue Sep 14 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _eoAdaptorOperator {
	EOAdaptorLockOperator = 0,
	EOAdaptorInsertOperator = 1,
	EOAdaptorUpdateOperator = 2,
	EOAdaptorDeleteOperator = 3,
	EOAdaptorStoredProcedureOperator = 4
} EOAdaptorOperator;

@class EODatabaseOperation, EOEntity, EOQualifier, EOStoredProcedure;

@interface EOAdaptorOperation :NSObject
{
	int						adaptorOperator;
	EOEntity					*entity;
	EOQualifier				*qualifier;
	NSDictionary			*changedValues;
	NSArray					*attributes;
	EOStoredProcedure		*storedProcedure;
	NSException				*exception;
	EODatabaseOperation	*databaseOperation;
}

// Creating a new EOAdaptorOperation
- (id)initWithEntity:(EOEntity *)entity;

// Accessing the entity
- (EOEntity *)entity;

// Accessing the operator
- (void)setAdaptorOperator:(EOAdaptorOperator)adaptorOperator;
- (EOAdaptorOperator)adaptorOperator;

// Accessing the qualifier
- (void)setQualifier:(EOQualifier *)qualifier;
- (EOQualifier *)qualifier;

// Accessing the attributes
- (void)setAttributes:(NSArray *)attributes;
- (NSArray *)attributes;

// Accessing operation values
- (NSDictionary *)changedValues;
- (void)setChangedValues:(NSDictionary *)changedValues;

// Accessing a stored procedure
- (void)setStoredProcedure:(EOStoredProcedure *)storedProcedure;
- (EOStoredProcedure *)storedProcedure;

// Handling errors during the operation
- (void)setException:(NSException *)exception;
- (NSException *)exception;

// Comparing operations
- (NSComparisonResult)compareAdaptorOperation:(EOAdaptorOperation *)operation;

@end
