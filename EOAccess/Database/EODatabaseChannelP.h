
#import "EODatabaseChannel.h"

@interface EODatabaseChannel (EOPrivate)

- (EOAdaptorChannel *)_adaptorChannel:(BOOL)connect;
- (void)_setDatabaseContext:(EODatabaseContext *)aContext;

@end
