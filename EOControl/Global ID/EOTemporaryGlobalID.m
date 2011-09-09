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

#import "EOTemporaryGlobalID.h"

#import "EOKeyGlobalID.h"

@implementation EOTemporaryGlobalID

- (id)initWithEntityName:(NSString *)anEntityName
{
   entityName = [anEntityName retain];
   uniqueID = [[[NSProcessInfo processInfo] globallyUniqueString] retain];

   return self;
}

- (void)dealloc
{
   [entityName release];
   [uniqueID release];
	[newGlobalID release];

   [super dealloc];
}

- (BOOL)isTemporary
{
   return YES;
}

- (BOOL)isEqual:(id)other
{
   if ([other isKindOfClass:[EOTemporaryGlobalID class]]) {
      EOTemporaryGlobalID	*trueOther = other;
      return [entityName isEqualToString:trueOther->entityName] && [uniqueID isEqualToString:trueOther->uniqueID];
   }
   return NO;
}

- (unsigned)hash
{
   return [uniqueID hash];
}

- (int)compare:(id)other
{
   if ([other isKindOfClass:[EOTemporaryGlobalID class]]) {
      EOTemporaryGlobalID	*trueOther = other;
      int						result;

      result = [entityName compare:trueOther->entityName];
      if (result == NSOrderedSame) {
         return [uniqueID compare:trueOther->uniqueID];
      }

      return result;
   }
   return NSOrderedAscending;
}

- (NSString *)entityName
{
   return entityName;
}

- (EOQualifier *)buildQualifier
{
	if (newGlobalID) return [(EOKeyGlobalID *)newGlobalID buildQualifier];
   return nil;
}

- (id)valueForKey:(NSString *)key
{
	if (newGlobalID) return [newGlobalID valueForKey:key];
   return nil;
}

- (NSString *)description
{
    NSMutableString	*buffer = [[@"[" mutableCopyWithZone:[self zone]] autorelease];
	
	[buffer appendString: entityName!= nil ? entityName : @"Null"];
    [buffer appendString:@":"];
    [buffer appendString:uniqueID];
    [buffer appendString:@"]"];

    return buffer;
}

- (void)setNewGlobalID:(EOGlobalID *)aGlobalID
{
	if (newGlobalID != aGlobalID) {
		[newGlobalID release];
		newGlobalID = [aGlobalID retain];
	}
}

- (EOGlobalID *)newGlobalID
{
	return newGlobalID;
}

@end
