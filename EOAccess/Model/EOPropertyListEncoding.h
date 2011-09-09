
#import <Foundation/Foundation.h>

@protocol EOPropertyListEncoding

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)awakeWithPropertyList:(NSDictionary *)properties;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end
