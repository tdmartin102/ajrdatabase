
#import "PostgreSQLSchemaGeneration.h"

@interface EOAttribute (Private)

- (BOOL)_isIntegralNumeric;

@end

@implementation PostgreSQLSchemaGeneration

- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSMutableArray		*statements;
	EOSQLExpression	*expression;
	int					x;
	int numEntities;
	
	statements = [[NSMutableArray allocWithZone:[self zone]] init];
	numEntities = [entityGroup count];
	for (x = 0; x < numEntities; x++) {
		EOEntity		*entity = [entityGroup objectAtIndex:x];
		NSArray		*pks = [entity primaryKeyAttributes];
		
		if ([pks count] == 1 && [[pks objectAtIndex:0] _isIntegralNumeric]) {
			expression = [[[self expressionClass] allocWithZone:[self zone]] init];
			[expression setStatement:EOFormat(@"DROP SEQUENCE %@_PK", [entity externalName])];
			[statements addObject:expression];
			[expression release];
		}
	}
			
	return [statements autorelease];
}

- (NSArray *)primaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSMutableArray		*statements;
	EOSQLExpression	*expression;
	int					x;
	int numEntities;
	
	statements = [[NSMutableArray allocWithZone:[self zone]] init];
	numEntities = [entityGroup count];
	for (x = 0; x < numEntities; x++) {
		EOEntity		*entity = [entityGroup objectAtIndex:x];
		NSArray		*pks = [entity primaryKeyAttributes];
		
		if ([pks count] == 1 && [[pks objectAtIndex:0] _isIntegralNumeric]) {
			expression = [[[self expressionClass] allocWithZone:[self zone]] init];
			[expression setStatement:EOFormat(@"CREATE SEQUENCE %@_PK MINVALUE 1 START 1", [entity externalName])];
			[statements addObject:expression];
			[expression release];
		}
	}
			
	return [statements autorelease];
}

@end
