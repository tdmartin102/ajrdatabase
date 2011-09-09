//
//  EOObjectStoreCoordinator-EOAccess.m
//  EOAccess
//
//  Created by Alex Raftis on 11/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOObjectStoreCoordinator-EOAccess.h"

#import "EOModelGroup.h"

#import <EOControl/EOControl.h>
#import <EOControl/NSObject-EOEnterpriseObjectP.h>

@implementation EOObjectStoreCoordinator (EOAccess)

- (EOModelGroup *)modelGroup
{
	EOModelGroup		*group = [self _eofInstanceObjectForKey:@"_eoModelGroup"];
	
	if (group == nil) return [EOModelGroup defaultModelGroup];
	
	return group;
}

- (void)setModelGroup:(EOModelGroup *)aModelGroup
{
	[self _setEOFInstanceObject:aModelGroup forKey:@"_eoModelGroup"];
}

@end
