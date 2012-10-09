//
//  EOFetchSpecification-Model.h
//  EOAccess/
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOFetchSpecification.h>

@class EOEntity;

@interface EOFetchSpecification (Model)

// Tom.Martin @ Riemer.com  2012-10-9
// The below as a category override of a class method which is not a good idea.  The class method
// was tweaked so that it should not need to be overridden here.
//+ (EOFetchSpecification*) fetchSpecificationNamed: (NSString*)name entityNamed: (NSString*)entityName;

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

- (EOEntity *)entity;
- (void)setName:(NSString *)name;
- (NSString *)name;

@end
