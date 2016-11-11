
#import "EOConnectionPane.h"

#import "EOModel.h"

@implementation EOConnectionPane

- (id)view
{
	if (view == nil) {
        
        NSBundle *bundle;
        NSArray *anArray;
        
        bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:NSStringFromClass([self class]) owner:self topLevelObjects:&anArray];
        uiElements = [anArray copy];
        // Tom.Martin @ riemer.com  2016-11-11
        // replace depreciated call
		//[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
	
	return view;
}

- (id)smallView
{
	[self view];
	return smallView;
}

- (void)setModel:(EOModel *)aModel
{
	if (model != aModel) {
		[model release];
		model = [aModel retain];
	}
}

- (EOModel *)model
{
	return model;
}

- (void)setConnectionValue:(id)value forKey:(NSString *)key
{
	NSMutableDictionary		*values = [[[self model] connectionDictionary] mutableCopy];
	
	if (value == nil) {
		[values removeObjectForKey:key];
	} else {
		[values setObject:value forKey:key];
	}
	
	[[self model] setConnectionDictionary:values];
	[values release];
}

@end
