
#import <Foundation/Foundation.h>

#import "NSClassDescription-EO.h"

@class EOEditingContext, EOGlobalID;

@protocol EOEnterpriseObject

// Initializing enterprise objects
- (id)initWithEditingContext:(EOEditingContext *)editingContext classDescription:(NSClassDescription *)classDescription globalID:(EOGlobalID *)globalID;
- (void)awakeFromFetchInEditingContext:(EOEditingContext *)editingContext;
- (void)awakeFromInsertionInEditingContext:(EOEditingContext *)editingContext;

// Announcing changes
- (void)willChange;

// Getting an object's EOEditingContext
- (EOEditingContext *)editingContext;

// Getting class description information
- (NSArray *)allPropertyKeys;
- (NSClassDescription *)classDescriptionForDestinationKey:(NSString *)key;
- (EODeleteRule)deleteRuleForRelationshipKey:(NSString *)key;
- (NSString *)entityName;
- (BOOL)isToManyKey:(NSString *)key;
- (BOOL)ownsDestinationObjectsForRelationshipKey:(NSString *)key;

/***********
 * Defined in NSClassDescriptionPrimitives
 * - (NSClassDescription *)classDescription;
 * - (NSString *)inverseForRelationshipKey:(NSString *)key;
 * - (NSArray *)toManyRelationshipKeys;
 * - (NSArray *)toOneRelationshipKeys;
 * - (NSArray *)attributeKeys;
 ************/

// Modifying relationships
/*! @todo EOEnterpriseObject: propagateDeleteWithEditingContext: */
- (void)propagateDeleteWithEditingContext:(EOEditingContext *)editingContext;
- (void)clearProperties;

// Working with snapshots
- (NSDictionary *)snapshot;
- (void)updateFromSnapshot:(NSDictionary *)snapshot;

// Merging values
- (NSDictionary *)changesFromSnapshot:(NSDictionary *)snapshot;
- (void)reapplyChangesFromDictionary:(NSDictionary *)changes;

// Getting descriptions
- (NSString *)eoDescription;
- (NSString *)eoShallowDescription;
- (NSString *)userPresentableDescription;

@end
