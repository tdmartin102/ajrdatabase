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

#import "EOOrQualifier-EOAccess.h"

#import "EOQualifier-EOAccess.h"
#import "EOSQLExpression.h"

@implementation EOOrQualifier (EOAccess)

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
	NSMutableString	*sqlString;
	int					x;
	int numQualifiers;
	NSString				*joinString;
	EOQualifier			*qualifier;

	sqlString = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];

	[sqlString appendString:@"("];
   
	numQualifiers = [qualifiers count];
	for (x = 0; x < numQualifiers; x++) {
		qualifier = [qualifiers objectAtIndex:x];
		if (x >= 1) {
			[sqlString appendString:@" OR "];
		}
		/*
		joinString = [qualifier sqlJoinForSQLExpression:expression];
		if (joinString != nil) {
			[sqlString appendString:@"("];
			[sqlString appendString:joinString];
			[sqlString appendString:@" AND "];
			[sqlString appendString:[qualifier sqlStringForSQLExpression:expression]];
			[sqlString appendString:@")"];
		} else {
			[sqlString appendString:[qualifier sqlStringForSQLExpression:expression]];
		}
		*/
		[sqlString appendString:[qualifier sqlStringForSQLExpression:expression]];
	}
	[sqlString appendString:@")"];

	return sqlString;
}

- (NSString *)sqlJoinForSQLExpression:(EOSQLExpression *)expression
{
   // This never promotes a join because OR is not communitive.
   return nil;
}

@end
