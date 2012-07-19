//
//  NSObject-EOAccess.m
//  EOAccess
//
//  Created by Alex Raftis on 11/8/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSObject-EOAccess.h"

#import "EOAttributeP.h"
#import "EOEditingContext-EOAccess.h"
#import "EOEntity.h"
#import "EOEntityClassDescription.h"
// mont_rothstein @ yahoo.com 2004-12-06
// Added #import
#import "EOEntityP.h"

#import <EOControl/EOControl.h>
// mont_rothstein @ yahoo.com 2004-12-24
// Added #import
#import "EORelationship.h"
// mont_rothstein @ yahoo.com 2005-01-18
// Added #import
#import "EOObjectFaultHandler.h"

#import <objc/objc-class.h>

// mont_rothstein @ yahoo.com 2005-01-08
// We need to keep NSObject's original dealloc around because we are going to override
// it, but still need to call it.
//static void (*_eofSavedDealloc)(id, SEL);
// Tom.Martin @ Riemer.com - 2011-09-18
// I am changing this a bit as the internals for objects are now opaque.  
// Same idea though, implemented in the same way.
// declare the method here so the compilier knows about it.
@interface NSObject (EOAccessPrivateParts)
- (void)_eofNSObjectDealloc;
@end

@implementation NSObject (EOAccess)

// mont_rothstein @ yahoo.com 2005-01-08
// Here we save NSObject's dealloc method and point to our own alternate dealloc, which
// will in turn call the original dealloc.
+ (void)load
{
	Method		originalMethod;
	Method		ourMethod;
	originalMethod = class_getInstanceMethod([NSObject class], @selector(dealloc));
	
	// Tom.Martin @ Riemer.com - 2011-09-18
	// I am changing this a bit as the internals for objects are now opaque.  
	// Same idea though, implemented in the same way.
	// todo:  I think this should be moved to EOModel and only perform this swap on clases that
	// we KNOW are EO's  It is silly to do this for ALL objects.  On the other hand that may fail for Faults
	// but that could be handled as well.  Should look into this.
	//_eofSavedDealloc = (void (*)(id, SEL))originalMethod->method_imp;
	//originalMethod->method_imp = [NSObject instanceMethodForSelector:@selector(_eofNSObjectDealloc)];
	ourMethod = class_getInstanceMethod([NSObject class], @selector(_eofNSObjectDealloc));
	method_exchangeImplementations(originalMethod, ourMethod);

}

- (NSDictionary *)primaryKey
{
	return [[self editingContext] primaryKeyForObject:self];
}

- (EOGlobalID *)globalID
{
	return [[self editingContext] globalIDForObject:self];
}

+ (NSFormatter *)defaultFormatterForAttribute:(EOAttribute *)attribute
{
	return nil;
}

// mont_rothstein @ yahoo.com 2004-12-24
// Convience method for accessing a relationship's sort orderings
// mont_rothstein @ yahoo.com 2005-08-14
// Modified to use sortOrderingsForRelationshipNamed:inEntityNamed:
- (NSArray *)sortOrderingsForRelationshipNamed:(NSString *)name
{
	return [self sortOrderingsForRelationshipNamed: name inEntityNamed: [self entityName]];
}

// mont_rothstein @ yahoo.com 2005-08-14
// Convience method for accessing a relationship's sort orderings
- (NSArray *)sortOrderingsForRelationshipNamed:(NSString *)name 
								 inEntityNamed:(NSString *)entityName
{
	EOEntity *entity;
	
	entity = [[self editingContext] entityNamed: entityName];
	
	return [[entity relationshipNamed: name] sortOrderings];
}

// mont_rothstein @ yahoo.com 2005-01-08
// This method is pointed to in +load as a replacement for the standard dealloc.
// This allows EOs to tell their editing context to release them.  We then call
// the original dealloc.
- (void)_eofNSObjectDealloc
{
	// Only do this if our class description is an EOEntityClassDescription
	// 2005-05-13 AJR Changed this to check against a nil editingContext, because the attempt at getting the class description was causing IB to dead lock on start up. Also, this should be a faster check than looking up the class description for all objects. On top of that, it should be a sufficient check, since, after all, we're just cleaning ourself out of our editing context, so we only need to do this is we are an editing context.
	EOEditingContext *editingContext = [self editingContext];
	if (editingContext != nil && [editingContext globalIDForObject:self] != nil) {
		if (EOMemoryDebug) [EOLog logDebugWithFormat:@"- [%@ (%p) dealloc]\n", [(id)self className], self];
		
		[editingContext forgetObject:self];
		
		// Clear the EO's pointer to it's editing context
		[self _clearInstanceObjects];
	}
	
	// Calls NSObjects's original dealloc
	// Tom.Martin @ Riemer.com 2011-09-18
	// change the call to be more OBJ-C like.
	//_eofSavedDealloc(self, @selector(dealloc));
	// This is NOT recursive since msg_send will reslove this call to the original dealloc
	[self _eofNSObjectDealloc];
}

@end

@interface NSCalendarDate (EOAccessFormatters)

+ (NSFormatter *)defaultFormatterForAttribute:(EOAttribute *)attribute;

@end

@implementation NSCalendarDate (EOAccessFormatters)

+ (NSFormatter *)defaultFormatterForAttribute:(EOAttribute *)attribute
{
	return [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S %z" allowNaturalLanguage:NO] autorelease];
}

@end

@interface NSString (EOAccessFormatters)

+ (NSFormatter *)defaultFormatterForAttribute:(EOAttribute *)attribute;

@end

@implementation NSString (EOAccessFormatters)

+ (NSFormatter *)defaultFormatterForAttribute:(EOAttribute *)attribute
{
	/*! @todo NSString-EOAccessFormatters: A default formatter that limits input length. */
	return nil;
}

@end

/*! @todo NSObject-EOAccessFormatters: A default number formatter */

// mont_rothstein @ yahoo.com 2004-12-06
// Added this so the changesFromSnapshot: in EOControl can get to the class properties.
@implementation NSObject (EOEnterpriseObject_P)

- (NSArray *)classAttributeKeys
{
	return [[(EOEntityClassDescription *)[self classDescription] entity] _classAttributes];
}

@end
