//
//  EODecimalNumberPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInternalTypePane.h"

@interface EODecimalNumberPane : EOInternalTypePane
{
	IBOutlet NSTextField			*scaleField;
	IBOutlet NSTextField			*precisionField;
}

- (IBAction)setScale:(id)sender;
- (IBAction)setPrecision:(id)sender;

@end
