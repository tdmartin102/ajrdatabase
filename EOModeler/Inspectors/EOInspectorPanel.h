//
//  EOInspectorPanel.h
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Document;

@interface EOInspectorPanel : NSPanel < NSToolbarDelegate >
{
	IBOutlet NSView		*nothingView;
	IBOutlet NSView		*multipleView;
	IBOutlet NSToolbar	*nothingToolbar;
    
    NSArray             *uiElements;
}

- (void)updateInspector;

@end


@interface NSObject (EOInspectorPanel)

- (void)showInspector:(id)sender;

@end
