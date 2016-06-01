//
//  MySQLSQLExpression.m
//  Adaptors
//
//  Created by Tom Martin on 4/29/16.
/*

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


#import "MySQLSQLExpression.h"

@implementation MySQLSQLExpression

- (void)prepareStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values
{
	NSArray		*arguments = [storedProcedure arguments];
	int			x;
	int numArguments;
	
	[statement release];
	statement = [@"SELECT " mutableCopy];
	[statement appendString:[storedProcedure externalName]];
	[statement appendString:@"("];
	numArguments = (int)[arguments count];
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

// MySQL bindings are really simple.  There is no name binding it is position ONLY
// So the placeholder is ALWAYS a single character '?' and there is no key binding
// the binds are just an array where the element of the array corrasponds to the
// position of the place holder so:
//
// a SQL string would look like this
// "update tableName set name = ?, address = ?, city = ? where id = ?"
// and the binds are:
//   bind[0] is the name
//   bind[1] is the address
//   bind[2] is the city
//   bind[3] is the id
// So EOBindVariablePlaceHolderKey is ALWASY '?' for all bindings
// there IS no variable name key but we will store the index here
// The issue is that the order of the bind array MUST match the order of the
// attributes in the SQL.  I believe the ways things are coded now that this
// will indeed be the case.  Any significant change to the SQLExpression may
// change that, so this is kind of risky.  That all said I can't think of any
// way of making a map between the attributes and the binds given the current
// API and without a key name binding.
- (NSMutableDictionary *)bindVariableDictionaryForAttribute:(EOAttribute *)attribute value:value
{
	int	index;
	NSMutableDictionary	*binding;
	NSString			*name;
	
	index = (int)([bindings count] + 1);
	
	binding = [[NSMutableDictionary alloc] initWithCapacity:4];
    name = [NSString stringWithFormat:@"%d", index];
	[binding setObject:attribute forKey:EOBindVariableAttributeKey];
	[binding setObject:name forKey:EOBindVariableNameKey];
	[binding setObject:@"?" forKey:EOBindVariablePlaceHolderKey];
	if (! value)
		[binding setObject:[EONull null] forKey:EOBindVariableValueKey];
	else
		[binding setObject:value forKey:EOBindVariableValueKey];
	
	return [binding autorelease];
}

- (BOOL)shouldUseBindVariableForAttribute:(EOAttribute *)att { return YES; }
- (BOOL)mustUseBindVariableForAttribute:(EOAttribute *)att { return YES; }


// all ordering an comparisons in MySQL are case insensitive
// it is possible to force a case sensitive ordering / compare.
// For now I think I will leave most everything case insensitive as
// I just don't think it will cause harm.  It MAY cause it to miss
// something was modified between the fetch and the save, but
// I am thinking this may not be critical.
// if we really want to do case sensitive compares then we should
// add a prefix of 'BINARY' before the attribute name.
// so for THIS method it we would want
//  ORDER BY BINARY attribName ASC, BINARY attribName1 DESC
//  and then for a case INSENSITIVE ordering just leave out BINARY
// since it is so easy to do here, I will go ahead and do case
// sensitive ordering when specified.  For other compares I am not
// so sure that I will go there.
- (void)addOrderByAttributeOrdering:(EOSortOrdering *)sortOrdering
{
    SEL				selector = [sortOrdering selector];
    NSMutableString	*string = [[NSMutableString allocWithZone:[self zone]] init];
    NSString		*keySql;
    
    keySql = [self sqlStringForAttributeNamed:[sortOrdering key]];
    if ((selector == EOCompareAscending) || (selector == EOCompareDescending))
        [string appendString:@"BINARY "];
    [string appendString:keySql];
    
    if ((selector == EOCompareAscending) ||
        (selector == EOCompareCaseInsensitiveAscending)) {
        [string appendString:@" ASC"];
    } else if ((selector == EOCompareDescending) ||
               (selector == EOCompareCaseInsensitiveDescending)){
        [string appendString:@" DESC"];
    }
    
    [self appendItem:string toListString:orderByString];
    [string release];
}

@end
