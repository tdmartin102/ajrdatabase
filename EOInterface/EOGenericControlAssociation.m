//
//  EOGenericControlAssociation.m
//  EOInterface
//
//  Created by Enrique Zamudio Lopez on 26/10/11.
//  Copyright 2011 Desarrollo de Soluciones Abiertas, S.C.. All rights reserved.
//

#import "EOGenericControlAssociation.h"
#import "EOAssociation.h"

@implementation EOGenericControlAssociation

+ (NSArray *)aspects
{
    return [NSArray arrayWithObjects:@"value", @"enabled", nil];
}

+ (NSArray *)aspectSignatures
{
    return [NSArray arrayWithObjects:@"A", @"A", nil];
}

+ (NSArray *)objectKeysTaken
{
    return [NSArray arrayWithObjects:@"target", @"delegate", nil];
}

+ (BOOL)isUsableWithObject:(id)object
{
    return NO;
}

- (NSControl *)control
{
    return target;
}

- (EOGenericControlAssociation *)editingAssociation
{
    return self;
}

//Puts itself between the control and its target.
- (void)establishConnection
{
    if (established) return;
    controlTarget = [[self control] target];
    controlAction = [[self control] action];
    [[self control] setTarget:self];
    [[self control] setAction:@selector(controlChanged:)];
    if ([[self object] respondsToSelector:@selector(setDelegate:)]) {
        controlDelegate = [[self object] delegate];
        [[self object] setDelegate:self];
    }
    [super establishConnection];
}

- (void)breakConnection
{
    [[self control] setTarget:controlTarget];
    [[self control] setAction:controlAction];
    if ([[self object] respondsToSelector:@selector(setDelegate:)]) {
        [[self object] setDelegate:controlDelegate];
    }
    [super breakConnection];
}

//Copies the value from the control to the selected EO, then performs the original invocation.
- (void)controlChanged:(id)sender
{
    if (sender == [self control]) {
        [self setValue:[sender objectValue] forAspect:@"value"];
        [controlTarget performSelector:controlAction withObject:target];
    }
}

/** NSControl Delegate methods **/
- (void)controlTextDidBeginEditing:(NSNotification *)notif
{
    [[self displayGroupForAspect:@"value"] associationDidBeginEditing:self];
    if ([controlDelegate respondsToSelector:@selector(controlTextDidBeginEditing:)]) {
        [controlDelegate controlTextDidBeginEditing:notif];
    }
}

- (void)controlTextDidChange:(NSNotification *)notif
{
    if ([controlDelegate respondsToSelector:@selector(controlTextDidChange:)]) {
        [controlDelegate controlTextDidChange:notif];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)notif
{
    [[self displayGroupForAspect:@"value"] associationDidEndEditing:self];
    if ([controlDelegate respondsToSelector:@selector(controlTextDidEndEditing:)]) {
        [controlDelegate controlTextDidEndEditing:notif];
    }
}

- (BOOL)control:(NSControl *)sender didFailToFormatString:(NSString *)string errorDescription:(NSString *)desc
{
    //Not sure about this
    BOOL result = NO;
    if ([self shouldEndEditingForAspect:@"value" invalidInput:string errorDescription:desc]) {
        [self endEditing];
    }
    if ([controlDelegate respondsToSelector:@selector(control:didFailToFormatString:errorDescription:)]) {
        result = [controlDelegate control:sender didFailToFormatString:string errorDescription:desc];
    }
    return result;
}

- (void)subjectChanged
{
    [[self control] setObjectValue:[self valueForAspect:@"value"]];
    if ([self displayGroupForAspect:@"enabled"]) {
        [[self control] setEnabled:[self valueForAspect:@"enabled"]];
    }
}

@end
