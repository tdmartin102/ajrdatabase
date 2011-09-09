
#import <Cocoa/Cocoa.h>

extern NSString *EOCreateDatabaseKey;
extern NSString *EOCreatePrimaryKeySupportKey;
extern NSString *EOCreateTablesKey;
extern NSString *EODropDatabaseKey;
extern NSString *EODropPrimaryKeySupportKey;
extern NSString *EODropTablesKey;
extern NSString *EOForeignKeyConstraintsKey;
extern NSString *EOPrimaryKeyConstraintsKey;

@class EORelationship, EOSQLExpression;

@interface EOSchemaGeneration : NSObject
{
}

- (void)appendExpression:(EOSQLExpression *)expression toScript:(NSMutableString *)script;
- (NSArray *)createDatabaseStatementsForConnectionDictionary:(NSDictionary *)connectionDictionary administrativeConnectionDictionary:(NSDictionary *)administrativeConnectionDictionary;
- (NSArray *)createTableStatementsForEntityGroup:(NSArray *)entityGroup;
- (NSArray *)createTableStatementsForEntityGroups:(NSArray *)entityGroups; 
- (NSArray *)dropDatabaseStatementsForConnectionDictionary:(NSDictionary *)connectionDictionary administrativeConnectionDictionary:(NSDictionary *)administrativeConnectionDictionary;
- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup;
- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroups:(NSArray *)entityGroups;
- (NSArray *)dropTableStatementsForEntityGroup:(NSArray *)entityGroup;
- (NSArray *)dropTableStatementsForEntityGroups:(NSArray *)entityGroups;
- (NSArray *)foreignKeyConstraintStatementsForRelationship:(EORelationship *)relationship;
- (NSArray *)primaryKeyConstraintStatementsForEntityGroup:(NSArray *)entityGroup;
- (NSArray *)primaryKeyConstraintStatementsForEntityGroups:(NSArray *)entityGroups;
- (NSArray *)primaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup;
- (NSArray *)primaryKeySupportStatementsForEntityGroups:(NSArray *)entityGroups;
- (NSString *)schemaCreationScriptForEntities:(NSArray *)allEntities options:(NSDictionary *)options;
- (NSArray *)schemaCreationStatementsForEntities:(NSArray *)allEntities options:(NSDictionary *)options;

// EO Extensions
- (Class)expressionClass;

@end
