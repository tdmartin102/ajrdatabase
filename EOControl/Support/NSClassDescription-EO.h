
#import <Foundation/Foundation.h>

@class EOEditingContext, EOFetchSpecification, EOGlobalID;

typedef enum _eoDeleteRule {
   EODeleteRuleNullify  = 0,
   EODeleteRuleCascade  = 1,
   EODeleteRuleDeny     = 2,
   EODeleteRuleNoAction = 3
} EODeleteRule;

@interface NSClassDescription (EO)

// Getting EOClassDescriptions
+ (NSClassDescription *)classDescriptionForEntityName:(NSString *)entityName;

//Creating new object instances
- (id)createInstanceWithEditingContext:(EOEditingContext *)anEditingContext globalID:(EOGlobalID *)globalID zone:(NSZone *)zone;

// Returning information from the EOClassDescription
- (NSString *)entityName;

// Propagating delete
- (void)propagateDeleteForObject:(id)object editingContext:(EOEditingContext *)anEditingContext;

// Returning information from the EOClassDescription
- (NSClassDescription *)classDescriptionForDestinationKey:(NSString *)key;
- (BOOL)ownsDestinationObjectsForRelationshipKey:(NSString *)key;
- (EODeleteRule)deleteRuleForRelationshipKey:(NSString *)key;

// Performing validation
- (NSException *)validateObjectForDelete:(id)object;
- (NSException *)validateObjectForSave:(id)object;
- (NSException *)validateValue:(id *)value forKey:(NSString *)key;

// Providing default characteristics for key display
- (NSFormatter *)defaultFormatterForKey:(NSString *)key;
- (NSFormatter *)defaultFormatterForKeyPath:(NSString *)keyPath;
- (NSString *)displayNameForKey:(NSString *)key;
	
// Handling newly inserted and newly fetched objects
- (void)awakeObjectFromFetch:(id)object inEditingContext:(EOEditingContext *)anEditingContext;
- (void)awakeObjectFromInsert:(id)object inEditingContext:(EOEditingContext *)anEditingContext;

// Getting an object's description
- (NSString *)userPresentableDescriptionForObject:(id)object;

// Getting fetch specifications
- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)name;

// Creating snapshots
#if !defined(STRICT_EOF)

// This produces a snapshot suitable for undo.  this is NOT the same as a 
// EODatabase/EODatabaseContext snapshot.
- (NSDictionary *)snapshotForObject:(id)object;

// Tom.Martin @ Riemer.com 2012-03-26
// Add non API method to produce a snapshot that is destined to become a database snapshot.
// The difference between this and what 'snapshot' returns is that the to-many relationship is
// an array of GID's not a shallow copy,  also it does not contain a copy of the to-one objects
// Finally we build the snapshot from the ORIGINAL database snapshot just in case there are values 
// that in the snapshot THAT CAN NOT BE SET.  This is Extremely unlikely, but easy to do, so why not.
// this mehod is called from the database context when it creates its snapshots.
// This is called from enterprise object EOControl contextSnapshotWithDBSnapshot:
- (NSMutableDictionary *)contextSnapshotWithDBSnapshot:(NSDictionary *)dbsnapshot forObject:(id)object;

// Tom.Martin @ Riemer.com 2012-3-27
// This takes a database/databaseContext snapshot which does not contain to-one objects, and
// has the to-many relationships as arrays of GIDs.  It converts the arrays of GIDs to arrays
// of objects (or fault) and SETS the to-one objects or re-faults them.
// this is used by revert when we have the database snapshot and we need to revert our object
// to the last saved image.  unfortunatly the database snapshot is missing some information  
// needed to make that easy.  The undo snapshot works great for this, and it is possible to 
// fill in the blanks from a database snapshot and make it look like an undo snapshot
// This method could potentialy be used elsewhere.
// 
// To recap: the purpose of this method is to CONVERT a database snapshot into an undo
// snapshot.  The resulting snapshot is identical to an undo snapshot that would have been
// been created if it were created the same time as the database snapshot was created.
- (NSDictionary *)snapshotFromDBSnapshot:(NSDictionary *)dbSnapshot forObject:(id)object;

#endif

@end

@interface NSClassDescription (EOPrivate)
// mont_rothstein @ yahoo.com 2005-09-29
// Needed to add this method so that it can be overridden in EOAccess, so that the updateFromSnapshot: method in EOEnterpriseObject can be completed.
// Tom.Martin @ Riemer.com 2012-03-28
// This method is no longer needed becuase the to-many snapshots WILL be in the snapshot.
// However we still needed a special non API method to pull that off. 
// snapshotFromDBSnapshot:forObject: is doing this for us.  This method is potentialy useful
// so I made it public.
//- (void)completeUpdateForObject:(NSObject *)object fromSnapshot:(NSDictionary *)snapshot;

// Tom.Martin @ Riemer.com 2012-03-06
// This method is needed to detect objects in to-many 
- (NSDictionary *)relationshipChangesForObject:(id)object withEditingContext:(EOEditingContext *)anEditingContext;

@end


// For compatibility with EOF API's.
@interface EOClassDescription : NSClassDescription

@end
