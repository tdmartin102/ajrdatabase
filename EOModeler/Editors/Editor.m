//
//  Editor.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Editor.h"

#import "Document.h"

@implementation Editor

+ (NSString *)name
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of Editor must implement +name"];
	return nil;
}

- (instancetype)initWithDocument:(Document *)aDocument
{
    if ((self = [super init]))
    {
        document = aDocument;
    }
	
	return self;
}

- (NSView *)view
{
	if (view == nil) {
        NSBundle *bundle;
        NSArray  *anArray;
                
        bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:NSStringFromClass([self class]) owner:self topLevelObjects:&anArray];
        uiElements = anArray;
	}
	
	return view;
}

- (EOModel *)model
{
	return [document model];
}

- (EOEntity *)selectedEntity
{
	return [document selectedEntity];
}

- (EOStoredProcedure *)selectedStoredProcedure
{
	return [document selectedStoredProcedure];
}

- (void)update
{
}

- (void)deleteSelection:(id)sender
{
}

- (void)objectWillChange:(id)object
{
}

- (void)objectDidChange:(id)object
{
}

@end
