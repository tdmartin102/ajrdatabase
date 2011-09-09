//
//  EOEntityInspector.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspector.h"

#import <EOAccess/EOAccess.h>

@interface EOEntityInspector : EOInspector
{
}

@end


@interface EOEntity (EOInspector)

- (EOInspector *)inspector;

@end
