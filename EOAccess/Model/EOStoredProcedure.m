//
//  EOStoredProcedure.m
//  EOAccess/
//
//  Created by Alex Raftis on 9/17/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOStoredProcedure.h"

#import "EOAttributeP.h"
#import "EOModelP.h"
#import "NSString-EOAccess.h"

NSString *EOStoredProcedureDidChangeNameNotification = @"EOStoredProcedureDidChangeNameNotification";

@implementation EOStoredProcedure

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	[self initWithName:[properties objectForKey:@"name"]];
	
	model = owner; // Not retained, because owner/model retains storedProcedure
		
	return self;
}

- (id)initWithName:(NSString *)aName
{
    [super init];
	name = [aName retain];
	
	arguments = [[NSMutableArray allocWithZone:[self zone]] init];
	
	return self;
}

- (void) dealloc 
{
    [name release];
    [externalName release];
    [arguments release];
    [userInfo release];
    
    [super dealloc];
}

- (void)_initialize
{
	if (!initialized) {
      [self awakeWithPropertyList:[model _propertiesForStoredProcedureNamed:name]];
	}
}

- (void)awakeWithPropertyList:(NSDictionary *)properties
{
	NSArray		*someArguments;
	int			x;
	int numArguments;
	
	initialized = YES;
	
	externalName = [[properties objectForKey:@"externalName"] retain];
	userInfo = [[properties objectForKey:@"userInfo"] mutableCopyWithZone:[self zone]];
	
	someArguments = [properties objectForKey:@"arguments"];
	numArguments = [someArguments count];
	for (x = 0; x < numArguments; x++) {
		EOAttribute		*attribute;
		
		attribute = [[EOAttribute allocWithZone:[self zone]] initWithPropertyList:[someArguments objectAtIndex:x] owner:self];
		[arguments addObject:attribute];
		[EOObserverCenter addObserver:self forObject:attribute];
		[attribute release];
	}
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	NSMutableDictionary		*argument;
	NSMutableArray				*someArguments;
	NSInteger							x;
	NSInteger numArguments;
	
	[self _initialize];
	
	if ([arguments count]) {
		someArguments = [[NSMutableArray allocWithZone:[self zone]] init];
		numArguments = [arguments count];
		for (x = 0; x < numArguments; x++ ){
			argument = [[NSMutableDictionary allocWithZone:[self zone]] init];
			[[arguments objectAtIndex:x] encodeIntoPropertyList:argument];
			[someArguments addObject:argument];
			[argument release];
		}
		[properties setObject:someArguments forKey:@"arguments"];
		[someArguments release];
	}
	
	if (name != nil) [properties setObject:name forKey:@"name"];
	if (externalName != nil) [properties setObject:externalName forKey:@"externalName"];
	if (userInfo != nil) [properties setObject:userInfo forKey:@"userInfo"];
}

- (void)_setModel:(EOModel *)aModel
{
	model = aModel;
}

- (EOModel *)model
{
	return model;
}

- (void)setName:(NSString *)aName
{
	[self _initialize];
	if (name != aName && ![name isEqualToString:aName]) {
		NSString		*oldName = [name retain];
		
		[self willChange];
		if ([model undoManager]) {
			[(EOStoredProcedure *)[[model undoManager] prepareWithInvocationTarget:self] setName:name];
		}
		[name release];
		name = [aName retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOStoredProcedureDidChangeNameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
		[oldName release];
	}
}

- (void)beautifyName
{
	[self _initialize];
	[self setName:[NSString nameForExternalName:name separatorString:@"_" initialCaps:NO]];
    [arguments makeObjectsPerformSelector:@selector(beautifyName)];
}

- (NSString *)name
{
	[self _initialize];
	return name;
}

- (void)setExternalName:(NSString *)anExternalName
{
	[self _initialize];
	if (externalName != anExternalName && ![externalName isEqualToString:anExternalName]) {
		[self willChange];
		if ([model undoManager]) {
			[(EOStoredProcedure *)[[model undoManager] prepareWithInvocationTarget:self] setExternalName:externalName];
		}
		[externalName release];
		externalName = [anExternalName retain];
	}
}

- (NSString *)externalName
{
	[self _initialize];
	return [externalName length] > 0 ? externalName : nil; // According to WO4.5 doc, returns nil when no externalName
}

- (void)setArguments:(NSArray *)someArguments
{
	[self _initialize];
	if (someArguments != arguments) {
		int			x;
		int numArguments;
		
		[self willChange];
		if ([model undoManager]) {
			[(EOStoredProcedure *)[[model undoManager] prepareWithInvocationTarget:self] setArguments:arguments];
		}
		
		numArguments = [arguments count];
		for (x = 0; x < numArguments; x++ ) {
			[EOObserverCenter removeObserver:self forObject:[arguments objectAtIndex:x]];
		}
		
		[arguments release];
		arguments = [someArguments retain];
		
		numArguments = [arguments count];
		for (x = 0; x < numArguments; x++ ) {
			[EOObserverCenter addObserver:self forObject:[arguments objectAtIndex:x]];
		}
	}
}

- (NSArray *)arguments
{
	[self _initialize];
	return [arguments count] > 0 ? arguments : nil; // According to WO4.5 doc, returns nil when no arguments
}

- (void)addArgument:(EOAttribute *)anArgument
{
	NSInteger		index;
	
	[self _initialize];

	index = [arguments indexOfObjectIdenticalTo:anArgument];
	if (index == NSNotFound) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] removeArgument:anArgument];
		}
		[arguments addObject:anArgument];
	}
}

- (void)removeArgument:(EOAttribute *)anArgument
{
	NSInteger	index;
	
	[self _initialize];
	
	index = [arguments indexOfObjectIdenticalTo:anArgument];
	if (index != NSNotFound) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] removeArgument:anArgument];
		}
		[arguments removeObjectAtIndex:index];
	}
}

- (void)moveArgumentAtIndex:(unsigned)index toIndex:(unsigned)otherIndex
{
	if (index != otherIndex) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] moveArgumentAtIndex:otherIndex toIndex:index];
		}
        id    temp = [[arguments objectAtIndex:index] retain];
        
        [arguments removeObjectAtIndex:index];
        
        if (index < otherIndex) {
            [arguments insertObject:temp atIndex:otherIndex];
        } else {
            [arguments insertObject:temp atIndex:otherIndex];
        }
        [temp release];
	}
}

- (void)setUserInfo:(NSDictionary *)someInfo
{
	[self _initialize];
	if (![userInfo isEqualToDictionary:someInfo]) {
		[self willChange];
		if ([model undoManager]) {
			[(EOStoredProcedure *)[[model undoManager] prepareWithInvocationTarget:self] setUserInfo:userInfo];
		}
		[userInfo release];
		userInfo = [someInfo mutableCopyWithZone:[self zone]];
	}
}

- (NSDictionary *)userInfo
{
	[self _initialize];
	return userInfo;
}

- (int)compare:(id)other
{
	if ([other isKindOfClass:[EOStoredProcedure class]]) {
		return [[self name] caseInsensitiveCompare:[other name]];
	}
	return NSOrderedAscending;
}

- (void)objectWillChange:(id)object
{
	[model objectWillChange:object];
}

@end
