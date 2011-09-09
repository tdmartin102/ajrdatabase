
#import "EOAdaptorOperation.h"

@class EODatabaseOperation;

@interface EOAdaptorOperation (EOPrivate)

- (void)_setDatabaseOperation:(EODatabaseOperation *)anOperation;
- (EODatabaseOperation *)_databaseOperation;

@end
