//
//  EODatabaseP.h
//  EOAccess
//
//  Created by Mont Rothstein on 7/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EODatabase.h"

@interface EODatabase (Private)

+(BOOL)_isSnapshotRefCountingDisabled;

@end
