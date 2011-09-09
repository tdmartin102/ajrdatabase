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

#import "EOCooperatingObjectStore.h"
#import "EOObserver.h"

extern NSString *EOEditingContextDidSaveChangesNotification;

@class EOEntity, EOFetchSpecification, EOGlobalID, EOObjectStore;

@interface EOEditingContext : EOCooperatingObjectStore <EOObserving, NSCoding>
{
   NSMutableDictionary	*objects;
	NSMutableDictionary	*objectGlobalIDs;
   NSMutableDictionary	*updatedObjects;
	NSMutableArray			*updatedCache;
   NSMutableDictionary	*insertedObjects;
	NSMutableArray			*insertedCache;
   NSMutableDictionary	*deletedObjects;
	NSMutableArray			*deletedCache;
   NSMutableDictionary	*updatedQueue;
   NSMutableDictionary	*insertedQueue;
   NSMutableDictionary	*deletedQueue;

   EOObjectStore			*objectStore;
	int						objectStoreLockCount;
	
	NSUndoManager			*undoManager;
	NSMutableDictionary	*undoObjects;
	NSMutableArray			*editors;
	
	id							delegate;
	id							messageHandler;
	
   BOOL						isValidating:1;
	BOOL						isUndoingOrRedoing:1;
	BOOL						propagatesDeletesAtEndOfEvent:1;
	BOOL						stopsValidationAfterFirstError:1;
	BOOL						invalidatesObjectsWhenFreed:1;
}

// Initializing an EOEditingContext
- (id)init;
- (id)initWithParentObjectStore:(EOObjectStore *)anObjectStore;

// Fetching objects
- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetch;

// Committing or discarding changes
- (void)saveChanges;
- (void)saveChanges:(id)sender;
- (NSException *)tryToSaveChanges;
- (void)refaultObjects;
- (void)refault:(id)sender;
- (void)refetch:(id)sender;
- (void)revert;
- (void)revert:(id)sender;
- (void)invalidateAllObjects;

// Registering changes
- (void)deleteObject:(id)object;
- (void)insertObject:(id)object;
- (void)insertObject:(id)object withGlobalID:(EOGlobalID *)aGlobalID;
- (void)objectWillChange:(id)object;
- (void)processRecentChanges;

// Checking changes
- (NSArray *)deletedObjects;
- (NSArray *)insertedObjects;
- (NSArray *)updatedObjects;
- (BOOL)hasChanges;

// Object registration and snapshotting
- (void)forgetObject:(id)object;
- (void)recordObject:(id)object globalID:(EOGlobalID *)globalID;
- (NSDictionary *)committedSnapshotForObject:(id)object;
- (NSDictionary *)currentEventSnapshotForObject:(id)object;
- (id)objectForGlobalID:(EOGlobalID *)globalID;
- (EOGlobalID *)globalIDForObject:(id)object;
- (NSArray *)registeredObjects;

// Locking objects
/*! @todo EOEditingContext: Object level locking. */
- (void)lockObject:(id)object;
- (void)lockObjectWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)editingContext;
- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)editingContext;
- (void)setLocksObjectsBeforeFirstModification:(BOOL)flag;
- (BOOL)locksObjectsBeforeFirstModification;

// Undoing operations
- (void)redo:(id)sender;
- (void)undo:(id)sender;
- (void)setUndoManager:(NSUndoManager *)aManager;
- (NSUndoManager *)undoManager;

// Deletion and Validation Behavior
/*! @todo EOEditingContext: propagatesDeletesAtEndOfEvent */
- (void)setPropagatesDeletesAtEndOfEvent:(BOOL)flag;
- (BOOL)propagatesDeletesAtEndOfEvent;
/*! @todo EOEditingContext: stopsValidationAfterFirstError */
- (void)setStopsValidationAfterFirstError:(BOOL)flag;
- (BOOL)stopsValidationAfterFirstError;

// Returning related object stores
- (EOObjectStore *)parentObjectStore;
- (EOObjectStore *)rootObjectStore;

// Managing editors
- (NSArray *)editors;
- (void)addEditor:(id)anEditor;
- (void)removeEditor:(id)anEditor;

// Setting the delegate
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

// Setting the message handler
/*! @todo EOEditingContext: Message handlers */
- (void)setMessageHandler:(id)handler;
- (id)messageHandler;

// Invalidating objects
- (void)setInvalidatesObjectsWhenFreed:(BOOL)flag;
- (BOOL)invalidatesObjectsWhenFreed;

// NSLocking
- (void)lock;
- (BOOL)tryLock;
- (void)unlock;
- (void)lockObjectStore;
- (void)unlockObjectStore;

// Working with raw rows
- (id)faultForRawRow:(NSDictionary *)row entityNamed:(NSString *)entityName;
	
//	Unarchiving from nib
+ (EOObjectStore *)defaultParentObjectStore;
+ (void)setDefaultParentObjectStore:(EOObjectStore *)anObjectStore;
/*! @todo EOEditingContext: substitution editing contexts */
+ (void)setSubstitutionEditingContext:(EOEditingContext *)aContext;
+ (EOEditingContext *)substitutionEditingContext;

// Nested EOEditingContext support

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetch editingContext:(EOEditingContext *)editingContext;
- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name editingContext:(EOEditingContext *)anEditingContext;
- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext;
- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (void)saveChangesInEditingContext:(EOEditingContext *)childContext;
- (void)refaultObject: (id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs;
- (void)initializeObject:(id)object withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;


// EOUtilities
- (id)faultForGlobalID:(EOGlobalID *)anId;
- (id)objectForGlobalID:(EOGlobalID *)anId;

@end


@interface NSObject (EOEditor)

- (void)editingContextWillSaveChanges:(EOEditingContext *)editingContext;
- (BOOL)editorHasChangesForEditingContext:(EOEditingContext *)anEditingContext;

@end


@interface NSObject (EOMessageHandler)

- (void)editingContext:(EOEditingContext *)anEditingContext presentErrorMessage:(NSString *)message;
- (BOOL)editingContext:(EOEditingContext *)anEditingContext shouldContinueFetchingWithCurrentObjectCount:(unsigned)count originalLimit:(unsigned)limit objectStore:(EOObjectStore *)objectStore;

@end


@interface NSObject (EOEditingContextDelegate)

- (void)editingContextDidMergeChanges:(EOEditingContext *)anEditingContext;
- (NSArray *)editingContext:(EOEditingContext *)editingContext shouldFetchObjectsDescribedByFetchSpecification:(EOFetchSpecification *)fetchSpecification;
- (BOOL)editingContext:(EOEditingContext *)anEditingContext shouldInvalidateObject:(id)object globalID:(EOGlobalID *)globalID;
- (BOOL)editingContext:(EOEditingContext *)anEditingContext shouldMergeChangesForObject:(id)object;
- (BOOL)editingContext:(EOEditingContext *)anEditingContext shouldPresentException:(NSException *)exception;
- (BOOL)editingContextShouldUndoUserActionsAfterFailure:(EOEditingContext *)anEditingContext;
- (BOOL)editingContextShouldValidateChanges:(EOEditingContext *)anEditingContext;
- (void)editingContextWillSaveChanges:(EOEditingContext *)editingContext;

@end
