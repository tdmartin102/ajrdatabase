//
//  PreferencesModels.h
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferencesModule.h"

@interface PreferencesModels : PreferencesModule <NSTableViewDataSource>

- (IBAction)addPath:(id)sender;
- (IBAction)removePath:(id)sender;

@end
