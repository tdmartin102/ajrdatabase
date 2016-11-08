//
//  EOModelWizard.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOModelWizard.h"

#import "EOWizardAdaptorPane.h"
#import "EOWizardFeaturesPane.h"
#import "EOWizardTablesPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOModelWizard

- (instancetype)init
{
	EOWizardPane		*pane;
	
	if ((self = [super init]))
    {
        assignPrimaryKeys = YES;
        assignRelationships = NO;
        assignStoredProcedures = NO;
        assignCustomObjects = YES;
	
	
        steps = [[NSMutableArray alloc] init];
        pane = [[EOWizardAdaptorPane alloc] initWithModelWizard:self];
        [steps addObject:pane];
        pane = [[EOWizardFeaturesPane alloc] initWithModelWizard:self];
        [steps addObject:pane];
        pane = [[EOWizardTablesPane alloc] initWithModelWizard:self];
        [steps addObject:pane];
        
        stepIndex = 0;
        step = [steps objectAtIndex:stepIndex];
    }
	return self;
}

- (void)updatePane
{
	step = [steps objectAtIndex:stepIndex];
	[step update];
	[step updateButtons];
	[view setContentView:[step view]];
	[finishButton setNextKeyView:[[step view] nextKeyView]];
	[[[step view] previousKeyView] setNextKeyView:cancelButton];
	[window makeFirstResponder:[[step view] nextKeyView]];
	[stepMatrix selectCellWithTag:stepIndex];
}

- (EOModel *)run
{
	if (window == nil) {
        NSBundle *bundle;
        NSArray  *anArray;
        
        bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:@"EOModelWizard" owner:self topLevelObjects:&anArray];
        uiElements = anArray;

		[window center];
	}
	
	model = [[EOModel alloc] init];
	
	[self updatePane];
	[window makeKeyAndOrderFront:self];
	
	if ([NSApp runModalForWindow:window] == NSOKButton) {
		EOModel		*temp;
		
		[window orderOut:self];
		temp = model;
		model = nil;
		
		return temp;
	}
	[window orderOut:self];
	model = nil;
	
	return nil;
}

- (void)endEditing
{
	id		firstResponder = [window firstResponder];
	
	[window resignFirstResponder];
	[window endEditingFor:firstResponder];
}

- (void)next:(id)sender
{
	[self endEditing];
	if ([step canGoNext]) {
		stepIndex++;
		[self updatePane];
	}
}

- (void)previous:(id)sender
{
	[self endEditing];
	if ([step canGoPrevious] && stepIndex > 0) {
		stepIndex--;
		[self updatePane];
	}
}

- (void)cancel:(id)sender
{
	[NSApp stopModalWithCode:NSCancelButton];
	model = nil;
}

- (void)finish:(id)sender
{
	[self endEditing];
	if ([step canGoNext]) {
		[NSApp stopModalWithCode:NSOKButton];
	} else {
		NSBeep();
	}
}

- (NSButton *)cancelButton
{
	return cancelButton;
}

- (NSButton *)nextButton
{
	return nextButton;
}

- (NSButton *)previousButton
{
	return previousButton;
}

- (NSButton *)finishButton
{
	return finishButton;
}

- (EOModel *)model
{
	return model;
}

- (void)setAssignPrimaryKeys:(BOOL)flag
{
	assignPrimaryKeys = flag;
}

- (BOOL)assignPrimaryKeys
{
	return assignPrimaryKeys;
}

- (void)setAssignRelationships:(BOOL)flag
{
	assignRelationships = flag;
}

- (BOOL)assignRelationships
{
	return assignRelationships;
}

- (void)setAssignStoredProcedures:(BOOL)flag
{
	assignStoredProcedures = flag;
}

- (BOOL)assignStoredProcedures
{
	return assignStoredProcedures;
}

- (void)setAssignCustomObjects:(BOOL)flag
{
	assignCustomObjects = flag;
}

- (BOOL)assignCustomObjects
{
	return assignCustomObjects;
}

@end
