
#import <Foundation/Foundation.h>

@class EOEditingContext, EOFetchSpecification, EOGlobalID, EOFaultHandler;

extern NSString *EOInvalidatedAllObjectsInStoreNotification;
extern NSString *EOObjectsChangedInStoreNotification;

// mont_rothstein @ yahoo.com 2005-08-08
// Added keys used in notification posts
extern NSString *EODeletedKey;
extern NSString *EOInvalidatedKey;
extern NSString *EOInsertedKey;
extern NSString *EOUpdatedKey;


@interface EOObjectStore : NSObject
{
	NSRecursiveLock		*lock;
	int						lockCount;
}

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext;
- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (id)faultForRawRow:(id)row entityNamed:(NSString *)entityName editingContext:(EOEditingContext *)anEditingContext;
- (void)initializeObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (void)invalidateAllObjects;
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs;
- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (void)lockObjectWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext;
- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)aFetchSpecification editingContext:(EOEditingContext *)anEditingContext;
- (void)refaultObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;
- (void)saveChangesInEditingContext:(EOEditingContext *)anEditingContext;
// Not sure if this is the correct method signature - Apple's missing the html file for this page.
- (void)editingContext:(EOEditingContext *)anEditingContext didForgetObject:(id)object withGlobalID:(EOGlobalID *)globalID;

- (BOOL)tryLock;
- (void)lock;
- (void)unlock;

@end
