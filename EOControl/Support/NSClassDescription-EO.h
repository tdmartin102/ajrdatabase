
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
- (NSDictionary *)snapshotForObject:(id)object;
#endif

@end

@interface NSClassDescription (EOPrivate)
// mont_rothstein @ yahoo.com 2005-09-29
// Needed to add this method so that it can be overridden in EOAccess, so that the updateFromSnapshot: method in EOEnterpriseObject can be completed.
- (void)completeUpdateForObject:(NSObject *)object fromSnapshot:(NSDictionary *)snapshot;

// Tom.Martin @ Riemer.com 2012-03-06
// This method is needed to detect objects in to-many 
- (NSDictionary *)relationshipChangesForObject:(id)object withEditingContext:(EOEditingContext *)anEditingContext;

@end


// For compatibility with EOF API's.
@interface EOClassDescription : NSClassDescription

@end
