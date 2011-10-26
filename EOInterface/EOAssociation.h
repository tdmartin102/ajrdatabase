//
//  EOAssociation.h
//  EOInterface
//
//  Created by Enrique Zamudio Lopez on 25/10/11.
//  Copyright 2011 Enrique Zamudio Lopez. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EOControl/EOControl.h>
#import <EOInterface/EODisplayGroup.h>

@interface EOAssociation : EODelayedObserver <NSCoding>
{

}

+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;
+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject:(id)object;
+ (NSArray *)associationClassesSuperseded;
+ (NSString *)displayName;
+ (NSString *)primaryAspect;
+ (NSArray *)associationClassesForObject:(id)displayObject;

- (id)initWithObject:(id)aDisplayObject;
- (BOOL)canBindAspect:(NSString *)aspectName displayGroup:(EODisplayGroup *)group
    key:(NSString *)key;
- (void)bindAspect:(NSString *)aspectName displayGroup:(EODisplayGroup *)group
    key:(NSString *)key;
- (void)establishConnection;
- (void)breakConnection;
- (void)copyMatchingBindingsFromAssociation:(EOAssociation *)association;

- (id)object;

- (EODisplayGroup *)displayGroupForAspect:(NSString *)aspect;
- (NSString *)displayGroupKeyForAspect:(NSString *)aspect;

- (void)subjectChanged;
- (BOOL)endEditing;

- (BOOL)setValue:(id)value forAspect:(NSString *)aspect;
- (BOOL)setValue:(id)value forAspect:(NSString *)aspect atIndex:(NSUInteger)index;
- (id)valueForAspect:(NSString *)aspect;
- (id)valueForAspect:(NSString *)aspect atIndex:(NSUInteger)index;

- (BOOL)shouldEndEditingForAspect:(NSString *)aspect invalidInput:(NSString *)inputString
    errorDescription:(NSString *)description;
- (BOOL)shouldEndEditingForAspect:(NSString *)aspect invalidInput:(NSString *)inputString
    errorDescription:(NSString *)description index:(NSUInteger)index;

@end
