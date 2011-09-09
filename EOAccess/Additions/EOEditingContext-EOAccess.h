//
//  EOEditingContext-EOAccess.h
//  EOAccess
//
//  Created by Alex Raftis on 11/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOControl.h>
#import "EOStoredProcedure.h"

@class EOModelGroup;

@interface EOEditingContext (EOAccess)

// Creating new objects
- (id)createAndInsertInstanceOfEntityNamed:(NSString *)entityName;

// Fetching multiple objects
- (NSArray *)objectsForEntityNamed:(NSString *)entityName;
- (NSArray *)objectsForEntityNamed:(NSString *)entityName qualifierFormat:(NSString *)format, ...;
- (NSArray *)objectsMatchingValue:(id)value forKey:(NSString *)key entityNamed:(NSString *)entityName;
- (NSArray *)objectsMatchingValues:(NSDictionary *)dictionary entityNamed:(NSString *)entityName;
- (NSArray *)objectsOfClass:(Class)aClass;
- (NSArray *)objectsWithFetchSpecificationNamed:(NSString *)fetchName entityNamed:(NSString *)entityName bindings:(NSDictionary *)bindings;

// Fetching single objects
- (id)objectForEntityNamed:(NSString *)entityName qualifierFormat:(NSString *)formta, ...;
- (id)objectMatchingValue:(id)value forKey:(NSString *)key entityNamed:(NSString *)entityName;
- (id)objectMatchingValues:(NSDictionary *)values entityNamed:(NSString *)entityName;
- (id)objectWithFetchSpecificationNamed:(NSString *)fetchName entityNamed:(NSString *)entityName bindings:(NSDictionary *)bindings;
- (id)objectWithPrimaryKey:(NSDictionary *)primaryKey entityNamed:(NSString *)entityName;
- (id)objectWithPrimaryKeyValue:(id)value entityNamed:(NSString *)entityName;

// Fetching raw rows
- (NSDictionary *)executeStoredProcedureNamed:(NSString *)storedProcedureName arguments:(NSDictionary *)arguments;
- (id)objectFromRawRow:(NSDictionary *)row entityNamed:(NSString *)entityName;
- (NSArray *)rawRowsForEntityNamed:(NSString *)entityName qualifierFormat:(NSString *)format, ...;
- (NSArray *)rawRowsMatchingValue:(id)value forKey:(NSString *)key entityNamed:(NSString *)entityName;
- (NSArray *)rawRowsMatchingValues:(NSDictionary *)values entityNamed:(NSString *)entityName;
- (NSArray *)rawRowsWithSQL:(NSString *)sqlString modelNamed:(NSString *)modelName;
- (NSArray *)rawRowsWithStoredProcedureNamed:(NSString *)storedProcedureName arguments:(NSDictionary *)arguments;
- (NSDictionary *)returnValuesForLastStoredProcedureInvocationForEntityNamed:(NSString *)entityName;

// Accessing the EOF stack
- (void)connectWithModelNamed:(NSString *)modelName connectionDictionaryOverrides:(NSDictionary *)overrides;
- (EODatabaseContext *)databaseContextForModelNamed:(NSString *)modelName;

// Accessing object data
- (NSDictionary *)destinationKeyForSourceObject:(id)object relationshipNamed:(NSString *)relationshipName;
- (id)localInstanceOfObject:(id)object;
- (NSArray *)localInstancesOfObjects:(NSArray *)objects;
- (NSDictionary *)primaryKeyForObject:(id)object;

// Accessing model information
- (EOEntity *)entityForClass:(Class)classObject;
- (EOEntity *)entityForObject:(id)object;
- (EOEntity *)entityNamed:(NSString *)entityName;
- (EOModelGroup *)modelGroup;

#if !defined(STRICT_EOF)
- (int)countOfObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)maxValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)minValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)sumOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)averageOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (void)executeStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values forEntityNamed:(NSString *)entityName;
#endif

@end
