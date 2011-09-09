//
//  EOIntegerPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInternalTypePane.h"

@interface EOIntegerPane : EOInternalTypePane
{
	IBOutlet NSPopUpButton		*typePopUp;
}

- (void)selectType:(id)sender;

@end
