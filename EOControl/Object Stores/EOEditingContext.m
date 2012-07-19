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

#import "EOEditingContext.h"

#import "_EOWeakMutableDictionary.h"
#import "EODefines.h"
#import "EOFault.h"
#import "EOFetchSpecification.h"
#import "EOGenericRecordP.h"
#import "EOGlobalID.h"
#import "EOLog.h"
#import "EOObjectStore.h"
#import "EOObjectStoreCoordinator.h"
#import "EOObjectStoreCoordinatorP.h"
#import "EOQualifier.h"
#import "EOTemporaryGlobalID.h"
#import "NSClassDescription-EO.h"
#import "NSObject-EOEnterpriseObject.h"
#import "NSException-EO.h"

static EOObjectStore		*_eoDefaultObjectStore = nil;
static EOEditingContext	*_eoSubstitutionEditingContext = nil;

NSString *EOEditingContextDidSaveChangesNotification = @"EOEditingContextDidSaveChangesNotification";

@implementation EOEditingContext

- (id)init
{
	return [self initWithParentObjectStore:[[self class] defaultParentObjectStore]];
}

- (id)initWithParentObjectStore:(EOObjectStore *)anObjectStore
{
	self = [super init];
   
	// mont_rothstein @ yahoo.com 2005-01-07
	// I made the objects dictionary weak again.  The EOs now tell their editing context
	// to forget them when they are deallocing.
	objects = [[_EOWeakMutableDictionary allocWithZone:[self zone]] init];
	objectGlobalIDs = [[NSMutableDictionary allocWithZone:[self zone]] init];

   updatedObjects = [[NSMutableDictionary allocWithZone:[self zone]] init];
   updatedCache = [[NSMutableArray allocWithZone:[self zone]] init];
   insertedObjects = [[NSMutableDictionary allocWithZone:[self zone]] init];
   insertedCache = [[NSMutableArray allocWithZone:[self zone]] init];
   deletedObjects = [[NSMutableDictionary allocWithZone:[self zone]] init];
   deletedCache = [[NSMutableArray allocWithZone:[self zone]] init];
   updatedQueue = [[NSMutableDictionary allocWithZone:[self zone]] init];
   deletedQueue = [[NSMutableDictionary allocWithZone:[self zone]] init];
   insertedQueue = [[NSMutableDictionary allocWithZone:[self zone]] init];

   objectStore = [anObjectStore retain];
	
	undoManager = [[NSUndoManager allocWithZone:[self zone]] init];
	// undoObjects tracks object undos. This is kind of like out the undo manager tracks the changes, but since each time an object changes, we could have an undo, and that could chew through a lot of memory fast, we note when the object first changes and create a "snapshot" of the object at the first change. These are stored in undoObjects. Then, just a single undo action is registered with the undo manager. The undoObjects cache is reset to empty each time processRecentChanges is called.
	undoObjects = [[NSMutableDictionary allocWithZone:[self zone]] init];
	// mont_rothstein @ yahoo.com 2005-07-07
	// We don't need to start an initial group, this is done automatically.  Staring one here actually creates nested groups, which is a problem.
//	// Start an undo grouping immediately. New groupings are created / closed when processRecentChanges is called.
//	[undoManager beginUndoGrouping];
	isUndoingOrRedoing = NO;
	
	editors = [[NSMutableArray allocWithZone:[self zone]] init];
	
	// Tom.Martin @ Riemer.com 2011-08-22
	// lock was already created by the call to super init
	// lock = [[NSRecursiveLock allocWithZone:[self zone]] init];
	// lockCount = 0;

	// mont_rothstein @ yahoo.com 2005-07-11
	// Added registration for the EOObjectsChangedInStoreNotification notification
	// mont_rothstein @ yahoo.com 2005-08-08
	// Changed name of method called by notification to better reflect what it does.
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(_processChangedObjects:) 
			   name: EOObjectsChangedInStoreNotification 
			 object: nil];
	
	// mont_rothstein @ yahoo.com 2005-09-11
	// Added registration for the EOGlobalIDChangedNotification notification.
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(_changeGlobalIDs:)
			   name: EOGlobalIDChangedNotification
			 object: nil];
	
   return self;
}

- (void)dealloc
{
	if (invalidatesObjectsWhenFreed) {
		[self invalidateAllObjects];
	}
	
	// aclark @ ghoti.org 2005-07-24
	// we don't need to release lock here, it get's released in the EOObjectStore dealloc
	//	[lock release];
	[objects release];
	[objectGlobalIDs release];
	[updatedObjects release];
	[insertedObjects release];
	[deletedObjects release];
	[updatedQueue release];
	[deletedQueue release];
    [insertedQueue release];

    // tom.Martin @ Riemer.com 2012-02-01
    // inserted, updated and deletedCache was not being released
    [updatedCache release];
    [deletedCache release];
    [insertedCache release];
    
	[objectStore release];
	[undoManager release];
	[undoObjects release];
	[editors release];
	[messageHandler release];

	// mont_rothstein @ yahoo.com 2005-08-13
	// If we don't unregister for notifications then the notification center will try and send us notifications after we have gone.
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[super dealloc];
}


// mont_rothstein @ yahoo.com 2005-08-08
// Renamed this method to better reflect what it does.  Modified to correctly re-apply changes made in 
// this context to those made in the notifying context.  Added handling of invalidated objects.
// This is called as a result of the EOObjectsChangedInStoreNotification notification 
- (void)_processChangedObjects:(NSNotification *)notification
{
	NSArray *globalIDs;
	EOGlobalID *globalID;
	id object;
	NSDictionary *localChanges;
	
	// mont_rothstein @ yahoo.com 2005-09-19
	// Added skip if this editing context sent the notification.  Otherwise we re-fault our own objects and loose the changes.
	if ([notification object] == self) return;
	    
    // Tom.Martin @ Riemer.com 2012-05-10
    // on a delete
    // on a ddelete we need to remove the snapshot and also the object itself.  Removing
    // the object will have the side effect of removing the snapshot so ..
    globalIDs = [[notification userInfo] objectForKey: EODeletedKey];
    for (globalID in globalIDs)
	{
		object = [self objectForGlobalID: globalID];		
		if (object)
            [self forgetObject:object];
	}

	globalIDs = [[notification userInfo] objectForKey: EOUpdatedKey];
	
	for (globalID in globalIDs)
	{
		object = [self objectForGlobalID: globalID];
		
		if (!object) continue;
		
        [object retain];
		localChanges = [object changesFromSnapshot: [object snapshot]];
		
		[self refaultObject: object
			   withGlobalID: globalID
			 editingContext: self];
		
		if ([localChanges count]) [object reapplyChangesFromDictionary: localChanges];
        [object autorelease];
	}

	globalIDs = [[notification userInfo] objectForKey: EOInvalidatedKey];
	
	for (globalID in globalIDs)
	{
		object = [self objectForGlobalID: globalID];
		
		if (!object) continue;
        
        // if it is already a fault I see no point in attempting to re-fault
        if ([EOFault isFault:object])
            continue;

		[self refaultObject: object
			   withGlobalID: globalID
			 editingContext: self];
	}
}


// mont_rothstein @ yahoo.com 2005-09-11
// Added method to change globalIDs from temporary IDs to permanent ones
- (void)_changeGlobalIDs:(NSNotification *)notification
{
	NSDictionary *globalIDMappings;
	NSEnumerator *temporaryGlobalIDs;
	EOGlobalID *temporaryGlobalID;
	EOGlobalID *newGlobalID;
	NSObject *objectForIDs;
	
	globalIDMappings = [notification userInfo];
	temporaryGlobalIDs = [globalIDMappings keyEnumerator];
	
	while (temporaryGlobalID = (EOGlobalID *)[temporaryGlobalIDs nextObject])
	{
		newGlobalID = (EOGlobalID *)[globalIDMappings objectForKey: temporaryGlobalID];
		objectForIDs = [self objectForGlobalID: temporaryGlobalID];

		// Add the object under the new globalID
		[objects setObject: objectForIDs forKey: newGlobalID];
		[objectGlobalIDs setObject: newGlobalID 
							forKey: [NSValue valueWithPointer:objectForIDs]];
		
		// Remove the object under the temp globalID
		[objects removeObjectForKey: temporaryGlobalID];
	}
}


- (void)handleException:(NSException *)exception
{
	if (![delegate respondsToSelector:@selector(editingContext:shouldPresentException:)] || 
		 [delegate editingContext:self shouldPresentException:exception]) {
		if ([messageHandler respondsToSelector:@selector(editingContext:presentErrorMessage:)]) { 
			[messageHandler editingContext:self presentErrorMessage:[exception description]];
		} else {
			[exception raise];
		}
	}
}

+ (EOObjectStore *)defaultParentObjectStore
{
	if (_eoDefaultObjectStore == nil) return [EOObjectStoreCoordinator defaultCoordinator];
	return _eoDefaultObjectStore;
}

+ (void)setDefaultParentObjectStore:(EOObjectStore *)anObjectStore
{
	_eoDefaultObjectStore = anObjectStore;
}

+ (void)setSubstitutionEditingContext:(EOEditingContext *)aContext
{
	if (_eoSubstitutionEditingContext != aContext) {
		[_eoSubstitutionEditingContext release];
		_eoSubstitutionEditingContext = [aContext retain];
	}
}

+ (EOEditingContext *)substitutionEditingContext
{
	return _eoSubstitutionEditingContext;
}

- (void)lock
{
	[super lock];
	[self lockObjectStore];
}

- (BOOL)tryLock
{
	BOOL result = NO;
	if ([super tryLock])
	{
		result = YES;
		[self lockObjectStore];
	}
	return result;
}

- (void)unlock
{
	[super unlock];
	[self unlockObjectStore];
}

- (void)lockObjectStore
{
	if (objectStoreLockCount == 0) {
		[objectStore lock];
	}
	objectStoreLockCount++;
}

- (void)unlockObjectStore
{
	objectStoreLockCount--;
	if (objectStoreLockCount == 0) {
		[objectStore unlock];
	}
}

- (EOObjectStore *)rootObjectStore
{
	EOObjectStore		*aStore = objectStore;
	
	while (1) {
		if ([aStore respondsToSelector:@selector(parentObjectStore)]) {
			// This is just typecast to shut-up the compiler.
			aStore = [(EOEditingContext *)aStore parentObjectStore];
		} else {
			return aStore;
		}
	}
	
	return nil;
}

- (EOObjectStore *)parentObjectStore
{
	return objectStore;
}

- (void)forgetObject:(id)object
{
    EOGlobalID		*globalID = [self globalIDForObject:object];
	
    [object retain];
	[objects removeObjectForKey:globalID];
	// mont_rothstein @ yahoo.com 2005-05-15
	// The below line was moved to after we are done using the globalID in the methods below.
	//	[objectGlobalIDs removeObjectForKey:[NSValue valueWithPointer:object]];
	
	// Make sure we're not tracking the object in any other way...
	[updatedObjects removeObjectForKey:globalID];
	[updatedQueue removeObjectForKey:globalID];
	[insertedObjects removeObjectForKey:globalID];
	[insertedQueue removeObjectForKey:globalID];
	[deletedObjects removeObjectForKey:globalID];
	[deletedQueue removeObjectForKey:globalID];
    
    // Tom.Martin @ Riemer.com 2012-2-2
    // We also need to remove the object from the cache
    [insertedCache removeObject:object];
    [updatedCache removeObject:object];
    [deletedCache removeObject:object];
    
    [EOObserverCenter removeObserver:self forObject:object];
	[objectStore editingContext:self didForgetObject:object withGlobalID:globalID];
	[objectGlobalIDs removeObjectForKey:[NSValue valueWithPointer:object]];
    [object release];
}

- (void)recordObject:(id)object globalID:(EOGlobalID *)globalID;
{
   id				existing = [objects objectForKey:globalID];

	// Don't do anything if we already have the object.
   if (existing != nil) return;

   // mont_rothstein @ yahoo.com 2004-12-05
   // Moved the following two lines from after the if statement to before it.  The editing
   // context needs to store the object and its global ID before it is sent an awake method.
   [objects setObject:object forKey:globalID];
   [objectGlobalIDs setObject:globalID forKey:[NSValue valueWithPointer:object]];

   // mont_rothstein @ yahoo.com 2004-12-06
   // Moved this code to insertObject:withGlobalID: and fetchObject
   // This is both correct as per the WO 4.5 API, and necessary so that we can
   // call this method (recrodObject:globalID:) from places we don't want the awake
   // methods called, such as to replace the globalID after saving.
//   if ([globalID isTemporary]) {
//      [object awakeFromInsertionInEditingContext:self];
//   } else {
//      [object awakeFromFetchInEditingContext:self];
//   }
   [EOObserverCenter addObserver:self forObject:object];
}

// mont_rothstein @ yahoo.com 2005-07-11
// Implemented method
- (NSDictionary *)committedSnapshotForObject:(id)object
{
	EOObjectStoreCoordinator *rootObjectStore;
	EOGlobalID *globalID;
	
	rootObjectStore = (EOObjectStoreCoordinator *)[self rootObjectStore];
	globalID = [self globalIDForObject: object];
	
	// This is going to give a warning because snapshotForGlobalID: is in EOAccess on EODatabaseContext, which EOControl shouldn't know about.  I don't know how to get this without the warning.
	return [[rootObjectStore objectStoreForGlobalID:globalID] performSelector:@selector(snapshotForGlobalID:) withObject:globalID];
}

- (NSDictionary *)currentEventSnapshotForObject:(id)object
{
	return [undoObjects objectForKey:[self globalIDForObject:object]];
}

- (id)objectForGlobalID:(EOGlobalID *)globalID
{
	return [objects objectForKey:globalID];
}

- (EOGlobalID *)globalIDForObject:(id)object
{
	return [objectGlobalIDs objectForKey:[NSValue valueWithPointer:object]];
}

- (NSArray *)registeredObjects
{
	return [objects allValues];
}

- (void)lockObject:(id)object
{
	[EOLog logWarningWithFormat:@"WARNING: -[%C %S] unimplemented\n", self, _cmd];
}

- (void)lockObjectWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)editingContext;
{
	[EOLog logWarningWithFormat:@"WARNING: -[%C %S] unimplemented\n", self, _cmd];
}

- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)editingContext;
{
	[EOLog logWarningWithFormat:@"WARNING: -[%C %S] unimplemented\n", self, _cmd];
	return NO;
}

- (void)setLocksObjectsBeforeFirstModification:(BOOL)flag;
{
	[EOLog logWarningWithFormat:@"WARNING: -[%C %S] unimplemented\n", self, _cmd];
}

- (BOOL)locksObjectsBeforeFirstModification;
{
	[EOLog logWarningWithFormat:@"WARNING: -[%C %S] unimplemented\n", self, _cmd];
	return NO;
}

/*! @todo Appear to be deprecated */
#if 0
- (NSArray *)objectsFromDictionary:(NSDictionary *)dictionary into:(NSMutableArray *)array withFetchSpecification:(EOFetchSpecification *)fetch
{
	EOEntity			*entity = [[EOModelGroup defaultModelGroup] entityNamed:[fetch entityName]];
	NSEnumerator	*enumerator = [dictionary objectEnumerator];
	id					object;
	EOQualifier		*qualifier = [fetch qualifier];
	
   //[EOLog logWithFormat:@"Entity = %@\n", [entity name]];
	while ((object = [enumerator nextObject])) {
      // [EOLog logWithFormat:@"%@ %@\n", object, [[object entity] name]];
	   // mont_rothstein @ yahoo.com 2004-12-06
	   // Changed to get the entity from the class description.
		if ([[object classDescription] entity] == entity && [qualifier evaluateWithObject:object]) {
			[array addObject:object];
		}
	}
	
	return array;
}

- (NSArray *)objectsFromInsertedObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
   NSMutableArray	*array = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];

   [self objectsFromDictionary:insertedObjects into:array withFetchSpecification:fetch];
   [self objectsFromDictionary:insertedQueue into:array withFetchSpecification:fetch];

   return array;
}
#endif

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
	return [self objectsWithFetchSpecification:fetch editingContext:self];
}

- (void)objectWillChange:(id)object
{
    EOGlobalID	*globalID = [self globalIDForObject:object];
    
    // Tom.Martin @ Riemer.com 2012-04-25
    // I think we only want to add this object to the updated cache IF
    // it is not already in the inserted, deleted, or updated Queue
    //if (
   if (![updatedQueue objectForKey:globalID]) {
       [updatedQueue setObject:object forKey:globalID];
       [updatedCache removeAllObjects]; // Invalidate cache.
   }
	
	// See about tracking undo / redo.
	if (undoManager && !isUndoingOrRedoing) {
		// Only track if we have an undo manager and we're not in the process of doing a undo/redo.
		if (![undoObjects objectForKey:globalID]) {
			// Record the state of the object, as it exists at the begin of the loop
			[undoObjects setObject:[object snapshot] forKey:globalID];
		}
	}
}

// add information to our toManyUpdatedMembers store, the status can only be added or removed
// so if added is NO then it is a removed member
- (void)_recordToManyMemberAdded:(BOOL)added member:(EOGlobalID *)memberGid 
                  owner:(EOGlobalID *)ownerGid 
        relationshipName:(NSString *)relationshipName
{
    NSMutableDictionary *memberInfo;
    NSMutableDictionary *change;
    NSMutableArray *anArray;
    
    // first check to see if the member is already in there
    memberInfo = [toManyUpdatedMembers objectForKey:memberGid];
    if (! memberInfo)
    {
        // it wasn't there, add it
        // structure is MutableDictionary with two keys.
        // (removed, added) the values for these are NSMutableArrays
        memberInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
        [memberInfo setObject:[NSMutableArray arrayWithCapacity:5] forKey:@"removed"];
        [memberInfo setObject:[NSMutableArray arrayWithCapacity:5] forKey:@"added"];
        [toManyUpdatedMembers setObject:memberInfo forKey:memberGid];
        [memberInfo release];
    }
    
    // create the dictionary describing the change
    // structure is:
    // key: ownerEntityName
    // key: relationshipName
    // key: ownerGID (string key not object)
    // THIS dictionary does not need to be mutable
    change = [NSDictionary dictionaryWithObjectsAndKeys:[ownerGid entityName], @"ownerEntityName",
              relationshipName, @"relationshipName",
              ownerGid, @"ownerGID", nil];
    if (added)
        anArray = [memberInfo objectForKey:@"added"];
    else
        anArray = [memberInfo objectForKey:@"removed"];
    [anArray addObject:change];
}

- (NSDictionary *)toManyChangesForMemberGlobalId:(EOGlobalID *)aGID
{
    return [toManyUpdatedMembers objectForKey:aGID];
}

-(void)_processRecentChanges
{
    NSEnumerator	*iterator;
    EOGlobalID	*globalID;
    
    iterator = [insertedQueue keyEnumerator];
    while ((globalID = [iterator nextObject]))
        [insertedObjects setObject:[insertedQueue objectForKey:globalID] forKey:globalID];
    [insertedQueue removeAllObjects];
	[insertedCache removeAllObjects];
    
    iterator = [deletedQueue keyEnumerator];
    while ((globalID = [iterator nextObject]))
        [deletedObjects setObject:[deletedQueue objectForKey:globalID] forKey:globalID];
    [deletedQueue removeAllObjects];
	[deletedCache removeAllObjects];
    
    iterator = [updatedQueue keyEnumerator];
    while ((globalID = [iterator nextObject]))
    {
        if (![insertedObjects objectForKey:globalID] &&
            ![deletedObjects objectForKey:globalID] &&
            ![updatedObjects objectForKey:globalID]) 
        {
            [updatedObjects setObject:[updatedQueue objectForKey:globalID] forKey:globalID];
        }
    }
    [updatedQueue removeAllObjects];
	[updatedCache removeAllObjects]; // Invalidate the cache.
}


- (void)processRecentChanges
{
    NSDictionary *userInfo;

    [self _processRecentChanges];
    
	// mont_rothstein @ yahoo.com 2005-09-19
	// Added post of notification as per API.  This is needed particularly for changes that aren't saved (like adding objects to a to-many relationship).  However the WO docs do not make it clear what happens if the save fails.  When this notification is posted for changes actually saved to the DB it happens after the save has succeeded.
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys: [insertedObjects allKeys], EOInsertedKey, [updatedObjects allKeys], EOUpdatedKey, [deletedObjects allKeys], EODeletedKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: EOObjectsChangedInStoreNotification object: self userInfo: userInfo];
    [userInfo autorelease];

	// Reset the undos, if necessary.
	if (undoManager) 
    {
        EOGlobalID			*key;
		NSArray				*keys = [undoObjects allKeys];
		NSEnumerator		*enumerator = [keys objectEnumerator];

		while ((key = [enumerator nextObject])) 
        {
			id				object = [self objectForGlobalID:key];
			NSDictionary	*snapshot = [undoObjects objectForKey:key];

			[undoManager registerUndoWithTarget:object 
                selector:@selector(reapplyChangesFromDictionary:) 
                object:[object changesFromSnapshot:snapshot]];
		}
		
		// mont_rothstein @ yahoo.com 2005-10-23
		// This previously called levelsOfUndo which was incorrect and meant that the undoObjects were never cleared.  Chanced to call groupingLevel.
		// mont_rothstein @ yahoo.com 2005-09-10
		// If save has been called with no changes then there is no undo grouping to end 
		if ([undoManager groupingLevel] == 0) return;
		
		[undoManager endUndoGrouping];	// End the previous grouping.
		[undoObjects removeAllObjects];	// Remove the coallescing cache.
		[undoManager beginUndoGrouping];	// And start a new grouping.
	}
}

// We need to check to-one and to-many relationships against the current objet graph.
// we do this for all objects in the updated and in inserted (only for added to-manys)
// 1) If a to-one has bee nulled and it is owned, then the object needs to be deleted.
// 2) if there are new objects in a to-many, and they are not newly inserted then they 
//    go into added.
// 3) if there are objects MISSING from a to-many, then if they are owned they need to
//    be deleted, if not, they go into removed.
//
// we will also build the added,removed array in EOEditingContext and
// ACCESS it from the database context.  the database context could then check each 
// member to see if it owns it, before updating values based upon the releationship join
//
// I think we want to create the following structure where information about
// relationship member object changes can be stored.  So that in databaseContext
// when the new row is created databaseContext can retrieve this information so
// that these relationships can be updated correctly.  By storing this in the
// editingContext we can make ONE PASS through all objects and have the databaseContext
// simply ask for changes on objects that it owns.  THe OWNER objects may be
// in a different databaseContext and that is just fine.
//
//  <dict>
//     <key>@BillingGID</key>
//     <dict>
//          <key>removed</key>
//          <array>
//              <dict>
//                  <key>ownerEntityName</key>
//                  <string>INVOICE</string>
//                  <key>relationshipName</key>
//                  <string>billings</string>
//                  <key>ownerGID</key>
//                  <object>@GID</object>
//              </dict>
//          </array>
//          <key>added</key>
//          <array>
//              <dict>
//                  <key>ownerEntityName</key>
//                  <string>INVOICE</string>
//                  <key>relationshipName</key>
//                  <string>billings</string>
//                  <key>ownerGID</key>
//                  <object>@GID</object>
//              </dict>
//          </array>
//     </dict>
//     <key>@AccountGID</key>
//     <dict>
//          <key>removed</key>
//          .....
//      </dict>
//  </dict>
//
// The above example may happen if a member was removed from one owner and added to another for the
// same relationship.  We would need to do another pass and look through added for each updated
// object and see if the same entity/relationship exists in removed.  if so, entry in removed 
// needs to be err removed.  THis is because depending upon the order of operations you could
// end up nulifying a relationship that should be an add.
- (void)_processRelationships
{
    NSMutableArray      *added;
    NSMutableArray      *removed;
    NSMutableArray      *deleted;
    EOGlobalID          *aGid;
    NSObject            *object;
    NSDictionary        *aDict;
    NSArray             *localInsertedObjects;
    NSArray             *localUpdatedObjects;
    
    added =     [[NSMutableArray alloc] init];
    removed =   [[NSMutableArray alloc] init];
    deleted =   [[NSMutableArray alloc] init];
    
    // make sure our information store is okay, which it SHOULD be but, we will check
    if ([toManyUpdatedMembers count])
    {
        [toManyUpdatedMembers release];
        toManyUpdatedMembers = nil;
    }
    if (! toManyUpdatedMembers)
        toManyUpdatedMembers = [[NSMutableDictionary alloc] init];
    
    // store inserted and updated objects so we don't have to call that more than once.
    // This should ONLY be called after processRecentChanges!!
    [self _processRecentChanges];
    localInsertedObjects = [[self insertedObjects] retain];
    localUpdatedObjects = [[self updatedObjects] retain];
    
    // build arrays of all added, removed and deleted objects
    // updatedObjects
    [localUpdatedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSClassDescription  *classDescription = [obj classDescription];
         NSDictionary        *changes;
         NSDictionary        *dict;
         id                  keyEnum;
         EOGlobalID          *gid;
         
         changes = [[classDescription relationshipChangesForObject:obj withEditingContext:self] retain];
         dict = [changes objectForKey:@"added"];
         // added is a dictionary of keys (globalIDs) and value = dict with keys ownerGID, relationshipName
         if (dict)
         {   
             [dict enumerateKeysAndObjectsUsingBlock:^(id member, id memberDict, BOOL *stop)
              {
                  [added addObject:member];
                  EOGlobalID *ownerGid = [memberDict objectForKey:@"ownerGID"];
                  NSString *relationshipName = [memberDict objectForKey:@"relationshipName"];
                  [self _recordToManyMemberAdded:YES member:member 
                                           owner:ownerGid 
                                relationshipName:relationshipName];
              }];
         }
         dict = [changes objectForKey:@"removed"];
         if (dict)        
         {   
             [dict enumerateKeysAndObjectsUsingBlock:^(id member, id memberDict, BOOL *stop)
              {
                  [removed addObject:member];
                  EOGlobalID *ownerGid = [memberDict objectForKey:@"ownerGID"];
                  NSString *relationshipName = [memberDict objectForKey:@"relationshipName"];
                  [self _recordToManyMemberAdded:NO member:member 
                                           owner:ownerGid 
                                relationshipName:relationshipName];
                  
              }];
         }
         
         for (gid in [changes objectForKey:@"deleted"])
         {   
             [deleted addObject:gid];
         }
         [changes release];
     }];
    
    // do the same for inserted objects but only for added
    [localInsertedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSClassDescription  *classDescription = [obj classDescription];
         NSDictionary        *changes;
         NSDictionary        *dict;
         id                  keyEnum;
         EOGlobalID          *gid;
         
         changes = [classDescription relationshipChangesForObject:obj withEditingContext:self];
         dict = [changes objectForKey:@"added"];
         // added is a dictionary of keys (globalIDs) and value = dict with keys ownerGID, relationshipName
         if (dict)
         {   
             [dict enumerateKeysAndObjectsUsingBlock:^(id member, id memberDict, BOOL *stop)
              {
                  [added addObject:member];
                  EOGlobalID *ownerGid = [memberDict objectForKey:@"ownerGID"];
                  NSString *relationshipName = [memberDict objectForKey:@"relationshipName"];
                  [self _recordToManyMemberAdded:YES member:member 
                                           owner:ownerGid 
                                relationshipName:relationshipName];
              }];
         }
     }];
    
    [localInsertedObjects release];
    [localUpdatedObjects release];
    // now we want flag these objects as updated or deleted in our editing context
    // if we that is what is called for.
    // deleted
    //    check in added, if they are not there then send to self delete.
    // removed
    //    check in added, if not there then touch object (willChange)
    // added
    //    check in insertedObjects, if not there, then touch object (willChange)
    //    on second thought why bother, just touch object
    if ([deleted count])
    {
        id iterator;
        
        for (aGid in deleted)
        {
            if (! [added containsObject:aGid])
            {
                object = [self objectForGlobalID:aGid];
                if (! object)
                {
                    // looks like this object has left the scene.
                    // lets try to get it back.
                    object = [self faultForGlobalID:aGid editingContext:self];
                    // and fire the fault, but if the object is REALY gone, then thats just fine
                    NS_DURING
                    [object self];
                    NS_HANDLER
                    NSLog(@"WARNING(%s), Deleted relationship member %@ no longer in context, failed to refetch.", __PRETTY_FUNCTION__, aGid);
                    object = nil;
                    NS_ENDHANDLER
                }
                if (object)
                    [self deleteObject:object];
            }
        }
     }
    
    
    for (aGid in removed)
    {
        if (! [added containsObject:aGid])
        {
            object = [self objectForGlobalID:aGid];
            if (! object)
            {
                // looks like this object has left the scene.
                // lets try to get it back.
                object = [self faultForGlobalID:aGid editingContext:self];
                // and fire the fault, but if the object is REALY gone, then thats just fine
                NS_DURING
                [object self];
                NS_HANDLER
                NSLog(@"WARNING(%s), Removed relationship member %@ no longer in context, failed to refetch.", __PRETTY_FUNCTION__, aGid);
                object = nil;
                NS_ENDHANDLER
            }
            if (object)
            {
                // put object into updated
                [object willChange];
            }
        }
    }
    
    for (aGid in added)
    {
        object = [self objectForGlobalID:aGid];
        if (object)
            // put object into updated
            [object willChange];
    }
    
    [added release];
    [removed release];
    [deleted release];
}

- (void)_sendSelector:(SEL)selector toObjects:(NSMutableDictionary *)someObjects moveTo:(NSMutableDictionary *)other
{
   NSEnumerator	*enumerator = [someObjects objectEnumerator];
   id					object;

   while ((object = [enumerator nextObject])) {
      [object performSelector:selector];
      if (other != nil) {
         [other setObject:object forKey:[self globalIDForObject:object]];
      }
   }
   if (other) {
      [someObjects removeAllObjects];
   }
}

- (NSException *)_mergeException:(NSException *)exception with:(NSException *)baseException
{
	// No exception occured, just return the base.
	if (exception == nil) return baseException;
	
	// Base hasn't yet been initialized, so it becomes exception.
	if (baseException == nil) return exception;
	
	// Only one exception has occured, so it's not yet an aggregate exception. Make it one.
	if (![[baseException name] isEqualToString:EOAggregateException]) {
		baseException = [NSException aggregateExceptionWithException:baseException];
	}
	
	// Add the exception to the aggreate.
	[baseException addException:exception];
	
	return baseException;
}

- (NSException *)_sendExceptionSelector:(SEL)selector toObjects:(NSMutableDictionary *)someObjects moveTo:(NSMutableDictionary *)other into:(NSException *)exception
{
   NSEnumerator	*enumerator = [someObjects objectEnumerator];
   id					object;

   while ((object = [enumerator nextObject])) {
      exception = [self _mergeException:[object performSelector:selector] with:exception];
      if (other != nil) {
         [other setObject:object forKey:[self globalIDForObject:object]];
      }
   }
   if (other) {
      [someObjects removeAllObjects];
   }
	
	return exception;
}

/*!
 * Implements the first phase of saving changes, which still allows for the
 * update, insertion, and deletion of objects. Doing any of these three
 * operations after this method may cause unexpected behavior.
 *
 * This will first send each object the method:
 * <UL>
 *     <LI>prepareForUpdate()</LI>
 *     <LI>prepareForInsert()</LI>
 *     <LI>prepareForDelete()</LI>
 * </UL>
 *
 * This will also be followed by a prepareForSave() method.
 *
 * Under simple circumstances, these methods will only be called once. They
 * can be called multiple times if the object is modified by another object
 * during this process. Regardless, prepareForSave() will only be called
 * once for each of the other three methods listed above, but will be
 * called a second time if one of the above methods is called a second time.
 *
 * For example: We save our objects and a myObject receives a prepareForUpdate()
 * and a prepareInsert() method. It will then receive a prepareForSave() method.
 * Then, during this cycle, joesObject causes us to be further modified. That
 * will cause myObject to receive another prepareForUpdate() and prepareForSave()
 * call, but not another prepareForInsert() call, because we can't be inserted
 * a second time.
 */
- (void)sendPrepareMessages
{
   BOOL						done = NO;

   // First, process through each of the three arrays once, then we proceed to the queues
   [self _sendSelector:@selector(prepareForSave) toObjects:updatedObjects moveTo:nil];
   [self _sendSelector:@selector(prepareForInsert) toObjects:insertedObjects moveTo:nil];
   [self _sendSelector:@selector(prepareForDelete) toObjects:deletedObjects moveTo:nil];
   
   // mont_rothstein @ yahoo.com 2005-02-09
   // Changed the selectors below to call the selector specific to the queue.  They had
   // all been calling prepareForDelete.
   while (!done) {
      done = YES;
      if ([deletedQueue count]) {
         [self _sendSelector:@selector(prepareForDelete) toObjects:deletedQueue moveTo:deletedObjects];
         done = NO;
      }
      if ([insertedQueue count]) {
         [self _sendSelector:@selector(prepareForInsert) toObjects:insertedQueue moveTo:insertedObjects];
         done = NO;
      }
      if ([updatedQueue count]) {
         [self _sendSelector:@selector(prepareForUpdate) toObjects:updatedQueue moveTo:updatedObjects];
         done = NO;
      }
   }
}

/*!
 * Causes the objects to validate. The validation methods should not cause
 * objects to be inserted or deleted. If you do, this changes may or may not
 * be committed to the database. You may update objects.
 */
- (void)sendValidateMethods
{
   BOOL				done = NO;
	NSException		*exception = nil;

   isValidating = YES;
   
   // First, process through each of the three arrays once, then we proceed to the queues
   exception = [self _sendExceptionSelector:@selector(validateForSave) toObjects:updatedObjects moveTo:nil into:exception];
   exception = [self _sendExceptionSelector:@selector(validateForInsert) toObjects:insertedObjects moveTo:nil into:exception];
   exception = [self _sendExceptionSelector:@selector(validateForDelete) toObjects:deletedObjects moveTo:nil into:exception];

   while (!done) {
      done = YES;
      if ([deletedQueue count]) {
         exception = [self _sendExceptionSelector:@selector(validateForDelete) toObjects:deletedQueue moveTo:deletedObjects into:exception];
         done = NO;
      }
      if ([insertedQueue count]) {
         exception = [self _sendExceptionSelector:@selector(validateForInsert) toObjects:insertedQueue moveTo:insertedObjects into:exception];
         done = NO;
      }
      if ([updatedQueue count]) {
         exception = [self _sendExceptionSelector:@selector(validateForSave) toObjects:updatedQueue moveTo:updatedObjects into:exception];
         done = NO;
      }
   }
	
	if (exception) [self handleException:exception];

   isValidating = NO;
}

- (BOOL)hasChanges
{
   [self processRecentChanges];
   return ([updatedObjects count] != 0 ||
           [insertedObjects count] != 0 ||
           [deletedObjects count] != 0);
}

- (void)_notifyEditorsOfSave
{
	int				x;
	int numEditors;
	
	numEditors = [editors count];
	
	for (x = 0; x < numEditors; x++) {
		id		editor = [editors objectAtIndex:x];
		
		if ([editor respondsToSelector:@selector(editingContextWillSaveChanges:)]) {
			[editor editingContextWillSaveChanges:self];
		}
	}
}

- (void)saveChanges
{
	if ([delegate respondsToSelector:@selector(editingContextWillSaveChanges:)]) {
		[delegate editingContextWillSaveChanges:self];
	}
	
	// Notify our editors of a pending save.
	[self _notifyEditorsOfSave];
	
    // Tom.Martin @ Riemer.com
    // put any objects in relationships that may need to be updated into our editing context
    // this does not actually modify anything just looks at relationships that have changed and 
    // puts the member objects that have been added or removed into the editing context.
    // it also builds the toManyUpdatedMembers dictionary
    [toManyUpdatedMembers release];
    toManyUpdatedMembers = [[NSMutableDictionary alloc] init];
    [self _processRelationships];
    
    // object may have been marked as updated by _processRelationships
    [self processRecentChanges];
    [self sendPrepareMessages];
   // The above should be written such that a second call to processRecentChanges isn't necessary.
	
    // Tom.Martin @ Riemer.com 2012-2-14
    // Logic error is here with if statement.  Fixed it up.
	//if (![delegate respondsToSelector:@selector(editingContextShouldValidateChanges:)] || [delegate editingContextShouldValidateChanges:self]) {
	//	[self sendValidateMethods];
	//}
    if ([delegate respondsToSelector:@selector(editingContextShouldValidateChanges:)])
    {
        if ([delegate editingContextShouldValidateChanges:self])
            [self sendValidateMethods];
    }
    else
        [self sendValidateMethods];
	
	[objectStore saveChangesInEditingContext:self];

	// Let the object's do any post processing.
	[self _sendSelector:@selector(objectDidSave) toObjects:updatedObjects moveTo:nil];
	[self _sendSelector:@selector(objectDidSave) toObjects:insertedObjects moveTo:nil];
	[self _sendSelector:@selector(objectDidDelete) toObjects:deletedObjects moveTo:nil];
    
    // aclark @ ghoti.org 2006-01-02
    // add post of EOEditingContextDidSaveChangesNotification after objectStore has saved the changes per EOControl spec
    // Tom.Martin @ Riemer.com 2012-02-01
    // moved this to BEFORE the contents of updated,inserted, and deletedObjects are removed.
    [[NSNotificationCenter defaultCenter] postNotificationName:EOEditingContextDidSaveChangesNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[updatedObjects allValues], EOUpdatedKey, [insertedObjects allValues], EOInsertedKey, [deletedObjects allValues], EODeletedKey, nil]];
    
	// We succeeded, so we can discard the various state trackers.
	[updatedObjects removeAllObjects];
	[insertedObjects removeAllObjects];
	[deletedObjects removeAllObjects];
	// Invalidate the cache.
	[updatedCache removeAllObjects];
	[insertedCache removeAllObjects];
	[deletedCache removeAllObjects];
    
    [toManyUpdatedMembers release];
    toManyUpdatedMembers = nil;
    
	// And clear out the undo stack. It's possible to maintain this over saves, but somewhat difficult (I think), so I'm not going to worry about it for the time being.
	if (undoManager) {
		[undoManager removeAllActions];
		// mont_rothstein @ yahoo.com 2005-07-07
		// We don't need to start an initial group, this is done automatically.  Staring one here actually creates nested groups, which is a problem.
//		// mont_rothstein @ yahoo.com 2004-11-15
//		// Since we just cleared out the undoManager we need to start a new group.
//		// Otherwise when we go to save we will add a group that hasn't been started.
//		[undoManager beginUndoGrouping];	// And start a new grouping.
	}
}

- (void)saveChanges:(id)sender
{
	// Tom.Martin @ riemer.com 2011-08-17
	// Added support for the mesageHandler.
	NS_DURING
		[self saveChanges];
	NS_HANDLER
		[self handleException:localException];
	NS_ENDHANDLER
}

- (NSException *)tryToSaveChanges
{
	NS_DURING
		[self saveChanges];
	NS_HANDLER
		return [[localException retain] autorelease];
	NS_ENDHANDLER
	
	return nil;
}

- (void)revert
{
	// Make sure we're in a valid state to do this. This could possibly be avoided, but it's easier to just make sure we're in a sane state.
	[self processRecentChanges];
	
	// Don't need to listen to anything, since we're going to discard all changes in the undo manager anyways.
	[undoManager disableUndoRegistration];
	
	// Loop over the updated objects and make them revert.
	[self lockObjectStore];
	NS_DURING
		// mont_rothstein @ yahoo.com 2005-07-11
		// This is specifically not supposed to call invalidateAllObjects, it is supposed
		// to revert updated objects back to there last committed values.
        //	[objectStore invalidateAllObjects];
		NSEnumerator *updatedObjectsEnumerator;
		NSObject *nextUpdatedObject;
		NSDictionary *committedSnapshot;
        NSDictionary *snapshot;

		updatedObjectsEnumerator = [updatedObjects objectEnumerator];
		
		while (nextUpdatedObject = [updatedObjectsEnumerator nextObject])
		{
			committedSnapshot = [self committedSnapshotForObject: nextUpdatedObject];
            // Tom.Martin @ Riemer.com 2012-3--27
            // This WAS using commited snapshot which is a database snapshot.  This snapshot
            // does not have enough information to revert an object.  I added the folowing
            // class description method to convert a database snapshot into a full
            // undo snapshot.
            snapshot = [[self classDescription] snapshotFromDBSnapshot:committedSnapshot forObject:nextUpdatedObject];
			[nextUpdatedObject updateFromSnapshot: snapshot];
		}
		
		[updatedObjects removeAllObjects];
	NS_HANDLER
		[self unlockObjectStore];
		[undoManager enableUndoRegistration];
		[undoManager removeAllActions];
		[self handleException:localException];
		return;
	NS_ENDHANDLER
	[self unlockObjectStore];
	
	// Remove all inserted and deleted objects. We just discard these, since we should no longer be referencing them in our updated objects, since those were reverted first.
	[insertedObjects removeAllObjects];
	[deletedObjects removeAllObjects];
	
	// And clear out the undo stack. It's possible to maintain this over reverts, but somewhat difficult (I think), so I'm not going to worry about it for the time being.
	[undoManager enableUndoRegistration];
	[undoManager removeAllActions];
}

- (void)revert:(id)sender
{
	[self revert];
}

- (void)invalidateAllObjects
{
	[self lockObjectStore];
	NS_DURING
		// mont_rothstein @ yahoo.com 2005-09-10
		// This had been sending invalidateAllObjects to the objectStore, which caused all objects in memory to be invalidated, not just those in this editing context.
		[self invalidateObjectsWithGlobalIDs: [objects allKeys]];
	NS_HANDLER
		[self unlockObjectStore];
		[self handleException:localException];
	NS_ENDHANDLER
	[self unlockObjectStore];
}

- (void)insertObject:(id)object
{
	EOTemporaryGlobalID		*globalID;
	
	globalID = [[EOTemporaryGlobalID allocWithZone:[object zone]] initWithEntityName:[object entityName]];
	[self insertObject:object withGlobalID:globalID];
	[globalID release];
}

- (void)insertObject:(id)object withGlobalID:(EOGlobalID *)globalID;
{
   if (isValidating) {
      [NSException raise:EOException format:@"Interal Error: You have attempted to insert an object during validation. This is not permitted. Please see the prepareFor...() Methods."];
   }
	
	// mont_rothstein @ yahoo.com 2005-02-17
	// Added a call to request the object store for this object.  We don't actually need
	// it here, but if we don't ask for it here it might not be available when we go to 
	// save later.
	[[NSNotificationCenter defaultCenter] postNotificationName:EOCooperatingObjectStoreNeeded object:objectStore userInfo:[NSDictionary dictionaryWithObjectsAndKeys:globalID, @"globalID", nil]];

	[self recordObject:object globalID:globalID];

	// mont_rothstein @ yahoo.com 2004-12-06
	// Mode the below call to awakeFromInsertionInEditingContext: from recordObject:globalID:
	if ([globalID isTemporary]) [object awakeFromInsertionInEditingContext:self];
	
	[insertedQueue setObject:object forKey:globalID];
	[insertedCache removeAllObjects]; // Invalidate cache.
	
	if (undoManager) {
		[undoManager registerUndoWithTarget:self selector:@selector(_undoObjectInsert:) object:object];
	}
}

- (void)_undoObjectInsert:(id)object
{
	// And stop tracking the object.
	[self forgetObject:object];
	if (undoManager) {
		[undoManager registerUndoWithTarget:self selector:@selector(_redoObjectInsert:) object:object];
	}
}

- (void)_redoObjectInsert:(id)object
{
	[self insertObject:object];
}

- (void)_undoObjectDelete:(id)object
{
	EOGlobalID		*globalID = [self globalIDForObject:object];
	
	// Remove from the deleted caches.
	[deletedObjects removeObjectForKey:globalID];
	[deletedQueue removeObjectForKey:globalID];
	
	// And setup the redo action.
	if (undoManager) {
		[undoManager registerUndoWithTarget:self selector:@selector(_redoObjectDelete:) object:object];
	}
}

- (void)_undoObjectDeleteViaInsert:(id)object
{
	EOGlobalID		*globalID = [self globalIDForObject:object];
	
	// Remove from the deleted caches.
	[deletedObjects removeObjectForKey:globalID];
	[deletedQueue removeObjectForKey:globalID];
	
	// The object had be inserted, so insert it back into the insertedQueue. This doesn't go directly into the insertedObjects dictionary.
	[insertedQueue setObject:object forKey:globalID];
	[insertedCache removeAllObjects]; // Invalidate cache.
	
	// And setup the redo action.
	if (undoManager) {
		[undoManager registerUndoWithTarget:self selector:@selector(_redoObjectDelete:) object:object];
	}
}

- (void)_redoObjectDelete:(id)object
{
	[self deleteObject:object];
}

- (void)deleteObject:(id)object
{
	EOGlobalID		*globalID;
	BOOL				wasInserted = NO;
	
   if (isValidating) {
      [NSException raise:EOException format:@"Interal Error: You have attempted to delete an object during validation. This is not permitted. Please see the prepareFor...() Methods."];
   }
	
	globalID = [self globalIDForObject:object];
	
	// If the object had previously been inserted, then we just "uninsert" it.
	if ([insertedQueue objectForKey:globalID] || [insertedObjects objectForKey:globalID]) {
		[insertedQueue removeObjectForKey:globalID];
		[insertedObjects removeObjectForKey:globalID];
		wasInserted = YES;
		// Note that we don't unregister the object. That'll happen after the save, since we're still concerned about the object up to the point where it will no longer exist in the database.
	}
    
	[deletedQueue setObject:object forKey:globalID];
	[deletedCache removeAllObjects]; // Invalidate cache.
	
	// mont_rothstein @ yahoo.com 2005-04-10
	// Added code to propagate deletes
	[object propagateDeleteWithEditingContext: self];
	
	if (undoManager) {
		[undoManager registerUndoWithTarget:self 
											selector:wasInserted ? @selector(_undoObjectDeleteViaInsert:) : @selector(_undoObjectDelete:) 
											  object:object];
	}
}

- (id)faultForGlobalID:(EOGlobalID *)anId
{
	// mont_rothstein @ yaho0.com 2005-08-10
	// Modified this to be a cover method for faultForGlobalID:editingContext:
//   id		object = [objects objectForKey:anId];
//
//   if (!object) {
//      object = [EOFault createObjectFaultWithGlobalID:anId inEditingContext:self];
//   }
//
//   return object;
   return [self faultForGlobalID: anId editingContext: self];
}


- (NSArray *)updatedObjects
{
	if ([updatedCache count] == 0) {
		[updatedCache addObjectsFromArray:[updatedObjects allValues]];
		[updatedCache addObjectsFromArray:[updatedQueue allValues]];
	}
	
   return updatedCache;
}

- (NSDictionary *)_insertedObjects
{
	return insertedObjects;
}

- (NSArray *)insertedObjects
{
	if ([insertedCache count] == 0) {
		[insertedCache addObjectsFromArray:[insertedObjects allValues]];
		[insertedCache addObjectsFromArray:[insertedQueue allValues]];
	}

   return insertedCache;
}

- (NSArray *)deletedObjects
{
	if ([deletedCache count] == 0) {
		[deletedCache addObjectsFromArray:[deletedObjects allValues]];
		[deletedCache addObjectsFromArray:[deletedQueue allValues]];
	}
	
   return deletedCache;
}

- (void)refaultObjects
{
   NSArray				*keys = [objects allKeys];
   EOGlobalID			*globalID;
   int					x;
   int numKeys;
   
   [self processRecentChanges];

   numKeys = [keys count];
   
   for (x = 0; x < numKeys; x++) {
      globalID = [keys objectAtIndex:x];
      [objectStore refaultObject:[objects objectForKey:globalID] withGlobalID:globalID editingContext:self];
   }
}

- (void)refault:(id)sender
{
	[self refaultObjects];
}

- (void)refetch:(id)sender
{
	[self invalidateAllObjects];
}

- (void)undo:(id)sender
{
	isUndoingOrRedoing = YES;
	[undoManager undo];
	isUndoingOrRedoing = NO;
}

- (void)redo:(id)sender
{
	isUndoingOrRedoing = YES;
	[undoManager redo];
	isUndoingOrRedoing = NO;
}

- (void)setUndoManager:(NSUndoManager *)aManager
{
	if (undoManager != aManager) {
		[undoManager release];
		undoManager = [aManager retain];
	}
}

- (NSUndoManager *)undoManager
{
	return undoManager;
}

- (void)setPropagatesDeletesAtEndOfEvent:(BOOL)flag
{
	propagatesDeletesAtEndOfEvent = flag;
}

- (BOOL)propagatesDeletesAtEndOfEvent
{
	return propagatesDeletesAtEndOfEvent;
}

- (void)setStopsValidationAfterFirstError:(BOOL)flag
{
	stopsValidationAfterFirstError = flag;
}

- (BOOL)stopsValidationAfterFirstError
{
	return stopsValidationAfterFirstError;
}

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext
{
	NSArray		*fault;
	
	[self lockObjectStore];
	NS_DURING
		fault = [objectStore arrayFaultWithSourceGlobalID:globalID relationshipName:relationshipName editingContext:anEditingContext];
	NS_HANDLER
		[self unlockObjectStore];
		[self handleException:localException];
		return nil;
	NS_ENDHANDLER
	[self unlockObjectStore];
	
	return fault;
}

- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	// See if we have the object already.
	id	object; // mont_rothstein @ yahoo.com 2004-12-06 Moved initialization of this object down.
	
	// mont_rothstein @ yahoo.com 2004-12-06
	// If we don't have a globalID the return nil
	if (!globalID) return nil;
	
	object = [objects objectForKey:globalID];
	if (object) return object;
	
	// Nope, so go ahead and have our object store create a fault for the object.
	[self lockObjectStore];
	NS_DURING
		object = [objectStore faultForGlobalID:globalID editingContext:anEditingContext];
		
		// mont_rothstein @ yahoo.com 2004-12-05
		// Now that we have the object we need to store it
		[objects setObject:object forKey:globalID];
		[objectGlobalIDs setObject:globalID forKey:[NSValue valueWithPointer:object]];
	NS_HANDLER
		[self unlockObjectStore];
		[self handleException:localException];
		return nil;
	NS_ENDHANDLER
	[self unlockObjectStore];
	
	return object;
}

- (id)faultForRawRow:(NSDictionary *)row entityNamed:(NSString *)entityName
{
	return [self faultForRawRow:row entityNamed:entityName editingContext:self];
}

- (id)faultForRawRow:(id)row entityNamed:(NSString *)entityName editingContext:(EOEditingContext *)anEditingContext
{
	id		fault;
	
	[self lockObjectStore];
	NS_DURING
		fault = [objectStore faultForRawRow:row entityNamed:entityName editingContext:anEditingContext];
	NS_HANDLER
		[self unlockObjectStore];
		[self handleException:localException];
		return nil;
	NS_ENDHANDLER
	[self unlockObjectStore];
	
	return fault;
}

- (NSArray *)editors
{
	return editors;
}

- (void)addEditor:(id)anEditor
{
	if (![editors containsObject:anEditor]) {
		[editors addObject:anEditor];
	}
}

- (void)removeEditor:(id)anEditor
{
	[editors removeObjectIdenticalTo:anEditor];
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (id)delegate
{
	return delegate;
}

- (void)setMessageHandler:(id)handler
{
	if (handler != messageHandler) {
		[messageHandler release];
		messageHandler = [handler retain];
	}
}

- (id)messageHandler
{
	return messageHandler;
}

- (void)setInvalidatesObjectsWhenFreed:(BOOL)flag
{
	invalidatesObjectsWhenFreed = flag;
}

- (BOOL)invalidatesObjectsWhenFreed
{
	return invalidatesObjectsWhenFreed;
}

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetch editingContext:(EOEditingContext *)editingContext
{
	NSArray		*databaseObjects = nil;
	
	if ([delegate respondsToSelector:@selector(editingContext:shouldFetchObjectsDescribedByFetchSpecification:)]) {
		databaseObjects = [delegate editingContext:self shouldFetchObjectsDescribedByFetchSpecification:fetch];
	}
	
	if (databaseObjects == nil) {
		// We don't want to be observing during the fetch.
		[self lockObjectStore];
		[EOObserverCenter suppressObserverNotification];
		NS_DURING
			databaseObjects = [objectStore objectsWithFetchSpecification:fetch editingContext:self];
		NS_HANDLER
			[EOObserverCenter enableObserverNotification];
			[self unlockObjectStore];
			[self handleException:localException];
			return nil;
		NS_ENDHANDLER
		[EOObserverCenter enableObserverNotification];
		[self unlockObjectStore];
	}
		
	return databaseObjects;
}

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name editingContext:(EOEditingContext *)anEditingContext
{
	id			object;
	
	// See if we own the object...
	object = [objects objectForKey:globalID];
	
	if (object != nil) {
		id			destination;
		
		// Yep, we do, so see if we have a fault or not.
        // Tom.Martin @ Riemer.com 2012-04-24
        // This can be called from EOArrayFaultHandler when an array fault is fired.
        // If the EO accessor does not simply return the array but, for instance, SORTS it first, 
        // thereby firing the fault, then this will go into an infinite loop.  We need to get the 
        // STORED value here to prevent that from happening.
		//destination = [object valueForKey:name];
        destination = [object primitiveValueForKey:name];
		if (![EOFault isFault:destination]) {
			NSMutableArray		*copy;
			int					x;
			int max;
			
			// It's not a fault, so should copy the result.
			copy = [[NSMutableArray allocWithZone:[object zone]] initWithCapacity:[(NSArray *)destination count]];
			
			max = [(NSArray *)destination count];
			for (x = 0; x < max; x++) {
				id		destinationObject = [destination objectAtIndex:x];
				id		copiedObject;
				
				copiedObject = [anEditingContext faultForGlobalID:[self globalIDForObject:destinationObject] editingContext:anEditingContext];
				if (copiedObject != nil) {
					[copy addObject:copiedObject];
				}
			}
            // Tom.Martin @ Riemer.com 2012-04-24
            // add autorelease
			return [copy autorelease];
		}
		
		// It is a fault, so fall through and let the parent object store fetch the objects.
	}
	
	// Nope, don't have the object, so just foward to the parent object store.
	[self lockObjectStore];
	NS_DURING
		object = [objectStore objectsForSourceGlobalID:globalID relationshipName:name editingContext:anEditingContext];
	NS_HANDLER
		[self unlockObjectStore];
		[self handleException:localException];
		return nil;
	NS_ENDHANDLER
	[self unlockObjectStore];
	
	return object;
}

- (void)saveChangesInEditingContext:(EOEditingContext *)childContext
{
	NSArray			*array;
	int				x;
	int max;
	
	// If this is for ourself, then just call save...
	if (childContext == self) {
		[self saveChanges];
		return;
	}
	
	// Otherwise this is in a child, and we want to propagate our child's changes down to ourself.

	// mont_rothstein @ yahoo.com 2005-09-10
	// If save has been called with no changes then there is no undo grouping to end
	if ([undoManager levelsOfUndo] > 0)
	{
		// Start by creating an undo grouping. Even though we don't support undo's across saves, we will support this, since it's not actually a save to the database.
		// mont_rothstein @ yahoo.com 2005-07-07
		// We need to end the previous grouping before we start a new one otherwise we nest, which just causes problems.
		[undoManager endUndoGrouping];
		[undoManager beginUndoGrouping];
	}
	
	// First, propagate the inserts. Basically, to do this, we create a local copy of the object and insert it into ourself.
	array = [childContext insertedObjects];
	
	max = [array count];
	
	for (x = 0; x < max; x++) {
		id				object = [array objectAtIndex:x];
		EOGlobalID	*globalID = [childContext globalIDForObject:object];
		id				localObject;

		// Create a local version of the object.
		localObject = [[object classDescription] createInstanceWithEditingContext:self globalID:globalID zone:[object zone]];
		[self insertObject:localObject];
	}

	// Propagate the updates. This happens after inserts, but before deletes, since deleted objects can also be updated.
	array = [childContext updatedObjects];
	max = [array count];
	
	for (x = 0; x < max; x++) {
		id				object = [array objectAtIndex:x];
		EOGlobalID	*globalID = [childContext globalIDForObject:object];
		id				localObject = [self faultForGlobalID:globalID editingContext:self];
		
		[childContext initializeObject:localObject withGlobalID:globalID editingContext:self];
	}
	
	// Now propagate the deletes.
	array = [childContext deletedObjects];
	max = [array count];
	
	for (x = 0; x < max; x++) {
		id				object = [array objectAtIndex:x];
		EOGlobalID	*globalID = [childContext globalIDForObject:object];
		// mont_rothstein @ yahoo.com 2005-08-10
		// Changed this to call the correct method that specifies the editingContext.  The version without the editingContext parameter was not part of the 4.5 API and has been removed.
		id				localObject = [self faultForGlobalID:globalID editingContext: self];
		
		[self initializeObject:localObject withGlobalID:globalID editingContext:self];
		[self deleteObject:localObject];
	}
	
	// mont_rothstein @ yahoo.com 2005-09-10
	// If save has been called with no changes then there is no undo grouping to end
	if ([undoManager levelsOfUndo] > 0)
	{
		[undoManager endUndoGrouping];
		// mont_rothstein @ yahoo.com 2005-07-07
		// Since we ended an undo group we need to start a new one.
		[undoManager beginUndoGrouping];
	}
}

- (void)refaultObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	// If this is a child editing context, we need to translate the object into the child context.
	if (anEditingContext != self) {
		[self lockObjectStore];
		NS_DURING
			[objectStore refaultObject:anObject withGlobalID:globalID editingContext:anEditingContext];
		NS_HANDLER
			[self unlockObjectStore];
			[self handleException:localException];
			return;
		NS_ENDHANDLER
		[self unlockObjectStore];
	}
	// tom.martin @ riemer.com 2012-2-2
    // I am pretty DARN sure we need an 'else' here so I am putting it in
    else
    {
        // Nope, we're responsible for the object, so we need to clear out any actions on the object (except for insert).
        [deletedObjects removeObjectForKey:globalID];
        [deletedQueue removeObjectForKey:globalID];
        [updatedObjects removeObjectForKey:globalID];
        [updatedQueue removeObjectForKey:globalID];
        
        // tom.martin @ riemer.com 2012-2-2
        // AND clear out the updated and deleted cache
        [updatedCache removeAllObjects];
        [deletedCache removeAllObjects];
        
        [self lockObjectStore];
        NS_DURING
            if ([globalID isTemporary]) {
                // This is a freshly inserted object, so we just re-initialize it, since there's nothing to fetch from the database. Make sure no one (especially us) is listening for the changes, either.
                [EOObserverCenter suppressObserverNotification];
                NS_DURING
                    [objectStore initializeObject:anObject withGlobalID:globalID editingContext:anEditingContext];
                NS_HANDLER
                    [EOObserverCenter enableObserverNotification];
                    [self handleException:localException];
                    return;
                NS_ENDHANDLER
                [EOObserverCenter enableObserverNotification];
            } else {
                // Nope, it's in the database so we can actually refault it.
                [objectStore refaultObject:anObject withGlobalID:globalID editingContext:anEditingContext];
            }
        NS_HANDLER
            [self unlockObjectStore];
            [self handleException:localException];
            return;
        NS_ENDHANDLER
        [self unlockObjectStore];
    }
}

- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs
{
	int				x;
	int numGlobalIDs;
	BOOL				delegateRespondsToInvalidateObject;
	NSMutableArray	*invalidatedObjects;
	
	[self processRecentChanges];
	
	delegateRespondsToInvalidateObject = [delegate respondsToSelector:@selector(editingContext:shouldInvalidateObject:globalID:)];
	
	invalidatedObjects = [[NSMutableArray allocWithZone:[self zone]] init];
	
	// First, refault the objects. We also want to track which objects in the requested array actually get refaulted, since the delegate can prevent object invalidating.
	// tom.martin @ riemer.com - 2011-12-1
	// added missing lock  
	[self lockObjectStore];
	NS_DURING
		numGlobalIDs = [globalIDs count];
		for (x = 0; x < numGlobalIDs; x++) {
			EOGlobalID	*globalID = [globalIDs objectAtIndex:x];
			id				object = [self objectForGlobalID:globalID];
			
			if (object && (!delegateRespondsToInvalidateObject || [delegate editingContext:self shouldInvalidateObject:object globalID:globalID])) {
				[self refaultObject:object withGlobalID:globalID editingContext:self];
				[invalidatedObjects addObject:globalID];
			}
		}
	NS_HANDLER
		[self unlockObjectStore];
		[invalidatedObjects release];
		[self handleException:localException];
		return;
	NS_ENDHANDLER
	[self unlockObjectStore];
	
	// Now, propagate the invalidate to the object store. This will cause the object store to forget it's snapshow, subsequently causing a re-trip of the object fault to get new values from the database.
	[self lockObjectStore];
	NS_DURING
		[objectStore invalidateObjectsWithGlobalIDs:invalidatedObjects];
	NS_HANDLER
		[self unlockObjectStore];
		[self handleException:localException];
		return;
	NS_ENDHANDLER
	[self unlockObjectStore];
}

- (void)initializeObject:(id)object withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	id					localObject = [objects objectForKey:globalID];
	NSClassDescription	*description;
	NSArray				*array;
	int					x;
	int max;
	
	// Check and see if we're the appropriate object store for the object. If we are, then our job is easy and we just initialize the object. 
	if (anEditingContext == self) {
		[self lockObjectStore];
		NS_DURING
			[objectStore initializeObject:object withGlobalID:globalID editingContext:anEditingContext];
		NS_HANDLER
			[self unlockObjectStore];
			[self handleException:localException];
			return;
		NS_ENDHANDLER
		[self unlockObjectStore];
		
		return;
	}
	
	// Now, if we don't have a local copy of the object or the object is a fault, then we can also initialize it.
	if (localObject == nil || [EOFault isFault:localObject]) {
		[self lockObjectStore];
		NS_DURING
			[objectStore initializeObject:object withGlobalID:globalID editingContext:anEditingContext];
		NS_HANDLER
			[self unlockObjectStore];
			[self handleException:localException];
			return;
		NS_ENDHANDLER
		[self unlockObjectStore];
		
		return;
	}
		 
	// Nope, so we have to translate the object to the provided context
	description = [object classDescription];
	
	// Copy the attributes first.
	array = [description attributeKeys];
	
	max = [array count];
	for (x = 0; x < max; x++) {
		NSString		*key = [array objectAtIndex:x];
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  
		//[object takeValue:[localObject valueForKey:key] forKey:key];
		[object setValue:[localObject valueForKey:key] forKey:key];
	}
	
	// Copy the to-one relationships
	array = [description toOneRelationshipKeys];
	
	max = [array count];
	for (x = 0; x < max; x++) {
		NSString		*key = [array objectAtIndex:x];
		id				destination = [localObject valueForKey:key];
		
		if (destination == nil) {
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
			//[object takeValue:nil forKey:key];
			[object setValue:nil forKey:key];
		} else {
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
			//[object takeValue:[anEditingContext faultForGlobalID:[self globalIDForObject:destination] editingContext:anEditingContext] forKey:key];
			[object setValue:[anEditingContext faultForGlobalID:[self globalIDForObject:destination] editingContext:anEditingContext] forKey:key];
		}
	}
	
	// Finally, copy the to-many relationships
	array = [description toManyRelationshipKeys];
	
	max = [array count];
	for (x = 0; x < max; x++) {
		NSString		*key = [array objectAtIndex:x];
		// Just copy as an array fault. This may create a little more work later on, but hey, isn't deferment always good?
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  
		//[object takeValue:[anEditingContext arrayFaultWithSourceGlobalID:globalID relationshipName:key editingContext:anEditingContext] forKey:key];
		[object setValue:[anEditingContext arrayFaultWithSourceGlobalID:globalID relationshipName:key editingContext:anEditingContext] forKey:key];
	}
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
    if (! self)
        return nil;
	
	if ([coder allowsKeyedCoding]) {
		delegate = [[coder decodeObjectForKey:@"delegate"] retain];
		messageHandler = [[coder decodeObjectForKey:@"messageHandler"] retain];
		propagatesDeletesAtEndOfEvent = [coder decodeBoolForKey:@"propagatesDeletesAtEndOfEvent"];
		stopsValidationAfterFirstError = [coder decodeBoolForKey:@"stopsValidationAfterFirstError"];
		invalidatesObjectsWhenFreed = [coder decodeBoolForKey:@"invalidatesObjectsWhenFreed"];
	} else {
		BOOL tempBool;
		
		delegate = [[coder decodeObject] retain];
		messageHandler = [[coder decodeObject] retain];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; propagatesDeletesAtEndOfEvent = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; stopsValidationAfterFirstError = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; invalidatesObjectsWhenFreed = tempBool;
	}
	
	return self;	
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:delegate forKey:@"delegate"];
		[coder encodeObject:messageHandler forKey:@"messageHandler"];
		[coder encodeBool:propagatesDeletesAtEndOfEvent forKey:@"propagatesDeletesAtEndOfEvent"];
		[coder encodeBool:stopsValidationAfterFirstError forKey:@"stopsValidationAfterFirstError"];
		[coder encodeBool:invalidatesObjectsWhenFreed forKey:@"invalidatesObjectsWhenFreed"];
	} else {
		BOOL tempBool;
		
		[coder encodeObject:delegate];
		[coder encodeObject:messageHandler];
		tempBool = propagatesDeletesAtEndOfEvent; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = stopsValidationAfterFirstError; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = invalidatesObjectsWhenFreed; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
	}
}

@end
