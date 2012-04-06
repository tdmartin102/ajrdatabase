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

#import "EOEntityClassDescription.h"

#import "EOAttributeP.h"
#import "EODatabaseContext.h"
#import "EOEntityP.h"
#import "EOJoin.h"
#import "EOMutableArray.h"
#import "EORelationshipP.h"
#import "NSObject-EOAccess.h"
#import "EOModelGroup.h"
#import "EOArrayFaultHandler.h"

#import <EOControl/EOControl.h>


@interface NSObject (EOPrivate) 

- (void)_setEditingContext:(EOEditingContext *)editingContext;
// mont_rothstein @ yahoo.com 2004-12-06
// This method was removed.
//- (void)_setGlobalID:(EOGlobalID *)globalID;

@end


@implementation EOEntityClassDescription

static NSMutableDictionary *_classDescriptionCache = nil;

+ (void)registerClassDescription:(NSClassDescription *)description forClass:(Class)class
{
	if (_classDescriptionCache == nil) {
		_classDescriptionCache = [[NSMutableDictionary alloc] init];
	}
	
	[_classDescriptionCache setObject:description forKey:[[(EOEntityClassDescription *)description entity] name]];
	[super registerClassDescription:description forClass:class];
}

+ (NSClassDescription *)classDescriptionForEntityName:(NSString *)entityName
{
	NSClassDescription	*description;
	
	if (_classDescriptionCache == nil) {
		_classDescriptionCache = [[NSMutableDictionary alloc] init];
	}
	
	description = [_classDescriptionCache objectForKey:entityName];
	if (description == nil) {
		// mont_rothstein @ yahoo.com 2005-02-17
		// Added call to make sure the model is loaded, otherwise we won't
		// find the entity/
		[EOModelGroup defaultGroup];
		[[NSNotificationCenter defaultCenter] postNotificationName:NSClassDescriptionNeededForClassNotification object:self userInfo:[NSDictionary dictionaryWithObject:entityName forKey:@"entityName"]];
		description = [_classDescriptionCache objectForKey:entityName];
	}
	
	return description;
}

- (id)initWithEntity:(EOEntity *)anEntity
{
	if (self = [super init])
		entity = [anEntity retain];
	
	return self;
}

- (void)dealloc
{
	[entity release];
	
	[super dealloc];
}

- (EOEntity *)entity
{
	return entity;
}

- (NSString *)entityName
{
	return [entity name];
}

- (NSClassDescription *)classDescriptionForDestinationKey:(NSString *)key
{
	EORelationship	*relationship = [entity relationshipNamed:key];
	
	if (relationship != nil) {
		return [EOEntityClassDescription classDescriptionForEntityName:[[relationship destinationEntity] name]];
	}
	
	return nil;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey:(NSString *)key
{
	return [[entity relationshipNamed:key] ownsDestination];
}

- (EODeleteRule)deleteRuleForRelationshipKey:(NSString *)key
{
	return [[entity relationshipNamed:key] deleteRule];
}

- (NSArray *)attributeKeys
{
	return [entity _attributeNames];
}

- (NSString *)inverseForRelationshipKey:(NSString *)relationshipKey
{
	return [[[entity relationshipNamed:relationshipKey] inverseRelationship] name];
}

- (NSArray *)toManyRelationshipKeys
{
	return [entity _toManyRelationshipKeys];
}

- (NSArray *)toOneRelationshipKeys
{
	return [entity _toOneRelationshipKeys];
}

// mont_rothstein @ yahoo.com 10/26/04
// Modified this to only use the class relationships, not all relationships.  Accessing all relationships was including the multi-entity relationships used to create flattened relationships.
- (void)awakeObjectFromFetch:(id)object inEditingContext:(EOEditingContext *)anEditingContext
{
   NSArray			*relationships;
   int				x, max;
	EOGlobalID		*globalID = [anEditingContext globalIDForObject:object];
	
   [object _setEditingContext:anEditingContext];
	
	//relationships = [entity relationships];
   relationships = [entity _classRelationships];
   for (x = 0, max = [relationships count]; x < max; x++) {
		//EORelationship  *relationship = [relationships objectAtIndex:x];
	   EORelationship		*relationship = [entity relationshipNamed:[relationships objectAtIndex:x]];
		
      if ([relationship isToMany]) {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//[object takeStoredValue:[anEditingContext arrayFaultWithSourceGlobalID:globalID relationshipName:[relationship name] editingContext:anEditingContext] forKey:[relationship name]];
		// tom.martin @ riemer.com 2011-11-16
		// it turns out that the purpose of takeStoredValue is basically to 
		// avoid calling the accessor method so that willChange will NOT be called
		// I have implemented setPrimitiveValue:forKey to replace takeStoredValue:forKey:
		// So this method is replaced here.      
		//[object setValue:[anEditingContext arrayFaultWithSourceGlobalID:globalID relationshipName:[relationship name] editingContext:anEditingContext] forKey:[relationship name]];
		[object setPrimitiveValue:[anEditingContext arrayFaultWithSourceGlobalID:globalID relationshipName:[relationship name] editingContext:anEditingContext] forKey:[relationship name]];
      } else if ([relationship definition] != nil) {
         /*! @todo Create many to many relationship. This may actually be nothing, since it may be handled by the above block. */
      } else {
			EODatabaseContext	*EOContext;
         EOGlobalID			*dstGlobalID;
		 NSDictionary *snapshot;
		 NSArray *sourceAttributes;
		 NSArray *destinationAttributes;
		 NSMutableDictionary *row;
		 int index, numAttributes;
		 id value;
			
			EOContext = [EODatabaseContext registeredDatabaseContextForModel:[entity model] editingContext:anEditingContext];
			// mont_rothstein @ yahoo.com 2005-05-06
			// This was assuming that the source and destination attrribute names were the same.
			// Corrected to handle source and destination attributes separately
//			dstGlobalID = [[relationship destinationEntity] globalIDForRow:[EOContext snapshotForGlobalID:globalID]];
			snapshot = [EOContext snapshotForGlobalID:globalID];
			row = [NSMutableDictionary dictionary];
			sourceAttributes = [relationship sourceAttributes];
			destinationAttributes = [relationship destinationAttributes];
			numAttributes = [sourceAttributes count];
			
			for (index = 0; index < numAttributes; index++)
			{
				value = [snapshot objectForKey: [[sourceAttributes objectAtIndex: index] name]];
				
				if (value)
				{
					[row setObject: value
							forKey: [[destinationAttributes objectAtIndex: index] name]];
				}
			}

			dstGlobalID = [[relationship destinationEntity] globalIDForRow: row];
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			//[object takeStoredValue:[anEditingContext faultForGlobalID:dstGlobalID editingContext:anEditingContext] forKey:[relationship name]];
			// tom.martin @ riemer.com 2011-11-16
			// it turns out that the purpose of takeStoredValue is basically to 
			// avoid calling the accessor method so that willChange will NOT be called
			// I have implemented setPrimitiveValue:forKey to replace takeStoredValue:forKey:
			// So this method is replaced here.  
			//[object setValue:[anEditingContext faultForGlobalID:dstGlobalID editingContext:anEditingContext] forKey:[relationship name]];
			[object setPrimitiveValue:[anEditingContext faultForGlobalID:dstGlobalID editingContext:anEditingContext] forKey:[relationship name]];
      }
   }
}

- (void)awakeObjectFromInsert:(id)object inEditingContext:(EOEditingContext *)anEditingContext
{
	NSArray			*relationships;
	int				x, max;
	
	[object _setEditingContext:anEditingContext];
	
	// mont_rothstein @ yahoo.com 10/27/04
	// We only want to set class relationships.  The full relationships array includes non-class relationships (such as for many-to-many relationships) that don't have class attributes.
	//relationships = [entity relationships];
	relationships = [entity _classRelationships];
	for (x = 0, max = [relationships count]; x < max; x++) {
		//EORelationship  *relationship = [relationships objectAtIndex:x];
		EORelationship		*relationship = [entity relationshipNamed:[relationships objectAtIndex:x]];
		EOMutableArray		*array;
		
		// mont_rothstein @ yahoo.com 2004-12-06
		// Two changes were made here.  First, there was an if and else below that did the
		// exact same thing if they evaluated to true, they were combined.
		// Second, this used to always set the array value, it now only does so if there
		// is not already a value.  This is either a bug in the docs or design for WO 4.5.
		// WO 4.5 assumes that all newly inserted objects don't already have relationship
		// values, which may not be true.  Hence the user of STRICT_EOF
		if ((([relationship isToMany]) || ([relationship definition] != nil)) 
			#if !defined(STRICT_EOF)
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			// && (![object storedValueForKey: [relationship name]]) 
			&& (![object valueForKey: [relationship name]]) 
			#endif
		  ) 
		{
			array = [[EOMutableArray allocWithZone:[self zone]] init];
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			//[object takeStoredValue:array forKey:[relationship name]];
			// tom.martin @ riemer.com 2011-11-16
			// it turns out that the purpose of takeStoredValue is basically to 
			// avoid calling the accessor method so that willChange will NOT be called
			// I have implemented setPrimitiveValue:forKey to replace takeStoredValue:forKey:
			// So this method is replaced here.
			//[object setValue:array forKey:[relationship name]];
			[object setPrimitiveValue:array forKey:[relationship name]];
			[array release];
		}
	}
}

- (id)createInstanceWithEditingContext:(EOEditingContext *)anEditingContext globalID:(EOGlobalID *)globalID zone:(NSZone *)zone
{
	return [[[[entity _objectClass] allocWithZone:zone] initWithEditingContext:anEditingContext classDescription:self globalID:globalID] autorelease];
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

- (NSException *)validateObjectForDelete:(id)object
{
	/*! @todo Docs on this conflict.  The API references for this method says it returns nil.  However, the API reference for validateForDelete (which calls this), says that it does basic checking, including delete rules such as EODeleteRuleDeny. */
    
    // aclark @ ghoti.org    2005-12-08
    // Implemented this function to perform checking of delete rules
    NSException *exception = nil;
    
    NSEnumerator *relationshipKeys = [[self toOneRelationshipKeys] objectEnumerator];
    NSString *relationshipKey;
    
    while (relationshipKey = [relationshipKeys nextObject])
    {
        if ([self deleteRuleForRelationshipKey:relationshipKey] != EODeleteRuleDeny)
            continue;
        
        if ([object valueForKey: relationshipKey])
            exception = [self _mergeException:[NSException validationExceptionWithFormat:@"Relationship '%@' still references an object", relationshipKey] with:exception];
    }
    
    relationshipKeys = [[self toManyRelationshipKeys] objectEnumerator];
    while (relationshipKey = [relationshipKeys nextObject])
    {
        if ([self deleteRuleForRelationshipKey:relationshipKey] != EODeleteRuleDeny)
            continue;
        
        if ([[object valueForKey:relationshipKey] count])
            exception = [self _mergeException:[NSException validationExceptionWithFormat:@"Relationship '%@' still references objects", relationshipKey] with:exception];
    }
    
	return exception;
}


- (NSException *)validateObjectForSave:(id)object
{
	NSArray			*array;
	int				x;
	int numAttributes;
	int numKeys;
	NSException		*exception = nil;
	
	// Validate class properties.
	array = [entity attributes];
	numAttributes = [array count];
	for (x = 0; x < numAttributes; x++) {
		EOAttribute		*attribute = [array objectAtIndex:x];
		
		if ([attribute _isClassProperty]) {
			NSString			*key = [attribute name];
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			//id					value = [object storedValueForKey:key];
			id					value = [object valueForKey:key];
			exception = [self _mergeException:[self validateValue:&value forKey:key] with:exception];
		}
	}
	
	// mont_rothstein @ yahoo.com 2004-12-29
	// Comment this out because the primary key has not yet been fetched at this point in the
	// save process.  I'm not sure if validation should happen later in the process, or if
	// primary keys simply shouldn't be checked.
	// Validate primary key attributes
//	array = [entity primaryKeyAttributes];
//	for (x = 0; x < (const int)[array count]; x++) {
//		EOAttribute		*attribute = [array objectAtIndex:x];
//		
//		if (![attribute _isClassProperty]) {
//			NSString			*key = [attribute name];
//			id					value = [[object globalID] valueForKey:key];
//			exception = [self _mergeException:[self validateValue:&value forKey:key] with:exception];
//		}
//	}
	
	// Validate to one relationships (also indirectly validates the foreign key).
	array = [self toOneRelationshipKeys];
	numKeys = [array count];
	for (x = 0; x < numKeys; x++) {
		NSString			*key = [array objectAtIndex:x];
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//id					value = [object storedValueForKey:key];
		id					value = [object valueForKey:key];
		exception = [self _mergeException:[self validateValue:&value forKey:key] with:exception];
	}
	
	// Validate to many relationships.
	array = [self toManyRelationshipKeys];
	numKeys = [array count];
	for (x = 0; x < numKeys; x++) {
		NSString			*key = [array objectAtIndex:x];
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//id					value = [object storedValueForKey:key];
		id					value = [object valueForKey:key];
		exception = [self _mergeException:[self validateValue:&value forKey:key] with:exception];
	}
	
	return exception;
}

- (NSException *)validateValue:(id *)valuePointer forKey:(NSString *)key
{
	EOAttribute				*attribute;
	EORelationship			*relationship;
	
	// First, check attributes
	attribute = [entity attributeNamed:key];
	if (attribute) {
		return [attribute validateValue:valuePointer];
	}
	
	// Second check relationships
	relationship = [entity relationshipNamed:key];
	if (relationship) {
		return [relationship validateValue:valuePointer];
	}
	
	[NSException raise:NSInternalInconsistencyException format:@"Unknown property key (%@) to enterprise object %@ (0x%x)", key, NSStringFromClass([self class]), self];
	
	return nil;
}

- (NSFormatter *)defaultFormatterForKey:(NSString *)key
{
	EOAttribute		*attribute = [entity attributeNamed:key];
	NSString			*valueClassName;
	
	if (attribute == nil) return nil;
	
	return [NSClassFromString([attribute valueClassName]) defaultFormatterForAttribute:attribute];
}

- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)name
{
	return [entity fetchSpecificationNamed:name];
}

- (id)_valueForJoin:(EOJoin *)join inRelationship:(EORelationship *)relationship forObject:(id)object
{
	EOAttribute	*dst = [join destinationAttribute];
	id				dstObject;
	
	// mont_rothstein @ yahoo.com 2004-12-05
	// I am fairly certain this is supposed to send valueForKey: to object, not to self.
	//   dstObject = [self valueForKey:[relationship name]];
	dstObject = [object valueForKey:[relationship name]];
	if ([dst _isClassProperty]) {
		return [dstObject valueForKey:[dst name]];
	} else {
		EOGlobalID                *dstGlobalID = [dstObject globalID];
		
		// mont_rothstein @ yahoo.com 2005-04-02
		// The below line is unnecessary.  If the globalID is temporary it will try to get the
		// value from its new global ID (which this prohibited), if it doesn't have a new 
		// glabal ID it retusn nil.
//		if ([dstGlobalID isTemporary]) return nil;
		
		return [dstGlobalID valueForKey:[dst name]];
	}
	
	return nil;
}

// Tom.Martin @ Riemer.com 2012-3-26
// convert an array of EO's to an array of GIDs
- (NSArray *)_gidsForArray:(NSArray *)anArray
{
    NSMutableArray *result;
    id              object;
    id              aGID;
    
    result = [[NSMutableArray allocWithZone:[anArray zone]] initWithCapacity:[anArray count]];
    for (object in anArray)
    {
        aGID = [object globalID];
        // we will sliently fail to add GID's we can't find
        if (aGID)
            [result addObject:aGID];
    }
    return [result autorelease];
}

// Tom.Martin @ Riemer.com 2012-3-26
// re-factored from snapshotForObject: this now also serves the new method 
// contextSnapshotWithDBSnapshot:forObject: and generate either a undo snapshot or a 
// database snapshot the destinction being how the to-many relationship is archived.
// also we generate a database snapshot using the original database snapshot.
- (void)_updateSnapshot:(NSMutableDictionary *)snapshot fromObject:(id)object 
           isDBSnapshot:(BOOL)isDBSnapshot
{
	EOAttribute				*attribute;
    EOJoin                  *join;
	EORelationship			*relationship;
	NSString				*name;
	id						value;
	EOGlobalID				*globalID;
	
	// First, copy all the class properties.
    globalID = [object globalID];
    for (attribute in [entity attributes])
    {
        if ([attribute _isClassProperty])
        {
            name = [attribute name];
            value = [object valueForKey:name];
            // Tom.Martin @ riemer.com - 2012-02-16
            // blank strings are written to the database as nulls, we need the 
            // snapshot to match the database value
            if ([value isKindOfClass:[NSString class]])
            {
                if ([(NSString *)value length] == 0)
                    value = nil;
            }
			[snapshot setObject:value == nil ? [NSNull null] : value forKey:name];

        }
    }
	
   // If our global ID isn't temporary, we'll go ahead and add any values for it's attributes.        
    for (name in [entity primaryKeyAttributeNames])
    {
        attribute = [entity attributeNamed:name];
        // Only if we didn't get them previously
        if (! [attribute _isClassProperty])
        {
            value = [object valueForKey:name];
            // mont_rothstein @ yahoo.com 2004-12-05
			// In rare cases we won't have an editing context, and therefore it won't have
			// been able to give us our globalID.  This happens for many-to-many join objects
			// created during insert.  In those cases we need to grab the global ID from
			// the EOGenericRecord it self, where it will have been stored.
			if (!globalID) 
                globalID = [object valueForKey: @"globalID"];
            value = [globalID valueForKey:name];
			[snapshot setObject:value == nil ? [NSNull null] : value forKey:name];
        }
    }
    
    // set relationships
    // mont_rothstein @ yahoo.com 2004-12-05
    // We only want relationships that are class properties.
	// mont_rothstein @ yahoo.com 2005-09-22
	// In spite of the above comment this was grabbing all relationships instead of just ones that are clas properties.  This can cause problems for many-to-many joins among other things.  Changed the following two lines as well as necessary code after (_classRelationships is actually an array of names not actual relationships)
    //	relationships = [entity relationships];
    for (name in [entity _classRelationships])
    {
		relationship = [entity relationshipNamed:name];		
		name = [relationship name];
		if ([relationship isToMany]) 
        {
		    // mont_rothstein @ yahoo.com 2004-12-06
		    // We do not want to place toMany relationships in the snapshot at all.
		    // This causes faults to be tripped mid-fetch, which is bad.
			// mont_rothstein @ yahoo.com 2005-09-28
			// OK, the change noted above was wrong.  What we need to do here is check to see if the to-many relationship is still a fault and only if it is do we skip it.
            // tom.martin @ riemer.com 2012-03-27
            // And I am thinking we DO want the relationship even if it IS a fault, just take care
            // not to FIRE the fault.
			value = [object valueForKey:name];
            if (value)
            {
                if (! [EOFault isFault: value]) 
                {
                    // Tom.Martin @ Riemer.com 2012-3-26
                    // if this is destined to be a database snapshot then
                    // the to-many snapshot needs to be an array of GIDs
                    // if it is a undo snapshot then the to-many is a shallow copy
                    // of the to-many array.
                    if (isDBSnapshot)
                        value = [[self _gidsForArray:value] retain];
                    else
                        value = [value shallowCopy];
                    [snapshot setObject:value forKey:name];
                    [value release];
                }
                else if (! isDBSnapshot)
                    // store the fault if it is NOT a dbsnapshot
                    [snapshot setObject:value forKey:name];
            }
		} 
        else 
        {
			// Get all the foreign keys.
 			for (join in [relationship joins])
            {
                value = [self _valueForJoin:join inRelationship:relationship forObject:object];
				[snapshot setObject:value == nil ? [NSNull null] : value 
                             forKey:[[join sourceAttribute] name]];
            }
			// And the object itself.
			// mont_rothstein @ yahoo.com 2004-12-06
			// We only want the value if the relationship is a class property.  Otherwise we
			// end up trying to grab toMany relationships which we don't have.
            // Tom.Martin @ Riemer.com
            // Further we don't want the value if this is a context snapshot destined to be
            // a database snapshot.  
            if (! isDBSnapshot)
            {
                if ([relationship _isClassProperty])
                {
                    value = [object valueForKey:name];
                    [snapshot setObject:value == nil ? [NSNull null] : value forKey:name];
                }
            }
		}
	} 	
}

- (NSDictionary *)snapshotForObject:(id)object
{
	NSMutableDictionary  *snapshot = [NSMutableDictionary dictionary];
    [self _updateSnapshot:snapshot fromObject:object isDBSnapshot:NO];
    return snapshot;
}
    
// Tom.Martin @ Riemer.com 2012-03-26
// Add non API method to produce a snapshot that is destined to become a database snapshot.
// The difference between this and what 'snapshotForObject:' returns is that the to-many relationship is
// an array of GID's not a shallow copy,  also it does not contain a copy of the to-one objects
// Finally we build the snapshot from the ORIGINAL database snapshot just in case there are values 
// that in the snapshot THAT CAN NOT BE SET.  This is Extremely unlikely, but easy to do, so why not.
// this mehod is called from the database context when it creates its snapshots.
// This is called from enterprise object EOControl contextSnapshotWithDBSnapshot:
- (NSMutableDictionary *)contextSnapshotWithDBSnapshot:(NSDictionary *)dbsnapshot forObject:(id)object
{
    NSMutableDictionary *snapshot;
    if (dbsnapshot)
        snapshot = [dbsnapshot mutableCopyWithZone:[dbsnapshot zone]];
    else
        snapshot = [[NSMutableDictionary allocWithZone:[object zone]] initWithCapacity:20];
    [self _updateSnapshot:snapshot fromObject:object isDBSnapshot:YES];
    return [snapshot autorelease];
}
    
// mont_rothstein @ yahoo.com 2005-04-10
// Added override of method from EOControl
- (void)propagateDeleteForObject:(id)object editingContext:(EOEditingContext *)editingContext
{
	NSEnumerator *relationshipKeys;
	NSString *relationshipKey;
	EODeleteRule deleteRule;
	NSEnumerator *relatedObjects;
	NSObject *relatedObject;
	
	relationshipKeys = [[self toOneRelationshipKeys] objectEnumerator];
	
	while (relationshipKey = [relationshipKeys nextObject])
	{
		relatedObject = [object valueForKey: relationshipKey];
		if (relatedObject)
		{
			switch ([self deleteRuleForRelationshipKey: relationshipKey])
			{
				case  EODeleteRuleNullify :
					[object removeObject:relatedObject fromBothSidesOfRelationshipWithKey: relationshipKey];
					break;
				case EODeleteRuleCascade :
					[editingContext deleteObject:relatedObject];
					break;
				case EODeleteRuleDeny :
					// aclark @ ghoti.org   2005-12-08
					// implemented basic EODeleteRuleDeny
					[NSException raise: @"Denied" format: @"Can not delete because an object in relationship '%@' references this one.", relationshipKey];
					break;
				default : // EODeleteRuleNoAction
					break;
			}
		}
	}

	relationshipKeys = [[self toManyRelationshipKeys] objectEnumerator];
	
	while (relationshipKey = [relationshipKeys nextObject])
	{
		switch ([self deleteRuleForRelationshipKey: relationshipKey])
		{
			case  EODeleteRuleNullify :
				// mont_rothstein @ yahoo.com 2005-06-12
				// Changed an incorrect objectForKey: to valueForKey:
				relatedObjects = [[object valueForKey: relationshipKey] objectEnumerator];
				
				while (relatedObject = [relatedObjects nextObject])
				{
					[object removeObject: relatedObject fromBothSidesOfRelationshipWithKey: relationshipKey];
				}
					
				break;
			case EODeleteRuleCascade :
				relatedObjects = [[object valueForKey: relationshipKey] objectEnumerator];
				
				while (relatedObject = [relatedObjects nextObject])
				{
					[editingContext deleteObject: relatedObject];
				}
					
				break;
			case EODeleteRuleDeny :
                // aclark @ ghoti.org   2005-12-08
                // implemented basic EODeleteRuleDeny
                if ([[object valueForKey: relationshipKey] count])
                    [NSException raise: @"Denied" format: @"Can not delete because objects in relationship '%@' reference this one.", relationshipKey];
				break;
			default : // EODeleteRuleNoAction
				break;
		}
	}
}

// Tom.Martin @ Riemer.com 2012-3-27
// This takes a database/databaseContext snapshot which does not contain to-one objects, and
// has the to-many relationships as arrays of GIDs.  It converts the arrays of GIDs to arrays
// of objects (or fault) and SETS the to-one objects or re-faults them.
// this is used by revert when we have the database snapshot and we need to revert our object
// to the last saved image.  unfortunatly the database snapshot is missing some information  
// needed to make that easy.  The undo snapshot works great for this, and it is possible to 
// fill in the blanks from a database snapshot and make it look like an undo snapshot
// This method could potentialy be used elsewhere.
// 
// To recap: the purpose of this method is to CONVERT a database snapshot into an undo
// snapshot.  The resulting snapshot is identical to an undo snapshot that would have been
// been created if it were created the same time as the database snapshot was created.
- (NSDictionary *)snapshotFromDBSnapshot:(NSDictionary *)dbSnapshot forObject:(id)object
{
    NSMutableDictionary *snapshot;
    NSString            *name;
    EORelationship      *relationship;
    id                  value;
    EOEditingContext    *eoContext;
    EOGlobalID          *globalID;
    EOGlobalID          *aGID;
    id                  anObject;
  
    eoContext = [object editingContext];
    globalID = [object globalID];
    snapshot = [dbSnapshot copyWithZone:[dbSnapshot zone]];
    // so what is set now is all the entity attributes, what we DON't have set is our
    // relationships, so lets do that, but just do the class relationships
    for (name in [entity _classRelationships])
    {
		relationship = [entity relationshipNamed:name];		
		if ([relationship isToMany]) 
        {
            value = [dbSnapshot objectForKey:name];
            if (! value)
            {
                // replace with a fault
                value = [EOFault createArrayFaultWithSourceGlobalID:globalID 
                    relationshipName:name inEditingContext:eoContext];
            }
            else
            {
                // we have a snapshot, so use that
                NSMutableArray  *toManyArray;
                // convert an array of GIDs to an array of objects
                toManyArray = [[NSMutableArray allocWithZone:[value zone]] 
                               initWithCapacity:[value count]];
                for (aGID in value)
                {
                    anObject = [eoContext objectForGlobalID:aGID];
                    if (! anObject)
                    {
                        // The object is no longer in the editingContext
                        // it was probably released.  Just create a fault.
                        anObject = [eoContext faultForGlobalID:aGID editingContext:eoContext];
                    }
                    [toManyArray addObject:anObject];
                }
                value = [toManyArray autorelease];
            }
            [snapshot setObject:value forKey:name];
        }
        else
        {
            // build the GID from the snapshot
            NSMutableDictionary *row = [NSMutableDictionary dictionary];
            NSArray             *sourceAttributes;
            NSArray             *destinationAttributes;
            NSInteger           numAttributes;
            NSInteger           index;
            
			sourceAttributes = [relationship sourceAttributes];
			destinationAttributes = [relationship destinationAttributes];
			numAttributes = [sourceAttributes count];
			for (index = 0; index < numAttributes; index++)
			{
				value = [dbSnapshot objectForKey: [[sourceAttributes objectAtIndex: index] name]];
				
				if (value)
				{
					[row setObject: value
							forKey: [[destinationAttributes objectAtIndex: index] name]];
				}
			}
            aGID = [[relationship destinationEntity] globalIDForRow:row];
            // a lot of work to get the GID, now we try to get the object itself
            value = [eoContext objectForGlobalID:aGID];
            if (! value)
            {
                // The object is no longer in the editingContext
                // it was probably released.  Just create a fault.
                value = [eoContext faultForGlobalID:aGID editingContext:eoContext];
            }
            [snapshot setObject:value forKey:name];
        }
    }
    return [snapshot autorelease];
}

@end

@implementation EOEntityClassDescription (EOPrivate)

// mont_rothstein @ yahoo.com 2005-09-29
// Needed to add this method so that that the updateFromSnapshot: method in EOEnterpriseObject can be completed.  This was needed because when a new object was created, inserted, and added to relationships, it was not being removed from the relationship if revert was called before saving.
// Tom.Martin @ Riemer.com 2012-03-28
// This method is no longer needed becuase the to-many snapshots WILL be in the snapshot.
// However we still needed a special non API method to pull that off. 
// snapshotFromDBSnapshot:forObject: is doing this for us.  This method is potentialy useful
// so I made it public.
/*
- (void)completeUpdateForObject:(NSObject *)object fromSnapshot:(NSDictionary *)snapshot;
{
	NSEnumerator *toManyKeys;
	NSObject *value;
	NSString *key;

	toManyKeys = [[[self entity] _toManyRelationshipKeys] objectEnumerator];
	
	while (key = [toManyKeys nextObject])
	{
		value = [object valueForKey: key];

		if (([EOFault isFault: value]) || (value == nil) || (value == [NSNull null]) || ([snapshot objectForKey: key] != nil)) 
			continue;
		else
		// We only have to worry about those keys that don't have a value in the snapshot because if there was a value in the snapshot it was handled back in updateFromSnapshot:
		{
			// Any to-many relationships that have been tripped, but are not in the snapshot (meaning the relationship was a fault when the snapshot was last taken) need to re-set the realtionship back to a fault.
			EOFaultHandler *faultHandler = [[EOArrayFaultHandler alloc] initWithSourceGlobalID: [object globalID] relationshipName: key editingContext: [object editingContext]];
			[EOFault makeObjectIntoFault: value 
							 withHandler: faultHandler];
			[faultHandler release];
		}
	}
}
*/

// Tom.Martin @ Riemer.com 2012-03-28
// Method to detect changes in relationships in the object graph.  This creates a dictionary 
// that describes the changes found so that EOEditingContext may handle the changes. This method is
// called by EOEditingContext in saveChanges before processRecentChanges is called.
- (NSDictionary *)relationshipChangesForObject:(id)object withEditingContext:(EOEditingContext *)anEditingContext
{
	// changes will be a dictionary with two dictionaries. and one array 
    /*
    
     Two dictionaries
        removed
        added
     array 
        deleted
     
    each is a mutable.  For the dictionaries
    key = GID, value = DICTIONARY (not mutable)  any number of GID
        The GID is for the member object of a to-many relationship that has been
        detected to be deleted, removed, or added.
        The Dictionary keys and values:
            key: ownerGID (string)   value: The GID for the owner of the relationship
            key: relationshipName (string) value: the NAME for the relationship
            key = GID, value relationship  (any number of GID)
     The deleted dictionary is a bit different.  We don't care about the owner here, so
     we simply return an array of GID's that should be deleted from the editing context 
    
     we evaluate each object in a relationship and BUILD our deleted, removed and added 
     arrays/dictionaries.  if an object has been removed from a to-many relationship, 
     for instance, then we ADD the gid for that object allong with a dictionary for the 
     owning object and the to-many relationship for which the object was a member.
     
     EXAMPLE of changes:
        
     <dict>
        <key>removed</key>
        <dict>
            <key>@MemberGID</key>  // This is the object that was missing from the to-many
            <dict>
                <key>ownerGID</key>
                <object>@OwnerGID</object>  // This is the GID for the object that OWNS the to-many
                <key>relationshipName</key>
                <string>aRelationshipName</string>// This is the relationship name for OwnerGID >> MemberGID
            </dict>
            <key>@MemberGID</key>  // This is the object that was missing from the to-many\
            <dict>
                <key>ownerGID</key>
                <object>@OwnerGID</object>  // This is the GID for the object that OWNS the to-many
                <key>relationshipName</key>
                <string>aRelationshipName</string>// This is the relationship name for OwnerGID >> MemberGID        
            </dict>
            <key>added</key>
            <key>@MemberGID</key>  // This is the object that was added from the to-many
            <dict>
                <key>ownerGID</key>
                <object>@OwnerGID</object>  // This is the GID for the object that OWNS the to-many
                <key>relationshipName</key>
                <string>aRelationshipName</string>// This is the relationship name for OwnerGID >> MemberGID
                <key>@MemberGID</key>  // This is the object that was missing from the to-many
            </dict>
            <key>@MemberGID</key>  // This is the object that was added from the to-many
            <dict>
                <key>ownerGID</key>
                <object>@OwnerGID</object>  // This is the GID for the object that OWNS the to-many
                <key>relationshipName</key>
                <string>aRelationshipName</string>// This is the relationship name for OwnerGID >> MemberGID
            </dict>
        </dict>
        <key>deleted</key>
        <array>
            <@GID />  // objects that need to be deleted
            <@GID />
            <@GID />
        </array>
     </dict>
        
     */   

    // very similar to changesFromSnapshot:
    // the only difference here is that the snapshot is a EODatabase snapshot, not an object/undo snapshot
    // also we don't care about the object changes only the relationship changes.  The idea is to identify 
    // and return objects that need to be deleted from the editingContex or marked as modified so that they 
    // are available for save changes.  Also we need to return information so that all removed objects may be
    // processed in one pass, then added, then deleted.  The order is important so that we don't end up clearing
    // a foreign key that was just set. or deleting an object that was in fact MOVED.
    EODatabaseContext	*EOContext;
    NSDictionary        *dbSnapshot;
    EOGlobalID          *srcGlobalID;
    EOGlobalID          *dstGlobalID;
    NSString            *key;
    NSMutableDictionary	*changes;
    NSMutableArray      *deleted;
    NSMutableDictionary *removed;
    NSMutableDictionary *added;
    EORelationship		*relationship;
    
    // set up our return value
    changes = [[[NSMutableDictionary allocWithZone:[self zone]] init] autorelease];
    deleted = [[NSMutableArray allocWithZone:[self zone]] init];
    removed = [[NSMutableDictionary allocWithZone:[self zone]] init];
    added = [[NSMutableDictionary allocWithZone:[self zone]] init];
    [changes setObject:added forKey:@"added"];
    [changes setObject:removed forKey:@"removed"];
    [changes setObject:deleted forKey:@"deleted"];
    [added release];
    [removed release];
    [deleted release];
    
    EOContext = [EODatabaseContext registeredDatabaseContextForModel:[entity model] editingContext:anEditingContext];
    srcGlobalID = [anEditingContext globalIDForObject:object];
    
    // if this is a newly inserted object, there is no database snapshot, and no need to 
    // look for deleted to-ones or removed to-manys, just added to-manys
    if ([srcGlobalID isTemporary])
        dbSnapshot = nil;
    else
        dbSnapshot = [EOContext snapshotForGlobalID:srcGlobalID];
    
    if (dbSnapshot)
    {
        // Lets check the to-one relationships
        for (key in [self toOneRelationshipKeys]);
        {
            relationship = [entity relationshipNamed:key];    
            // we only need to be concerned with to-one relationships where we
            // own the destination, and we removed the original object.
            // If we ADDED an object, we don't care, because the ADDED ojbect
            // does not need any chanages, only the parent/source object.
            // the Source/Parent foriegn key(s) are set to the primary key
            // of the destination.
            //
            // so get the relationsihp first
            if ([relationship ownsDestination])
            {
                // The destination object needs to be deleted only if
                // there originall was an object and now that relationship
                // is nil or a different object.  Also if the relationship is a
                // Fault then it COULD have STILL changed if the object was set to 
                // a different object and then all objects were refaulted the 
                // to-one could be a fault and yet point to a different object.
                // SO, get the GID from the database snapshot and then compare that
                // to the GID of the existing object OR existing fault.
                NSArray             *sourceAttributes;
                NSArray             *destinationAttributes;
                NSMutableDictionary *row;
                id                  value;
                NSInteger           index, numAttributes;
                EOGlobalID          *newDstGlobalID;
                
                // re-create the original destination GID from the commited snapshot
                row = [NSMutableDictionary dictionary];
                sourceAttributes = [relationship sourceAttributes];
                destinationAttributes = [relationship destinationAttributes];
                numAttributes = [sourceAttributes count];
                EOAttribute *attrib;
                
                for (index = 0; index < numAttributes; index++)
                {
                    value = [dbSnapshot objectForKey:[[sourceAttributes objectAtIndex:index] name]];
                    
                    if (value)
                    {
                        [row setObject:value
                                forKey:[[destinationAttributes objectAtIndex:index] name]];
                    }
                }
                dstGlobalID = [[relationship destinationEntity] globalIDForRow: row];
                
                
                // You can't delete something if you never had anything
                if (dstGlobalID)
                {
                    id	left = [object valueForKey:key];
                    newDstGlobalID = nil;
                    if (left && left != [NSNull null])
                    {
                        // I am pretty sure this works even if the object is a fault.
                        // which means a GID may be added to the array that maps to
                        // a fault.
                        newDstGlobalID = [anEditingContext globalIDForObject:left];
                        if ([newDstGlobalID compare:dstGlobalID] != NSOrderedSame)
                            [deleted addObject:dstGlobalID];
                    }
                    else
                        [deleted addObject:dstGlobalID];
                }
            }
        }
    }
    
    // For to-many relationships we need to check for any objects that
    // wern't there before, and for any objects that have been removed.
    // Further, if an object has been removed, if the object is OWNED we
    // need to delete it,  otherwise it goes into the updated array	
    for (key in [self toManyRelationshipKeys]);
	{
        NSArray         *toManyArray;
        NSMutableArray  *newToManyArray;
        id              member;
        NSDictionary    *dstChangeDict;
        
        relationship = [entity relationshipNamed:key];    

        // convert the exiting to-many array of objects into an array of GID's so 
        // we can do the compare
        newToManyArray = [[NSMutableArray alloc] initWithCapacity:100];
        toManyArray = [object valueForKey:key];
        if (toManyArray && ((id)toManyArray != [EONull null]) && (! [EOFault isFault:toManyArray]))
        {
            EOGlobalID  *gid;
            for (member in toManyArray)
            {
                gid = [anEditingContext globalIDForObject:member];
                if (gid)
                {
                    [newToManyArray addObject:gid];
                }
            }
        }

        // This is just a bit easier than the to-one compare as we have a snapshot of the original array.
        // but of course only if there WAS a snapshot
        if (dbSnapshot)
        {
            toManyArray = [EOContext snapshotForSourceGlobalID:srcGlobalID relationshipName:key];
             
            // if the toManyArray was never fired then toManyArray should be nil.
            // AND newToManyArray should be a fault.  in this case there is nothing to do
            if (toManyArray)
            {
                // toMany WAS fired.  look for removed objects
                id                      value;


                      
                for (member in toManyArray)
                {
                    if (! [newToManyArray containsObject:member])
                    {
      
                        if ([relationship ownsDestination])
                            [deleted addObject:member]; // the object needs to be deleted
                        else
                        {
                            dstChangeDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                             srcGlobalID, @"ownerGID", 
                                             [relationship name], @"relationshipName", nil];
                            [removed setObject:dstChangeDict forKey:member]; // the foreign key needs to be nullified
                            [dstChangeDict release];
                        }
                    }
                }
            }
        }
        else
            toManyArray = nil;
            
        // now look for added object
        for (member in newToManyArray)
        {
            if (! [toManyArray containsObject:member])
            {
                dstChangeDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 srcGlobalID, @"ownerGID", 
                                 [relationship name], @"relationshipName", nil];
                [dstChangeDict release];
            }
        }
        [newToManyArray release];
    }
    
	return changes;
}

@end

