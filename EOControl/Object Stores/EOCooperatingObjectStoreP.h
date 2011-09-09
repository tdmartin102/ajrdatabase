
#import "EOCooperatingObjectStore.h"

@interface EOCooperatingObjectStore (EOPrivate)

- (void)_setCoordinator:(EOObjectStoreCoordinator *)aCoordinator;
- (BOOL)_handlesEntityNamed:(NSString *)entityName;

@end
