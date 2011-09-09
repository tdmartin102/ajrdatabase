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

#import "EODatabaseChannelP.h"

#import "EOAdaptor.h"
#import "EOAdaptorChannel.h"
#import "EOAdaptorContext.h"
#import "EOAttribute.h"
#import "EODatabase.h"
#import "EODatabaseContextP.h"
#import "EOEntity.h"
#import "EOEntityP.h"
#import "EOEntityClassDescription.h"
#import "EOJoin.h"
#import "EOModel.h"
#import "EORelationship.h"

#import <EOControl/EOControl.h>
#import <EOControl/EONumericKeyGlobalID.h>

@implementation EODatabaseChannel

- (id)initWithDatabaseContext:(EODatabaseContext *)aDatabaseContext
{
   [super init];
   
	[self _setDatabaseContext:aDatabaseContext];

   return self;
}

- (void)dealloc
{
   [updatedObjects release];
   [adaptorChannel release];

   [super dealloc];
}

- (EOAdaptorChannel *)_adaptorChannel:(BOOL)connect
{
   if (!adaptorChannel) {
      adaptorChannel = [[[databaseContext adaptorContext] createAdaptorChannel] retain];
      if (!adaptorChannel) {
         [NSException raise:EODatabaseException format:@"Unable to obtain an adaptor channel\n"];
      }
   }
   if (connect && ![adaptorChannel isOpen]) {
      [adaptorChannel openChannel];
   }

   return adaptorChannel;
}

- (EOAdaptorChannel *)adaptorChannel
{
   return [self _adaptorChannel:NO];
}

- (EODatabaseContext *)databaseContext
{
	return databaseContext;
}

- (void)selectObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
                           inEditingContext:(EOEditingContext *)anEditingContext;
{
   [self _adaptorChannel:YES]; // Make sure this is created and connected.
   if (!adaptorChannel) {
      [NSException raise:EODatabaseException format:@"Unable to obtain an adaptor channel\n"];
   }
   
   // mont_rothstein @ yahoo.com 2005-06-27
   // If the update strategy is pessimistic locking then override the setting on the
   // fetch specification to always lock
   if ([databaseContext updateStrategy] == EOUpdateWithPessimisticLocking)
   {
	   [fetch setLocksObjects: YES];
   }

   [self setCurrentEditingContext:anEditingContext];
	[self setCurrentEntity:[[[self databaseContext] database] entityNamed:[fetch entityName]]];
	[self setIsRefreshingObjects:[fetch refreshesObjects]];
	[self setIsLocking:[fetch locksObjects]];

   [adaptorChannel selectAttributes:nil fetchSpecification:fetch lock:lockingObjects entity:fetchEntity];

   fetchClass = [fetchEntity _objectClass];
   if (fetchClass == Nil) {
      fetchClass = [EOGenericRecord class];
   }
	
	checkDelegateForRefresh = [[self delegate] respondsToSelector:@selector(databaseContext:shouldUpdateCurrentSnapshot:newSnapshot:globalID:databaseChannel:)];
}

- (id)fetchObject
{
	id					object;
	EOGlobalID			*globalID;
	NSAutoreleasePool	*pool;
	
	fetchedRow = [adaptorChannel fetchRowWithZone:NULL];

	if (fetchedRow == nil) {
		[self cancelFetch];
		return nil;
	}

	// Create the global ID. This will allow us to check if the object is already in the object store.
	globalID = [fetchEntity globalIDForRow:fetchedRow];

	// Check the object store for the object...
	object = [editingContext objectForGlobalID:globalID];
   
	pool = [[NSAutoreleasePool allocWithZone:[self zone]] init];
   
	if (object) {
		// Check the object, since we need to do special handling if it's a fault...
		if ([EOFault isFault:object]) {
			// The object is s fault, so we need to initialize it, but we don't want the fault to do a round trip to the database for this. So, instead, we'll have the fault handler initialize it from the raw row.
			[[EOFault faultHandlerForFault:object] faultObject:object withRawRow:fetchedRow databaseContext:databaseContext];
			// Don't forget to register the snapshot, since we just went from a fault to an object, which means we now actually have our snapshot to register.
			// Tom.Martin @ Riemer.com 8/30/2011
			// No need to register the snapshot as the faultHandler does that.
			//[[databaseContext database] recordSnapshot:fetchedRow forGlobalID:globalID];
			// And, on top of that, we don't initialize through the database context, but we're now a real object, so we should increment our snapshot reference count.
			[[databaseContext database] incrementSnapshotCountForGlobalID:globalID];
		} else {
			BOOL		refresh = NO;
			
			// The object exists, so see if we need to do anything with it...
			if (checkDelegateForRefresh) {
				fetchedRow = [[self delegate] databaseContext:databaseContext shouldUpdateCurrentSnapshot:[[databaseContext database] snapshotForGlobalID:globalID] newSnapshot:fetchedRow globalID:globalID databaseChannel:self];
				refresh = fetchedRow != nil;
			} else if (refreshesObjects) {
				refresh = YES;
			}
			
			if (refresh) {
				// This indicates that we need to replace the values of the object in memory with the values newly refetched from the database.
				
				// Regiester the snapshot with the new values.
				[[databaseContext database] recordSnapshot:fetchedRow forGlobalID:globalID];
				// Rebind the new values... Use the private method to avoid increment the snapshot's reference count.
				[databaseContext _initializeObject:object withGlobalID:globalID editingContext:editingContext];
				// The above code will increment the snapshot count, but we're not actually added a "new" object, so decrement the snapshot back down.
				
				[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:databaseContext userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:globalID] forKey:EOUpdatedKey]];
			}
		}
	} else {
		// Create the object.
		object = [(EOEntityClassDescription *)[fetchEntity classDescriptionForInstances] createInstanceWithEditingContext:editingContext globalID:globalID zone:NULL];
		
		// And register the snapshot with the recordSnapshot context.
		[[databaseContext database] recordSnapshot:fetchedRow forGlobalID:globalID];
		// Allow the object to initialize itself. This is normally done in EOGenericRecord.
		[databaseContext initializeObject:object withGlobalID:globalID editingContext:editingContext];
		
		[editingContext recordObject:object globalID:globalID];
		
		// mont_rothstein @ yahoo.com 2004-12-06
		// Moved the call to awakeFromFetchInEditingContext: from recordObject:globalID:
		[object awakeFromFetchInEditingContext: editingContext];
   }
   [object retain];
   
   [pool release];

   return [object autorelease];
}

- (NSDictionary *)row
{
   return fetchedRow;
}

- (BOOL)isFetchInProgress
{
   return fetchClass != Nil;
}

- (void)cancelFetch
{
	// mont_rothstein 3 yahoo.com 2005/12/03
	// This wasn't calling EOAdaptorChannel's cancelFetch, which was leaving DB connections open for each fetch
	[[self adaptorChannel] cancelFetch];
	fetchClass = Nil;
	[fetchEntity release]; fetchEntity = nil;
   [fetchedRow release]; fetchedRow = nil;
   [editingContext release]; editingContext = nil;
}

- (void)setCurrentEntity:(EOEntity *)anEntity
{
	if (fetchEntity != anEntity) {
		[fetchEntity release];
		fetchEntity = [anEntity retain];
	}
}

- (void)setCurrentEditingContext:(EOEditingContext *)aContext
{
	if (editingContext != aContext) {
		[editingContext release];
		editingContext = [aContext retain];
	}
}

- (void)setIsLocking:(BOOL)flag
{
	lockingObjects = flag;
}

- (BOOL)isLocking
{
	return lockingObjects;
}

- (void)setIsRefreshingObjects:(BOOL)flag
{
	refreshesObjects = flag;
}

- (BOOL)isRefreshingObjects
{
	return refreshesObjects;
}

- (NSString *)description
{
   return EOFormat(@"<EODatabaseChannel: %p: %@>", self, [[[[[databaseContext database] models] lastObject] connectionDictionary] description]);
}

- (void)setDelegate:(id)delegate
{
	[[self databaseContext] setDelegate:delegate];
}

- (id)delegate
{
	return [[self databaseContext] delegate];
}

- (int)countOfObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
   EOAdaptorChannel		*channel = [[databaseContext adaptorContext] createAdaptorChannel];
   if (![channel isOpen]) [channel openChannel];
   return [channel countOfObjectsWithFetchSpecification:fetch entity:[[databaseContext database] entityNamed:[fetch entityName]]];
}

- (id)maxValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
   EOAdaptorChannel		*channel = [[databaseContext adaptorContext] createAdaptorChannel];
   if (![channel isOpen]) [channel openChannel];
   return [channel maxValueForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch entity:[[databaseContext database] entityNamed:[fetch entityName]]];
}

- (id)minValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
   EOAdaptorChannel		*channel = [[databaseContext adaptorContext] createAdaptorChannel];
   if (![channel isOpen]) [channel openChannel];
   return [channel minValueForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch entity:[[databaseContext database] entityNamed:[fetch entityName]]];
}

- (id)sumOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
   EOAdaptorChannel		*channel = [[databaseContext adaptorContext] createAdaptorChannel];
   if (![channel isOpen]) [channel openChannel];
   return [channel sumOfValuesForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch entity:[[databaseContext database] entityNamed:[fetch entityName]]];
}

- (id)averageOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
   EOAdaptorChannel		*channel = [[databaseContext adaptorContext] createAdaptorChannel];
   if (![channel isOpen]) [channel openChannel];
   return [channel averageOfValuesForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch entity:[[databaseContext database] entityNamed:[fetch entityName]]];
}

- (void)_setDatabaseContext:(EODatabaseContext *)aContext
{
	if (databaseContext != aContext) {
		// We're owned by the context, so don't retain it.
		databaseContext = aContext;
	}
}

@end
