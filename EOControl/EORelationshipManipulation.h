
#import <Foundation/Foundation.h>

@protocol EORelationshipManipulation

- (void)addObject:(id)anObject toBothSidesOfRelationshipWithKey:(NSString *)key;
- (void)addObject:(id)anObject toPropertyWithKey:(NSString *)key;
- (void)removeObject:(id)anObject fromBothSidesOfRelationshipWithKey:(NSString *)key;
- (void)removeObject:(id)anObject fromPropertyWithKey:(NSString *)key;

@end
