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

#import "EOEntity-ObjCCode.h"

#import "EOAttributeP.h"
#import "EOEntityP.h"
#import "EORelationship.h"

#import <EOControl/EOControl.h>

@implementation EOEntity (ObjCCode)

- (NSString *)objectiveCInterface
{
   NSMutableString		*string = [NSMutableString string];
   EOAttribute				*attribute;
   EORelationship			*relationship;
   int						x;
   int numRelationships;
   int numAttributes;
   NSMutableArray			*temp;

   [self _initialize];
   
   [string appendString:@"\n"];
   [string appendString:@"#import <EOAccess/EOAccess.h>\n"];
   [string appendString:@"\n"];

   temp = [[NSMutableArray alloc] init];
   numRelationships = [relationships count];
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      if ([classPropertyNames containsObject:[relationship name]]) {
         if (![[[relationship destinationEntity] className] isEqualToString:@"EOGenericRecord"]) {
            [temp addObject:[[relationship destinationEntity] className]];
         }
      }
   }

   if ([temp count]) {
	   int classNames;
	   
	   [string appendString:@"@class "];
	   classNames = [temp count];
	   for (x = 0; x < classNames; x++) {
		   if (x > 0) [string appendString:@", "];
		   [string appendString:[temp objectAtIndex:x]];
	   }
	   [string appendString:@";\n"];
	   [string appendString:@"\n"];
   }
   
   [string appendFormat:@"@interface %@ : %@\n", [self className], [self parentEntity] ? [[self parentEntity] className] : @"EOGenericRecord"];
   [string appendString:@"{\n"];
   [string appendString:@"}\n"];
   [string appendString:@"\n"];

   numAttributes = [attributes count];
   for (x = 0; x < numAttributes; x++) {
      attribute = [attributes objectAtIndex:x];
      if ([attribute _isClassProperty]) {
         [string appendFormat:@"- (void)set%@:(%@ *)value;\n", [[attribute name] capitalizedName], [attribute _valueClass]];
         [string appendFormat:@"- (%@ *)%@;\n", [attribute _valueClass], [attribute name]];
      }
   }

   [string appendString:@"\n"];
   [string appendString:@"// To-One Relationships\n"];
   [string appendString:@"\n"];

   numRelationships = [relationships count];
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      if (![relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
         [string appendFormat:@"- (void)set%@:(%@ *)value;\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
         [string appendFormat:@"- (%@ *)%@;\n", [[relationship destinationEntity] className], [relationship name]];
      }
   }

   [string appendString:@"\n"];
   [string appendString:@"// To-Many Relationships\n"];
   [string appendString:@"\n"];

   numRelationships = [relationships count];
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
         [string appendFormat:@"- (void)set%@:(%@ *)value;\n", [[relationship name] capitalizedName], @"NSMutableArray"];
         [string appendFormat:@"- (%@ *)%@;\n", @"NSArray", [relationship name]];
         [string appendFormat:@"- (void)addTo%@:(%@ *)value;\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
         [string appendFormat:@"- (void)removeFrom%@:(%@ *)value;\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
      }
   }

   [string appendString:@"\n"];
   [string appendString:@"@end\n"];
   [string appendString:@"\n"];
   
   [temp release];
   
   return string;
}

- (NSString *)objectiveCImplementation
{
   NSMutableString		*string = [NSMutableString string];
   EOAttribute				*attribute;
   EORelationship			*relationship;
   int						x;
   int numClassNames;
   int numRelationships;
   int numAttributes;
   NSMutableArray			*temp;

   [self _initialize];

   temp = [[NSMutableArray alloc] init];
   numRelationships = [relationships count];
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      if ([classPropertyNames containsObject:[relationship name]]) {
         if (![[[relationship destinationEntity] className] isEqualToString:@"EOGenericRecord"]) {
            [temp addObject:[[relationship destinationEntity] className]];
         }
      }
   }

   [string appendString:@"\n"];
   [string appendFormat:@"#import \"%@.h\"\n", [self className]];
   [string appendString:@"\n"];

   numClassNames = [temp count];
   if (numClassNames) {
	   
	   for (x = 0; x < numClassNames; x++) {
		   [string appendFormat:@"#import \"%@.h\"\n", [temp objectAtIndex:x]];
	   }
	   [string appendString:@"\n"];
   }
   
   [string appendFormat:@"@implementation %@\n", [self className]];
   [string appendString:@"\n"];

   numAttributes = [attributes count];
   for (x = 0; x < numAttributes; x++) {
      attribute = [attributes objectAtIndex:x];
      if ([attribute _isClassProperty]) {
         [string appendFormat:@"- (void)set%@:(%@ *)value\n", [[attribute name] capitalizedName], [attribute _valueClass]];
         [string appendFormat:@"{\n"];
         [string appendFormat:@"   [self willChange];\n"];
         [string appendFormat:@"   [self setPrimitiveValue:value forKey:@\"%@\"];\n", [attribute name]];
         [string appendFormat:@"}\n"];
         [string appendFormat:@"\n"];
         [string appendFormat:@"- (%@ *)%@\n", [attribute _valueClass], [attribute name]];
         [string appendFormat:@"{\n"];
         [string appendFormat:@"   return [self valueForKey:@\"%@\"];\n", [attribute name]];
         [string appendFormat:@"}\n"];
         [string appendFormat:@"\n"];
      }
   }

   [string appendString:@"// To-One Relationships\n"];
   [string appendString:@"\n"];

   numRelationships = [relationships count];
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      if (![relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
         [string appendFormat:@"- (void)set%@:(%@ *)value\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
         [string appendFormat:@"{\n"];
         [string appendFormat:@"   [self willChange];\n"];
         [string appendFormat:@"   [self setPrimitiveValue:value forKey:@\"%@\"];\n", [relationship name]];
         [string appendFormat:@"}\n"];
         [string appendFormat:@"\n"];
         [string appendFormat:@"- (%@ *)%@\n", [[relationship destinationEntity] className], [relationship name]];
         [string appendFormat:@"{\n"];
         [string appendFormat:@"   return [self valueForKey:@\"%@\"];\n", [relationship name]];
         [string appendFormat:@"}\n"];
         [string appendFormat:@"\n"];
      }
   }

   [string appendString:@"\n"];
   [string appendString:@"// To-Many Relationships\n"];
   [string appendString:@"\n"];

   numRelationships = [relationships count];
   for (x = 0; x < numRelationships; x++) {
      relationship = [relationships objectAtIndex:x];
      if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
         [string appendFormat:@"- (void)set%@:(%@ *)value\n", [[relationship name] capitalizedName], @"NSMutableArray"];
         [string appendString:@"{\n"];
         [string appendString:@"   [self willChange];\n"];
         [string appendFormat:@"   [self setPrimitiveValue:value forKey:@\"%@\"];\n", [relationship name]];
         [string appendString:@"}\n"];
         [string appendString:@"\n"];
         [string appendFormat:@"- (%@ *)%@\n", @"NSArray", [relationship name]];
         [string appendString:@"{\n"];
         [string appendFormat:@"   return [self valueForKey:@\"%@\"];\n", [relationship name]];
         [string appendString:@"}\n"];
         [string appendString:@"\n"];
         [string appendFormat:@"- (void)addTo%@:(%@ *)value\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
         [string appendString:@"{\n"];
         [string appendFormat:@"   NSMutableArray\t*array = (NSMutableArray *)[self %@];\n", [relationship name]];
         [string appendString:@"\n"];
         [string appendString:@"   [self willChange];\n"];
         [string appendString:@"   [array addObject:value];\n"];
         [string appendString:@"}\n"];
         [string appendString:@"\n"];
         [string appendFormat:@"- (void)removeFrom%@:(%@ *)value\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
         [string appendString:@"{\n"];
         [string appendFormat:@"   NSMutableArray\t*array = (NSMutableArray *)[self %@];\n", [relationship name]];
         [string appendString:@"\n"];
         [string appendString:@"   [self willChange];\n"];
         [string appendString:@"   [array removeObject:value];\n"];
         [string appendString:@"}\n"];
         [string appendString:@"\n"];
      }
   }

   [string appendString:@"@end\n"];
   [string appendString:@"\n"];

   [temp release];
   
   return string;
}

@end
