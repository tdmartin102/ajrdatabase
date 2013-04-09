
#import "NSObject-EORelationshipManipulation.h"

#import "_EOSelectorTable.h"
#import "NSClassDescription-EO.h"
#import "EOFormat.h"
#import "NSString-EO.h"
#import "EOEnterpriseObject.h"
#import "EOEditingContext.h"

#import <Foundation/Foundation.h>

#import <objc/objc-class.h>

@interface NSObject (EOEnterpriseObject) <EOEnterpriseObject>
@end


static NSMutableDictionary *_eoAddMethodCache = nil;
static NSMutableDictionary *_eoRemoveMethodCache = nil;

@implementation NSObject (EORelationshipManipulation)

- (NSMutableDictionary *)_eoAddMethodCache
{
	if (_eoAddMethodCache == nil) {
		_eoAddMethodCache = [[NSMutableDictionary alloc] init];
	}
	return _eoAddMethodCache;
}

- (NSMutableDictionary *)_eoRemoveMethodCache
{
	if (_eoRemoveMethodCache == nil) {
		_eoRemoveMethodCache = [[NSMutableDictionary alloc] init];
	}
	return _eoRemoveMethodCache;
}

- (SEL)_addMethodForKey:(NSString *)key
{
   _EOSelectorTable	*table = [[self _eoAddMethodCache] objectForKey:object_getClass(self)];
   SEL					selector;
	
   if (table == nil) {
      table = [[_EOSelectorTable alloc] init];
      [_eoAddMethodCache setObject:table forKey:object_getClass(self)];
      [table release];
   }
	
   selector = [table selectorForKey:key];
   if (selector == @selector(bogus)) return NULL;
   if (selector == NULL) {
      selector = NSSelectorFromString(EOFormat(@"addTo%@:", [key capitalizedName]));
      if (selector != NULL && [self respondsToSelector:selector]) {
         [table setSelector:selector forKey:key];
      } else {
         [table setSelector:@selector(bogus) forKey:key];
         selector = NULL;
      }
   }
	
   return selector;
}

- (SEL)_removeMethodForKey:(NSString *)key
{
   _EOSelectorTable	*table = [[self _eoRemoveMethodCache] objectForKey:object_getClass(self)];
   SEL					selector;
	
   if (table == nil) {
      table = [[_EOSelectorTable alloc] init];
      [_eoRemoveMethodCache setObject:table forKey:object_getClass(self)];
      [table release];
   }
	
   selector = [table selectorForKey:key];
   if (selector == @selector(bogus)) return NULL;
   if (selector == NULL) {
      selector = NSSelectorFromString(EOFormat(@"removeFrom%@:", [key capitalizedName]));
      if (selector != NULL && [self respondsToSelector:selector]) {
         [table setSelector:selector forKey:key];
      } else {
         [table setSelector:@selector(bogus) forKey:key];
         selector = NULL;
      }
   }
	
   return selector;
}

- (void)addObject:(id)object toBothSidesOfRelationshipWithKey:(NSString *)key
{
	NSString		*inverseKey;
	
	// Add the object to our side.
	[self addObject:object toPropertyWithKey:key];
	
	// And add the reverse relationship
	inverseKey = [[self classDescription] inverseForRelationshipKey:key];
	if (inverseKey) {
		[object addObject:self toPropertyWithKey:inverseKey];
	}
}

// jean_alexis at users.sourceforge.net 2005-09-08
// Added ownsDestinationSupport
- (void)addObject:(id)object toPropertyWithKey:(NSString *)key
{
	SEL					selector;
	BOOL ownsDestination = [[self classDescription] ownsDestinationObjectsForRelationshipKey:key];
	
	selector = [self _addMethodForKey:key];

	if (selector) {
		[self performSelector:selector withObject:object];
	} else {
//		id		value;
		
		// mont_rothstein @ yahoo.com 2004-12-06
		// value was uninitialized here and it was checking to see if value
		// was a mutable dictionary, I presume this was supposed to be mutable array.
		// Added initialization and changed if from dictionary to array.
		// mont_rothstein @ yahoo.com 2004-12-13
		// After making the above changes I realized that this direct access to the 
		// NSMutableArray circumvents any business logic in a setter method.  Therefore I
		// commented out the code that directly accesses the array.
//		value = [self valueForKey: key];
//		if ([value isKindOfClass:[NSMutableArray class]]) {
//			[self willChange];
//			[value addObject:object];
//		} else {
		if (ownsDestination) {
			id oldValue = [self valueForKey: key];
			if ((oldValue != nil) && ([oldValue editingContext] != nil)) {
				[[self editingContext] deleteObject: key];
			}
		}
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
			//[self takeValue:object forKey:key];
			[self setValue:object forKey:key];
//		}
	}
	if (ownsDestination && ([object editingContext] == nil)) {
		[[self editingContext] insertObject: object];
	}
}

// jean_alexis at users.sourceforge.net 2005-09-08
// Added ownsDestinationSupport
- (void)removeObject:(id)object fromBothSidesOfRelationshipWithKey:(NSString *)key
{
	NSString		*inverseKey;
    
    [object retain];
	
	// mont_rothstein @ yahoo.com 2005-08-14
	// If a relationship is empty we can get null for an object here.  In which case we just return
	if (! object || object == [NSNull null]) return;
	
	// Remove the object to our side.
	[self removeObject:object fromPropertyWithKey:key];
	
	// And add the reverse relationship
	inverseKey = [[self classDescription] inverseForRelationshipKey:key];
	if (inverseKey) {
		[object removeObject:self fromPropertyWithKey:inverseKey];
	}
    
    [object autorelease];
}

- (void)removeObject:(id)object fromPropertyWithKey:(NSString *)key
{
	SEL			selector = [self _removeMethodForKey:key];
	BOOL ownsDestination = [[self classDescription] ownsDestinationObjectsForRelationshipKey:key];
    
    [object retain];
	
	if (selector) {
		[self performSelector:selector withObject:object];
	} else {
		// mont_rothstein @ yahoo.com 2004-12-14
		// Commented the direct access to mutable arrays out because it circumvents business logic.
//		id		value = [self valueForKey:key];
//		
//		if ([value isKindOfClass:[NSMutableArray class]]) {
//			[self willChange];
//			[value removeObjectIdenticalTo:object];
//		} else {
			// tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
			//[self takeValue:NULL forKey:key];
			[self setValue:nil forKey:key];
//		}
	}
	if (ownsDestination  && ([object editingContext] != nil)) {
		[[self editingContext] deleteObject: object];
	}
    [object autorelease];
}

@end
