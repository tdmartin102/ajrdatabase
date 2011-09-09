//
//  EOWizardAdaptorPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardPane.h"

@class EOConnectionPane;

@interface EOWizardAdaptorPane : EOWizardPane
{
	IBOutlet NSTableView		*adaptorTable;
	IBOutlet NSBox				*connectionBox;
	IBOutlet NSView			*noneView;
	
	EOConnectionPane			*connectionPane;
}

- (void)selectAdaptor:(id)sender;

@end
