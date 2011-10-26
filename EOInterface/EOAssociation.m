//
//  EOAssociation.m
//  EOInterface
//
//  Created by Enrique Zamudio Lopez on 25/10/11.
//  Copyright 2011 Enrique Zamudio Lopez. All rights reserved.
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
    return @"???";
}

+ (NSString *)primaryAspect
{
    return @"???";
}

+ (NSArray *)associationClassesForObject:(id)displayObject
{
    return [NSArray array];
}

- (id)initWithObject:(id)aDisplayObject
{
    return self;
}

- (BOOL)canBindAspect:(NSString *)aspectName displayGroup:(EODisplayGroup *)group
                  key:(NSString *)key
{
    return NO;
}

- (void)bindAspect:(NSString *)aspectName displayGroup:(EODisplayGroup *)group
               key:(NSString *)key
{
}

- (void)establishConnection
{
}

- (void)breakConnection
{
}

- (void)copyMatchingBindingsFromAssociation:(EOAssociation *)association
{
}

- (id)object
{
    return nil;
}

- (EODisplayGroup *)displayGroupForAspect:(NSString *)aspect
{
    return nil;
}

- (NSString *)displayGroupKeyForAspect:(NSString *)aspect
{
    return @"???";
}

- (void)subjectChanged
{
}

- (BOOL)endEditing
{
    return YES;
}

- (BOOL)setValue:(id)value forAspect:(NSString *)aspect
{
    return YES;
}

- (BOOL)setValue:(id)value forAspect:(NSString *)aspect atIndex:(NSUInteger)index
{
    return YES;
}

- (id)valueForAspect:(NSString *)aspect
{
    return nil;
}

- (id)valueForAspect:(NSString *)aspect atIndex:(NSUInteger)index
{
    return nil;
}

- (BOOL)shouldEndEditingForAspect:(NSString *)aspect invalidInput:(NSString *)inputString
                 errorDescription:(NSString *)description
{
    return YES;
}

- (BOOL)shouldEndEditingForAspect:(NSString *)aspect invalidInput:(NSString *)inputString
                 errorDescription:(NSString *)description index:(NSUInteger)index
{
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
}

@end
