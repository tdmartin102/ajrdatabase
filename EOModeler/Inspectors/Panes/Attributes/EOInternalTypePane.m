//
//  EOInternalTypePane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInternalTypePane.h"

#import "EOAttributePane.h"
#import "EOInternalTypeInspector.h"

#import <EOAccess/EOAccess.h>

@implementation EOInternalTypePane

+ (NSString *)name
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of EOInternalTypeInspector must implement %@", NSStringFromSelector(_cmd)];
	return nil;
}

+ (Class)inspectedClass
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of EOInternalTypeInspector must implement %@", NSStringFromSelector(_cmd)];
	return Nil;
}

- (id)initWithInspector:(EOInternalTypeInspector *)anInspector
{
	[super init];
	
	inspector = anInspector;
	
	return self;
}

- (NSString *)name
{
	return [[self class] name];
}

- (NSView *)view
{
	if (view == nil) {
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
	
	return view;
}

- (Class)inspectedClass
{
	return [[self class] inspectedClass];
}

- (BOOL)canInspectAttribute:(EOAttribute *)attribute
{
	Class		class = [[self class] inspectedClass];
	
	//AJRPrintf(@"%@: inspected: %@, class name: %@, will: %B\n", attribute, NSStringFromClass(class), [attribute valueClassName], [NSStringFromClass(class) isEqualToString:[attribute valueClassName]]);
	
	if (class) return [NSStringFromClass(class) isEqualToString:[attribute valueClassName]];
		
	return NO;
}

- (void)update
{
}

- (void)updateAttribute
{
}

- (EOAttribute *)selectedAttribute
{
	return [inspector attribute];
}

@end
