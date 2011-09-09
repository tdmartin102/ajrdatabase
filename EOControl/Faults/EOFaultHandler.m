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

#import "EOFaultHandler.h"

#import "EOGlobalID.h"
#import "EOEditingContext.h"
#import "EOQualifier.h"

@implementation EOFaultHandler

- (void)dealloc
{
   [globalID release];
   [editingContext release];
   
   // jean_alexis @ sourceforge.net : save the ivars when makeObjectIntoFault is called
   savedIvars = nil;
   savedClass = nil;

   [super dealloc];
}

- (void)faultObject:(id)object
{
   /*! @todo EOFaultHandler: faultObject: This should throw an exception or at least attempt to do something, but I haven't decided what yet. */
}

- (void)faultObject:(id)object withRawRow:(NSDictionary *)row databaseContext:(EODatabaseContext *)databaseContext
{
   /*! @todo EOFaultHandler: faultObject:withRawRow: This should throw an exception or at least attempt to do something, but I haven't decided what yet. */
}

- (void)completeInitializationOfObject:(id)aFault
{
	/*! @todo EOFaultHandler: completeInitializationOfObject: This should throw an exception or at least attempt to do something, but I haven't decided what yet. */
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [NSString stringWithFormat:@"{ %@: %p }", [self class], self];
}

- (NSString *)description
{
   return [self descriptionWithLocale:nil indent:0];
}

- (Class)faultedClass
{
   return Nil;
}


- (EOGlobalID *)globalID
{
   return globalID;
}

- (void)setRestrictingQualifier:(EOQualifier *)qualifier
{
}

- (EOQualifier *)restrictingQualifier
{
}

- (void)setSavedIvars: (id)value
{
	savedIvars = value;
}

- (id)savedIvars
{
	return savedIvars;
}

- (void)setSavedClass: (Class)value
{
	savedClass = value;
}

- (Class)savedClass
{
	return savedClass;
}

/*
 * Checking class information
 */

- (BOOL)isKindOfClass:(Class)aClass forFault:(id)aFault
{
	return [[self faultedClass] isSubclassOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass forFault:(id)aFault
{
	// AJR - Is this right? I was a little unclear on the documentation, but it appears
	// that isMemberOfClass returns true if and only if an object is the same class
	// as the receiver, not also a subclass.
	return [self faultedClass] == aClass;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol forFault:(id)aFault
{
	return [[self faultedClass] conformsToProtocol:aProtocol];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector forFault:(id)aFault
{
	return [[self faultedClass] instanceMethodSignatureForSelector:aSelector];
}

// mont_rothstein @ yahoo.com 2005-08-28
// As per WO 4.5 API, needed for adding objects to a relationship on an object that is still a fault.
- (BOOL)respondsToSelector:(SEL)aSelector forFault:(id)aFault
{
	/*! @todo To support entity inheritance, the Access layer should fire te fault for entities with subentities to confirm their precise class membership. */
	return [[self faultedClass] instancesRespondToSelector:aSelector];
}

@end
