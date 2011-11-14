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
		[object setValue:[anEditingContext arrayFaultWithSourceGlobalID:globalID relationshipName:[relationship name] editingContext:anEditingContext] forKey:[relationship name]];
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
			[object setValue:[anEditingContext faultForGlobalID:dstGlobalID editingContext:anEditingContext] forKey:[relationship name]];
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
			[object setValue:array forKey:[relationship name]];
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

- (NSDictionary *)snapshotForObject:(id)object
{
	/*! @todo This isn't sufficient, because we have to duplicate the relationships, at least pull out non-class values represented by relationship keys. */
	NSMutableDictionary  *snapshot = [NSMutableDictionary dictionary];
	NSArray					*primaryKeyAttributeNames = [entity primaryKeyAttributeNames];
	int						x;
	int numAttributes;
	int numRelationships;
	NSArray					*attributes = [entity attributes];
	EOAttribute				*attribute;
	NSArray					*relationships;
	EORelationship			*relationship;
	NSString					*name;
	id							value;
	EOGlobalID				*globalID = [object globalID];
	
	// First, copy all the class properties.
	numAttributes = [attributes count];
	for (x = 0; x < numAttributes; x++) {
		attribute = [attributes objectAtIndex:x];
		name = [attribute name];
		if ([attribute _isClassProperty]) {
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			//value = [object storedValueForKey:name];
			value = [object valueForKey:name];
			[snapshot setObject:value == nil ? [NSNull null] : value forKey:name];
		}
	}
	
   // If our global ID isn't temporary, we'll go ahead and add any values for it's attributes.
	numAttributes = [primaryKeyAttributeNames count];
	for (x = 0; x < numAttributes; x++) {
		attribute = [entity attributeNamed:[primaryKeyAttributeNames objectAtIndex:x]];
		if (![attribute _isClassProperty]) {
			// Only if we didn't get them previously
			name = [attribute name];
			
			// mont_rothstein @ yahoo.com 2004-12-05
			// In rare cases we won't have an editing context, and therefore it won't have
			// been able to give us our globalID.  This happens for many-to-many join objects
			// created during insert.  In those cases we need to grab the global ID from
			// the EOGenericRecord it self, where it will have been stored.
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			//if (!globalID) globalID = [object storedValueForKey: @"globalID"];
			if (!globalID) globalID = [object valueForKey: @"globalID"];

			value = [globalID valueForKey:name];
			[snapshot setObject:value == nil ? [NSNull null] : value forKey:name];
		}
	}
	
   // mont_rothstein @ yahoo.com 2004-12-05
   // We only want relationships that are class properties.
	// mont_rothstein @ yahoo.com 2005-09-22
	// In spite of the above comment this was grabbing all relationships instead of just ones that are class properties.  This can cause problems for many-to-many joins among other things.  Changed the following two lines as well as necessary code after (_classRelationships is actually an array of names not actual relationships)
//	relationships = [entity relationships];
   relationships = [entity _classRelationships];
	numRelationships = [relationships count];
	for (x = 0; x < numRelationships; x++) {
		relationship = [entity relationshipNamed: [relationships objectAtIndex:x]];
		
		name = [relationship name];
		if ([relationship isToMany]) {
		    // mont_rothstein @ yahoo.com 2004-12-06
		    // We do not want to place toMany relationships in the snapshot at all.
		    // This causes faults to be tripped mid-fetch, which is bad.
			// mont_rothstein @ yahoo.com 2005-09-28
			// OK, the change noted above was wrong.  What we need to do here is check to see if the to-many relationship is still a fault and only if it is do we skip it.
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  This should be tested, behavior is different.
			// It may be acceptable, and then again maybe not. 
			//value = [object storedValueForKey:name];
			value = [object valueForKey:name];
			if ([EOFault isFault: value]) continue;
			value = [value shallowCopy];
			[snapshot setObject:value == nil ? [NSNull null] : value forKey:name];
			[value release];
		} else {
			NSArray		*joins = [relationship joins];
			EOJoin		*join;
			int			y;
			
			// Get all the foreign keys.
			for (y = 0; y < [joins count]; y++) {
				join = [joins objectAtIndex:y];
				value = [self _valueForJoin:join inRelationship:relationship forObject:object];
				[snapshot setObject:value == nil ? [NSNull null] : value forKey:[[join sourceAttribute] name]];
			}
			
			// And the object itself.
			// mont_rothstein @ yahoo.com 2004-12-06
			// We only want the value if the relationship is a class property.  Otherwise we
			// end up trying to grab toMany relationships which we don't have.
			if ([relationship _isClassProperty])
			{
				// tom.martin @ riemer.com - 2011-09-16
				// replace depreciated method.  This should be tested, behavior is different.
				// It may be acceptable, and then again maybe not. 
				//value = [object storedValueForKey:name];
				value = [object valueForKey:name];
				[snapshot setObject:value == nil ? [NSNull null] : value forKey:name];
			}
		}
	}
	
	return snapshot;
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

@end

@implementation EOEntityClassDescription (EOPrivate)
// mont_rothstein @ yahoo.com 2005-09-29
// Needed to add this method so that that the updateFromSnapshot: method in EOEnterpriseObject can be completed.  This was needed because when a new object was created, inserted, and added to relationships, it was not being removed from the relationship if revert was called before saving.
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

@end

