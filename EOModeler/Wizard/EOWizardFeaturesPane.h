//
//  EOWizardFeaturesPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/6/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardPane.h"

@interface EOWizardFeaturesPane : EOWizardPane
{
	IBOutlet NSButton			*primaryKeysCheck;
	IBOutlet NSButton			*relationshipsCheck;
	IBOutlet NSButton			*storedProceduresCheck;
	IBOutlet NSButton			*customObjectsCheck;
}

- (void)togglePrimaryKeys:(id)sender;
- (void)toggleRelationships:(id)sender;
- (void)toggleStoredProcedures:(id)sender;
- (void)toggleCustomObjects:(id)sender;

@end
