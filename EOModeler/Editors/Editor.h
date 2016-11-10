//
//  Editor.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOEntity, EOModel, EOStoredProcedure, Document;

@interface Editor : NSObject
{
	__weak Document				*document;
	
	IBOutlet NSView         *view;
    NSArray                 *uiElements;
}

+ (NSString *)name;

- (instancetype)initWithDocument:(Document *)aDocument;

- (NSView *)view;

- (EOModel *)model;
- (EOEntity *)selectedEntity;
- (EOStoredProcedure *)selectedStoredProcedure;

- (void)update;
- (void)deleteSelection:(id)sender;

- (void)objectWillChange:(id)object;
- (void)objectDidChange:(id)object;

@end
