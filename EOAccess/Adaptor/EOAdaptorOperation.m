//
//  EOAdaptorOperation.m
//  EOAccess/
//
//  Created by Alex Raftis on Tue Sep 14 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EOAdaptorOperation.h"

#import "EODatabaseOperation.h"
#import "EOEntity.h"
#import "EOQualifier-EOAccess.h"
#import "EOStoredProcedure.h"

@implementation EOAdaptorOperation

// Creating a new EOAdaptorOperation
- (id)initWithEntity:(EOEntity *)anEntity
{
	if (self = [super init])	
		entity = [anEntity retain];
	
	return self;
}

// Accessing the entity
- (EOEntity *)entity
{
	return entity;
}

// Accessing the operator
- (void)setAdaptorOperator:(EOAdaptorOperator)anAdaptorOperator
{
	adaptorOperator = anAdaptorOperator;
}

- (EOAdaptorOperator)adaptorOperator
{
	return adaptorOperator;
}

// Accessing the qualifier
- (void)setQualifier:(EOQualifier *)aQualifier
{
	if (qualifier != aQualifier) {
		[qualifier release];
		qualifier = [aQualifier retain];
	}
}

- (EOQualifier *)qualifier
{
	return qualifier;
}

	// Accessing the attributes
- (void)setAttributes:(NSArray *)someAttributes
{
	if (attributes != someAttributes) {
		[attributes release];
		attributes = [someAttributes retain];
	}
}

- (NSArray *)attributes
{
	return attributes;
}

// Accessing operation values
- (void)setChangedValues:(NSDictionary *)someChangedValues
{
	if (changedValues != someChangedValues) {
		[changedValues release];
		changedValues = [someChangedValues retain];
	}
}

- (NSDictionary *)changedValues
{
	return changedValues;
}

// Accessing a stored procedure
- (void)setStoredProcedure:(EOStoredProcedure *)aStoredProcedure
{
	if (storedProcedure != aStoredProcedure) {
		[storedProcedure release];
		storedProcedure = [aStoredProcedure retain];
	}
}

- (EOStoredProcedure *)storedProcedure
{
	return storedProcedure;
}

// Handling errors during the operation
- (void)setException:(NSException *)anException
{
	if (exception != anException) {
		[exception release];
		exception = [anException retain];
	}
}

- (NSException *)exception
{
	return exception;
}

// Comparing operations
- (NSComparisonResult)compareAdaptorOperation:(EOAdaptorOperation *)operation
{
	int		result;
	
	result = [[entity name] compare:[[operation entity] name]];
	if (result != NSOrderedSame) return result;
	
	result = adaptorOperator - [operation adaptorOperator];
	if (result < NSOrderedSame) return NSOrderedAscending;
	if (result > NSOrderedSame) return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (void)_setDatabaseOperation:(EODatabaseOperation *)anOperation
{
	databaseOperation = anOperation;
}

- (EODatabaseOperation *)_databaseOperation
{
	return databaseOperation;
}

@end
