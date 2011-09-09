
#import <Cocoa/Cocoa.h>

@class EOModel;

@interface EOConnectionPane : NSObject
{
	id						view;
	id						smallView;
	EOModel				*model;
}

- (id)view;
- (id)smallView;

- (void)setModel:(EOModel *)aModel;
- (EOModel *)model;
- (void)setConnectionValue:(id)value forKey:(NSString *)key;

@end
