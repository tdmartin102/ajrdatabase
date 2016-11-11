
#import <Cocoa/Cocoa.h>

@class EOModel;

@interface EOConnectionPane : NSObject
{
	IBOutlet NSView		*view;
	IBOutlet NSView		*smallView;
	EOModel				*model;
    NSArray             *uiElements;
}

- (id)view;
- (id)smallView;

- (void)setModel:(EOModel *)aModel;
- (EOModel *)model;
- (void)setConnectionValue:(id)value forKey:(NSString *)key;

@end
