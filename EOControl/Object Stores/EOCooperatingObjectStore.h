
#import <EOControl/EOObjectStore.h>

@class EOEditingContext, EOFetchSpecification, EOGlobalID, EOObjectStoreCoordinator;

@interface EOCooperatingObjectStore : EOObjectStore
{
	EOObjectStoreCoordinator	*coordinator;
}

- (void)commitChanges;
- (BOOL)handlesFetchSpecification:(EOFetchSpecification *)fetchSpecification;
- (BOOL)ownsGlobalID:(EOGlobalID *)globalID;
- (BOOL)ownsObject:(id)object;
- (void)performChanges;
- (void)prepareForSaveWithCoordinator:(EOObjectStoreCoordinator *)coordinator editingContext:(EOEditingContext *)anEditingContext;
- (void)recordChangesInEditingContext;
- (void)recordUpdateForObject:(id)object changes:(NSDictionary *)changes;
- (void)rollbackChanges;
- (NSDictionary *)valuesForKeys:(NSArray *)keys object:(id)object;

- (EOObjectStoreCoordinator *)coordinator;

@end
