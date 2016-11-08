//
//  EOInspectorPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

#import "EOInspector.h"
#import "EOInspectorPanel.h"
#import "Document.h"

#import <EOAccess/EOAccess.h>

@implementation EOInspectorPane

+ (id)paneWithInspector:(EOInspector *)anInspector
{
	return [[self alloc] initWithInspector:anInspector];
}

- (instancetype)initWithInspector:(EOInspector *)anInspector
{
	if ((self = [super init])) {
        inspector = anInspector;
    }
	return self;
}

- (NSString *)name
{
	return @"Untitled";
}

- (NSImage *)image
{
	NSImage		*image = [NSImage imageNamed:NSStringFromClass([self class])];
	if (image == nil) image = [NSApp applicationIconImage];
	return image;
}

- (NSView *)view
{
	if (view == nil) {
        NSBundle *bundle;
        NSArray  *anArray;
        
        bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:NSStringFromClass([self class])  owner:self topLevelObjects:&anArray];
        uiElements = anArray;
	}
	
	return view;
}

- (void)update
{
}

- (Document *)currentDocument
{
	return [Document currentDocument];
}

- (EOEntity *)selectedEntity
{
	id		object = [[self currentDocument] selectedObject];
	
	if ([object isKindOfClass:[EOEntity class]]) return object;
	
	return [[self currentDocument] selectedEntity];
}

- (EOStoredProcedure *)selectedStoredProcedure
{
	return [[self currentDocument] selectedStoredProcedure];
}

- (id)selectedObject
{
	return [[self currentDocument] selectedObject];
}

@end
