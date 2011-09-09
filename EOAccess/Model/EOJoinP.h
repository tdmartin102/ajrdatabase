
#import "EOJoin.h"

@interface EOJoin (EOPrivate)

- (void)_setSourceAttribute:(EOAttribute *)attribute;
- (void)_setDestinationAttribute:(EOAttribute *)attribute;

- (EOQualifier *)_qualifierForValues:(NSDictionary *)values;
- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression;

+ (BOOL)_joinsAreEqual:(NSArray *)joins1:(NSArray *)joins2;

@end
