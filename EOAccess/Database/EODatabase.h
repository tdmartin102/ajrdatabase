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

@class EOAdaptor, EOAdaptorChannel, EODatabaseContext, EOEntity, EOGlobalID, EOModel, EOModelGroup;

extern NSString *EODatabaseException;
extern NSTimeInterval EODistantPastTimeInterval;

@interface EODatabase : NSObject
{
   NSMutableDictionary	*models;
	NSMutableDictionary	*entityCache;
	NSMutableDictionary	*resultCache;
	
   EOAdaptor				*adaptor;
	NSMutableArray			*databaseContexts;
	NSMutableDictionary	*snapshots;
	
	// Used to track which database our models talk with.
	NSString					*adaptorName;
	NSDictionary			*connectionDictionary;
}

// Creating instances
- (id)initWithModel:(EOModel *)aModel;
- (id)initWithAdaptor:(EOAdaptor *)anAdaptor;

// Adding and removing models
- (void)addModel:(EOModel *)aModel;
- (BOOL)addModelIfCompatible:(EOModel *)aModel;
- (void)removeModel:(EOModel *)aModel;
- (NSArray *)models;

// Accessing entities
- (EOEntity *)entityForObject:(id)anObject;
- (EOEntity *)entityNamed:(NSString *)entityName;

// Recording snapshots
- (void)recordSnapshot:(NSDictionary *)snapshot forGlobalID:(EOGlobalID *)globalID;
- (void)recordSnapshot:(NSArray *)globalIDs forSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name;
- (void)recordSnapshots:(NSDictionary *)someSnapshots;
- (void)recordToManySnapshots:(NSDictionary *)someSnapshots;

// Forgetting snapshots
- (void)forgetSnapshotForGlobalID:(EOGlobalID *)globalID;
- (void)forgetSnapshotsForGlobalIDs:(NSArray *)someSnapshots;
- (void)forgetAllSnapshots;

// Accessing snapshots and snapshot timestamps
- (NSDictionary *)snapshotForGlobalID:(EOGlobalID *)globalID;
- (NSDictionary *)snapshotForGlobalID:(EOGlobalID *)globalID after:(NSTimeInterval)timestamp;
- (NSArray *)snapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name;
- (NSArray *)snapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name after:(NSTimeInterval)timestamp;
- (NSDictionary *)snapshots;
- (NSTimeInterval)timestampForGlobalID:(EOGlobalID *)globalId;
- (NSTimeInterval)timestampForSourceGlobalID:(EOGlobalID *)globalId relationshipName:(NSString *)relationshipName;

// Snapshot reference counting
- (void)incrementSnapshotCountForGlobalID:(EOGlobalID *)globalID;
- (void)decrementSnapshotCountForGlobalID:(EOGlobalID *)globalID;
+ (void)disableSnapshotRefCounting;
	
// Registering database contexts
- (void)registerContext:(EODatabaseContext *)aContext;
- (NSArray *)registeredContexts;
- (void)unregisterContext:(EODatabaseContext *)aContext;

// Accessing the adaptor
- (EOAdaptor *)adaptor;

// Managing the result cache
/*! @todo EODatabase: Result cache */
- (void)setResultCache:(NSArray *)cache forEntityNamed:(NSString *)entityName;
- (NSArray *)resultCacheForEntityNamed:(NSString *)entityName;
- (void)invalidateResultCache;
- (void)invalidateResultCacheForEntityNamed:(NSString *)entityName;

@end
