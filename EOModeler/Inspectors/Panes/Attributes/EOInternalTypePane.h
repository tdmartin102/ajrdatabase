//
//  EOInternalTypePane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOAttribute, EOInternalTypeInspector;

@interface EOInternalTypePane : NSObject
{
	IBOutlet NSView			*view;
	
	EOInternalTypeInspector	*inspector;
}

+ (NSString *)name;
+ (Class)inspectedClass;

- (id)initWithInspector:(EOInternalTypeInspector *)anInspector;

- (NSString *)name;
- (Class)inspectedClass;
- (BOOL)canInspectAttribute:(EOAttribute *)attribute;

- (NSView *)view;

- (void)update;
- (void)updateAttribute;
- (EOAttribute *)selectedAttribute;

@end
