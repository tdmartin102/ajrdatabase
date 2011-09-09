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

- (id)init
{
	EOWizardPane		*pane;
	
	[super init];
	
	assignPrimaryKeys = YES;
	assignRelationships = NO;
	assignStoredProcedures = NO;
	assignCustomObjects = YES;
	
	
	steps = [[NSMutableArray allocWithZone:[self zone]] init];
	pane = [[EOWizardAdaptorPane allocWithZone:[self zone]] initWithModelWizard:self];
	[steps addObject:pane];
	[pane release];
	pane = [[EOWizardFeaturesPane allocWithZone:[self zone]] initWithModelWizard:self];
	[steps addObject:pane];
	[pane release];
	pane = [[EOWizardTablesPane allocWithZone:[self zone]] initWithModelWizard:self];
	[steps addObject:pane];
	[pane release];
	
	stepIndex = 0;
	step = [steps objectAtIndex:stepIndex];
	
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
		[NSBundle loadNibNamed:@"EOModelWizard" owner:self];
		[window center];
	}
	
	[model release];
	model = [[EOModel alloc] init];
	
	[self updatePane];
	[window makeKeyAndOrderFront:self];
	
	if ([NSApp runModalForWindow:window] == NSOKButton) {
		EOModel		*temp;
		
		[window orderOut:self];
		temp = [model autorelease];
		model = nil;
		
		return temp;
	}
	[window orderOut:self];
	[model release]; model = nil;
	
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
	[model release];
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
