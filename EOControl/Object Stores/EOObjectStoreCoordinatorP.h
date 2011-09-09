
#import "EOObjectStoreCoordinator.h"

@interface EOObjectStoreCoordinator (EOPrivate)

- (EOCooperatingObjectStore *)_objectStoreForEntityNamed:(NSString *)name;

@end
