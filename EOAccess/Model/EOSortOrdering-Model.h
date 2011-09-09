//
//  EOSortOrdering-Model.h
//  EOAccess/
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOSortOrdering.h>

@interface EOSortOrdering (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end
