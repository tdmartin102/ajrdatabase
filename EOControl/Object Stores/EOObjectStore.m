
#import "EOObjectStore.h"

NSString *EOInvalidatedAllObjectsInStoreNotification = @"EOInvalidatedAllObjectsInStoreNotification";
NSString *EOObjectsChangedInStoreNotification = @"EOObjectsChangedInStoreNotification";

// mont_rothstein @ yahoo.com 2005-08-08
// Added keys used in notification posts
NSString *EODeletedKey = @"EODeletedKey";
NSString *EOInvalidatedKey = @"EOInvalidatedKey";
NSString *EOInsertedKey = @"EOInsertedKey";
NSString *EOUpdatedKey = @"EOUpdatedKey";

@implementation EOObjectStore

- (id)init
{
	lock = [[NSRecursiveLock allocWithZone:[self zone]] init];
	lockCount = 0;
	
	return self;
}

- (void)dealloc
{
	[lock release];
	
	[super dealloc];
}

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext
{
	return nil;
}

- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	return nil;
}

- (id)faultForRawRow:(id)row entityNamed:(NSString *)entityName editingContext:(EOEditingContext *)anEditingContext
{
	return nil;
}

- (void)initializeObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
}

- (void)invalidateAllObjects
{
}

- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs
{
}

- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	return NO;
}

- (void)lockObjectWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
}

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext
{
	return nil;
}

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)aFetchSpecification editingContext:(EOEditingContext *)anEditingContext
{
	return nil;
}

- (void)refaultObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
}

- (void)saveChangesInEditingContext:(EOEditingContext *)anEditingContext
{
}

- (void)editingContext:(EOEditingContext *)anEditingContext didForgetObject:(id)object withGlobalID:(EOGlobalID *)globalID
{
}

- (void)lock
{
	[lock lock];
	lockCount++;
}

- (BOOL)tryLock
{
	if ([lock tryLock]) {
		lockCount++;
		return YES;
	}
	return NO;
}

- (void)unlock
{
	if (lockCount) {
		lockCount--;
		[lock unlock];
	}
}

@end

