//
//  EODatabaseOperation.h
//  EOAccess/
//
//  Created by Alex Raftis on Tue Sep 14 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _eoDatabaseOperator {
	EODatabaseNothingOperator = 0,
	EODatabaseInsertOperator = 1,
	EODatabaseUpdateOperator = 2,
	EODatabaseDeleteOperator = 3
} EODatabaseOperator;

@class EOAdaptorOperation, EOGlobalID, EOGenericRecord, EOEntity;

@interface EODatabaseOperation : NSObject
{
	EOGlobalID				*globalID;
	id							object;
	EOEntity					*entity;
	EODatabaseOperator	databaseOperator;
	NSDictionary			*snapshot;
	NSMutableDictionary  *newRow;
	NSMutableArray			*adaptorOperations;
	NSMutableDictionary  *toManySnapshots;
}

// Creating a new EODatabaseOperation
- (id)initWithGlobalID:(EOGlobalID *)aGlobalID object:(id)anObject entity:(EOEntity *)anEntity;

// Accessing the global ID object
- (EOGlobalID *)globalID;

// Accessing the object
- (id)object;

// Accessing the entity
- (EOEntity *)entity;

// Accessing the operator
- (void)setDatabaseOperator:(EODatabaseOperator)anOperation;
- (EODatabaseOperator)databaseOperator;

// Accessing the database snapshot
- (void)setEOSnapshot:(NSDictionary *)snapshot;
- (NSDictionary *)EOSnapshot;

// Accessing the row
- (void)setNewRow:(NSDictionary *)aRow;
- (NSDictionary *)newRow;
	
// Accessing the adaptor operations
- (void)addAdaptorOperation:(EOAdaptorOperation *)anOperation;
- (void)removeAdaptorOperation:(EOAdaptorOperation *)anOperation;
- (NSArray *)adaptorOperations;
	
// Comparing new row and snapshot values
- (NSDictionary *)rowDiffs;
- (NSDictionary *)rowDiffsForAttributes:(NSArray *)attributes;

// Working with to-many snapshots
- (void)recordToManySnapshot:(NSArray *)snapshots relationshipName:(NSString *)name;
- (NSDictionary *)toManySnapshots;

@end
