//
//  EODatePane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInternalTypePane.h"

@class AJRTimeZoneChooser;

@interface EODatePane : EOInternalTypePane
{
	IBOutlet AJRTimeZoneChooser	*timeZoneChooser;
}

- (void)selectTimeZone:(id)sender;

@end
