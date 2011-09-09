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

#import "EOJoin.h"

#import "EOAttribute.h"
#import "EOSQLExpression.h"

#import <EOControl/EOControl.h>

@implementation EOJoin

- (id)initWithSourceAttribute:(EOAttribute *)source destinationAttribute:(EOAttribute *)destination
{
    [super init];
   sourceAttribute = [source retain];
   destinationAttribute = [destination retain];

   return self;
}

- (void) dealloc
{
    [sourceAttribute release];
    [destinationAttribute release];
    
    [super dealloc];
}

- (void)_setSourceAttribute:(EOAttribute *)attribute
{
   if (sourceAttribute != attribute) {
		[self willChange];
      [sourceAttribute release];
      sourceAttribute = [attribute retain];
   }
}

- (EOAttribute *)sourceAttribute
{
   return sourceAttribute;
}

- (void)_setDestinationAttribute:(EOAttribute *)attribute
{
   if (destinationAttribute != attribute) {
		[self willChange];
      [destinationAttribute release];
      destinationAttribute = [attribute retain];
   }
}

- (EOAttribute *)destinationAttribute
{
   return destinationAttribute;
}

- (BOOL)isReciprocalToJoin:(EOJoin *)other
{
    return ([[self sourceAttribute] isEqual:[other destinationAttribute]] && [[other sourceAttribute] isEqual:[self destinationAttribute]]);
}

- (EOQualifier *)_qualifierForValues:(NSDictionary *)values
{
   return [EOKeyValueQualifier qualifierWithKey:[destinationAttribute name]
                                          value:[values objectForKey:[sourceAttribute name]]];
}

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
   NSMutableString 	*sqlString = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];

   [sqlString appendString:@"("];
   [sqlString appendString:[expression sqlStringForAttribute:sourceAttribute]];
   [sqlString appendString:@" = "];
   [sqlString appendString:[expression sqlStringForAttribute:destinationAttribute]];
   [sqlString appendString:@")"];

   return sqlString;
}

+ (BOOL)_joinsAreEqual:(NSArray *)joins1:(NSArray *)joins2
{
    int numJoins1, numJoins2;

    numJoins1 = [joins1 count];
    numJoins2 = [joins2 count];
	if (numJoins1 == numJoins2) {
		int			x, y;
		EOJoin		*join1, *join2;
		
		for (x = 0; x < numJoins1; x++) {
			join1 = [joins1 objectAtIndex:x];
			for (y = 0; y < numJoins1; y++) {
				join2 = [joins2 objectAtIndex:x];
				if ([[join1 sourceAttribute] isEqual:[join2 destinationAttribute]] &&
					[[join2 sourceAttribute] isEqual:[join1 destinationAttribute]]) {
					break;
				}
			}
			if (y == numJoins2) return NO;
		}
		return YES;
	}
	
	return NO;
}

@end
