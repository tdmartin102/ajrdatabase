//
//  OracleSchemaGeneration.m
//  Adaptors
//
//  Created by Tom Martin on 8/18/11.
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


#import "OracleSchemaGeneration.h"

@implementation OracleSchemaGeneration

- (NSArray *)createTableStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSMutableArray	*statements;
	NSZone			*zone = [self zone];
	Class			ExpressionClass = [self expressionClass];
	int				x;
	int				numEntityGroups;

	statements = [[NSMutableArray allocWithZone:zone] init];
	numEntityGroups = [entityGroup count];
	for (x = 0; x < numEntityGroups; x++) 
	{
		EOEntity			*entity = [entityGroup objectAtIndex:x];
		NSArray				*attributes = [entity attributes];
		int					y;
		int					numAttributes;
		int					width = 0;
		NSMutableString		*statement = [[NSMutableString alloc] init];
		EOSQLExpression		*expression;
		NSString			*pad;
		
		numAttributes = [attributes count];
		for (y = 0; y < numAttributes; y++) 
		{
			if (width < [[[attributes objectAtIndex:y] columnName] length]) 
				width = [[[attributes objectAtIndex:y] columnName] length];
		}
		
		pad = [[@" " stringByPaddingToLength:width+4 withString:@" " startingAtIndex:0] retain];
		[statement appendString:@"CREATE TABLE "];
		[statement appendString:[entity externalName]];
		[statement appendString:@" (\n"];
		numAttributes = [attributes count];
		for (y = 0; y < numAttributes; y++) 
		{
			EOAttribute		*attribute = [attributes objectAtIndex:y];
			NSString		*externalType = [[attribute externalType] uppercaseString];
			NSRange			aRange;
			
			if (y != 0) 
			{
				[statement appendString:@",\n"];
			}
			[statement appendString:pad];
			[statement appendString:[attribute columnName]];
			[statement appendString:@" "];
			// check for VARCHAR(2), NVARCHAR(2), CHAR, NCHAR as syntax is the same for all
			aRange = [externalType rangeOfString:@"CHAR"];
			if (aRange.length == 0)
			{
				// test for RAW and FLOAT as syntax is the same
				if ([externalType isEqualToString:@"RAW"] || [externalType isEqualToString:@"FLOAT"])
					aRange.length = 1;
			}
			
			if (aRange.length > 0) 
			{
				// mont_rothstein @ yahoo.com 2004-12-03
				// The width for varchar's with no width specified was being generated as
				// "(0)" which is invalid.  This was corrected to omit the width if it
				// wasn't specified.
				[statement appendString:externalType];
				if ([attribute width]) 
					[statement appendFormat:@"(%d)", [attribute width]];
			} 
			else if ([externalType isEqualToString:@"NUMBER"]) 
			{
				[statement appendString:externalType];
				if ([attribute precision] || [attribute scale])
				{
					[statement appendFormat:@"(%d", [attribute precision]];
					if ([attribute scale])
						[statement appendFormat:@",%d", [attribute scale]];
					[statement appendString:@")"];
				}
			}
			else 				
				[statement appendString:externalType];
			
			if (![attribute allowsNull]) 
				[statement appendString:@" NOT NULL"];
		}
        [pad release];
		
		[statement appendString:EOFormat(@"\n)")];
		
		expression = [[ExpressionClass allocWithZone:zone] init];
		[expression setStatement:statement];
		[statement release];
		[statements addObject:expression];
		[expression release];
	}
	
	return [statements autorelease];
}

- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSArray             *statements;
	EOSQLExpression		*expression;
	EOEntity			*entity;
	NSMutableString		*sql;
	
	if ([entityGroup count] == 0)
		return [NSArray array];
		
	entity = [entityGroup objectAtIndex:0];	
	expression = [[[self expressionClass] allocWithZone:[self zone]] init];
	sql = [@"DROP SEQUENCE " mutableCopy];
	[sql appendString:[entity externalName]];
	[sql appendString:@"_SEQ"];
	[expression setStatement:sql];
	[sql release];
	statements = [[NSArray allocWithZone:[self zone]] initWithObjects:&expression count:1];
	[expression release];
	
	return [statements autorelease];
}


- (NSArray *)primaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSArray         *statements;
	EOSQLExpression	*expression;
	EOEntity			*entity;
	NSMutableString		*sql;

	if ([entityGroup count] == 0)
		return [NSArray array];
		
	entity = [entityGroup objectAtIndex:0];	
	sql = [@"create SEQUENCE " mutableCopy];
	[sql appendString:[entity externalName]];
	[sql appendString:@"_SEQ increment by 1 start with 1 order"];
	expression = [[[self expressionClass] allocWithZone:[self zone]] init];
	[expression setStatement:sql];
	[sql release];
	statements = [[NSArray allocWithZone:[self zone]] initWithObjects:&expression count:1];
	[expression release];
	
	return [statements autorelease];
}

@end
