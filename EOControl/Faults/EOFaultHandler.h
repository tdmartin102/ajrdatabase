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

#import <Foundation/Foundation.h>

@class EODatabaseContext, EOEditingContext, EOGlobalID, EOQualifier;

@interface EOFaultHandler : NSObject
{
   EOEditingContext	*editingContext;
   EOGlobalID			*globalID;
// jean_alexis @ sourceforge.net : save the ivars when makeObjectIntoFault is called
   Class savedClass;
   id savedIvars;
}

- (void)faultObject:(id)object;
- (void)faultObject:(id)object withRawRow:(NSDictionary *)row databaseContext:(EODatabaseContext *)databaseContext;

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent;
- (NSString *)description;

- (Class)faultedClass;
- (EOGlobalID *)globalID;

#if !defined(STRICT_EOF)
- (void)setRestrictingQualifier:(EOQualifier *)qualifier;
- (EOQualifier *)restrictingQualifier;
#endif

- (void)setSavedIvars: (id)value;
- (id)savedIvars;
- (void)setSavedClass: (Class)value;
- (Class)savedClass;

// Checking class information
- (BOOL)isKindOfClass:(Class)aClass forFault:(id)aFault;
- (BOOL)isMemberOfClass:(Class)aClass forFault:(id)aFault;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol forFault:(id)aFault;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector forFault:(id)aFault;
- (BOOL)respondsToSelector:(SEL)aSelector forFault:(id)aFault;

@end
