//
//  PreferencesGeneral.h
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferencesModule.h"

@interface PreferencesGeneral : PreferencesModule
{
	IBOutlet NSTextField		*fetchLimitText;
}

- (void)setFetchLimit:(id)sender;

@end
