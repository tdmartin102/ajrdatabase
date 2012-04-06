
#import "EOEnterpriseObject.h"

@interface NSObject (EOEnterpriseObject)

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

// Tom.Martin @ Riemer.com 2012-03-26
// Add non API method to produce a snapshot that is destined to become a database snapshot.
// The difference between this and what 'snapshot' returns is that the to-many relationship is
// an array of GID's not a shallow copy,  also it does not contain a copy of the to-one objects
// Finally we build the snapshot from the ORIGINAL database snapshot just in case there are values 
// that in the snapshot THAT CAN NOT BE SET.  This is Extremely unlikely, but easy to do, so why not.
// this mehod is called from the database context when it creates its snapshots.
// This is called from enterprise object EOControl contextSnapshotWithDBSnapshot:
- (NSMutableDictionary *)contextSnapshotWithDBSnapshot:(NSDictionary *)dbsnapshot;

// Merging values
- (NSDictionary *)changesFromSnapshot:(NSDictionary *)snapshot;
- (void)reapplyChangesFromDictionary:(NSDictionary *)changes;

// Getting descriptions
- (NSString *)eoDescription;
- (NSString *)eoShallowDescription;
- (NSString *)userPresentableDescription;

// mont_rothstein @ yahoo.com 2005-01-14
// Added support for the EO's to keep a pointer to their editing context rather
// than having AJRUserInfo do it.
// Private
- (void)_clearInstanceObjects;

// tom.martin @ riemer.com 2011-11-16
// it turns out that the purpose of takeStoredValue is basically to 
// avoid calling the accessor method so that willChange will NOT be called
// I have implemented setPrimitiveValue:forKey here to replace takeStoredValue:forKey:
- (void)setPrimitiveValue:(id)value forKey:(NSString *)key;

@end
