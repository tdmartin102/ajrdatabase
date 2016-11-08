//
//  EOWizardPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardPane.h"

@implementation EOWizardPane

- (instancetype)initWithModelWizard:(EOModelWizard *)aWizard
{
    if ((self = [super init])) {
        modelWizard = aWizard;
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
