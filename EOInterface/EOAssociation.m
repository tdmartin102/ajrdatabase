//
//  EOAssociation.m
//  EOInterface
//
//  Created by Enrique Zamudio Lopez on 25/10/11.
//  Copyright 2011 Enrique Zamudio Lopez. All rights reserved.
//  TODO: Add LGPL notice...
//

#import "EOAssociation.h"


@implementation EOAssociation

+ (NSArray *)aspects
{
    return [NSArray array];
}

+ (NSArray *)aspectSignatures
{
    return [NSArray array];
}

+ (NSArray *)objectKeysTaken
{
    return [NSArray array];
}

+ (BOOL)isUsableWithObject:(id)object
{
    return NO;
}

+ (NSArray *)associationClassesSuperseded
{
    return [NSArray array];
}

+ (NSString *)displayName
{
    return [self className];
}

+ (NSString *)primaryAspect
{
    return nil;
}

+ (NSArray *)associationClassesForObject:(id)displayObject
{
    //I think this needs an internal array where EOAssociation subclasses add themselves.
    return [NSArray array];
}

- (id)initWithObject:(id)aDisplayObject
{
    if ((self = [super init]))
    {
        target = [aDisplayObject retain];
        boundGroups = [[NSMutableDictionary alloc] init];
        boundKeys = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)canBindAspect:(NSString *)aspectName displayGroup:(EODisplayGroup *)group
                  key:(NSString *)key
{
    /*if ([[[self class] aspects] containsObject:aspectName]) {
        //Get the aspect signature
        NSString *sig = [[[self class] aspectSignatures] objectAtIndex:
                         [[[self class] aspects] indexOfObject:aspectName]];
        //Get the class description
        EOClassDescription *cdesc = [[group dataSource] classDescriptionForObjects];
        //Validate the conditions to allow binding to the specified aspect
        return ([sig rangeOfString:@"A"].length > 0 && [[cdesc attributeKeys] indexOfObject:key] >= 0) ||
            ([sig rangeOfString:@"1"].length > 0 && [[cdesc toOneRelationshipKeys] indexOfObject:key] >= 0) ||
            ([sig rangeOfString:@"M"].length > 0 && [[cdesc toManyRelationshipKeys] indexOfObject:key] >= 0) ||
            ([[group localKeys] indexOfObject:key] >= 0);
    }*/
    //Should always return YES as per the spec
    return YES;
}

- (void)bindAspect:(NSString *)aspectName displayGroup:(EODisplayGroup *)group
               key:(NSString *)key
{
    [boundGroups setObject:group forKey:aspectName];
    [boundKeys setObject:key forKey:aspectName];
}

- (void)establishConnection
{
    if (established) return;
    NSMutableArray *done = [NSMutableArray arrayWithCapacity:[boundGroups count]];
    NSEnumerator *ke = [boundGroups keyEnumerator];
    EODisplayGroup *group;
    while ((group = [ke nextObject]) != nil) {
        if (![done containsObject:group]) {
            [EOObserverCenter addObserver:self forObject:group];
            [done addObject:group];
        }
    }
    established=YES;
    [self retain];
}

- (void)breakConnection
{
    if (!established) return;
    NSEnumerator *ke = [boundGroups keyEnumerator];
    EODisplayGroup *group;
    while ((group = [ke nextObject]) != nil) {
        [EOObserverCenter removeObserver:self forObject:group];
    }
    established=NO;
    [self release];
}

- (void)copyMatchingBindingsFromAssociation:(EOAssociation *)other
{
    NSEnumerator *e = [[[self class] aspects] objectEnumerator];
    NSString *aspect;
    while ((aspect = [e nextObject]) != nil) {
        EODisplayGroup *group = [other displayGroupForAspect:aspect];
        if (group) {
            [self bindAspect:aspect displayGroup:group key:[other displayGroupKeyForAspect:aspect]];
        }
    }
}

- (id)object
{
    return target;
}

- (EODisplayGroup *)displayGroupForAspect:(NSString *)aspect
{
    return [boundGroups objectForKey:aspect];
}

- (NSString *)displayGroupKeyForAspect:(NSString *)aspect
{
    return [boundKeys objectForKey:aspect];
}

- (void)subjectChanged
{
}

- (BOOL)endEditing
{
    //as per the spec
    return YES;
}

- (BOOL)setValue:(id)value forAspect:(NSString *)aspect
{
    return [[boundGroups objectForKey:aspect] setSelectedObjectValue:value forKey:
            [boundKeys objectForKey:aspect]];
}

- (BOOL)setValue:(id)value forAspect:(NSString *)aspect atIndex:(NSUInteger)index
{
    return [[boundGroups objectForKey:aspect] setValue:value forObjectAtIndex:(unsigned int)index
            key:[boundKeys objectForKey:aspect]];
}

- (id)valueForAspect:(NSString *)aspect
{
    return [[boundGroups objectForKey:aspect] selectedObjectValueForKey:
            [boundKeys objectForKey:aspect]];
}

- (id)valueForAspect:(NSString *)aspect atIndex:(NSUInteger)index
{
    return [[boundGroups objectForKey:aspect] valueForObjectAtIndex:(unsigned int)index key:
            [boundKeys objectForKey:aspect]];
}

- (BOOL)shouldEndEditingForAspect:(NSString *)aspect invalidInput:(NSString *)inputString
                 errorDescription:(NSString *)description
{
    EODisplayGroup *group = [boundGroups objectForKey:aspect];
    if (group) {
        return [group association:self failedToValidateValue:inputString forKey:
                [boundKeys objectForKey:aspect] object:[group selectedObject]
                errorDescription:description];
    }
    return YES;
}

- (BOOL)shouldEndEditingForAspect:(NSString *)aspect invalidInput:(NSString *)inputString
                 errorDescription:(NSString *)description index:(NSUInteger)index
{
    EODisplayGroup *group = [boundGroups objectForKey:aspect];
    if (group) {
        //TODO could be allObjects or displayedObjects
        return [group association:self failedToValidateValue:inputString forKey:
                [boundKeys objectForKey:aspect] object:[[group allObjects] objectAtIndex:index]
                 errorDescription:description];
    }
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
}

- (EOObserverPriority)priority
{
    //as per the spec
    return EOObserverPriorityThird;
}

- (void)dealloc
{
    [self breakConnection];
    [target release];
    [boundGroups release];
    [boundKeys release];
    [super dealloc];
}

@end
