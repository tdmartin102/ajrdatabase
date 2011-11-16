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

#import "EOFault.h"

#import "EOFaultHandler.h"
#import "EOGlobalID.h"

#import <objc/objc.h>
#import <objc/objc-api.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

@implementation EOFault
// jean_alexis @ sourceforge.net 2005-11-23 moved from EOAccess and adapted for +clearFault
+ (void)makeObjectIntoFault:(id)anObject withHandler:(EOFaultHandler *)aFaultHandler;
{
	Class faultClass = [EOFault class];
	if (((EOFault *)anObject)->isa != faultClass) {
		[aFaultHandler setSavedClass: ((EOFault *)anObject)->isa];
		[aFaultHandler setSavedIvars: ((EOFault *)anObject)->handler];
		
		((EOFault *)anObject)->isa = faultClass;
		((EOFault *)anObject)->handler = [aFaultHandler retain];
	} else {
		// jean_alexis @ sourceforge.net 2005-12-09 maybe we should raise
		[self setFaultHandler: aFaultHandler forFault: anObject];
	}
}



+ (id)createObjectFaultWithGlobalID:(EOGlobalID *)globalID
                   inEditingContext:(EOEditingContext *)editingContext
{
	// Does nothing. Over ridden by a subclass to do the actual work.
	return nil; 
}

+ (id)createArrayFaultWithSourceGlobalID:(EOGlobalID *)sourceGlobalID
                        relationshipName:(NSString *)relationshipName
                        inEditingContext:(EOEditingContext *) editingContext
{
	// Does nothing. Over ridden by a subclass to do the actual work.
	return nil; 
}

+ (BOOL)isFault:(id)object
{
	if (object == nil) return NO;
	
	// aclark78@users.sourceforge.org - 2006/10/02
	//Class isaClass = ((struct objc_class *)object)->isa;
	// tom.martin @ riemer.com - 2011/09/15
	Class isaClass = ((Class)object)->isa;
	return ((isaClass == [EOFault class]) || 
			(isaClass == NSClassFromString(@"NSKVONotifying_EOFault")));
}

+ (void)clearFault: (EOFault *)aFault
{
	if ([EOFault isFault: aFault]) {
		EOFaultHandler *theHandler = aFault->handler;
		Class savedClass = [theHandler savedClass];
		if (savedClass != NULL) {
			aFault->isa = [theHandler savedClass];
			aFault->handler = [theHandler savedIvars];
		} else {
			aFault->handler = nil;
		}
		[theHandler release];
	} else {
		/*! @todo EOFault: clearFault: should raise if not a fault */
	}
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [handler descriptionWithLocale:locale indent:indent]; 
}

- (NSString *)description
{
   return [self descriptionWithLocale:nil indent:0];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
   return [[handler faultedClass] instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
   [handler faultObject:self];
   [anInvocation invokeWithTarget:self];
}

- (EOGlobalID *)globalID
{
   return [handler globalID]; 
}

+ (EOFaultHandler *)faultHandlerForFault:(id)aFault
{
   if ([EOFault isFault:aFault]) {
      return ((EOFault *)aFault)->handler;
   }

   return nil;
}

+ (void)setFaultHandler:(EOFaultHandler *)faultHandler forFault:(id)object
{
   if ([EOFault isFault:object] && ((EOFault *)object)->handler != faultHandler) {
	   if (((EOFault *)object)->handler) {
		   [faultHandler setSavedIvars: [((EOFault *)object)->handler savedIvars]];
		   [faultHandler setSavedClass: [((EOFault *)object)->handler savedClass]];
	   }
	   [((EOFault *)object)->handler release];
	   ((EOFault *)object)->handler = [faultHandler retain];
   }
}

// mont_rothstein @ yahoo.com 2004-12-05
// We need to be able to clear the handler variable from within the handler itself.
// This is because the handler is going to release it self, but if the fault still has
// a pointer it will cause problems as the attributes of the object replaced by the
// fault are set.
// jean_alexis @ sourceforge.net 2005-23-11 replaced by clearFault:.

- (void)dealloc
{
/*! @todo This should be using the clearFault: class method per the WO 4.5 API */
	//jean_alexis @ sourceforge.net 2005-23-11 done
	[EOFault clearFault:self];
   
	if ([EOFault isFault: self]) {
		[super dealloc];
	} else {
		[self dealloc];
	}
}

- (id)valueForKey:(NSString *)key
{
   id		value;

   // If the value is part of our primary key, we can actually avoid faulting by returning the value from our global ID.
   if ((value = [[handler globalID] valueForKey:key])) {
      return value;
   }
   [handler faultObject:self];
   return [self valueForKey:key];
}

- (id)_valueForKey:(NSString *)key
{
   [handler faultObject:self];
   return [self _valueForKey:key];
}

// tom.martin @ riemer.com - 2011-09-16
// replace depreciated method.  
- (void)takeValue:(id)value forKey:(NSString *)key
{
   [self setValue:value forKey:key];
}
- (void)setValue:(id)value forKey:(NSString *)key
{
   [handler faultObject:self];
   [self setValue:value forKey:key];
}


// tom.martin @ riemer.com - 2011-09-16
// replace depreciated method.  
- (void)_takeValue:(id)value forKey:(NSString *)key
{
   [handler faultObject:self];
   [self setValue:value forKey:key];
}

- (id)storedValueForKey:(NSString *)key
{
    [handler faultObject:self];
	// tom.martin @ riemer.com - 2011-09-16
	// replace depreciated method.  This should be tested, behavior is different.
	// It may be acceptable, and then again maybe not. 
	// [self storedValueForKey:key];    
	[self valueForKey:key];
}

// tom.martin @ riemer.com 2011-11-16
// it turns out that the purpose of takeStoredValue is basically to 
// avoid calling the accessor method so that willChange will NOT be called
// I have implemented setPrimitiveValue:forKey to replace takeStoredValue:forKey:
// So this method is replaced here.                                              
- (void)setPrimitiveValue:(id)value forkey:(NSString *)key
{
	[handler faultObject:self];
	[self  setPrimitiveValue:value forkey:key];
}

// (ja @ sente.ch) was missing
- (void)takeStoredValue:(id)value forKey:(NSString *)key
{
	//[handler faultObject:self];
	// tom.martin @ riemer.com - 2011-09-16
	// replace depreciated method.  This should be tested, behavior is different.
	// It may be acceptable, and then again maybe not. 
	//[self takeStoredValue:value forKey:key];
	//[self setValue:value forKey:key];
	// tom.martin @ riemer.com 2011-11-16
	// it turns out that the purpose of takeStoredValue is basically to 
	// avoid calling the accessor method so that willChange will NOT be called
	// I have implemented setPrimitiveValue:forKey to replace takeStoredValue:forKey:
	// So this method is replaced here.  
	[self setPrimitiveValue:value forkey:key];
}


// mont_rothstein @ yahoo.com 2005-05-15
// Trip the fault when classDescription is called.
// alex @ raftis.net 2006-07-03
// Actually, don't trip, since it's not necessary, however, do make sure to return
// the correct class description.
- (NSClassDescription *)classDescription
{
	return [NSClassDescription classDescriptionForClass:[handler faultedClass]];
}


// mont_rothstein @ yahoo.com 2005-05-15
// Added as per WO 4.5.1 API
- self
{
	[handler faultObject:self];
	return [self self];
}

/*
 * AJR 2006-07-03
 * This needs to return the class that will be faulted in, since we don't want
 * a query for the class to trip the fault. However, whatever is querying us needs to
 * think it already has an instance of the eventual class.
 */
- (Class)class
{
	return [handler faultedClass];
}

- (BOOL)isKindOfClass:(Class)aClass
{
	return [handler isKindOfClass:aClass forFault:self];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
	return [handler isMemberOfClass:aClass forFault:self];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol forFault:(id)aFault
{
	return [handler conformsToProtocol:aProtocol forFault:self];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector forFault:(id)aFault
{
	return [handler methodSignatureForSelector:aSelector forFault:self];
}

// mont_rothstein @ yahoo.com 2005-08-28
// As per WO 4.5 API, needed for adding objects to a relationship on an object that is still a fault.
- (BOOL)respondsToSelector:(SEL)aSelector
{
	return [handler respondsToSelector:aSelector forFault:self];
}

@end
