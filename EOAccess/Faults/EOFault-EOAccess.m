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

static size_t faultSize = 0;
static size_t arraySize;

@implementation EOFault (EOAccess)

// mont_rothstein @ yahoo.com 2005-07-11
// Added method to support re-faulting objects, as per 4.5 API

+ (id)createObjectFaultWithGlobalID:(EOGlobalID *)globalID
                   inEditingContext:(EOEditingContext *)editingContext
{
	Class		targetClass;
	EOEntity	*entity;
	EOFault		*newFault;
	size_t		objectSize;

	// tom.martin @ riemer.com 2011-12-5
	// it is EXTREMELY unlikey, but if the traget class was smaller than the fault class there would be
	// problems.  To assure we are okay here we will test the size and alloc wichever object is larger.
	if (faultSize == 0)
	{
		faultSize = class_getInstanceSize([EOFault class]);
		arraySize = class_getInstanceSize([EOMutableArray class]);
	}
	
	entity = [editingContext entityNamed: [globalID entityName]];
	targetClass = [entity _objectClass];	
	objectSize = class_getInstanceSize(targetClass);
	//newFault = class_createInstance(targetClass, MAX(0, faultSize - objectSize));
	//newFault->isa = [EOFault class];
	// tom.martin @ riemer.com 2011-12-6
	// I was getting unexpected results with class_createInstance.  I am not sure
	// why, but since I no longer need to allocate additional bytes, I can simply call
	// alloc.  I suspect that class_createInstance does not set all the memory to zero.
	// further we are going to use object_setClass rather than simply set the isa pointer
	// object_setClass is slightly safer.
	// alloc what ever is bigger
	if (objectSize > faultSize)
	{
		newFault = [targetClass alloc];
		object_setClass(newFault, [EOFault class]);
	}
	else
		newFault = [EOFault alloc];
	// tom.martin @ riemer.com 2011-12-5
	// add call to init.  probably not needed, but seems safer
	[newFault init];
	newFault->handler = [[EOObjectFaultHandler alloc] initWithGlobalID:globalID editingContext:editingContext];
	[newFault autorelease];
	
	return newFault;
}

+ (id)createArrayFaultWithSourceGlobalID:(EOGlobalID *)sourceGlobalID
                        relationshipName:(NSString *)relationshipName
                        inEditingContext:(EOEditingContext *) editingContext
{
	EOFault		*newFault;
	size_t		objectSize;
	
	// tom.martin @ riemer.com 2011-12-5
	// it is EXTREMELY unlikey, but if the EOMutableArray class is smaller than the fault class there would be
	// problems.  To assure we are okay here we will test the size and allocated additional memory if need be.
	//newFault = class_createInstance([EOMutableArray class], 0);
	if (faultSize == 0)
	{
		faultSize = class_getInstanceSize([EOFault class]);
		arraySize = class_getInstanceSize([EOMutableArray class]);
	}
	// I was getting unexpected results with class_createInstance.  I am not sure
	// why, but since I no longer need to allocate additional bytes, I can simply call
	// alloc.  I suspect that class_createInstance does not set all the memory to zero.
	// further we are going to use object_setClass rather than simply set the isa pointer
	// object_setClass is slightly safer.
	//newFault = class_createInstance([EOMutableArray class], extraArrayBytes);
	// alloc what ever is bigger
	if (arraySize > faultSize)
	{
		newFault = (EOFault *)[EOMutableArray alloc];
		object_setClass(newFault, [EOFault class]);
	}
	else
		newFault = [EOFault alloc];

	// tom.martin @ riemer.com 2011-12-5
	// add call to init.  probably not needed, but seems safer
	[newFault init];
	newFault->handler = [[EOArrayFaultHandler alloc] initWithSourceGlobalID:sourceGlobalID relationshipName:relationshipName editingContext:editingContext];
	[newFault autorelease];
	
	return newFault;
}

@end
