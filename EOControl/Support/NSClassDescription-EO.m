
#import "NSClassDescription-EO.h"

#import "EOFormat.h"
#import "NSArray-EO.h"
#import "EOEnterpriseObject.h"
#import "EOEditingContext.h"
#import "EOFault.h"
#import "NSObject-EOEnterpriseObject.h"

#import <Foundation/Foundation.h>

@implementation NSClassDescription (EO)

+ (NSClassDescription *)classDescriptionForEntityName:(NSString *)entityName
{
	// mont_rothstein @ yahoo.com 2005-02-17
	// This method originally did nothing, assuming that it would be overridden by
	// an implementation in EOAccess.  Howver, the implmentation of this method in
	// EOAccess is in EOEntityClassDescription, not in a category.  Therefore 
	// it was never called.  This method has been changed to try and access the
	// EOEntityClassDescription class in EOAccess.

	Class otherClass = NSClassFromString(@"EOEntityClassDescription");
	if (otherClass != Nil) {
		return [otherClass classDescriptionForEntityName:entityName];
	}
	
	return nil;
}

- (id)createInstanceWithEditingContext:(EOEditingContext *)anEditingContext globalID:(EOGlobalID *)globalID zone:(NSZone *)zone
{
	/*! NSClassDescription-EO: Should do more. But main work horse in EOAccess will. */
	return nil;
}

- (NSString *)entityName
{
	// Does nothing. Overridden by subclasses.
}

- (void)propagateDeleteForObject:(id)object editingContext:(EOEditingContext *)anEditingContext
{
	// Do nothing, overridden in subclasses (EOAccess).
}

- (NSClassDescription *)classDescriptionForDestinationKey:(NSString *)key
{
	return nil;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey:(NSString *)key
{
	return NO;
}

- (EODeleteRule)deleteRuleForRelationshipKey:(NSString *)key
{
	return EODeleteRuleNullify;
}

- (void)awakeObjectFromFetch:(id)object inEditingContext:(EOEditingContext *)anEditingContext
{
}

- (void)awakeObjectFromInsert:(id)object inEditingContext:(EOEditingContext *)anEditingContext
{
}

- (NSException *)validateObjectForDelete:(id)object
{
	// Implemented in EOAccess
	return nil;
}

- (NSException *)validateObjectForSave:(id)object
{
	return nil;
}

- (NSException *)validateValue:(id *)value forKey:(NSString *)key
{
	// Implemented in EOAccess
	return nil;
}

- (NSFormatter *)defaultFormatterForKey:(NSString *)key
{
	return nil;
}

- (NSFormatter *)defaultFormatterForKeyPath:(NSString *)keyPath
{
	NSArray					*keys = [keyPath componentsSeparatedByString:@"."];
	int						x;
	int numKeys;
	NSClassDescription	*classDescription = self;
	
	numKeys = [keys count] - 1;
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		
		classDescription = [classDescription classDescriptionForDestinationKey:key];
		// Something that can't play nice, so no formatter.
		if (classDescription == nil) return nil;
	}
	
	return [classDescription defaultFormatterForKey:[keys lastObject]];
}

- (NSString *)displayNameForKey:(NSString *)key
{
	NSMutableString		*string = [[key capitalizedString] mutableCopy];
	NSCharacterSet			*lowerCase = [NSCharacterSet uppercaseLetterCharacterSet];
	NSCharacterSet			*upperCase = [NSCharacterSet lowercaseLetterCharacterSet];
	int						x;
	int stringLength;
	BOOL						insertSpace = NO;
	
	/*! @todo Make smarter: displayNameForKey: */
	
	stringLength = [string length];
	for (x = 0; x < stringLength; x++) {
		unichar character = [string characterAtIndex:x];
		
		if ([upperCase characterIsMember:character]) {
			if (insertSpace) {
				[string insertString:@"" atIndex:x];
				x++;
			}
			insertSpace = NO;
		}
		if ([lowerCase characterIsMember:character]) {
			insertSpace = YES;
		}
	}
	
	return [string autorelease];
}

- (NSString *)userPresentableDescriptionForObject:(id)object
{
	NSArray				*keys = [self attributeKeys];
	int					x;
	int numKeys;
	NSMutableString	*description;
	
	description = [[NSMutableString alloc] init];
	[description appendString:EOFormat(@"[%C (%p): ", self, self)];
	
	numKeys = [keys count];
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		NSFormatter	*formatter = [self defaultFormatterForKey:key];
		
		if (x != 0) [description appendString:@", "];
		
		[description appendString:key];
		[description appendString:@"="];
		if (formatter) {
			[description appendString:[formatter stringForObjectValue:[object valueForKey:key]]];
		} else {
			[description appendString:[[object valueForKey:key] description]];
		}
	}
	
	return [description autorelease];
}

- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)name
{
	return nil;
}

// Note that EOF doesn't do this here, but then EOF had tight control over the key/value coding protocol, which we don't, because it's defined by Apple, not us. For this reason, in order to be able to properly create a snapshot for an EO object, we have to do it in the class description, where we can be aware of the object's entity and relationships.
- (NSDictionary *)snapshotForObject:(id)object
{
	NSMutableDictionary	*snapshot = [[NSMutableDictionary allocWithZone:[self zone]] init];
	id						value;
    NSString                *key;
		
    for (key in [self attributeKeys])
    {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//value = [self storedValueForKey:key];
		//value = [self valueForKey:key];
        // tom.martin @ riemer.com - 2012-04-19
        // and so we did change it yet again.
        value = [self primitiveValueForKey:key];
        // tom.martin @ riemer.com - 2012-02-15
        // NSStrings need special handling becuase empty strings should
        // be treated as nulls.  An EONull string read by the database
        // may get changed to an empty string.  If we try to do an update
        // with optimistic locking and the database string is null yet the
        // snapshot is an empty string, then the row will not be updated.
        if ([value isKindOfClass:[NSString class]])
        {
            if ([(NSString *)value length] == 0)
                value = [NSNull null];
        }
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
	}
	
    for (key in [self toOneRelationshipKeys])
    {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//value = [self storedValueForKey:key];
        // tom.martin @ riemer.com - 2012-04-19
        // and so we did change it yet again. This would cause a fault to fire
        // when the EO was designed to do that.
		// value = [self valueForKey:key];
        value = [self primitiveValueForKey:key];
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
	}
	
    for (key in [self toManyRelationshipKeys])
    {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not.
		//value = [[self storedValueForKey:key] shallowCopy];
        // tom.martin @ riemer.com - 2012-04-19
        // and so we did change it yet again. This would cause a fault to fire
        // when the EO was designed to do that.
		// value = [[self valueForKey:key] shallowCopy];
        value = [[self primitiveValueForKey:key] shallowCopy];
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
		[value release];
	}
	
	return [snapshot autorelease];
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
    // unfortunatly there is realy no way to do this here, but... we will return SOMETHING.
    // this is overridden in EOAccess and this code here would never be called unless there is
    // not a model.
	NSMutableDictionary	*snapshot = [dbsnapshot mutableCopy];
    EOEditingContext    *eoContext;
	int                 x;
	int                 numKeys;
	NSArray				*keys;
	id					value;
	NSString            *key;
    
    eoContext = [object editingContext];
	keys = [self attributeKeys];
    
    for (key in keys)
    {
        value = [self primitiveValueForKey:key];
        // NSStrings need special handling becuase empty strings should
        // be treated as nulls.  An EONull string read by the database
        // may get changed to an empty string.  If we try to do an update
        // with optimistic locking and the database string is null yet the
        // snapshot is an empty string, then the row will not be updated.
        if ([value isKindOfClass:[NSString class]])
        {
            if ([(NSString *)value length] == 0)
                value = [NSNull null];
        }
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
	}
	
    // we do NOT include toOne objects
    // but we also have no way of setting foriegn keys to the to-ones either
    // that is too bad, but nothing can be done.
    
    // handle the toMany relationships
    for (key in [self toManyRelationshipKeys])
    {
        NSArray         *anArray;
        id              anObject;
        NSMutableArray  *result = nil;
		anArray = [self primitiveValueForKey:key];
        if (anArray)
        {
            id aGID;
            NSMutableArray *result = [[NSMutableArray allocWithZone:[anArray zone]] 
                                      initWithCapacity:[anArray count]];
            for (anObject in anArray)
            {
                aGID = [eoContext globalIDForObject:anObject];
                if (aGID)
                    [result addObject:aGID];
            }
        }
        [snapshot setObject:(result == nil) ? [NSNull null] : result forKey:key];
		[result release];
	}
	
	return [snapshot autorelease];
}

- (NSDictionary *)snapshotFromDBSnapshot:(NSDictionary *)dbSnapshot forObject:(id)object
{
    // This must be overriden in EOAccess
    // but we will give it a stab here just in case there is no model.
    // this will not work well since we can to nothing about the to-one relationships
    NSMutableDictionary *snapshot;
    NSString            *name;
    id                  value;
    EOEditingContext    *eoContext;
    EOGlobalID          *globalID;
    EOGlobalID          *aGID;
    id                  anObject;
    
    eoContext = [object editingContext];
    globalID = [eoContext globalIDForObject:object];
    snapshot = [dbSnapshot copyWithZone:[dbSnapshot zone]];
    for (name in [self toManyRelationshipKeys])
    {
        {
            value = [dbSnapshot objectForKey:name];
            if (! value)
            {
                // replace with a fault
                value = [eoContext arrayFaultWithSourceGlobalID:globalID
                        relationshipName:name editingContext:eoContext];
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
     }
    return [snapshot autorelease];
}

@end

@implementation NSClassDescription (EOPrivate)

// mont_rothstein @ yahoo.com 2005-09-29
// Needed to add this method so that it can be overridden in EOAccess, so that the updateFromSnapshot: method in EOEnterpriseObject can be completed.
// Tom.Martin @ Riemer.com 2012-03-28
// This method is no longer needed becuase the to-many snapshots WILL be in the snapshot.
// However we still needed a special non API method to pull that off. 
// snapshotFromDBSnapshot:forObject: is doing this for us.  This method is potentialy useful
// so I made it public.
/*
- (void)completeUpdateForObject:(NSObject *)object fromSnapshot:(NSDictionary *)snapshot;
{
	
}
*/

// Tom.Martin @ Riemer.com 2012-3-6
// This is here so that it can be overridden in EOAccess.
- (NSDictionary *)relationshipChangesForObject:(id)object withEditingContext:(EOEditingContext *)anEditingContext
{
    return nil;
}

@end

@implementation EOClassDescription

@end

