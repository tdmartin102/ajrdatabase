//
//  EODatabaseDataSource.h
//  EOAccess
//
//  Created by Alex Raftis on 6/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOControl.h>

@interface EODatabaseDataSource : EODataSource <NSCoding, EOKeyValueArchiving>
{
	EOEditingContext		*editingContext;
	EOEntity					*entity;
	NSString					*fetchSpecificationName;
	EOFetchSpecification	*fetchSpecification;
	NSDictionary			*qualifierBindings;
	EOQualifier				*auxiliaryQualifier;
	
	BOOL						fetchEnabled:1;
}

// Creating instances
- (id)initWithEditingContext:(EOEditingContext *)anEditingContext entityName:(NSString *)anEntityName;
- (id)initWithEditingContext:(EOEditingContext *)anEditingContext entityName:(NSString *)anEntityName fetchSpecificationName:(NSString *)aFetchSpecification;
	
// Accessing selection criteria
- (EOQualifier *)auxiliaryQualifier;
- (EOFetchSpecification *)fetchSpecification;
- (EOFetchSpecification *)fetchSpecificationForFetch;
- (NSString *)fetchSpecificationName;
- (void)setAuxiliaryQualifier:(EOQualifier *)aQualifier;
- (void)setFetchSpecification:(EOFetchSpecification *)aFetchSpecification;
- (void)setFetchSpecificationByName:(NSString *)aName;

// Accessing objects used for fetching
- (EOEntity *)entity;
- (EODatabaseContext *)databaseContext;

// Enabling fetching
- (void)setFetchEnabled:(BOOL)flag;
- (BOOL)isFetchEnabled;

// Accessing qualifier bindings
- (NSArray *)qualifierBindingKeys;
- (NSDictionary *)qualifierBindings;
- (void)setQualifierBindings:(NSDictionary *)someBindings;

@end
