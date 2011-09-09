
#import "EOCooperatingObjectStore.h"

#import "EOEditingContext.h"
#import "EOGenericRecord.h"
#import "EOObjectStoreCoordinator.h"
#import "NSObject-EOEnterpriseObject.h"

@implementation EOCooperatingObjectStore

- (void)dealloc
{
	[super dealloc];
}

- (void)commitChanges
{
}

- (BOOL)handlesFetchSpecification:(EOFetchSpecification *)fetchSpecification
{
	return NO;
}

- (BOOL)_handlesEntityNamed:(NSString *)entityName
{
	return NO;
}
								
- (BOOL)ownsGlobalID:(EOGlobalID *)globalID
{
	return NO;
}

- (BOOL)ownsObject:(id)object
{
	return [self ownsGlobalID:[[object editingContext] globalIDForObject:object]];
}

- (void)performChanges
{
}

- (void)prepareForSaveWithCoordinator:(EOObjectStoreCoordinator *)coordinator editingContext:(EOEditingContext *)anEditingContext
{
}

- (void)recordChangesInEditingContext
{
}

- (void)recordUpdateForObject:(id)object changes:(NSDictionary *)changes
{
}

- (void)rollbackChanges
{
}

- (NSDictionary *)valuesForKeys:(NSArray *)keys object:(id)object
{
	return nil;
}

- (EOObjectStoreCoordinator *)coordinator
{
	return coordinator;
}

- (void)_setCoordinator:(EOObjectStoreCoordinator *)aCoordinator
{
	if (coordinator != aCoordinator) {
		[coordinator release];
		coordinator = [aCoordinator retain];
	}
}

@end
