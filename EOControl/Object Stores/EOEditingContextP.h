
#import "EOEditingContext.h"

@interface EOEditingContext (EOPrivate)

// Returns the actual object dictionary. Only fully valid after a -performRecentChanges has been called.
- (NSDictionary *)_insertedObjects;
- (EOEntity *)_entityNamed:(NSString *)name;

@end