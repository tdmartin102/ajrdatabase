//
//  EOWizardFeaturesPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/6/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardFeaturesPane.h"

#import "EOModelWizard.h"

#import <EOAccess/EOAccess.h>

@implementation EOWizardFeaturesPane

- (void)updateButtons
{
	[primaryKeysCheck setState:[modelWizard assignPrimaryKeys]];
	[relationshipsCheck setState:[modelWizard assignRelationships]];
	[storedProceduresCheck setState:[modelWizard assignStoredProcedures]];
	[customObjectsCheck setState:[modelWizard assignCustomObjects]];
	[[modelWizard previousButton] setEnabled:YES];
	[[modelWizard finishButton] setEnabled:YES];
	[[modelWizard nextButton] setEnabled:YES];
}

- (void)togglePrimaryKeys:(id)sender
{
	[modelWizard setAssignPrimaryKeys:[sender state]];
}

- (void)toggleRelationships:(id)sender
{
	[modelWizard setAssignRelationships:[sender state]];
}

- (void)toggleStoredProcedures:(id)sender
{
	[modelWizard setAssignStoredProcedures:[sender state]];
}

- (void)toggleCustomObjects:(id)sender
{
	[modelWizard setAssignCustomObjects:[sender state]];
}

@end
