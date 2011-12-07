
#import "EOObjectStoreCoordinator.h"

#import "EOLog.h"
#import "EOCooperatingObjectStoreP.h"

NSString *EOCooperatingObjectStoreWasAdded = @"EOCooperatingObjectStoreWasAdded";
NSString *EOCooperatingObjectStoreWasRemoved = @"EOCooperatingObjectStoreWasRemoved";
NSString *EOCooperatingObjectStoreNeeded = @"EOCooperatingObjectStoreNeeded";

@implementation EOObjectStoreCoordinator

static EOObjectStoreCoordinator	*_eoDefaultCoordinator = nil;

- (id)init
{
	if (self = [super init])
	{
		storesLock = [[NSLock allocWithZone:[self zone]] init];
		objectStores = [[NSMutableArray allocWithZone:[self zone]] init];
	}

	return self;
}

+ (id)defaultCoordinator
{
	if (_eoDefaultCoordinator == nil) {
		_eoDefaultCoordinator = [[EOObjectStoreCoordinator alloc] init];
	}
	
	return _eoDefaultCoordinator;
}

+ (void)setDefaultCoordinator:(EOObjectStoreCoordinator *)coordinator
{
	if (_eoDefaultCoordinator != coordinator) {
		[_eoDefaultCoordinator release];
		_eoDefaultCoordinator = [coordinator retain];
	}
}

- (void)dealloc
{
	[objectStores release];
	[userInfo release];
	[storesLock release];
	
	[super dealloc];
}

// Safely returns a copy of the current array of object stores.
- (NSArray *)_objectStores
{
	NSArray		*stores;
	
	[storesLock lock];
	stores = [NSArray arrayWithArray:objectStores];
	[storesLock unlock];
	
	return stores;
}

- (void)addCooperatingObjectStore:(EOCooperatingObjectStore *)store
{
	if (![store isKindOfClass:[EOCooperatingObjectStore class]]) {
		[NSException raise:NSInternalInconsistencyException format:@"Attempt to add something other than a EOCooperatingObjectStore to a EOObjectStoreCoordinator."];
	}
	
	[objectStores addObject:store];
	[store _setCoordinator:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:EOCooperatingObjectStoreWasAdded object:self];
}

- (NSArray *)cooperatingObjectStores
{
	return objectStores;
}

- (void)forwardUpdateForObject:(id)object changes:(NSDictionary *)changes
{
}

- (EOCooperatingObjectStore *)_objectStoreForEntityNamed:(NSString *)name
{
	int			x;
	NSArray		*stores = [self _objectStores];
	
	for (x = 0; x < [stores count]; x++) {
		EOCooperatingObjectStore	*store;
		
		store = [stores objectAtIndex:x];
		if ([store _handlesEntityNamed:name]) return store;
	}
	
	return nil;
}

- (EOCooperatingObjectStore *)objectStoreForFetchSpecification:(EOFetchSpecification *)fetchSpecification
{
	int			tries = 0;
	
	do {
		int			x;
		NSArray		*stores = [self _objectStores];
		
		for (x = 0; x < [stores count]; x++) {
			EOCooperatingObjectStore	*store;
			
			store = [stores objectAtIndex:x];
			if ([store handlesFetchSpecification:fetchSpecification]) return store;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOCooperatingObjectStoreNeeded object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fetchSpecification, @"fetchSpecification", nil]];
		
		tries++;
	} while (tries <= 1);

	return nil;
}

- (EOCooperatingObjectStore *)objectStoreForGlobalID:(EOGlobalID *)globalID
{
	int			tries = 0;
	
	do {
		int			x;
		NSArray		*stores = [self _objectStores];
		
		for (x = 0; x < [stores count]; x++) {
			EOCooperatingObjectStore	*store;
			
			store = [stores objectAtIndex:x];
			if ([store ownsGlobalID:globalID]) return store;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOCooperatingObjectStoreNeeded object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:globalID, @"globalID", nil]];
		
		tries++;
	} while (tries <= 1);
	
	return nil;
}

- (EOCooperatingObjectStore *)objectStoreForObject:(id)object
{
	int			tries = 0;
	
	do {
		int			x;
		NSArray		*stores = [self _objectStores];
		
		for (x = 0; x < [stores count]; x++) {
			EOCooperatingObjectStore	*store;
			
			store = [stores objectAtIndex:x];
			if ([store ownsObject:object]) return store;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOCooperatingObjectStoreNeeded object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:object, @"object", nil]];
		
		tries++;
	} while (tries <= 1);
	
	return nil;
}

- (void)removeCooperatingObjectStore:(EOCooperatingObjectStore *)store
{
	[storesLock lock];
	if ([objectStores indexOfObjectIdenticalTo:store] != NSNotFound) {
		[objectStores removeObjectIdenticalTo:store];
		[[NSNotificationCenter defaultCenter] postNotificationName:EOCooperatingObjectStoreWasRemoved object:self];
	}
	[storesLock unlock];
		
}

- (void)saveChangesInEditingContext: (EOEditingContext *)anEditingContext
{
	// This method is the work horse of the whole object store procedure when saving objects.
	NSArray						*stores = [self _objectStores]; // To make sure the array doesn't change while working.
	int							storesCount = [stores count];
	NSException					*exception = nil;
	int			x;
	
	NS_DURING
		// First, let each object store get ready for the save operation.
		// lock all the stores first
		for (x = 0; x < storesCount; x++) {
			[[stores objectAtIndex:x] lock];
		}

		for (x = 0; x < storesCount; x++) {
			[[stores objectAtIndex:x] prepareForSaveWithCoordinator:self editingContext:anEditingContext];
		}
		// Now, have each record their changes.
		for (x = 0; x < storesCount; x++) {
			[[stores objectAtIndex:x] recordChangesInEditingContext];
		}
		// And finally have them do their changes.
		for (x = 0; x < storesCount; x++) {
			[[stores objectAtIndex:x] performChanges];
		}
		
		// unlock the stores
		for (x = 0; x < storesCount; x++) {
			[[stores objectAtIndex:x] unlock];
		}
	NS_HANDLER
		exception = [localException retain];
	NS_ENDHANDLER
	
	// Now, attempt to commit or rollback the changes, depending if the above generated an error or not.
	for (x = 0; x < storesCount; x++) {
		EOCooperatingObjectStore	*objectStore = [stores objectAtIndex:x];
		[objectStore lock];
		if (exception) {
			// An error did occur, so rollback the changes.
			NS_DURING
				[objectStore rollbackChanges];
			NS_HANDLER
				[EOLog logDebugWithFormat:@"Rollback failed on object store: %@", objectStore];
				[exception release];
				exception = [localException retain];
			NS_ENDHANDLER
		} else {
			// No error occurred, so we're good to go and we can commit the changes.
			NS_DURING
				[objectStore commitChanges];
			NS_HANDLER
				[EOLog logDebugWithFormat:@"Commit failed on object store: %@", objectStore];
				[exception release];
				exception = [localException retain];
			NS_ENDHANDLER
		}
		[objectStore unlock];
	}
	
	if (exception) {
		[exception autorelease];
		[exception raise];
	}
}

- (void)setUserInfo:(NSDictionary *)dictionary
{
	if (userInfo != dictionary) {
		[userInfo release];
		userInfo = [dictionary retain];
	}
}

- (NSDictionary *)userInfo
{
	return userInfo;
}

- (NSDictionary *)valuesForKeys:(NSArray *)keys object:(id)object
{
	return nil;
}

- (void)lock
{
    [super lock];
    [[self _objectStores] makeObjectsPerformSelector:@selector(lock)];
}

- (void)unlock
{
    [[self _objectStores] makeObjectsPerformSelector:@selector(unlock)];
	[super unlock];
}

- (id)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext
{
	return [[self objectStoreForGlobalID:globalID] arrayFaultWithSourceGlobalID:globalID relationshipName:relationshipName editingContext:anEditingContext];
}

- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	return [[self objectStoreForGlobalID:globalID] faultForGlobalID:globalID editingContext:anEditingContext];
}

- (id)faultForRawRow:(id)row entityNamed:(NSString *)entityName editingContext:(EOEditingContext *)anEditingContext
{
	return [[self _objectStoreForEntityNamed:entityName] faultForRawRow:row entityNamed:entityName editingContext:anEditingContext];
}

- (void)refaultObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)context
{
	[[self objectStoreForGlobalID:globalID] refaultObject:anObject withGlobalID:globalID editingContext:context];
}

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetch editingContext:(EOEditingContext *)context
{
	return [[self objectStoreForFetchSpecification:fetch] objectsWithFetchSpecification:fetch editingContext:context];
}

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)context
{
	return [[self objectStoreForGlobalID:globalID] objectsForSourceGlobalID:globalID relationshipName:relationshipName editingContext:context];
}

- (void)invalidateAllObjects
{
	NSArray		*stores = [self _objectStores]; // To make sure the array doesn't change while working.
	int			x;
	int numStores;
	
	numStores = [stores count];
	
	for (x = 0; x < numStores; x++) {
		[[stores objectAtIndex:x] invalidateAllObjects];
	}
}

- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs
{
	NSArray		*stores = [self _objectStores]; // To make sure the array doesn't change while working.
	int			x;
	int numStores;
	
	numStores = [stores count];
	for (x = 0; x < numStores; x++) {
		[[stores objectAtIndex:x] invalidateObjectsWithGlobalIDs:globalIDs];
	}
}

- (void)editingContext:(EOEditingContext *)anEditingContext didForgetObject:(id)object withGlobalID:(EOGlobalID *)globalID
{
	[[self objectStoreForGlobalID:globalID] editingContext:anEditingContext didForgetObject:object withGlobalID:globalID];
}

@end
