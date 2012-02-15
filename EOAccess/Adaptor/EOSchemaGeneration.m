
#import "EOSchemaGeneration.h"

#import "EOAttribute.h"
#import "EOEntity.h"
#import "EORelationship.h"
#import "EOSQLExpression.h"

#import <EOControl/EOControl.h>

NSString *EOCreateDatabaseKey = @"EOCreateDatabaseKey";
NSString *EOCreatePrimaryKeySupportKey = @"EOCreatePrimaryKeySupportKey";
NSString *EOCreateTablesKey = @"EOCreateTablesKey";
NSString *EODropDatabaseKey = @"EODropDatabaseKey";
NSString *EODropPrimaryKeySupportKey = @"EODropPrimaryKeySupportKey";
NSString *EODropTablesKey = @"EODropTablesKey";
NSString *EOForeignKeyConstraintsKey = @"EOForeignKeyConstraintsKey";
NSString *EOPrimaryKeyConstraintsKey = @"EOPrimaryKeyConstraintsKey";

@implementation EOSchemaGeneration

- (BOOL)_check:(NSString *)key in:(NSDictionary *)options
{
	return [options objectForKey:key] && [[options objectForKey:key] caseInsensitiveCompare:@"YES"] == NSOrderedSame;
}

- (void)appendExpression:(EOSQLExpression *)expression toScript:(NSMutableString *)script
{
	[script appendString:[expression statement]];
	[script appendString:@";\n"];
}

- (NSArray *)createDatabaseStatementsForConnectionDictionary:(NSDictionary *)connectionDictionary administrativeConnectionDictionary:(NSDictionary *)administrativeConnectionDictionary
{
	/*! @todo EOSchemaGeneration: Create database statements */
	return nil;
}

- (NSArray *)createTableStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSMutableArray	*statements;
	NSZone			*zone = [self zone];
	Class				ExpressionClass = [self expressionClass];
	int				x;
	int numEntityGroups;

	statements = [[NSMutableArray allocWithZone:zone] init];
	numEntityGroups = [entityGroup count];
	for (x = 0; x < numEntityGroups; x++) {
		EOEntity				*entity = [entityGroup objectAtIndex:x];
		NSArray				*attributes = [entity attributes];
		int					y;
		int numAttributes;
		int					width = 0;
		NSMutableString	*statement = [[NSMutableString alloc] init];
		EOSQLExpression	*expression;
		
		numAttributes = [attributes count];
		for (y = 0; y < numAttributes; y++) {
			if (width < [[[attributes objectAtIndex:y] columnName] length]) width = [[[attributes objectAtIndex:y] columnName] length];
		}
		
		[statement appendString:EOFormat(@"CREATE TABLE %@ (\n", [entity externalName])];
		numAttributes = [attributes count];
		for (y = 0; y < numAttributes; y++) {
			EOAttribute		*attribute = [attributes objectAtIndex:y];
			NSString			*externalType = [attribute externalType];
			
			if (y != 0) {
				[statement appendString:@",\n"];
			}
			[statement appendString:EOFormat(@"    %-*@ ", width, [attribute columnName])];
			
			if ([externalType isEqualToString:@"varchar"]) {
				// mont_rothstein @ yahoo.com 2004-12-03
				// The width for varchar's with no width specified was being generated as
				// "(0)" which is invalid.  This was corrected to omit the width if it
				// wasn't specified.
				if ([attribute width]) {
					[statement appendString:EOFormat(@"%@(%d)", externalType, [attribute width])];
				} else {
					[statement appendString:EOFormat(@"%@", externalType)];
				}
			// mont_rothstein @ yahoo.com 2004-12-03
			// External type char was not beign specifically handled and therefore the
			// width was not being set.
			} else if ([externalType isEqualToString:@"char"]) {
				if ([attribute width]) {
					[statement appendString:EOFormat(@"%@(%d)", externalType, [attribute width])];
				} else {
					[statement appendString:EOFormat(@"%@", externalType)];
				}
			} else if ([externalType isEqualToString:@"float"]) {
				if ([attribute precision] != 0) {
					[statement appendString:EOFormat(@"%@(%d)", [attribute externalType], [attribute precision])];
				} else {
					[statement appendString:EOFormat(@"%@", [attribute externalType])];
				}
			} else if ([externalType isEqualToString:@"double"]) {
				[statement appendString:EOFormat(@"%@(%d,%d)", [attribute externalType], [attribute scale], [attribute precision])];
			} else if ([externalType isEqualToString:@"numeric"]) {
				[statement appendString:EOFormat(@"%@(%d,%d)", [attribute externalType], [attribute scale], [attribute precision])];
			} else {
				[statement appendString:EOFormat(@"%@", [attribute externalType])];
			}
			
			if (![attribute allowsNull]) {
				[statement appendString:@" NOT NULL"];
			}
		}
		
		[statement appendString:EOFormat(@"\n)")];
		
		expression = [[ExpressionClass allocWithZone:zone] init];
		[expression setStatement:statement];
		[statement release];
		[statements addObject:expression];
		[expression release];
	}
	
	return [statements autorelease];
}

- (NSArray *)createTableStatementsForEntityGroups:(NSArray *)entityGroups
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	int					x;
	int numEntityGroups;
	
	numEntityGroups = [entityGroups count];
	for (x = 0; x < numEntityGroups; x++) {
		[array addObjectsFromArray:[self createTableStatementsForEntityGroups:[entityGroups objectAtIndex:x]]];
	}
	
	return [array autorelease];
}

- (NSArray *)dropDatabaseStatementsForConnectionDictionary:(NSDictionary *)connectionDictionary administrativeConnectionDictionary:(NSDictionary *)administrativeConnectionDictionary
{
	/*! @todo EOSchemaGeneration: Drop database statements */
	return nil;
}

- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSArray         *statements;
	EOSQLExpression	*expression;
	
	expression = [[[self expressionClass] allocWithZone:[self zone]] init];
	[expression setStatement:@"DROP TABLE EO_pk_table CASCADE"];
	statements = [[NSArray allocWithZone:[self zone]] initWithObjects:&expression count:1];
	[expression release];
	
	return [statements autorelease];
}

- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroups:(NSArray *)entityGroups
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	int					x;
	int numEntityGroups;
	
	numEntityGroups = [entityGroups count];
	for (x = 0; x < numEntityGroups; x++) {
		[array addObjectsFromArray:[self dropPrimaryKeySupportStatementsForEntityGroup:[entityGroups objectAtIndex:x]]];
	}
	
	return [array autorelease];
}

- (NSArray *)dropTableStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSMutableArray	*statements;
	int				x;
	int numEntityGroups;
	NSZone			*zone = [self zone];
	Class				ExpressionClass = [self expressionClass];
	
	statements = [[NSMutableArray allocWithZone:zone] init];
	
	numEntityGroups = [entityGroup count];
	for (x = 0; x < numEntityGroups; x++) {
		EOEntity				*entity = [entityGroup objectAtIndex:x];
		EOSQLExpression	*expression;
		
		expression = [[ExpressionClass allocWithZone:zone] init];
		[expression setStatement:EOFormat(@"DROP TABLE %@ CASCADE", [entity externalName])];
		[statements addObject:expression];
		[expression release];
	}

	return [statements autorelease];
}

- (NSArray *)dropTableStatementsForEntityGroups:(NSArray *)entityGroups
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	int					x;
	int numEntityGroups;
	
	numEntityGroups = [entityGroups count];
	for (x = 0; x < numEntityGroups; x++) {
		[array addObjectsFromArray:[self dropTableStatementsForEntityGroup:[entityGroups objectAtIndex:x]]];
	}
	
	return [array autorelease];
}

- (NSArray *)foreignKeyConstraintStatementsForRelationship:(EORelationship *)relationship
{
	return nil;
}

- (NSArray *)primaryKeyConstraintStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSMutableArray	*statements;
	NSZone			*zone = [self zone];
	Class				ExpressionClass = [self expressionClass];
	int				x;
	int numEntityGroups;
	
	statements = [[NSMutableArray allocWithZone:zone] init];
	numEntityGroups = [entityGroup count];
	for (x = 0; x < numEntityGroups; x++) {
		EOEntity				*entity = [entityGroup objectAtIndex:x];
		NSArray				*attributes = [entity primaryKeyAttributes];
		int					y;
		int numAttributes;
		NSMutableString	*statement;
		EOSQLExpression	*expression;
		
		if ([attributes count]) {
			statement = [[NSMutableString alloc] initWithString:EOFormat(@"ALTER TABLE %@ ADD PRIMARY KEY (", [entity externalName])];
			numAttributes = [attributes count];
			for (y = 0; y < numAttributes; y++) {
				EOAttribute		*attribute = [attributes objectAtIndex:y];
				
				if (y != 0) [statement appendString:@",\n"];
				[statement appendString:[attribute columnName]];
			}
			
			[statement appendString:EOFormat(@")")];
			
			expression = [[ExpressionClass allocWithZone:zone] init];
			[expression setStatement:statement];
			[statement release];
			[statements addObject:expression];
			[expression release];
		}
	}
	
	return [statements autorelease];
}

- (NSArray *)primaryKeyConstraintStatementsForEntityGroups:(NSArray *)entityGroups
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	int					x;
	int numEntityGroups;
	
	numEntityGroups = [entityGroups count];
	for (x = 0; x < numEntityGroups; x++) {
		[array addObjectsFromArray:[self primaryKeyConstraintStatementsForEntityGroup:[entityGroups objectAtIndex:x]]];
	}
	
	return [array autorelease];
}

- (NSArray *)primaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
	NSArray         *statements;
	EOSQLExpression	*expression;
	
	expression = [[[self expressionClass] allocWithZone:[self zone]] init];
	[expression setStatement:@"CREATE TABLE EO_pk_table (\n    name varchar(128),\n    pk   bigint\n)"];
	statements = [[NSArray allocWithZone:[self zone]] initWithObjects:&expression count:1];
	[expression release];
	
	return [statements autorelease];
}

- (NSArray *)primaryKeySupportStatementsForEntityGroups:(NSArray *)entityGroups
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	int					x;
	int numEntityGroups;
	
	numEntityGroups = [entityGroups count];
	for (x = 0; x < numEntityGroups; x++) {
		[array addObjectsFromArray:[self primaryKeySupportStatementsForEntityGroup:[entityGroups objectAtIndex:x]]];
	}
	
	return [array autorelease];
}

- (NSString *)schemaCreationScriptForEntities:(NSArray *)allEntities options:(NSDictionary *)options
{
	NSMutableString	*script;
	NSArray				*statements;
	int					x;
	int numStatements;
	
	statements = [self schemaCreationStatementsForEntities:allEntities options:options];

	script = [[NSMutableString allocWithZone:[self zone]] init];
	numStatements = [statements count];
	for (x = 0; x < numStatements; x++) {
		[self appendExpression:[statements objectAtIndex:x] toScript:script];
	}
	
	return [script autorelease];
}

- (void)_process:(NSArray *)entities with:(SEL)selector into:(NSMutableArray *)statements
{
	int				x, y;
	int numEntities;
	int numExpressions;
	
	numEntities = [entities count];
	for (x = 0; x < numEntities; x++) {
		EOEntity		*entity = [entities objectAtIndex:x];
		NSArray		*temp = [[NSArray alloc] initWithObjects:&entity count:1];
		NSArray		*subarray;

		subarray = [self performSelector:selector withObject:temp];
		numExpressions = [subarray count];
		for (y = 0; y < numExpressions; y++) {
			EOSQLExpression		*expression = [subarray objectAtIndex:y];

			if (![statements containsObject:expression]) {
				[statements addObject:expression];
			}
		}
		[temp release];
	}
}

- (NSArray *)schemaCreationStatementsForEntities:(NSArray *)entities options:(NSDictionary *)options
{
	NSMutableArray		*statements = [NSMutableArray array];

	// Must be done before table drops, since table drops may make these statements invalid.
	if ([self _check:EODropPrimaryKeySupportKey in:options]) {
		[self _process:entities with:@selector(dropPrimaryKeySupportStatementsForEntityGroup:) into:statements];
	}
	if ([self _check:EODropTablesKey in:options]) {
		[self _process:entities with:@selector(dropTableStatementsForEntityGroup:) into:statements];
	}
	if ([self _check:EOCreateTablesKey in:options]) {
		[self _process:entities with:@selector(createTableStatementsForEntityGroup:) into:statements];
	}
	if ([self _check:EOPrimaryKeyConstraintsKey in:options]) {
		[self _process:entities with:@selector(primaryKeyConstraintStatementsForEntityGroup:) into:statements];
	}
	if ([self _check:EOForeignKeyConstraintsKey in:options]) {
		/*! @todo EOSchemaGeneration: Generate foreign key constraints */
	}
	if ([self _check:EOCreatePrimaryKeySupportKey in:options]) {
		[self _process:entities with:@selector(primaryKeySupportStatementsForEntityGroup:) into:statements];
	}
	
	return statements;
}

- (Class)expressionClass
{
	return [EOSQLExpression class];
}

@end
