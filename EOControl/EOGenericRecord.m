/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import "EOGenericRecord.h"

#import "EODefines.h"
#import "EOEditingContext.h"
#import "EOFault.h"
#import "EOFormat.h"
#import "EOGlobalID.h"
#import "EOLog.h"
#import "EONumericKeyGlobalID.h"
#import "EOKeyGlobalID.h"
#import "_EOSelectorTable.h"
#import "NSClassDescription-EO.h"
#import "NSObject-EOEnterpriseObjectP.h"
#import "NSString-EO.h"

#import <objc/objc-class.h>

static NSMutableDictionary *getMethodCache = nil;
static NSMutableDictionary *_getMethodCache = nil;
static NSMutableDictionary *setMethodCache = nil;
static NSMutableDictionary *_setMethodCache = nil;

NSString *EOObjectDidUpdateGlobalIDNotification = @"EOObjectDidUpdateGlobalIDNotification";

@interface EOGenericRecord (Private)

- (EOGlobalID *)globalID;

@end


@interface NSObject (EOPrivate) 

- (EOEntity *)_entity;

@end


@implementation EOGenericRecord

- (void)bogus
{
}

+ (void)initialize
{
   if (getMethodCache == nil) {
      getMethodCache = [[NSMutableDictionary alloc] init];
      _getMethodCache = [[NSMutableDictionary alloc] init];
      setMethodCache = [[NSMutableDictionary alloc] init];
      _setMethodCache = [[NSMutableDictionary alloc] init];
   }
}

// mont_rothstein @ yahoo.com 2005-02-18
// Added proper init method so that instances (and subclasses) can be created via
// alloc/init.
- init
{
	self = [super init];
	
	if (self)
	{
		_values = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithEditingContext:(EOEditingContext *)editingContext classDescription:(NSClassDescription *)classDescription globalID:(EOGlobalID *)globalID;
{
   [self init];

// mont_rothstienn @ yahoo.com 2005-02-18
// Moved the initialization of _values to the init method.
//   _values = [[NSMutableDictionary alloc] init];

	// mont_rothstein @ yahoo.com 2005-02-25
	// _entityName has to be stored here because otherwise there is no way to know
	// what entity the EOGenericRecord is for.  Trying to call classDescription directly
	// on EOGenericRecord would always cause the first entity that has a generic record
	// to be returned.
	   _entityName = [[classDescription entityName] retain];

// mont_rothstein @ yahoo.com 2004-12-05
// Commented this out because we should be getting the globalID from the editingContext.
//	_globalID = [globalID retain];

   return self;
}

#define RELEASE(a) { id temp = a; a = nil; [temp release]; }

- (void)dealloc
{
   // We actually have to protect against this because our objects create circular references.
   if (_isDeallocating) {
      return;
   }
   _isDeallocating = YES;

   if (EOMemoryDebug) [EOLog logDebugWithFormat:@"- [%@ (%p) dealloc]\n", [(id)self entityName], self];
   
   [_editingContext forgetObject:self];

   RELEASE(_values);
   // mont_rothstein @ yahoo.com 2005-02-25
   // _entityName has to be stored here because otherwise there is no way to know
   // what entity the EOGenericRecord is for.  Trying to call classDescription directly
   // on EOGenericRecord would always cause the first entity that has a generic record
   // to be returned.
   RELEASE(_entityName);
   RELEASE(_editingContext);
	// mont_rothstein @ yahoo.com 2004-12-05
	// Commented this out because we should be getting the globalID from the editingContext.
//   RELEASE(_globalID);

   [super dealloc];
}

- (SEL)getMethodForKey:(NSString *)key
{
   _EOSelectorTable	*table = [getMethodCache objectForKey:self->isa];
   SEL					selector;
   
   if (table == nil) {
      table = [[_EOSelectorTable alloc] init];
      [getMethodCache setObject:table forKey:self->isa];
      [table release];
   }

   selector = [table selectorForKey:key];
   if (selector == @selector(bogus)) return NULL;
   if (selector == NULL) {
      selector = NSSelectorFromString(key);
      if (selector != NULL && [self respondsToSelector:selector]) {
         [table setSelector:selector forKey:key];
      } else {
         [table setSelector:@selector(bogus) forKey:key];
         selector = NULL;
      }
   }

   return selector;
}

- (SEL)_getMethodForKey:(NSString *)key
{
   _EOSelectorTable	*table = [_getMethodCache objectForKey:self->isa];
   SEL					selector;

   if (table == nil) {
      table = [[_EOSelectorTable alloc] init];
      [_getMethodCache setObject:table forKey:self->isa];
      [table release];
   }

   selector = [table selectorForKey:key];
   if (selector == @selector(bogus)) return NULL;
   if (selector == NULL) {
      selector = NSSelectorFromString(key);
      if (selector != NULL && [self respondsToSelector:selector]) {
         [table setSelector:selector forKey:key];
      } else {
         [table setSelector:@selector(bogus) forKey:key];
         selector = NULL;
      }
   }

   return selector;
}

- (SEL)setMethodForKey:(NSString *)key
{
   _EOSelectorTable	*table = [setMethodCache objectForKey:self->isa];
   SEL					selector;

   if (table == nil) {
      table = [[_EOSelectorTable alloc] init];
      [setMethodCache setObject:table forKey:self->isa];
      [table release];
   }

   selector = [table selectorForKey:key];
   if (selector == @selector(bogus)) return NULL;
   if (selector == NULL) {
      selector = NSSelectorFromString(EOFormat(@"set%@:", [key capitalizedName]));
      if (selector != NULL && [self respondsToSelector:selector]) {
         [table setSelector:selector forKey:key];
      } else {
         [table setSelector:@selector(bogus) forKey:key];
         selector = NULL;
      }
   }

   return selector;
}

- (SEL)_setMethodForKey:(NSString *)key
{
   _EOSelectorTable	*table = [_setMethodCache objectForKey:self->isa];
   SEL					selector;

   if (table == nil) {
		// Create a hash of the selectors. This avoids undo use of reflection.
      table = [[_EOSelectorTable alloc] init];
      [_setMethodCache setObject:table forKey:self->isa];
      [table release];
   }

	// See if we've created that selector before...
   selector = [table selectorForKey:key];
	// If the bogus selector is returned, then the object doesn't respond to the given selector, and return NULL. Note that this is a valid check, because selectors are unique across the entire Obj-C runtime. Also note that the use of the "bogus" selector prevents us from trying to re-find the selector everytime the method is accessed.
   if (selector == @selector(bogus)) return NULL;
   if (selector == NULL) {
		// Didn't find the selector, so try to find the selector. Use the pattern _set<name>:
      selector = NSSelectorFromString(EOFormat(@"_set%@:", [key capitalizedName]));
		// Check and see if the selector both exists, and if our current subclass responds to it.
      if (selector != NULL && [self respondsToSelector:selector]) {
			// Hey, it did, so cache it.
         [table setSelector:selector forKey:key];
      } else {
			// Nope, so set the selector to the "bogus" selector. See above for why.
         [table setSelector:@selector(bogus) forKey:key];
         selector = NULL;
      }
   }

	// Return the selector or null.
   return selector;
}

- (id)handleQueryWithUnboundKey:(NSString *)key
{
   return [_values valueForKey:key];
}

// mont_rothstein @ yahoo.com 2005-08-06
// Added method because handleTakeValue:forUnboundKey: has been deprecated.  handletakeValue: forUnboundKey: was also missing a call to willChange, so that has been added here.
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	[self willChange];
	[_values takeValue:value forKey:key];
}

- (void)handleTakeValue:(id)value forUnboundKey:(NSString *)key
{
// mont_rothstein @ yahoo.com 2005-08-06
// This method has been deprecated.  Changed this to call new method name
//	[_values takeValue:value forKey:key];
	[self setValue: value forUndefinedKey: key];
}

- (void)unableToSetNilForKey:(NSString *)key
{
	[_values takeValue:nil forKey:key];
}

- (void)takeStoredValue:(id)value forKey:(NSString *)key
{
	void		*variable;
	Ivar		ivar;
	
	// mont_rothstein @ yahoo.com 2005-02-17
	// As per the WO 4.5.1 docs call to willChange added
	[self willChange];

	// If the key exists as a ivar in the object, then use super's implementation.
	ivar = object_getInstanceVariable(self, [key cString], &variable);
	if (ivar) {
		[super takeStoredValue:value forKey:key];
	} else {
		[_values takeValue:value forKey:key];
	}
}

- (id)storedValueForKey:(NSString *)key
{
	void		*variable;
	id			value;
	Ivar		ivar;
	
	// If the key exists as a ivar in the object, then use super's implementation.
	ivar = object_getInstanceVariable(self, [key cString], &variable);
	if (ivar) {
		value = [super storedValueForKey:key];
	} else {
		value = [_values valueForKey:key];
	}
	
   return value;
}

// mont_rothstein @ yahoo.com 2004-12-05
// Commented this out because we should be getting the globalID from the editingContext.
///*!
// * Sets the global ID. This is package scoped, because setting this without
// * fore thought could break everything. Generally speaking, this will be set
// * by the EODatabaseChannel during fetch or by the EOEditingContext during
// * insert / save. Only the EOEditingContext should ever call this method
// * after it's been assigned initially, since it expects this value to remain
// * constant over the lifetime of the object.
// */
//- (void)_setGlobalID:(EOGlobalID *)aGlobalID
//{
//   if (_globalID != aGlobalID) {
//      EOGlobalID		*oldGlobalID = [_globalID retain];
//      
//      [_globalID release];
//      _globalID = [aGlobalID retain];
//
//      if (oldGlobalID != nil && _globalID != nil) {
//         [[NSNotificationCenter defaultCenter] postNotificationName:EOObjectDidUpdateGlobalIDNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldGlobalID, @"oldGlobalID", _globalID, @"newGlobalID", nil]];
//      }
//      [oldGlobalID release];
//   }
//}

- (EOEditingContext *)editingContext
{
   return _editingContext;
}

// mont_rothstein @ yahoo.com 2005-02-25
// _entityName has to be used here because otherwise there is no way to know
// what entity the EOGenericRecord is for.  Trying to call classDescription directly
// on EOGenericRecord would always cause the first entity that has a generic record
// to be returned.
- (NSString *)entityName
{
	return _entityName;
}

- (BOOL)isNull:(NSString *)key
{
   return [_values objectForKey:key] == nil;
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [self description];
}

- (NSDictionary *)values
{
	return [[[NSDictionary allocWithZone:[self zone]] initWithDictionary:_values] autorelease];
}

/*! @todo EOGenericRecord: Can refault be retired? Should probably be done by the class description. */
#if 0
- (void)refault
{
   NSArray			*relationships = [[self _entity] relationships];
   EORelationship	*relationship;
   NSString			*name;
   int				x;
   int numRelationships;

   [self retain]; // Makes sure we're not released while refaulting...
   
   numRelationships = [relationships count];
   
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      name = [relationship name];
      if ([relationship isToMany]) {
         EOMutableArray		*array = [_values valueForKey:name];
         if (![EOFault isFault:array]) {
			 // mont_rothstein @ yahoo.com 2004-12-25
			 // Modified to call the private globalID cover method.
			 [array refaultWithSourceGlobalID:[self globalID] 
							 relationshipName:name editingContext:_editingContext];
            // Don't access the array past this point, as it might now be freed.
         }
      } else if ([relationship definition] != nil) {
         /*! @todo Create many to many relationship. This may actually be nothing, since it may be handled by the above block. */
      } else {
         id					object = [_values objectForKey:name];
         if (![EOFault isFault:object] && ![object isKindOfClass:[EOGlobalID class]]) {
            EOGlobalID		*otherGlobalID = [[[object editingContext] globalIDForObject:object] retain];
            // Stick a global id in our object values, which will indicate later that we should produce a fault before returning it.
            // Doing this in two stages protects us against ourself getting deallocated.
            [_values removeObjectForKey:name];
            if (_values && otherGlobalID) [_values takeValue:otherGlobalID forKey:[relationship name]];
            [otherGlobalID release];
         }
      }
      // Check and see if we still have values. If we don't, then the indication is that we were deallocated as part of a circular retain cycle, so we can go ahead and just skip any more refaulting :)
      if (_values == nil) break;
   }

   [self release];
}
#endif

- (BOOL)isEqual:(id)other
{
   return other == self;
}

- (NSComparisonResult)compare:(id)other
{
	 // mont_rothstein @ yahoo.com 2004-12-05
	 // _globalID was removed so this had to be modified to get the globalID from the editingContext.
	return [[_editingContext globalIDForObject: self] compare:[[other editingContext] globalIDForObject:other]];
}

- (NSString *)description
{
	// mont_rothstein @ yahoo.com 2004-12-05
	// _globalID was removed so this had to be modified to get the globalID from the editingContext.
	// mont_rothstein @ yahoo.com 2005-02-25
	// _entityName has to be stored here because otherwise there is no way to know
	// what entity the EOGenericRecord is for.  Trying to call classDescription directly
	// on EOGenericRecord would always cause the first entity that has a generic record
	// to be returned.
//	return EOFormat(@"<%@ (%p): %@>", _entityName, self, [_editingContext globalIDForObject: self]);
	// mont_rothstein @ yahoo.com 2005-02-25
	// Changed [_editingContext globalIDForObject: self] to [self globalID] because
	// many-to-many relationship objects store their globalID in the _values dict.
//	return EOFormat(@"<%@ (%p): %@>", _entityName, self, [_editingContext globalIDForObject: self]);
	/*! @todo The definition of globalID on NSObject is in EOAccess/NSObject-EOAccess, thus this causes a warning.  I don't know why globalID on NSObject is in EOAccess, and I don't have time to dig into it right now, so I am going to leave this warning :-( */
	return EOFormat(@"<%@ (%p): %@>", _entityName, self, [self globalID]);
}

// mont_rothstein @ yahoo.com 2005-02-25
// This was commented out and moved to EOAccess so that EOEntityClassDescription could
// be used.
//- (NSClassDescription *)classDescription
//{
//	return [NSClassDescription classDescriptionForEntityName:_entityName];
//}

@end

@implementation EOGenericRecord (Private)

// mont_rothstein @ yahoo.com 2005-02-25
// Moved this here from the main implementation because it is part of this category.
- (void)_setEditingContext:(EOEditingContext *)aContext
{
	if (_editingContext != aContext) {
		[_editingContext release];
		_editingContext = [aContext retain];
	}
}

// mont_rothstein @ yahoo.com 2005-02-25
// A globalID method needed to be added because of many-to-many join objects.  Unlike
// other EOGenericRecords they don't have an editing context and therefore NSObject's
// globalID method does not work.  Therefore they store their globalID in the _values
// dictionary.  This method checks for a globalID there first, and then calls super if
// on isn't found.
- (EOGlobalID *)globalID
{
	EOGlobalID *globalID;
	
	globalID = [_values objectForKey: @"globalID"];
	
	if (!globalID) {
		globalID = [super globalID];
	}
	
	return globalID;
}


- (BOOL)_isPrimitive:(NSString *)key
{
	return NO;
#if 0
	Class		objectClass = [[[self _entity] attributeNamed:key] objectClass];
	
	if (objectClass == java.lang.Integer.class) return true;
	if (javaClass == java.lang.Long.class) return true;
	if (javaClass == java.lang.Float.class) return true;
	if (javaClass == java.lang.Double.class) return true;
	if (javaClass == java.lang.Boolean.class) return true;
	
	return false;
#endif
}


@end

