
#import "EOObjectStore.h"

extern NSString *EOCooperatingObjectStoreWasAdded;
extern NSString *EOCooperatingObjectStoreWasRemoved;
extern NSString *EOCooperatingObjectStoreNeeded;

@class EOCooperatingObjectStore, EOEditingContext, EOFetchSpecification, EOGlobalID;

@interface EOObjectStoreCoordinator : EOObjectStore
{
	NSMutableArray		*objectStores;
	NSDictionary		*userInfo;

	NSLock				*storesLock;
}

// Initializing instances
- (id)init;

// Setting the default coordinator
+ (id)defaultCoordinator;
+ (void)setDefaultCoordinator:(EOObjectStoreCoordinator *)coordinator;

// Managing EOCooperatingObjectStores
- (void)addCooperatingObjectStore:(EOCooperatingObjectStore *)store;
- (void)removeCooperatingObjectStore:(EOCooperatingObjectStore *)store;
- (NSArray *)cooperatingObjectStores;

// Saving changes
- (void)saveChangesInEditingContext:(EOEditingContext *)anEditingContext;

// Communication between EOCooperatingObjectStores
- (void)forwardUpdateForObject:(id)object changes:(NSDictionary *)changes;
- (NSDictionary *)valuesForKeys:(NSArray *)keys object:(id)object;
	
// Returning EOCooperatingObjectStores
- (EOCooperatingObjectStore *)objectStoreForFetchSpecification:(EOFetchSpecification *)fetchSpecification;
- (EOCooperatingObjectStore *)objectStoreForGlobalID:(EOGlobalID *)globalID;
- (EOCooperatingObjectStore *)objectStoreForObject:(id)object;

// Getting the userInfo dictionary
- (void)setUserInfo:(NSDictionary *)dictionary;
- (NSDictionary *)userInfo;

// Locking
- (void)lock;
- (void)unlock;

// Getting faults
- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)context;
- (id)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)context;
- (void)refaultObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)context;

// Getting objects
- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetch editingContext:(EOEditingContext *)context;
- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)context;

// Saving changes to objects
- (void)saveChangesInEditingContext:(EOEditingContext *)context;

// Invalidating objects
- (void)invalidateAllObjects;
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs;
- (void)editingContext:(EOEditingContext *)anEditingContext didForgetObject:(id)object withGlobalID:(EOGlobalID *)globalID;

@end
