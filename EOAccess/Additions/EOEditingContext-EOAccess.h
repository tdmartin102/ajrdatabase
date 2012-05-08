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

// Tom.Martin @ Riemer.com 2012-03-20
// NOT part of the API.  This is a hopefully temporary solution but for now this is the only 
// way I can think of sharing this
// information among all the database contexts such that all the relationship changes needed 
// for one object could be accessed.  This is important because if an object is removed from
// one to-many and then added to another the ORDER of the operations is critical.  Also my goal
// was to only have to analyse this ONCE for all objects queued for changes.  This COULD be
// done in the DatabaseContext, but each database context would need to loop through ALL objects
// in the Editing context.  That seemed quite ineffecient to me.  Finally, since your would either
// need to SET or READ attributes in objects potentially in other database contexts and because those
// attributes may very well be hidden, this operation can only happen AFTER all database contexts have
// built the EODatabaseOperations, which means this MUST go into a separate pass.  AGAIN not how EOF
// did things.
//
// This returns a dictionary that points to objects for which the argument was or is a 
// member of a to-many relationship and was either removed, added to that set.
// This is only valid DURING SaveChanges.
// The dictionary structure is:
//   Two arrays.  keys  "removed", "added"
//   each array is an array of dictionaries.  The dictionaries describe the previoius
//   or current owner of the member.  The dictionary has three keys all of which are
//   strings.
//        1) ownerEntityName  : the entity name of the object that contains the to-many
//                              relationship that once contained or now contains the 
//                              member object.
//        2) relationshipName:  The NAME of the relatoinship that the member object is
//                              or was part of.
//        3) ownerGID:          The EOGlobalID for the owner object.
//    The "removed" array represents owning objects that this object was a member of the 
//    to-many relationship but was removed.
//    The "added" array represents owing objects that this object is now a current member
//    but was not a member when the to-many fault was fired.
//
//    The following is an example:
//
// 
//     <dict>
//          <key>removed</key>
//          <array>
//              <dict>
//                  <key>ownerEntityName</key>
//                  <string>INVOICE</string>
//                  <key>relationshipName</key>
//                  <string>billings</string>
//                  <key>ownerGID</key>
//                  <object>@GID</object>
//              </dict>
//          </array>
//          <key>added</key>
//          <array>
//              <dict>
//                  <key>ownerEntityName</key>
//                  <string>INVOICE</string>
//                  <key>relationshipName</key>
//                  <string>billings</string>
//                  <key>ownerGID</key>
//                  <object>@GID</object>
//              </dict>
//          </array>
//     </dict>
- (NSDictionary *)updatedRelationshipsForMember:(EOGlobalID *)memberGID;

#endif

@end
