//
//  EOWizardPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOModelWizard;

@interface EOWizardPane : NSObject 
{
	IBOutlet NSView		*view;
	
	EOModelWizard			*modelWizard;
}

- (id)initWithModelWizard:(EOModelWizard *)aWizard;

- (NSView *)view;

- (void)update;
- (void)updateButtons;

- (BOOL)canGoNext;
- (BOOL)canGoPrevious;

@end
