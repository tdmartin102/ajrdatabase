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

#import "PostgreSQLExpression.h"

#import <libpq-fe.h>

@implementation PostgreSQLExpression

- (void)prepareStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values
{
	NSArray		*arguments = [storedProcedure arguments];
	int			x;
	int numArguments;
	
	[statement release];
	statement = [@"SELECT " mutableCopyWithZone:[self zone]];
	[statement appendString:[storedProcedure externalName]];
	[statement appendString:@"("];
	numArguments = [arguments count];
	for (x = 0; x < numArguments; x++) {
		EOAttribute	*argument = [arguments objectAtIndex:x];
		
		// mont_rothstein @ yahoo.com 2004-12-03
		// Wrapped an if around this that makes sure we are only grabbing arguments
		// being passed into the stored procedure.
		if ([argument parameterDirection] == EOInParameter)
		{
			id value = [values objectForKey:[argument name]];
			if (x) [statement appendString:@", "];
			[statement appendString:[self formatValue:value forAttribute:argument]];
		}
	}
	[statement appendString:@")"];
}


// mont_rothstein @ yahoo.com 2005-06-23
// Added PostgreSQL expression for locking selected rows
- (NSString *)lockClause
{
	return @"FOR UPDATE";
}

@end
