//
//  EOWizardTablesPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/6/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardPane.h"

@interface EOWizardTablesPane : EOWizardPane 
{
	IBOutlet NSTableView		*tablesTable;
	
	NSArray						*tableNames;
}

@end
