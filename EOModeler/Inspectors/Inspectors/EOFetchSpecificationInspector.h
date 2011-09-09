//
//  EOFetchSpecificationInspector.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspector.h"

#import <EOAccess/EOAccess.h>

@interface EOFetchSpecificationInspector : EOInspector
{
}

@end


@interface EOFetchSpecification (EOInspector)

- (EOInspector *)inspector;

@end
