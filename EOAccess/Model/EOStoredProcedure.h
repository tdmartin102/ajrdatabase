//
//  EOStoredProcedure.h
//  EOAccess/
//
//  Created by Alex Raftis on 9/17/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <EOAccess/EOPropertyListEncoding.h>
#import <EOControl/EOObserver.h>

@class EOAttribute, EOModel;

extern NSString *EOStoredProcedureDidChangeNameNotification;

@interface EOStoredProcedure : NSObject <EOPropertyListEncoding, EOObserving>
{
	EOModel				*model;
	NSString				*name;
	NSString				*externalName;
	NSMutableArray		*arguments;
	NSDictionary		*userInfo;
	
	BOOL					initialized:1;
}

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;

- (void)awakeWithPropertyList:(NSDictionary *)properties;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

// Creating a new EOStoredProcedure
- (id)initWithName:(NSString *)aName;

// Accessing the model
- (EOModel *)model;

// Accessing the name
- (void)setName:(NSString *)aName;
- (void)beautifyName;
- (NSString *)name;
	
// Accessing the external name
- (void)setExternalName:(NSString *)anExternalName;
- (NSString *)externalName;
	
// Accessing the arguments
- (void)setArguments:(NSArray *)someArguments;
- (NSArray *)arguments;
- (void)addArgument:(EOAttribute *)anArgument;
- (void)removeArgument:(EOAttribute *)anArgument;
- (void)moveArgumentAtIndex:(unsigned)index toIndex:(unsigned)otherIndex;

// Accessing the user dictionary
- (void)setUserInfo:(NSDictionary *)userInfo;
- (NSDictionary *)userInfo;

@end
