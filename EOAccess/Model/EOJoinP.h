
#import "EOJoin.h"

@interface EOJoin (EOPrivate)

- (void)_setSourceAttribute:(EOAttribute *)attribute;
- (void)_setDestinationAttribute:(EOAttribute *)attribute;

- (EOQualifier *)_qualifierForValues:(NSDictionary *)values;
- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression;

+ (BOOL)_joins:(NSArray *)joins1 areEqualToJoins:(NSArray *)joins2;

@end
