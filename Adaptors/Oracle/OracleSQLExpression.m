//
//  OracleSQLExpression.m
//  Adaptors
//
//  Created by Tom Martin on 12/3/10.
/*  Copyright (C) 2011 Riemer Reporting Service, Inc.

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

Tom Martin
24600 Detroit Road
Westlake, OH 44145
mailto:tom.martin@riemer.com
*/


#import "OracleSQLExpression.h"

@implementation OracleSQLExpression

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
		if ([argument parameterDirection] == EOInParameter)
		{
			id value = [values objectForKey:[argument name]];
			if (x) [statement appendString:@", "];
			[statement appendString:[self formatValue:value forAttribute:argument]];
		}
	}
	[statement appendString:@")"];
}

- (NSString *)lockClause
{
	return @"FOR UPDATE";
}

- (NSMutableDictionary *)bindVariableDictionaryForAttribute:(EOAttribute *)attribute value:value
{
	int	index;
	NSMutableDictionary	*binding;
	NSString			*name;
	NSString			*placeholder;
	
	index = [bindings count] + 1;
	
	binding = [[NSMutableDictionary allocWithZone:[self zone]] initWithCapacity:4];
	name = [[NSString allocWithZone:[self zone]] initWithFormat:@"%@_%d", [attribute columnName], index];
	placeholder = [[NSString allocWithZone:[self zone]] initWithFormat:@":%@", name];
	
	[binding setObject:attribute forKey:EOBindVariableAttributeKey];
	[binding setObject:name forKey:EOBindVariableNameKey];
	[binding setObject:placeholder forKey:EOBindVariablePlaceHolderKey];
	if (! value)
		[binding setObject:[EONull null] forKey:EOBindVariableValueKey];
	else
		[binding setObject:value forKey:EOBindVariableValueKey];
	
	[name release];
	[placeholder release];
	return [binding autorelease];
}

- (BOOL)shouldUseBindVariableForAttribute:(EOAttribute *)att { return YES; }
- (BOOL)mustUseBindVariableForAttribute:(EOAttribute *)att { return YES; }

@end
