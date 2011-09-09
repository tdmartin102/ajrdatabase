
#import "EORelationship.h"

@interface EORelationship (EOPrivate)

- (NSArray *)_externalModelsReferenced;
- (BOOL)_referencesProperty:(id)property;
- (void)_setDestinationEntity:(EOEntity *)entity;

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression;

- (void)_setIsClassProperty:(BOOL)flag;
- (BOOL)_isClassProperty;

@end
