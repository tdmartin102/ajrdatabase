//
//  NSPredicate-EOInterface.h
//  EOInterface
//
//  Created by Alex Raftis on 5/12/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOControl.h>

@interface NSPredicate (EOInterface)

- (NSPredicate *)predicateFromQualifier:(EOQualifier *)qualifier;

@end
