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

@class EOEntity, EOFetchSpecification, EOGlobalID, EOModel, EORelationship, EOStoredProcedure;

extern NSString *EOModelAddedNotification;
extern NSString *EOModelInvalidatedNotification;

@interface EOModelGroup :NSObject
{
   NSMutableArray			*models;
   NSMutableDictionary	*modelIndex;
   NSMutableDictionary	*modelPathIndex;
   NSMutableDictionary	*entityCache;
	NSMutableDictionary	*storedProcedureCache;
	id							delegate;
}

- (id)init;

+ (void)setDefaultGroup:(EOModelGroup *)group;
+ (EOModelGroup *)defaultGroup;
+ (EOModelGroup *)defaultModelGroup;
+ (EOModelGroup *)globalModelGroup;

// Accessing the group
- (void)addModel:(EOModel *)model;
- (EOModel *)addModelWithFile:(NSString *)path;
- (EOModel *)modelNamed:(NSString *)name;
- (NSArray *)modelNames;
- (NSArray *)models;
- (EOModel *)modelWithPath:(NSString *)path;
- (void)removeModel:(EOModel *)model;

// Searching a group;
- (EOEntity *)entityNamed:(NSString *)name;
- (EOEntity *)entityForObject:(id)object;
- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)fetchSpecName entityNamed:(NSString *)name;
- (EOStoredProcedure *)storedProcedureNamed:(NSString *)name;

//	Loading all of a group's objects
- (void)loadAllModelObjects;
	
// Assigning the delegate
+ (void)setClassDelegate:(id)anObject;
+ (id)classDelegate;
- (void)setDelegate:(id)delegate;
- (id)delegate;

@end


@interface NSObject (EOModelGroupClassDelegate)

- (EOModelGroup *)defaultModelGroup;

@end


@interface NSObject (EOModelGroupDelegate)

/*! @todo EOModelGroup: delegate methods */

- (Class)entity:(EOEntity *)entity classForObjectWithGlobalID:(EOGlobalID *)globalID;
- (Class)entity:(EOEntity *)entity failedToLookupClassNamed:(NSString *)className;
- (EORelationship *)entity:(EOEntity *)entity relationshipForRow:(NSDictionary *)row relationship:(EORelationship *)relationship;
- (EOModel *)modelGroup:(EOModelGroup *)group entityNamed:(NSString *)name;
- (EOEntity *)relationship:(EORelationship *)relationship failedToLookupDestinationNamed:(NSString *)entityName;
- (EOEntity *)subEntityForEntity:(EOEntity *)entity primaryKey:(NSDictionary *)primaryKey isFinal:(BOOL *)flag;

@end
