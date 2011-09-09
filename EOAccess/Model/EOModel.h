/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import <Foundation/Foundation.h>
#import <EOControl/EOObserver.h>

@class EOAdaptor, EODatabase, EOModelGroup, EOEntity, EOStoredProcedure;

extern NSString *EOModelDidChangeNameNotification;
extern NSString *EOModelDidChangePathNotification;
extern NSString *EOModelDidAddEntityNotification;
extern NSString *EOModelDidRemoveEntityNotification;
extern NSString *EOEntityLoadedNotification;

@interface EOModel : NSObject <EOObserving>
{
    NSURL        			*path;
    NSString				*name;
	 NSDictionary			*userInfo;

    // Internal paths
    NSURL					*indexPath;
    NSMutableDictionary	*index;
    NSMutableDictionary	*connectionProperties;

    // Various
    EOAdaptor				*adaptor;
    NSMutableDictionary	*entityCache;
    NSMutableDictionary	*entityCacheByClass;
	 NSMutableArray		*storedProcedures;
	 NSMutableDictionary	*storedProcedureCache;

    // We need / want a back pointer to our parent
    EOModelGroup  		*modelGroup;

    // Database encoding...
    NSStringEncoding		databaseEncoding;
	 
	 // Something for editing...
	 NSUndoManager			*undoManager;
	 
	 BOOL						recursionCheck:1;
}

// Initializing an EOModel instance
- (id)initWithContentsOfFile:(NSString *)aPath;
- (id)initWithContentsOfURL:(NSURL *)aURL;
- (id)initWithTableOfContentsPropertyList:(NSDictionary *)tableOfContents path:(NSString *)path;

+ (EOModel *)modelWithPath:(NSString *)aPath;
+ (EOModel *)modelWithURL:(NSURL *)url;

// Saving a model
- (void)encodeTableOfContentsIntoPropertyList:(NSMutableDictionary *)propertyList;
- (void)writeToFile:(NSString *)path;

// Loading a model's objects
- (void)loadAllModelObjects;

// Working with entities
- (void)addEntity:(EOEntity *)entity;
- (void)removeEntity:(EOEntity *)entity;
- (void)removeEntityAndReferences:(EOEntity *)entity;
- (NSArray *)entityNames;
- (EOEntity *)entityNamed:(NSString *)name;
- (NSArray *)entities;

// Naming a model's components
- (void)beautifyNames;

// Accessing the model's name
- (NSString *)path;
- (void)setName:(NSString *)aName;
- (NSString *)name;

// Checking references
- (NSArray *)referencesToProperty:(id)property;
- (NSArray *)externalModelsReferenced;
	
// Getting an object's entity
- (EOEntity *)entityForObject:(id)object;

// Accessing the adaptor bundle
- (void)setAdaptorName:(NSString *)aName;
- (NSString *)adaptorName;

// Accessing the connection dictionary
- (NSDictionary *)connectionDictionary;
- (void)setConnectionDictionary:(NSDictionary *)aDictionary;

// Accessing the user dictionary
- (void)setUserInfo:(NSDictionary *)userInfo;
- (NSDictionary *)userInfo;

// Accessing the model's group
- (void)setModelGroup:(EOModelGroup *)aModelGroup;
- (EOModelGroup *)modelGroup;

//	Working with stored procedures
- (void)addStoredProcedure:(EOStoredProcedure *)procedure;
- (void)removeStoredProcedure:(EOStoredProcedure *)procedure;
- (NSArray *)storedProcedureNames;
- (EOStoredProcedure *)storedProcedureNamed:(NSString *)name;
- (NSArray *)storedProcedures;

// Working with the database encoding
- (void)setDatabaseEncoding:(NSStringEncoding)anEncoding;
- (NSStringEncoding)databaseEncoding;

// Undo management
- (void)setUndoManager:(NSUndoManager *)anUndoManager;
- (NSUndoManager *)undoManager;

@end
