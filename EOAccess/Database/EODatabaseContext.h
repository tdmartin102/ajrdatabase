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

#import <EOControl/EOCooperatingObjectStore.h>

typedef enum _eoUpdateStrategy {
	EOUpdateWithOptimisticLocking = 0,
	EOUpdateWithPessimisticLocking = 1,
	EOUpdateWithNoLocking = 2
} EOUpdateStrategy;

@class EOAdaptorChannel, EOAdaptorContext, EODatabase, EODatabaseChannel, EOEntity, EOGlobalID, EOModel, EORelationship;

extern NSString *EODatabaseChannelNeededNotification;

extern NSString *EODatabaseContextKey;
extern NSString *EODatabaseOperationsKey;
extern NSString *EOFailedDatabaseOperationKey;

@interface EODatabaseContext : EOCooperatingObjectStore
{
    EODatabase              *database;
    EOAdaptorContext		*adaptorContext;
	NSMutableArray			*databaseChannels;
    NSMutableDictionary     *snapshots;
	NSMutableSet			*forgetSnapshots;
// mont_rothstein @ yahoo.com 2005-1-2
// The objects instance variable was removed because it was unnecessary and generally bad
// (objects were being shared between WO sessions).
//	NSMutableDictionary	*objects;
	
	EOUpdateStrategy		updateStrategy;
	NSMutableSet			*lockedObjects;
	EOEditingContext		*savingContext;
	NSMutableArray			*databaseOperations;
    
    // Tom.Martin @ Riemer.com 2012-03-30
    // added the following ivar as grease.
    EOGlobalID              *_currentGlobalID;

	id						delegate;
		
	BOOL					delegateRespondsToDidFetchObjectsFetchSpecificationEditingContext:1;
	BOOL					delegateRespondsToDidSelectObjectsWithFetchSpecificationDatabaseChannel:1;
	BOOL					delegateRespondsToFailedToFetchObjectGlobalID:1;
	BOOL					delegateRespondsToNewPrimaryKeyForObjectEntity:1;
	BOOL					delegateRespondsToShouldFetchArrayFault:1;
	BOOL					delegateRespondsToShouldFetchObjectFault:1;
	BOOL					delegateRespondsToShouldFetchObjectsWithFetchSpecificationEditingContext:1;
	BOOL					delegateRespondsToShouldInvalidateObjectWithGlobalIDSnapshot:1;
	BOOL					delegateRespondsToShouldLockObjectWithGlobalIDSnapshot:1;
	BOOL					delegateRespondsToShouldRaiseExceptionForLockFailure:1;
	BOOL					delegateRespondsToShouldSelectObjectsWithFetchSpecificationDatabaseChannel:1;
	BOOL					delegateRespondsToShouldUpdateCurrentSnapshotNewSnapshotGlobalIDDatabaseChannel:1;
	BOOL					delegateRespondsToShouldUsePessimisticLockWithFetchSpecificationDatabaseChannel:1;
	BOOL					delegateRespondsToWillOrderAdaptorOperationsFromDatabaseOperations:1;
	BOOL					delegateRespondsToWillPerformAdaptorOperationsAdaptorChannel:1;
	BOOL					delegateRespondsToWillRunLoginPanelToOpenDatabaseChannel:1;
	
	// mont_rothstein @ yahoo.com 2004-12-19
	// Added new instance variable
	NSMutableSet			*tempJoinIDs; // Holds global IDs of many-to-many join table objects created during the save process for inserts or deletes.
}

// Initializing instances
- (id)initWithDatabase:(EODatabase *)database;

// Obtaining an EODatabaseContext
+ (EODatabaseContext *)registeredDatabaseContextForModel:(EOModel *)aModel objectStoreCoordinator:(EOObjectStoreCoordinator *)objectStoreCoordinator;
+ (EODatabaseContext *)registeredDatabaseContextForModel:(EOModel *)aModel editingContext:(EOEditingContext *)anEditingContext;

// Accessing the context class
+ (Class)contextClassToRegister;
+ (void)setContextClassToRegister:(Class)contextClass;

// Accessing the Adaptor Context
- (EOAdaptorContext *)adaptorContext;

// Accessing the database
- (EODatabase *)database;

// Managing the channels
/*!
 @method availableChannel

 @discussion Returns an available database channel. In our simplified case, we return the channel associated with the current thread. Each thread has it's own database channel and connection to the database.
 */
- (EODatabaseChannel *)availableChannel;
- (void)registerChannel:(EODatabaseChannel *)aChannel;
- (NSArray *)registeredChannels;
- (void)unregisterChannel:(EODatabaseChannel *)aChannel;

// Checking connection status.
- (BOOL)hasBusyChannels;

// Other
- (void)lock;
- (void)unlock;

// Determining responsibility
- (BOOL)handlesFetchSpecification:(EOFetchSpecification *)fetchSpecification;
- (BOOL)ownsGlobalID:(EOGlobalID *)globalID;
- (BOOL)ownsObject:(id)object;

// Fetching objects
- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetchSpecification editingContext:(EOEditingContext *)anEditingContext;
- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name editingContext:(EOEditingContext *)anEditingContext;
- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name editingContext:(EOEditingContext *)anEditingContext;
/*! @todo EODatabaseContext: batch fetching support */
- (void)batchFetchRelationship:(EORelationship *)relationship forSourceObjects:(NSArray *)objects editingContext:(EOEditingContext *)anEditingContext;

// Initializing objects
- (void)initializeObject:(id)object withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;

// Accessing the delegate
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

// Managing snapshots
- (void)forgetSnapshotForGlobalID:(EOGlobalID *)globalID;
- (void)forgetSnapshotsForGlobalIDs:(NSArray *)globalIDs;
- (NSMutableDictionary *)localSnapshotForGlobalID:(EOGlobalID *)globalID;
- (void)recordSnapshot:(NSDictionary *)snapshot forGlobalID:(EOGlobalID *)globalID;
- (void)recordSnapshots:(NSDictionary *)someSnapshots;
- (NSDictionary *)snapshotForGlobalID:(EOGlobalID *)globalID;
- (void)recordSnapshot:(NSArray *)globalIDs forSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name;
- (NSArray *)snapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name;
- (NSArray *)localSnapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name;
- (void)recordToManySnapshots:(NSDictionary *)someSnapshots;

// Locking objects
- (void)setUpdateStrategy:(EOUpdateStrategy)strategy;
- (EOUpdateStrategy)updateStrategy;
- (void)registerLockedObjectWithGlobalID:(EOGlobalID *)globalID;
- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID;
- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (void)forgetAllLocks;
- (void)forgetLocksForObjectsWithGlobalIDs:(NSArray *)globalIDs;
- (void)lockObjectWithGlobalID:(EOGlobalID *)globalID  editingContext:(EOEditingContext *)anEditingContext;

// Returning information about objects
- (NSDictionary *)valuesForKeys:(NSArray *)keys object:(id)object;

// Commiting or discarding changes
- (void)invalidateAllObjects;
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs;
- (void)saveChangesInEditingContext:(EOEditingContext *)anEditingContext;
- (void)prepareForSaveWithCoordinator:(EOObjectStoreCoordinator *)coordinator editingContext:(EOEditingContext *)anEditingContext;
- (void)recordChangesInEditingContext;
- (void)performChanges;
- (void)commitChanges;
- (void)rollbackChanges;

// Getting faults
- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext;
- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (id)faultForRawRow:(id)row entityNamed:(NSString *)entityName editingContext:(EOEditingContext *)anEditingContext;

@end


@interface NSObject (EODatabaseContextDelegate)

/*! @todo EODatabaseContext: all delegate methods */

- (void)databaseContext:(EODatabaseContext *)aDatabaseContext didFetchObjects:(NSArray *)objects fetchSpecification:(EOFetchSpecification *)fetchSpecification editingContext:(EOEditingContext *)anEditingContext;
- (void)databaseContext:(EODatabaseContext *)aDatabaseContext didSelectObjectsWithFetchSpecification:(EOFetchSpecification *)fetchSpecification databaseChannel:(EODatabaseChannel *)channel;
- (BOOL)databaseContext:(EODatabaseContext *)aDatabaseContext failedToFetchObject:(id)object globalID:(EOGlobalID *)globalID;
- (NSDictionary *)databaseContext:(EODatabaseContext *)aDatabaseContext newPrimaryKeyForObject:(id)object entity:(EOEntity *)entity;
- (BOOL)databaseContext:(EODatabaseContext *)databaseContext shouldFetchArrayFault:(id)fault;
- (BOOL)databaseContext:(EODatabaseContext *)databaseContext shouldFetchObjectFault:(id)fault;
- (NSArray *)databaseContext:(EODatabaseContext *)aDatabaseContext shouldFetchObjectsWithFetchSpecification:(EOFetchSpecification *)fetchSpecification editingContext:(EOEditingContext *)anEditingContext;
- (BOOL)databaseContext:(EODatabaseContext *)aDatabaseContext shouldInvalidateObjectWithGlobalID:(EOGlobalID *)globalId snapshot:(NSDictionary *)snapshot;
- (BOOL)databaseContext:(EODatabaseContext *)aDatabaseContext shouldLockObjectWithGlobalID:(EOGlobalID *)globalID snapshot:(NSDictionary *)snapshot;
- (BOOL)databaseContext:(EODatabaseContext *)aDatabaseContext shouldRaiseExceptionForLockFailure:(NSException *)exception;
- (BOOL)databaseContext:(EODatabaseContext *)aDatabaseContext shouldSelectObjectsWithFetchSpecification:(EOFetchSpecification *)fetchSpecification databaseChannel:(EODatabaseChannel *)channel;
- (NSDictionary *)databaseContext:(EODatabaseContext *)aDatabaseContext shouldUpdateCurrentSnapshot:(NSDictionary *)currentSnapshot newSnapshot:(NSDictionary *)newSnapshot globalID:(EOGlobalID *)globalID databaseChannel:(EODatabaseChannel *)channel;
- (BOOL)databaseContext:(EODatabaseContext *)databaseContext shouldUsePessimisticLockWithFetchSpecification:(EOFetchSpecification *)fetchSpecification databaseChannel:(EODatabaseChannel *)channel;
- (NSArray *)databaseContext:(EODatabaseContext *)aDatabaseContext willOrderAdaptorOperationsFromDatabaseOperations:(NSArray *)databaseOperations;
- (NSArray *)databaseContext:(EODatabaseContext *)aDatabaseContext willPerformAdaptorOperations:(NSArray *)adaptorOperations adaptorChannel:(EOAdaptorChannel *)adaptorChannel;
- (BOOL)databaseContext:(EODatabaseContext *)aDatabaseContext willRunLoginPanelToOpenDatabaseChannel:(EODatabaseChannel *)channel;

@end
