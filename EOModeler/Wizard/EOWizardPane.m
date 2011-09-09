//
//  EOWizardPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardPane.h"

@implementation EOWizardPane

- (id)initWithModelWizard:(EOModelWizard *)aWizard
{
	[super init];
	
	modelWizard = aWizard;
	
	return self;
}

- (NSView *)view
{
	if (view == nil) {
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
	
	return view;
}

- (void)update
{
}

- (void)updateButtons
{
}

- (BOOL)canGoNext
{
	return YES;
}

- (BOOL)canGoPrevious
{
	return YES;
}

@end
