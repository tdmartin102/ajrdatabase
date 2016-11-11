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

#import "EOAndQualifier-EOAccess.h"

#import "EOQualifier-EOAccess.h"
#import "EOSQLExpression.h"

@implementation EOAndQualifier (EOAccess)

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
   NSMutableString	*string = [[[NSMutableString allocWithZone:[self zone]] initWithString:@"("] autorelease];
   NSInteger		x;
   NSInteger        numQualifiers;

   numQualifiers = [qualifiers count];
   for (x = 0; x < numQualifiers; x++) {
      if (x > 0) {
         [string appendString:@" AND "];
      }
      [string appendString:[[qualifiers objectAtIndex:x] sqlStringForSQLExpression:expression]];
   }
   [string appendString:@")"];

   return string;
}

- (NSString *)sqlJoinForSQLExpression:(EOSQLExpression *)expression
{
   // Promote our join, because AND is communitive.
   NSInteger			x, max = [qualifiers count];
   NSMutableArray		*joins;
   EOQualifier			*qualifier;
   NSString				*join;
   NSMutableString	*sqlString;

   joins = [[NSMutableArray allocWithZone:[self zone]] init];
   for (x = 0; x < max; x++) {
      qualifier = [qualifiers objectAtIndex:x];
      join = [qualifier sqlJoinForSQLExpression:expression];
      if (join != nil) [joins addObject:join];
   }

   max = [joins count];
   if (max == 0) {
      [joins release];
      return nil;
   }
   if (max == 1) {
      join = [[[joins objectAtIndex:0] retain] autorelease];
      [joins release];
      return join;
   }
   
   sqlString = [[[NSMutableString allocWithZone:[self zone]] initWithString:@"("] autorelease];
   for (x = 0; x < max; x++) {
      if (x >= 1) {
         [sqlString appendString:@" AND "];
      }
      [sqlString appendString:[joins objectAtIndex:x]];
   }
   [sqlString appendString:@")"];

   [joins release];
   
   return sqlString;
}

@end
