//
//  EOEntitySharedObjectsPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EOEntitySharedObjectsPane : EOInspectorPane
{
	IBOutlet NSMatrix		*shareMatrix;
	IBOutlet NSTableView	*fetchTableView;
}

- (IBAction)selectSharedMethod:(id)sender;
- (IBAction)selectFetchSpecification:(id)sender;

@end
