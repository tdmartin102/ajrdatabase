//
//  EODatabaseOperation.m
//  EOAccess/
//
//  Created by Alex Raftis on Tue Sep 14 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EODatabaseOperation.h"

#import "EOAdaptorOperationP.h"
#import "EOAttributeP.h"
#import "EODatabaseContext.h"
#import "EOEditingContext-EOAccess.h"
#import "EOEntity.h"
#import "EOJoin.h"
#import "EORelationship.h"
#import "EOEditingContext-EOAccess.h"

#import <EOControl/EOFault.h>
#import <EOControl/EOGenericRecord.h>
#import <EOControl/EOGlobalID.h>
#import <EOControl/NSObject-EOEnterpriseObject.h>

@implementation EODatabaseOperation

- (id)initWithGlobalID:(EOGlobalID *)aGlobalID object:(id)anObject entity:(EOEntity *)anEntity
{
    EODatabaseContext   *databaseContext;
    NSDictionary        *aSnapshot;
    NSMutableDictionary *contextSnapshot;
    
	if (self = [super init])
	{
		globalID = [aGlobalID retain];
		object = [anObject retain];
		entity = [anEntity retain];
  	}
	
	return self;
}

- (void)dealloc
{
	[globalID release];
	[object release];
	[entity release];
	[snapshot release];
	[newRow release];
	[adaptorOperations release];
	[toManySnapshots release];
	
	[super dealloc];
}

- (EOGlobalID *)globalID
{
	return globalID;
}

- (id)object
{
	return object;
}

- (EOEntity *)entity
{
	return entity;
}

- (void)setDatabaseOperator:(EODatabaseOperator)anOperation
{
	databaseOperator = anOperation;
}

- (EODatabaseOperator)databaseOperator
{
	return databaseOperator;
}

- (void)setEOSnapshot:(NSDictionary *)aSnapshot
{
	if (snapshot != aSnapshot) {
		[snapshot release];
		snapshot = [aSnapshot retain];
	}
}

- (NSDictionary *)EOSnapshot
{
	return snapshot;
}

- (void)setNewRow:(NSMutableDictionary *)aRow
{
	if (newRow != aRow) {
		[newRow release];
		newRow = [aRow retain];
	}
}

- (NSMutableDictionary *)newRow
{
	return newRow;
}

	// Accessing the adaptor operations
- (void)addAdaptorOperation:(EOAdaptorOperation *)anOperation
{
	if (adaptorOperations == nil) adaptorOperations = [[NSMutableArray allocWithZone:[self zone]] init];
	[adaptorOperations addObject:anOperation];
	[anOperation _setDatabaseOperation:self];
}

- (void)removeAdaptorOperation:(EOAdaptorOperation *)anOperation
{
	[adaptorOperations removeObject:anOperation];
}

- (NSArray *)adaptorOperations
{
	return adaptorOperations;
}

/*!
  Tom.Martin @Riemer.com 2012-04-05
  And we no longer need this at all..
* Get the correct value for the given key from the correct location. This
 * works for any attribute type. The rules are as follows:
 *
 * 1. If the attribute is a class property, just return object.getValue(...).
 * 2. If the attribute is not a class property, but is part of the primary key,
 *    then query it's global id. This means that the primary must have been
 *    converted from a temporary global ID if this object is newly inserted.
 *    Basically, don't call this method unless you've already harvested
 *    primary keys on the object graph.
 * 3. If it's not a class property, and not a primary key attribute, then
 *    go to the object's snapshot for it's value.
 *
 * Because of the contraints of point 2, this method would normally only be
 * called during the save cycle, after validation and after we've fetch
 * the primary keys.
 *
 *Tom.Martin @ Riemer.com
 *I reworked this to access the context snapshot or database snapshot.
 *The only problem with the old method was calling [object snapshot] 
 *which is a very expensive call. [object snapshot] was called when
 *the databaseContext snapshot was created during the save cycle.  PLUS
 *the primaryKey values are there without getting them from the globalID
 *IF there is no snapshot in the databaseContext then the database snapshot
 *can be used and IT will have any value we want as well.   As in the 
 *previous incarnation this is ONLY valid during the save cycle after
 *primary keys have been harvested AND after all databaseContext snapshots
 *have been created IN ALL databaseContext instances!!
 *
 *So the new rules are:
 *  1.  If a databaseContext snapshot exists the value is gotten from that.
 *      These values reflect the objects current state.
 *  2.  If no databaeContext snapshot exists it will go to the database
 *      snapshot for the value.
 *
 * @param object The object who's value we're attempting to access.
 * @param attribute The object's entity's attribute we're fetching.
 *
 * @return The value querried from the objects snapshot. See rules 
 *         1 through 2 for how this works.

- (id)_valueForAttribute:(EOAttribute *)attribute inObject:(id)anObject
{
    
 //  NSString	*key = [attribute name];
 //  if ([attribute _isClassProperty]) {
 //     return [anObject valueForKey:key];
 //  } else if ([attribute _isPrimaryKey]) {
 //     return [[anObject globalID] valueForKey:key];
 //  } else {
 //     return [[anObject snapshot] objectForKey:key];
 //  }
         
    EOEditingContext *eoContext;
    EOGlobalID *aGID; 
    EODatabaseContext *databaseContext;      

    // find the database context for this object.
    eoContext = [anObject editingContext];
    aGID = [eoContext globalIDForObject:anObject];  
    databaseContext = [eoContext databaseContextForModelNamed:[aGID entityName]];
    return [[databaseContext snapshotForGlobalID:aGID] objectForKey:[attribute name]];
}
*/

/*!
 Tom.Martin @ Riemer.com 2012-04-05
 Removed this method as this is no longer done here.  The newRow is set by EODatabaseContext
 and all attribues are set BEFORE it is passed along to EODatabaseOperation.
* This internal method is called from _updatedAttributesForObject:snapshot: to help determine
 * when to-one relationships have updated. Basicallly it checks the foreign
 * key defining the relationship to see if the relationship has updated.
 *
 * You normally shouldn't call this.
 *
 * @param relationship  The relationship to check.
 * @param object        The object using the relationship.
 * @param snapshot      The object's snapshot.
 * @param updated       A Hashtable which will be updated to reflect any
 *                      changes in the relationship.
 
// mont_rothstein @ yahoo.com 2004-12-2
// Removed withSnapshot: from method name because snapshot is an instance variable
- (void)_addToOneRelationship:(EORelationship *)relationship
				 andUpdatedValues:(NSMutableDictionary *)updated
{
   id					sourceValue;
   EOAttribute		*sourceAttribute;
   id					destinationValue;
   EOAttribute		*destinationAttribute;
   NSArray			*joins = [relationship joins];
   EOJoin			*join;
   int				jIndex, jMax;
   NSString			*key = [relationship name];
	
   for (jIndex = 0, jMax = [joins count]; jIndex < jMax; jIndex++) {
      join = [joins objectAtIndex:jIndex];
      sourceAttribute = [join sourceAttribute];
	  // mont_rothstein @ yahoo.com 2004-12-2
	  // The below line was changed because we don't want to get the value from the object
	  // itself, which is what _valueForAttribute:inObject: does, we want to get it from
	  // the snapshot, i.e. what it was when it was fetched from the EO.
	  // sourceValue = [self _valueForAttribute:sourceAttribute inObject:object];
      sourceValue = [snapshot objectForKey: [sourceAttribute name]];
      destinationAttribute = [join destinationAttribute];
      destinationValue = [self _valueForAttribute:destinationAttribute inObject:[object valueForKey:key]];
	  // mont_rothstein @ yahoo.com 2004-12-14
	  // Added check for both values being nil
	  // tom.Martin @ Riemer.com 2011-08-17 sourcevalue may also be NSNull
      if (!(((sourceValue == nil) || (sourceValue == [NSNull null])) && destinationValue == nil) &&
		  (![sourceValue isEqual:destinationValue])) {
         if (destinationValue == nil) {
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
            //[updated takeValue:[NSNull null] forKey:[sourceAttribute name]];
			[updated setValue:[NSNull null] forKey:[sourceAttribute name]];
         } else {
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
            //[updated takeValue:destinationValue forKey:[sourceAttribute name]];
			[updated setValue:destinationValue forKey:[sourceAttribute name]];
         }
      }
      //[EOLog logDebugWithFormat:@"\t%@ / %@\n", sourceValue, destinationValue];
   }
}
 */


/*!
 * Determines what attributes have been updated in our object. The object is
 * compared against it's snapshot to see if it's been updated. This method
 * should only be called once the object graph has had it's primary keys
 * generated.
 *
 *
 * @return A NSDictionary filled with key/value pairs of the values updated
 *        from the original database snapshot to the new database row.
 */
- (NSDictionary *)rowDiffs
{
    // tom.martin @ Riemer.com 2012-04-05
    // we want to get row diffs for MORE than just the classProperties
    // we want ALL the changes between the original row and the 
    // newRow.  We want all attributes that are not relationships 
    // derivied, or read only.  Instead of filtering out inappropriate
    // attributes, rowDiffsForAttributes will simply ignore
    // attributes that we do not track changes for.
	//return [self rowDiffsForAttributes:[entity classProperties]];
    return [self rowDiffsForAttributes:[entity attributes]];
}

- (NSDictionary *)rowDiffsForAttributes:(NSArray *)attributes
{
    NSMutableDictionary	*updated = [[[NSMutableDictionary allocWithZone:[self zone]] init] autorelease];
    int					x, max;
    NSString			*key;
    id					value1, value2;
    EOAttribute			*attribute;
	
    // First, check class properties...
    for (attribute in attributes)
    {
        // If this attribute is read only or derived then we skip it
        // if it is flattened, I'm unsure what we should do, I need to
        // revisit that, for now we will ignore it.
        if ((! [attribute isKindOfClass:[EOAttribute class]]) || ([attribute isReadOnly]) || 
            ([attribute isFlattened]))
            continue;
        
        key = [attribute name];
        value1 = [snapshot valueForKey:key];
        // tom.martin @ riemer.com 2011-08-16
        // fixed no op if (value1 == nil) value1 = nil;
        // to what was probably intended
        // 2012-2-15 ALSO deal with NSString equivelents
        // I am considering a string of length 0, EONull, nil all equivilent
        if (value1)
        {
            if (value1 == [NSNull null]) 
                value1 = nil;
            else if ([value1 isKindOfClass:[NSString class]])
            {
                if ([(NSString *)value1 length] == 0)
                    value1 = nil;
            }
        }
        // Tom.Martin @ Riemer.com 2012-04-04
        // get the value from our new row not the object
        // new row contains updated values from to-many relationships.
        // object does NOT. it also has values for HIDDEN attributes
        // not just the class attributes.
        // value2 = [object valueForKey:key];
        value2 = [newRow objectForKey:key];
        // tom.martin @ riemer.com 2011-08-16
        // valueForKey returns a string with no length when the object value is a string, and is nil;
        // The snapshot would be nil or NSNull.  strange.
        if ([value2 isKindOfClass:[NSString class]]) 
        {
            if ([(NSString *)value2 length] == 0)
             value2 = nil;
        
        }
        if (value1 == value2) continue;
        // tom.martin @ riemer.com 2011-08-16
        // got rid of redundant test
        //if (value1 == nil && value2 == nil) continue;
        if ((value1 != nil && value2 == nil) ||
            (value1 == nil && value2 != nil) ||
            (![value1 isEqual:value2])) {
            // aclark @ ghoti.org 2005-08-11
            // This was setting the value to nil fixed it to use NSNull.
            // tom.martin @ riemer.com - 2011-09-16
            // replace depreciated method.  
            //[updated takeValue:value2 == nil ? [NSNull null] : value2 forKey:key];
            [updated setValue:value2 == nil ? [NSNull null] : value2 forKey:key];
        }
    
        
        /*  
         Tom.Martin @ Riemer.com 2012-04-05
         The folloing code is no longer needed.  The attributes for foriegn keys
         to to-one relationships were set when the snapshot was created from the 
         object in EOEntityDescription.  foreign keys for to-many relationships
         is set by EODatabaseContext in a separate pass, so this is not evaluated
         here.  Basically when we get to this point the values in newRow
         are actually what the values in the newRow SHOULD be.
         
        else {
            EORelationship  	*relationship = (EORelationship *)attribute;
            id						value;
		
            // tom.martin @ riemer.com - 2011-09-16
            // replace depreciated method.  This should be tested, behavior is different.
            // It may be acceptable, and then again maybe not. 
            //value = [object storedValueForKey:key];
            value = [object valueForKey:key];

            //[EOLog logDebugWithFormat:@"%@ %@ is a fault\n", key, ([EOFault isFault:value] ? @"is" : @"isn't")];
			
            if (![EOFault isFault:value]) {
                // We only need to check the relationship if it's not a fault
                // since if it is, then the foreign key can't have changed,
                // now can it?
                if ([relationship isToMany]) {
                    if ([relationship definition] == nil) {
                        //! @todo See if many-many relationship has updated 
                    } else {
                        //! @todo See if to-many relationship has updated 
                    }
                } else {
                    // mont_rothstein @ yahoo.com 2004-12-2
                    // Removed withSnapshot: from method name because snapshot is an instance variable
                    
                    [self _addToOneRelationship:relationship andUpdatedValues:updated];
                }
            }
        }

        */

        
        
    }
	
    return updated;
}

// Tom.Martin @ Riemer.com 2012-04-05
// These snapshot methods are never called. Further this is broken.  The to-many snapshot is
// actually stored in the newRow dictionary NOT in the toManySnapshots dictionary which is never
// consulted.  This SHOULD be updated I suppose, but on the other hand it simply is not used.
// If this were to be fixed they would set the value in newRor for the key = name.
- (void)recordToManySnapshot:(NSArray *)snapshots relationshipName:(NSString *)name
{
	if (toManySnapshots == nil) toManySnapshots = [[NSMutableDictionary allocWithZone:[self zone]] init];
	[toManySnapshots setObject:snapshots forKey:name];
}

- (NSDictionary *)toManySnapshots
{
	return toManySnapshots;
}

@end
