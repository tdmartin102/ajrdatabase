//
//  EOGenericRecord-EOAccess.m
//  EOAccess
//
//  Created by Alex Raftis on 11/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOGenericRecord-EOAccess.h"
#import "EOEntityClassDescription.h"

#import "EOModelGroup.h"

@implementation EOGenericRecord (EOAccess)

- (EOEntity *)entity
{
	return [[EOModelGroup defaultModelGroup] entityNamed:[self entityName]];
}

// mont_rothstein @ yahoo.com 2004-12-06
// This was moved here from EOControl so we could use EOEntityClassDescription instead
// of NSClassDescription.  This had been calling the stubed out version of the method.
- (NSClassDescription *)classDescription
{
	return [EOEntityClassDescription classDescriptionForEntityName:[self entityName]];
}
	
@end
