//
//  EOInspectorPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOEntity, EOInspector, EOStoredProcedure, Document;

@interface EOInspectorPane : NSObject
{
	IBOutlet NSView		*view;
	EOInspector				*inspector;
    NSArray                 *uiElements;
}

+ (id)paneWithInspector:(EOInspector *)anInspector;
- (instancetype)initWithInspector:(EOInspector *)anInspector;

- (NSString *)name;
- (NSImage *)image;
- (NSView *)view;

- (void)update;

- (Document *)currentDocument;
- (EOEntity *)selectedEntity;
- (EOStoredProcedure *)selectedStoredProcedure;
- (id)selectedObject;

@end
