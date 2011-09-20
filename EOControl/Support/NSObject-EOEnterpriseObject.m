
#import "NSObject-EOEnterpriseObject.h"
// mont_rothstein @ yahoo.com 2004-12-06
// Added #import
#import "NSObject-EOEnterpriseObjectP.h"

#import "EOEditingContext.h"
#import "EOFault.h"
#import "EOGenericRecord.h"
#import "EOGlobalID.h"
#import "EOLog.h"
#import "NSArray-EO.h"
#import "NSClassDescription-EO.h"

#import <Foundation/Foundation.h>

// mont_rothstein @ yahoo.com 2005-01-14
// Added support for the EO's to keep a pointer to their editing context rather
// than having AJRUserInfo do it.

static NSHashTable	*eofInstanceObjects = NULL;

typedef struct _eofHashObject {
	unsigned					key;
	NSMutableDictionary	*objects;
} EOHashObject;

static unsigned _eofHash(NSHashTable *table, const EOHashObject *e1)
{
	return e1->key;
}

static BOOL _eofIsEqual(NSHashTable *table, const EOHashObject *e1, const EOHashObject *e2)
{
	return e1->key == e2->key;
}

static void _eofRetain(NSHashTable *table, const EOHashObject *e1)
{
	[e1->objects retain];
}

static void _eofRelease(NSHashTable *table, EOHashObject *e1)
{
	[e1->objects release];
    NSZoneFree(NSDefaultMallocZone(), e1);
}

static NSString *_eofDescribe(NSHashTable *table, const EOHashObject *e1)
{
	return [e1->objects description];
}

static NSHashTableCallBacks _eofHashCallbacks = {
	(NSUInteger (*)(NSHashTable *, const void *))_eofHash,
	(BOOL (*)(NSHashTable *, const void *, const void *))_eofIsEqual,
	(void (*)(NSHashTable *, const void *))_eofRetain,
	(void (*)(NSHashTable *, void *))_eofRelease,
	(NSString * (*)(NSHashTable *, const void *))_eofDescribe
};

static EOHashObject	*_eofKey = NULL;


@implementation NSObject (EOEnterpriseObject)

+ (void)load
{
	if (!_eofKey) {
		_eofKey = (EOHashObject *)NSZoneMalloc([(NSObject *)self zone], sizeof(EOHashObject));
		_eofKey->key = 0;
		_eofKey->objects = nil;
	}
}

- (void)_setEOFInstanceObject:(id)object forKey:(id)aKey
{
	EOHashObject	*element;
	
	if (!eofInstanceObjects) {
		eofInstanceObjects = NSCreateHashTable(_eofHashCallbacks, 101);
	}
	
	_eofKey->key = (NSUInteger)self;
	element = NSHashGet(eofInstanceObjects, _eofKey);
	if (!element) {
		element = (EOHashObject *)NSZoneMalloc([self zone], sizeof(EOHashObject));
		element->key = (NSUInteger)self;
		element->objects = [[NSMutableDictionary alloc] init];
		NSHashInsert(eofInstanceObjects, element);
		[element->objects release];
	}
	
	if (object == nil) {
		[element->objects removeObjectForKey:aKey];
	} else {
		[element->objects setObject:object forKey:aKey];
	}
}

- (id)_eofInstanceObjectForKey:(id)aKey
{
	if (eofInstanceObjects) {
		EOHashObject	*element;
		
		_eofKey->key = (NSUInteger)self;
		element = NSHashGet(eofInstanceObjects, _eofKey);
		if (element) {
			return [element->objects objectForKey:aKey];
		}
	}
	
	return nil;
}

// Remove this EO's pointer to its editing context.  This is called in EOAccess
// from the dealloc override method after the EO tells the editing context to forget it.
- (void)_clearInstanceObjects
{
    if (eofInstanceObjects) {
		EOHashObject	*element;
		
		_eofKey->key = (NSUInteger)self;
		element = NSHashGet(eofInstanceObjects, _eofKey);
		if (element) {
			NSHashRemove(eofInstanceObjects, _eofKey);
		}
    }
}


- (void)_setEditingContext:(EOEditingContext *)editingContext
{
	// mont_rothstein@yahoo.com 2006-03-09
	// If same editing context is already set we don't want to set it again because we would retain it too many times.  If we have a different EC set (which should really never happen) then we need to release it.
	if ([self editingContext] == editingContext) return;
	[self _setEOFInstanceObject: nil forKey: @"_eoEditingContext"];
	
	[self _setEOFInstanceObject:editingContext forKey:@"_eoEditingContext"];
}

// mont_rothstein @ yahoo.com 2004-12-05
// The following method was unnecesary.  See the comment in
// initWithEditingContext:classDescription:globalID:
//- (void)_setGlobalID:(EOGlobalID *)aGlobalID
//{
//	EOGlobalID		*_globalID = [self instanceObjectForKey:@"_eoGlobalID"];
//	
//   if (_globalID != aGlobalID) {
//      EOGlobalID		*oldGlobalID = [_globalID retain];
//      
//		[self setInstanceObject:aGlobalID forKey:@"_eoGlobalID"];
//		_globalID = aGlobalID;
//		
//      if (oldGlobalID != nil && _globalID != nil) {
//         [[NSNotificationCenter defaultCenter] postNotificationName:EOObjectDidUpdateGlobalIDNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldGlobalID, @"oldGlobalID", _globalID, @"newGlobalID", nil]];
//      }
//      [oldGlobalID release];
//   }
//}

// Initializing enterprise objects
- (id)initWithEditingContext:(EOEditingContext *)editingContext classDescription:(NSClassDescription *)classDescription globalID:(EOGlobalID *)globalID
{
	[self init];

	// mont_rothstein @ yahoo.com 2004-12-05
	// Commented these two lines out.  According to the WO 4.5 docs the editing context
	// and global ID should be ignored in the default implementation of this method.
	// Additionally they appear to be unnecessary.  The editing context is set in
	// EOEditingContext.m: recordObject:globalID:.  There was no accessor method for
	// the globalID, even though it was set below, and there doesn't need to be because
	// the editing context has it.
//	[self _setEditingContext:editingContext];
//	[self _setGlobalID:globalID];
	
	return self;
}

- (void)awakeFromFetchInEditingContext:(EOEditingContext *)editingContext
{
	[[self classDescription] awakeObjectFromFetch:self inEditingContext:editingContext];
}

- (void)awakeFromInsertionInEditingContext:(EOEditingContext *)editingContext
{
	[[self classDescription] awakeObjectFromInsert:self inEditingContext:editingContext];
}

- (void)willChange
{
	[EOObserverCenter notifyObserversObjectWillChange:self];
}

- (EOEditingContext *)editingContext
{
	return [self _eofInstanceObjectForKey:@"_eoEditingContext"];
}

- (NSArray *)allPropertyKeys
{
	NSClassDescription	*description = [self classDescription];
	NSMutableArray			*names = [NSMutableArray array];
	
	[names addObjectsFromArray:[description attributeKeys]];
	[names addObjectsFromArray:[description toOneRelationshipKeys]];
	[names addObjectsFromArray:[description toManyRelationshipKeys]];
	
	return names;
}

- (NSClassDescription *)classDescriptionForDestinationKey:(NSString *)key
{
	return [[self classDescription] classDescriptionForDestinationKey:key];
}

- (EODeleteRule)deleteRuleForRelationshipKey:(NSString *)key
{
	return [[self classDescription] deleteRuleForRelationshipKey:key];
}

- (NSString *)entityName
{
	return [[self classDescription] entityName];
}

- (BOOL)isToManyKey:(NSString *)key
{
	return [[[self classDescription] toManyRelationshipKeys] containsObject:key];
}

- (BOOL)ownsDestinationObjectsForRelationshipKey:(NSString *)key
{
	return [[self classDescription] ownsDestinationObjectsForRelationshipKey:key];
}

- (void)propagateDeleteWithEditingContext:(EOEditingContext *)editingContext
{
	// mont_rothstein @ yahoo.com 2005-04-10
	// Implemented this method
	[[self classDescription] propagateDeleteForObject: self editingContext: editingContext];
}

- (void)clearProperties
{
	NSArray		*array;
	int			x;
	int numObjects;
	
	array = [self toOneRelationshipKeys];
	numObjects = [array count];
	
	for (x = 0; x < numObjects; x++) {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behaviour is different.
		// It may be acceptable, and then again maybe not. 
		//[self takeStoredValue:nil forKey:[array objectAtIndex:x]];
		[self setValue:nil forKey:[array objectAtIndex:x]];
	}
	
	array = [self toManyRelationshipKeys];
	numObjects = [array count];
	
	for (x = 0; x < numObjects; x++) {
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behaviour is different.
		// It may be acceptable, and then again maybe not. 
		//[self takeStoredValue:nil forKey:[array objectAtIndex:x]];
		[self setValue:nil forKey:[array objectAtIndex:x]];
	}
}

- (NSDictionary *)snapshot
{
	return [[self classDescription] snapshotForObject:self];
}

- (void)updateFromSnapshot:(NSDictionary *)snapshot
{
	NSEnumerator		*enumerator = [snapshot keyEnumerator];
	NSString				*key;
	
	while ((key = [enumerator nextObject])) {
		if ([self isToManyKey:key]) {
			NSArray			*values = [snapshot valueForKey:key];
			if (values != nil) {
				NSMutableArray	*copy = [[NSMutableArray allocWithZone:[self zone]] init];
				[copy addObjectsFromArray:values];
				// tom.martin @ riemer.com - 2011-09-16
				// replace depreciated method.  This should be tested, behaviour is different.
				// It may be acceptable, and then again maybe not. 
				//[self takeStoredValue:copy forKey:key];
				[self setValue:copy forKey:key];
				[copy release];
			} 
		} else {
			// mont_rothstein @ yahoo.com 2005-07-11
			// If there are values in the snapshot that are not stored in the object, then just ignore the exceptions.  This isn't elegant, but to do more we would need knowledge about the EOEntity which is in EOAccess.
			NS_DURING
				// tom.martin @ riemer.com - 2011-09-16
				// replace depreciated method.  This should be tested, behaviour is different.
				// It may be acceptable, and then again maybe not. 
				//[self takeStoredValue:[snapshot valueForKey:key] forKey:key];
				[self setValue:[snapshot valueForKey:key] forKey:key];
			NS_HANDLER
				NS_ENDHANDLER
		}
	}
		
	[[self classDescription] completeUpdateForObject: self fromSnapshot: snapshot];
}

- (NSDictionary *)changesFromSnapshot:(NSDictionary *)snapshot
{
	NSArray					*keys;
	int						x;
	int numKeys;
	int numObjects;
	// mont_rothstein @ yahoo.com 2005-07-10
	// This was incorrectly creating a NSMutableArray instead of a NSMutableDictionary
	NSMutableDictionary	*changes = [[[NSMutableDictionary allocWithZone:[self zone]] init] autorelease];
	
	keys = [self classAttributeKeys];
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		id				left = [self valueForKey:key];
		id				right = [snapshot valueForKey:key];
		
		// mont_rothstein @ yahoo.com 2005-07-10
		// Added handling of null values in the snapshot
		// mont_rothstein @ yahoo.com 2005-09-29
		// Added better handling of snapshots
		if ((left == right) ||
			(left == nil && right == [NSNull null]) ||
			(left != [NSNull null] && right != [NSNull null] && [left isEqual: right]))
			continue;
		
		if (left != nil) [changes setObject: left forKey: key];
	}
	
	keys = [self toOneRelationshipKeys];
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		id				left = [self valueForKey:key];
		id				right = [snapshot valueForKey:key];
		
		// mont_rothstein @ yahoo.com 2005-08-30
		// Added handling of null values in the snapshot
		// mont_rothsteing @ yahoo.com 2005-09-29
		// Added better handling of null values
		if ((left == right) ||
			(left == nil && right == [NSNull null]) ||
			([EOFault isFault: left]) ||
			(left != [NSNull null] && right != [NSNull null] && [left isEqual: right]))
			continue;

		if (left != nil) [changes setObject:left forKey:key];
	}
	
	keys = [self toManyRelationshipKeys];
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString				*key = [keys objectAtIndex:x];
		NSArray				*left = [self valueForKey:key];
		NSArray				*right = [snapshot valueForKey:key];
		NSMutableArray		*added;
		NSMutableArray		*deleted;
		int					y;
		
		// mont_rothstein @ yahoo.com 2005-09-29
		// If right is nil, because there is no value in the snapshot, which is the case when the relationship was a fault when the snapshot was taken, then we have no way of knowing what was added so we have to continue.  Alternaitvely, we could simply return everything but that doesn't seem right.  Added check for right == nil
		// Ignore faults.
		if ([EOFault isFault:left] || [EOFault isFault:right] || right == nil) continue;
		
		if (right == (id)[NSNull null]) right = nil;
		
		added = [[NSMutableArray allocWithZone:[self zone]] init];
		deleted = [[NSMutableArray allocWithZone:[self zone]] init];
		if (right != nil) {
			[deleted addObjectsFromArray:right];
		}
		
		numObjects = [right count];
		
		// mont_rothstein @ yahoo.com 2005-09-29
		// Fixed typo.  Changed x++ to y++
		for (y = 0; y < numObjects; y++ ){
			id			object = [right objectAtIndex:y];
			
			if ([left indexOfObjectIdenticalTo:object] != NSNotFound) {
				[deleted removeObjectIdenticalTo:object];
			}
			// mont_rothstein @ yahoo.com 2005-09-29
			// Commented out the below lines because the objects from the relationship in the snapshot not in the relationship on the object are *not* the added objects, to get those we have to loop through the objects in the left array
			//			} else {
			//				[added addObject:object];
		}
		
		// mont_rothstein @ yahoo.com 2005-09-29
		// Added for loop over left objects to determine which are added
		numObjects = [left count];
		
		for (y = 0; y < numObjects; y++ ){
			id			object = [left objectAtIndex:y];
			
			if ([right indexOfObjectIdenticalTo:object] == NSNotFound) {
				[added addObject:object];
			}
		}
		
		if ([added count] || [deleted count]) {
			NSMutableArray		*value;
			
			value = [[NSMutableArray allocWithZone:[self zone]] initWithObjects:added, deleted, nil];
			// mont_rothstein @ yahoo.com 2005-07-10
			// takeValue:forKey: was deprecated, changed to setObject:forKey:
			// mont_rothstein @ yahoo.com 2005-09-29
			// Not sure if I made this mistake when I changed this before or not, but the below line was passing in right when it should have been passing in value.
			[changes setObject:value forKey:key];
			[value release];
		}
		
		[added release];
		[deleted release];
	}
	
	return changes;
}

- (void)reapplyChangesFromDictionary:(NSDictionary *)changes
{
	NSEnumerator		*enumerator = [changes keyEnumerator];
	NSString				*key;
	
	while ((key = [enumerator nextObject])) {
		id			object1 = [changes valueForKey:key];
		id			object2 = [self valueForKey:key];
		
		if ([self isToManyKey:key]) {
			NSArray		*toAdd = [object1 objectAtIndex:0];
			NSArray		*toRemove = [object1 objectAtIndex:1];
			
			// Should this only do this if the object isn't in the array? In other words, do we need to bother to check?
			[object2 addObjectsFromArray:toAdd];
			[object2 removeObjectsInArray:toRemove];
		} else {
			// This is sufficient, because we only care about pointer equality.
			if (object1 != object2) {
				// tom.martin @ riemer.com - 2011-09-16
				// replace depreciated method.  This should be tested, behavior is different.
				// It may be acceptable, and then again maybe not. 
				[self setValue:object1 forKey:key];
			}
		}
	}
}

- (NSString *)eoDescriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [self description];
}

- (NSString *)eoDescription
{
   return [self eoDescriptionWithLocale:nil indent:0];
}

- (NSString *)eoShallowDescriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [self description];
}

- (NSString *)eoShallowDescription
{
	return [self eoShallowDescriptionWithLocale:nil indent:0];
}

- (NSString *)userPresentableDescription
{
	return [self description];
}

- (EOGlobalID *)globalID
{
   return [[self editingContext] globalIDForObject:self];
}

// Manage instance variables

// mont_rothstein @ yahoo.com 2005-01-14
// Moved here from EOUserDefaults in AJRFoundation because it was conflicting with
// the re-direction of dealloc that allows an EO to tell its editing context to
// forget it.

@end

