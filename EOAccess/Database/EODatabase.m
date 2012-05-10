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

#import "EODatabase.h"

#import "_EOSnapshotMutableDictionary.h"
#import "EOAdaptor.h"
#import "EOAdaptorChannel.h"
#import "EOEntity.h"
#import "EOEntityClassDescription.h"
#import "EOModel.h"
#import "EOModelGroup.h"

#import <EOControl/EOEditingContext.h>
#import <EOControl/EOGenericRecord.h>
#import <EOControl/NSObject-EOEnterpriseObject.h>
// mont_rothstein @ yahoo.com 2005-08-08
#import <EOControl/EOObjectStore.h>
#import <EOControl/EOGlobalID.h>

NSString *EODatabaseException = @"EODatabaseException";

NSTimeInterval EODistantPastTimeInterval;

static BOOL _eoDisableSnapshotRefCounting = NO;

@implementation EODatabase

+ (void)initialize
{
	EODistantPastTimeInterval = [[NSDate distantPast] timeIntervalSinceReferenceDate];
}

- (id)init
{
	if (self = [super init])
	{
		models = [[NSMutableDictionary allocWithZone:[self zone]] init];
		entityCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
		resultCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
		databaseContexts = [[NSClassFromString(@"_EOWeakMutableArray") allocWithZone:[self zone]] init];
		snapshots = [[_EOSnapshotMutableDictionary allocWithZone:[self zone]] init];
	}
	return self;
}

- (id)initWithModel:(EOModel *)aModel
{
	if (self = [self init])
    {
        [self addModelIfCompatible:aModel];
	
        adaptor = [[EOAdaptor adaptorWithModel:aModel] retain];
        if (!adaptor) {
            [self release];
            [NSException raise:EODatabaseException format:@"Unable to create an adaptor for model \"%@\".", aModel];
        }
    }
	
    return self;
}

- (id)initWithAdaptor:(EOAdaptor *)anAdaptor
{
	if (self = [self init])
    {
        adaptor = [anAdaptor retain];
	}
	return self;
}

- (void)dealloc
{
	[models release];
    [adaptor release];
	[resultCache release];
	[snapshots release];
	[entityCache release];
	[databaseContexts release];
    
    [super dealloc];
}

- (void)addModel:(EOModel *)aModel
{
	[self addModelIfCompatible:aModel];
}

- (BOOL)addModelIfCompatible:(EOModel *)aModel
{
	NSDictionary	*otherConnection;
	
	if ([models count] == 0) {
		// Indicates the very first model.
		[models setObject:aModel forKey:[aModel name]];
		connectionDictionary = [[aModel connectionDictionary] mutableCopyWithZone:[self zone]];
		adaptorName = [[aModel adaptorName] retain];
		return YES;
	}
	
	if (![[aModel adaptorName] isEqualToString:adaptorName]) return NO;
	
	otherConnection = [aModel connectionDictionary];
	
	if (! [otherConnection isEqualToDictionary:connectionDictionary] ) return NO;
	
	[models setObject:aModel forKey:[aModel name]];
	
	return YES;
}

- (void)removeModel:(EOModel *)aModel
{
	NSArray		*entities = [aModel entities];
	int			x;
	int numEntities;
	
	numEntities = [entities count];
	for (x = 0; x < numEntities; x++) {
		[entityCache removeObjectForKey:[(EOEntity *)[entities objectAtIndex:x] name]];
	}
	
	[models removeObjectForKey:[aModel name]];
}

- (NSArray *)models
{
	return [models allValues];
}

- (EOEntity *)entityForObject:(id)anObject
{
	return [self entityNamed:[anObject entityName]];
}

- (EOEntity *)entityNamed:(NSString *)entityName
{
	EOEntity			*entity = [entityCache objectForKey:entityName];
	
	if (!entity) {
		NSEnumerator	*enumerator = [models objectEnumerator];
		EOModel			*model;
		
		while ((model = [enumerator nextObject])) {
			entity = [model entityNamed:entityName];
			if (entity) {
				[entityCache setObject:entity forKey:entityName];
				break;
			}
		}
	}
	
	return entity;
}

- (EOAdaptor *)adaptor
{
   return adaptor;
}

- (void)registerContext:(EODatabaseContext *)aContext
{
	[databaseContexts addObject:aContext];
}

- (NSArray *)registeredContexts
{
	return databaseContexts;
}

- (void)unregisterContext:(EODatabaseContext *)aContext
{
	[databaseContexts removeObject:aContext];
}

- (void)recordSnapshot:(NSDictionary *)snapshot forGlobalID:(EOGlobalID *)globalID
{
    // lets just create a new dictionary, but when recording relationship keys,
    // we will convert the snapshot type if it is not correct.  This SHOULD NOT happen
    // but we don't always have control over what another programmer might do.
    NSMutableDictionary *newSnapshot;
    
    
     newSnapshot = [snapshot mutableCopy];
    [snapshots setObject:newSnapshot forKey:globalID];
    [newSnapshot release];
}

// mont_rothstein @ yahoo.com 2005-08-08
// Modified this method to call forgetObjectsForGlobalIDs:
- (void)forgetSnapshotForGlobalID:(EOGlobalID *)globalID
{
	[self forgetSnapshotsForGlobalIDs: [NSArray arrayWithObject: globalID]];
}

// mont_rothstein @ yahoo.com 2005-08-08
// Added post of EOObjectsChangedInStoreNotification
- (void)forgetSnapshotsForGlobalIDs:(NSArray *)globalIDs
{
	[snapshots removeObjectsForKeys:globalIDs];
    // Tom.Martin @ Riemer.com 2012-04-24
    // There are three reasons to call forget snapshots
    // 1) the objects GID was updated  (No defined key for that)
    // 2) the object was deleted  (EODeletedKey)
    // 3) the object needs to be invalidated (EOInvalidateKey)
    // The problem is from this method there is no easy way to know the object status is that I can think of.
    // For EOUpdateKey and EOInvalidateKey, the object should be refaulted.  For EODeletedKey the Apple EOF did NOT refault the object
    // and this seems appropriate.  It DOES make some sense that a deleted object should NOT be used after it is deleted.
    // HOWEVER.  If it IS used the fault will fire to a database row that does not exist and an exception will be raised.
    // not nice.      
    // Frankly I think the documentation may be wrong and it is up to the CALLER to post the notification ...
	//[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:self userInfo:[NSDictionary 
    //dictionaryWithObject:globalIDs forKey:EOInvalidatedKey]];
}

- (void)recordSnapshots:(NSDictionary *)someSnapshots
{
	// Tom.Martin @ Riemer.com 2011-09=8-22
	// replace depreciated method call
	//[snapshots takeValuesFromDictionary:someSnapshots];
    //[snapshots setValuesForKeysWithDictionary:someSnapshots];
    // Tom.Martin @ Riemer.com 2012-03-22
    // we are setting the snapshot here so we need to be careful that
    // to-manys are handled, we will call recordSnapshot:forGlobalID:
    [someSnapshots enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        [self recordSnapshot:obj forGlobalID:key];
    }];
}

// mont_rothstein @ yahoo.com 2005-08-08
// Modified this method to call forgetObjectsForGlobalIDs:
- (void)forgetAllSnapshots
{
	[self forgetSnapshotsForGlobalIDs: [snapshots allKeys]];
}

- (NSDictionary *)snapshotForGlobalID:(EOGlobalID *)globalID
{
	return [snapshots objectForKey:globalID];
}

- (NSDictionary *)snapshotForGlobalID:(EOGlobalID *)globalID after:(NSTimeInterval)timestamp
{
	return [(_EOSnapshotMutableDictionary *)snapshots objectForKey:globalID after:timestamp];
}

- (NSDictionary *)snapshots
{
	return snapshots;
}

- (NSTimeInterval)timestampForGlobalID:(EOGlobalID *)globalID
{
	return [(_EOSnapshotMutableDictionary *)snapshots timestampForKey:globalID];
}

- (NSTimeInterval)timestampForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName
{
	return EODistantPastTimeInterval;
}

- (void)recordSnapshot:(NSArray *)globalIDs forSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name
{
	[[snapshots objectForKey:globalID] setObject:globalIDs forKey:name];
}

- (void)recordToManySnapshots:(NSDictionary *)someSnapshots
{
    // Tom.Martin @ Riemer.com  2012-2-29
    // structure of to many snapshots should be:
    //   (Dictionary) 
    //       (any number of) Key (SourceEO GlobalId) Value (Dictionary) 
    //           (any number of) Key (Relationship Name) Value (Array)
    //                Array is GlobalIds of EO at the destination of the relationship
    // NO CHECKING is performed to assure the structure of the pased in dictionary is correct
    [someSnapshots enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        id keyEnum;
        NSString *rname;
        NSArray  *gidArray;
        
        keyEnum = [(NSDictionary *)obj keyEnumerator];
        while ((rname = [keyEnum nextObject]) != nil)
        {
            gidArray = [obj objectForKey:rname];
            [self recordSnapshot:gidArray forSourceGlobalID:key relationshipName:rname];
        }
    }];
}

- (NSArray *)snapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name
{
	return [[snapshots objectForKey:globalID] objectForKey:name];
}

- (NSArray *)snapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name after:(NSTimeInterval)timestamp
{
	/*! @todo snapshotForSourceGlobalID:relationshipName:after: */
	return nil;
}

- (void)incrementSnapshotCountForGlobalID:(EOGlobalID *)globalID
{
	[(_EOSnapshotMutableDictionary *)snapshots incrementReferenceCountForKey:globalID];
}

- (void)decrementSnapshotCountForGlobalID:(EOGlobalID *)globalID
{
	[(_EOSnapshotMutableDictionary *)snapshots decrementReferenceCountForKey:globalID];
}

+ (BOOL)_isSnapshotRefCountingDisabled
{
	return _eoDisableSnapshotRefCounting;
}

+ (void)disableSnapshotRefCounting
{
	_eoDisableSnapshotRefCounting = YES;
}

- (void)setResultCache:(NSArray *)cache forEntityNamed:(NSString *)entityName
{
	[resultCache setObject:cache forKey:entityName];
}

- (NSArray *)resultCacheForEntityNamed:(NSString *)entityName
{
	return [resultCache objectForKey:entityName];
}

- (void)invalidateResultCache
{
	[resultCache removeAllObjects];
}

- (void)invalidateResultCacheForEntityNamed:(NSString *)entityName
{
	[resultCache removeObjectForKey:entityName];
}

@end
