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

#import "EOModelGroup.h"

#import "EODatabase.h"
#import "EOEntity.h"
#import "EOModel.h"
#import "EOStoredProcedure.h"

#import <EOControl/EOGenericRecord.h>
#import <EOControl/NSObject-EOEnterpriseObject.h>

/*!
 * Object is the added model; userInfo is nil
 */
NSString *EOModelAddedNotification = @"EOModelAddedNotification";

/*!
 * Object is the invalidated model; userInfo is nil
 */
NSString *EOModelInvalidatedNotification = @"EOModelInvalidatedNotification";

static EOModelGroup			*globalModelGroup = nil;
static EOModelGroup			*defaultModelGroup = nil;
static id						classDelegate = nil;

@implementation EOModelGroup

- (void)_scanForModels
{
   NSMutableArray	*bundles = [[NSBundle allBundles] mutableCopy];
   NSBundle			*bundle;
   NSArray			*possible;

   [bundles addObjectsFromArray:[NSBundle allFrameworks]];

    for (bundle in bundles) {
//      [EOLog logDebugWithFormat:@"Checking %@...\n", bundle];
      possible = [bundle pathsForResourcesOfType:@"eomodeld" inDirectory:nil];
      if ([possible count]) {
          NSString		*path;
          EOModel		*model;

          for (path in possible) {
            model = [(EOModel *)[EOModel alloc] initWithContentsOfFile:path];
            if (model) [self addModel:model];
            [model release];
         }
      }
   }

   [bundles release];
}

/*!
 * Initializes a newly created model group. You should never need to call
 * this directly. It will be called for you.
 */
- (id)init
{
	if ((self = [super init]) == nil)
		return nil;
   models = [[NSMutableArray allocWithZone:[self zone]] init];
   modelIndex = [[NSMutableDictionary allocWithZone:[self zone]] init];
   modelPathIndex = [[NSMutableDictionary allocWithZone:[self zone]] init];
   entityCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
   storedProcedureCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(entityDidChangeName:) name:EOEntityDidChangeNameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storedProcedureDidChangeName:) name:EOStoredProcedureDidChangeNameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelDidChangeName:) name:EOModelDidChangeNameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelDidChangePath:) name:EOModelDidChangePathNotification object:nil];

   return self;
}

- (void)dealloc
{
   [models release];
   [modelIndex release];
	[modelPathIndex release];
   [entityCache release];
	[storedProcedureCache release];

	// mont_rothstein @ yahoo.com 2005-08-13
	// If we don't unregister for notifications then the notification center will try and send us notifications after we have gone.
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[super dealloc];
}

+ (void)setDefaultGroup:(EOModelGroup *)group
{
	if (defaultModelGroup != group) {
		[defaultModelGroup release];
		defaultModelGroup = [group retain];
	}
}

+ (EOModelGroup *)globalModelGroup
{
	if (globalModelGroup == nil) {
		globalModelGroup = [[EOModelGroup alloc] init];
		[globalModelGroup _scanForModels];
	}
	
	return globalModelGroup;
}

/*!
 * Returns the default model group, creating it if necessary.
 *
 * @return The default model group.
 */
+ (EOModelGroup *)defaultModelGroup
{
	if (classDelegate != nil && [classDelegate respondsToSelector:@selector(defaultModelGroup)]) {
		EOModelGroup	*group = [classDelegate defaultModelGroup];
		if (group != nil) return group;
	}
   if (defaultModelGroup == nil) {
      defaultModelGroup = [[self globalModelGroup] retain];
   }
   return defaultModelGroup;
}

// mont_rothstein @ yahoo.com 2004-12-03
// Added for compliance to WO 4.5 API
+ (EOModelGroup *)defaultGroup
{
	return [EOModelGroup defaultModelGroup];
}

/*!
 * Returns the model named name.
 *
 * @return The model named name or null if not model by that name exists.
 */
- (EOModel *)modelNamed:(NSString *)name
{
   return [modelIndex objectForKey:name];
}

/*!
 * Registers the model with the model group. This model can later be
 * accessed by the getModel() method. Posts a EOModelAddedNotification
 * notification.
 *
 * @param model The model to register with the model group. model's name must
 *              be set.
 */
- (void)addModel:(EOModel *)model
{
   NSString      *name = [model name];

   if ([model modelGroup] != nil) {
      if ([model modelGroup] == self) return;
      [NSException raise:EODatabaseException format:@"You've attempted to add a model (%@) to a model group when it's already owned by another model group.", [model name]];
   }

//	[EOLog logDebugWithFormat:@"adding model: %@ name: %@\n", model, name];
   if (![modelIndex objectForKey:name]) {
      [models addObject:model];
      [modelIndex setObject:model forKey:name];
		if ([model path]) {
			[modelPathIndex setObject:model forKey:[model path]];
		}
      [model setModelGroup:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:EOModelAddedNotification object:model];
   }
}

- (EOModel *)addModelWithFile:(NSString *)path
{
	EOModel	*model = [[EOModel allocWithZone:[self zone]] initWithContentsOfFile:path];
	
    if(model != nil){
        [self addModel:model];	
        [model release];
    }
    
    return model;
}

- (EOModel *)modelWithPath:(NSString *)path
{
	EOModel	*model = [modelPathIndex objectForKey:path];
	
	if (model == nil) {
		model = [[EOModel allocWithZone:[self zone]] initWithContentsOfFile:path];
		[self addModel:model];
		[model release];
	}
	
	return model;
}

/*!
 * Removes the model from the model group. model's name must be set.
 * Posts a EOModelInvalidatedNotification notification.
 */
- (void)removeModel:(EOModel *)model
{
   if ([model modelGroup] == self) {
      [models removeObject:model];
      [modelIndex removeObjectForKey:[model name]];
      [modelPathIndex removeObjectForKey:[model path]];
      [entityCache removeObjectsForKeys:[model entityNames]];
      [storedProcedureCache removeObjectsForKeys:[model storedProcedureNames]];
      [model setModelGroup:nil];
      [[NSNotificationCenter defaultCenter] postNotificationName:EOModelInvalidatedNotification object:model];
   } else {
      [NSException raise:EODatabaseException format:@"You attempted to remove a model from a model group that does not own the model."];
   }
}

- (NSArray *)modelNames
{
	return [[modelIndex allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

/*!
 * Searches all the registered models for the entity named name. It returns
 * the first entity found.
 *
 * @param name The name of the entity to find.
 *
 * @return The first occurence of the entity named name in the registered
 *         models.
 */
- (EOEntity *)_findEntity:(NSString *)name
{
    EOEntity    *entity;
    EOModel     *model;

    for (model in models) {
        entity = [model entityNamed:name];
        if (entity != nil)
            return entity;
    }
    return nil;
}

/*!
 * Returns the entity named name.
 *
 * @return The entity named name.
 */
- (EOEntity *)entityNamed:(NSString *)name
{
   EOEntity    *entity = [entityCache objectForKey:name];

   if (entity == nil) {
      entity = [self _findEntity:name];
      if (entity != nil) {
         [entityCache setObject:entity forKey:name];
      }
   }

   return entity;
}

- (EOEntity *)entityForObject:(id)object
{
	return [self entityNamed:[object entityName]];
}

- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)fetchSpecName entityNamed:(NSString *)name
{
	return [[self entityNamed:name] fetchSpecificationNamed:fetchSpecName];
}

- (EOStoredProcedure *)_findStoredProcedure:(NSString *)name
{
    EOStoredProcedure	*storedProcedure;
    EOModel             *model;
    
    for (model in models) {
        storedProcedure = [model storedProcedureNamed:name];
        if (storedProcedure != nil)
            return storedProcedure;
    }
    return nil;
}

- (EOStoredProcedure *)storedProcedureNamed:(NSString *)name
{
	EOStoredProcedure		*storedProcedure = [storedProcedureCache objectForKey:name];
	
	if (storedProcedure == nil) {
		storedProcedure = [self _findStoredProcedure:name];
		if (storedProcedure != nil) {
			[storedProcedureCache setObject:storedProcedure forKey:name];
		}
	}

	return storedProcedure;
}

- (void)loadAllModelObjects
{
    EOModel             *model;
    
    for (model in models) {
        [model loadAllModelObjects];
    }
}

/*!
 * Returns the list of all registered models.
 *
 * @return All models registered with the model group.
 */
- (NSArray *)models
{
   return models;
}

+ (void)setClassDelegate:(id)anObject
{
	classDelegate = anObject;
}

+ (id)classDelegate
{
	return classDelegate;
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (id)delegate
{
	return delegate;
}

- (void)entityDidChangeName:(NSNotification *)notification
{
	NSString		*oldName = [[notification userInfo] objectForKey:@"oldName"];
	
	if (oldName && [[notification object] model] && [models containsObject:[[notification object] model]]) {
		[entityCache removeObjectForKey:oldName];
	}
}

- (void)modelDidChangeName:(NSNotification *)notification
{
	EOModel		*model;
	NSString		*oldName = [[notification userInfo] objectForKey:@"oldName"];
	NSString		*newName = [[notification userInfo] objectForKey:@"newName"];

	if (oldName) {
		model = [modelIndex objectForKey:oldName];
		// We care about this model...
		if (model) {
			[modelIndex removeObjectForKey:oldName];
			[modelIndex setObject:model forKey:newName];
		}
	}
}

- (void)modelDidChangePath:(NSNotification *)notification
{
	EOModel		*model;
	NSString		*oldPath = [[notification userInfo] objectForKey:@"oldPath"];
	NSString		*newPath = [[notification userInfo] objectForKey:@"newPath"];
	
	if (oldPath) {
		model = [modelIndex objectForKey:oldPath];
		// We care about this model...
		if (model) {
			[modelPathIndex removeObjectForKey:oldPath];
			[modelPathIndex setObject:model forKey:newPath];
		}
	}
}

- (void)storedProcedureDidChangeName:(NSNotification *)notification
{
	NSString		*oldName = [[notification userInfo] objectForKey:@"oldName"];
	
	if (oldName && [[notification object] model] && [models containsObject:[[notification object] model]]) {
		[storedProcedureCache removeObjectForKey:oldName];
	}
}

@end
