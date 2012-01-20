//
//  EOInspector.h
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EOInspectorPanel;

@interface EOInspector : NSObject <NSToolbarDelegate>
{
	EOInspectorPanel		*inspectorPanel;
	NSToolbar				*toolbar;
	NSArray					*inspectorPanes;
	int						currentPane;
}

- (void)activateInPanel:(EOInspectorPanel *)aPanel;

- (EOInspectorPanel *)inspectorPanel;
- (NSArray *)inspectorPanes;
- (NSToolbar *)toolbar;

- (NSView *)viewForPaneAtIndex:(unsigned int)index;

@end

@interface NSObject (EOInspector)

- (EOInspector *)inspector;

@end
