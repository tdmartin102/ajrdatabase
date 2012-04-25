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

#import "EOJoinQualifier.h"

#import "EOEntityP.h"
#import "EOJoin.h"
#import "EOQualifier-EOAccess.h"
#import "EORelationshipP.h"
#import "EOSQLExpression.h"

#import <EOControl/EOControl.h>

@implementation EOJoinQualifier

+ (EOQualifier *)qualifierForRow:(NSDictionary *)aRow withDefinition:(NSString *)aDefinition
{
   return [[[self alloc] initWithRow:aRow withDefinition:aDefinition] autorelease];
}

- (id)initWithRow:(NSDictionary *)aRow withDefinition:(NSString *)aDefinition
{
	// mont_rothstein @ yahoo.com 2004-12-20
	// The call to super wasn't assigning the return value to self.  Fixed.
   self = [super init];
   
   definition = [aDefinition retain];
   row = [aRow retain];

   return self;
}

- (void)dealloc
{
   [row release];
   [definition release];

   [super dealloc];
}

- (NSString *)sqlString
{
   return EOFormat(@"(%@ = %@)", definition, row);
}

// This method, in effect, produces our link into the join expression. That is, it's what gets us from our root entity to first part of the join expression.
- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
	EOEntity		*rootEntity = [expression rootEntity];
	NSArray			*attribPath = [rootEntity _attributesForKeyPath:definition];
	EORelationship	*r;
	int             x, max;
	EOJoin          *join;
	EOQualifier    *qualifier = nil;
	EOQualifier    *subqualifier;
	EOAttribute     *source, *destination;
	id		        joinValue;
	NSArray			*joins;

	// we need to add in our joins
	// so we will send a path to sqlStringForAttributePath and it will build aliases from that.
	// This is a SIDE AFFECT of this method, but we will leverage that.  Also sqlStringForAttributePath
	// is supposed to assume that the last element is an attribute.  We tweaked the method so that
	// it does NOT assume the last element is an attribute and will simply return a blank string
	// if there was no attribute in the path.
	[expression sqlStringForAttributePath:attribPath];
	 
	// I want the first relationship
	r = [attribPath objectAtIndex:0];
	joins = [r joins];
	for (x = 0, max = [joins count]; x < max; x++) 
	{
		join = [joins objectAtIndex:x];
		source = [join sourceAttribute];
		destination = [join destinationAttribute];
		joinValue = [row valueForKey: [source name]];
		if (joinValue)
		{
			subqualifier = [EOKeyValueQualifier qualifierWithKey:[source name] 
												   operation:EOQualifierEquals
													   value:joinValue];
			if (x == 0) 
				qualifier = subqualifier;
			else 
				qualifier = [EOAndQualifier qualifierFor:qualifier and:subqualifier];
		}
	}
	
	if ([[r destinationEntity] restrictingQualifier])
	{
		qualifier = [[EOAndQualifier allocWithZone:[self zone]] initWithArray:[NSArray arrayWithObjects:qualifier, [[r destinationEntity] restrictingQualifier], nil]];
        [qualifier autorelease];
	}
	
    return [qualifier sqlStringForSQLExpression:expression];
}

// This produces the actual join. This is separate from above since join expression are often associative, so we can often simplify our expressions by bubbling the join clauses up to the top level.
- (NSString *)sqlJoinForSQLExpression:(EOSQLExpression *)expression
{
   EOEntity				*rootEntity = [expression rootEntity];
   NSArray				*attributes = [rootEntity _attributesForKeyPath:definition];
   int            	x, max;
   EORelationship		*relationship;
   NSMutableString	*sqlJoin;

   sqlJoin = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];

   [sqlJoin appendString:@"("];
   for (x = 0, max = [attributes count]; x < max; x++) {
      relationship = [attributes objectAtIndex:x];
      if (x != 0) {
         [sqlJoin appendString:@" AND "];
      }
      [sqlJoin appendString:[relationship sqlStringForSQLExpression:expression]];
   }
   [sqlJoin appendString:@")"];

   return sqlJoin;
}

@end
