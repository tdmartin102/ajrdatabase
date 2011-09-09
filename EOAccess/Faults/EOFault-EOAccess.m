//
//  EOFault-EOAccess.m
//  EOAccess
//
//  Created by Mont Rothstein on 12/5/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOFault-EOAccess.h"
#import "EOArrayFaultHandler.h"
#import "EOObjectFaultHandler.h"
#import "EOEditingContext-EOAccess.h"
#import "EOEntity.h"
#import "EOEntityP.h"
#import "EOMutableArray.h"
#import <EOControl/EOControl.h>

#import <objc/objc-class.h>

@implementation EOFault (EOAccess)

// mont_rothstein @ yahoo.com 2005-07-11
// Added method to support re-faulting objects, as per 4.5 API

+ (id)createObjectFaultWithGlobalID:(EOGlobalID *)globalID
                   inEditingContext:(EOEditingContext *)editingContext
{
	Class		targetClass;
	EOEntity	*entity;
	EOFault		*newFault;
	
	entity = [editingContext entityNamed: [globalID entityName]];
	targetClass = [entity _objectClass];
	newFault = [targetClass alloc];
	newFault->isa = [EOFault class];
	newFault->handler = [[EOObjectFaultHandler alloc] initWithGlobalID:globalID editingContext:editingContext];
	[newFault autorelease];
	
	return newFault;
}

+ (id)createArrayFaultWithSourceGlobalID:(EOGlobalID *)sourceGlobalID
                        relationshipName:(NSString *)relationshipName
                        inEditingContext:(EOEditingContext *) editingContext
{
	EOFault		*newFault;
	
	newFault = class_createInstance([EOMutableArray class], 0);
	newFault->isa = [EOFault class];
	newFault->handler = [[EOArrayFaultHandler alloc] initWithSourceGlobalID:sourceGlobalID relationshipName:relationshipName editingContext:editingContext];
	[newFault autorelease];
	
	return newFault;
}

@end
