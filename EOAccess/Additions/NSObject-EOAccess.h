//
//  NSObject-EOAccess.h
//  EOAccess
//
//  Created by Alex Raftis on 11/8/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <EOControl/EOEnterpriseObject.h>

@class EOAttribute, EOGlobalID;

@interface EOEnterpriseObject (EOAccess)

#if !defined(STRICT_EOF)
- (NSDictionary *)primaryKey;
- (EOGlobalID *)globalID;
// mont_rothstein @ yahoo.com 2004-12-24
// Convience method for accessing a relationship's sort orderings
- (NSArray *)sortOrderingsForRelationshipNamed:(NSString *)name;
	// mont_rothstein @ yahoo.com 2005-08-14
	// Convenience method for accessing a relationship's sort orderings
- (NSArray *)sortOrderingsForRelationshipNamed:(NSString *)name 
								 inEntityNamed:(NSString *)entityName;
#endif

// Extension!
+ (NSFormatter *)defaultFormatterForAttribute:(EOAttribute *)attribute;

@end
