//
//  EOObjectStoreCoordinator-EOAccess.h
//  EOAccess
//
//  Created by Alex Raftis on 11/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOControl.h>

@class EOModelGroup;

@interface EOObjectStoreCoordinator (EOAccess)

- (EOModelGroup *)modelGroup;
- (void)setModelGroup:(EOModelGroup *)aModelGroup;

@end
