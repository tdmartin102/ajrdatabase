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
#import "EOModel.h"
#import "EOModelGroup.h"

#import <EOControl/EOGenericRecord.h>
#import <EOControl/NSObject-EOEnterpriseObject.h>
// mont_rothstein @ yahoo.com 2005-08-08
#import <EOControl/EOObjectStore.h>

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
	[self init];
	
	[self addModelIfCompatible:aModel];
	
   adaptor = [[EOAdaptor adaptorWithModel:aModel] retain];
   if (!adaptor) {
		[self release];
      [NSException raise:EODatabaseException format:@"Unable to create an adaptor for model \"%@\".", aModel];
   }
	
   return self;
}

- (id)initWithAdaptor:(EOAdaptor *)anAdaptor
{
	[self init];
	
	adaptor = [anAdaptor retain];
	
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
	// aclark @ ghoti.org 2005-08-08
	// This was incorrectly sending objectForKey: to snapshot instead of snapshots.  Changed to use snapshotForGlobalID: to keep abstracted.
	NSDictionary		*oldSnapshot = [self snapshotForGlobalID:globalID];
	
	if (oldSnapshot == nil) {
		// We don't already know about the snapshot, so go ahead and just set it. Note that it'll have an initial reference count of 0, until something external increments it.
		[snapshots setObject:snapshot forKey:globalID];
	// Tom.Martin @ Riemer.com 2011-08-30
	// check to see if the snapshot is the same as the stored one.
	// this can happen if recordSnapshot is called more than once on the same snapshot, which should not happen, but it could.
	} else if (snapshot != oldSnapshot) {
		// Tom.Martin @ Riemer.com 2011-09=8-22
		// replace depreciated method call
		//[oldSnapshot takeValuesFromDictionary:snapshot];
		if ([oldSnapshot isKindOfClass:[NSMutableDictionary class]])
			[(NSMutableDictionary *)oldSnapshot setValuesForKeysWithDictionary:snapshot];
		else
		{
			// I can't see how this can happen, but there is nothing to prevent it.
			// yank the old snapshot and replace it with the new.
			[snapshots removeObjectsForKeys:[NSArray arrayWithObject:globalID]];
			[snapshots setObject:snapshot forKey:globalID];
		}
	}
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
	[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:self userInfo:[NSDictionary dictionaryWithObject:globalIDs forKey:EOInvalidatedKey]];
}

- (void)recordSnapshots:(NSDictionary *)someSnapshots
{
	// Tom.Martin @ Riemer.com 2011-09=8-22
	// replace depreciated method call
	//[snapshots takeValuesFromDictionary:someSnapshots];
	[snapshots setValuesForKeysWithDictionary:someSnapshots];
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
