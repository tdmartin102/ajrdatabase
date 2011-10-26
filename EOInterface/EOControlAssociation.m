//
//  EOControlAssociation.m
//  EOInterface
//
//  Created by Enrique Zamudio Lopez on 26/10/11.
//  Copyright 2011 Desarrollo de Soluciones Abiertas, S.C.. All rights reserved.
//

#import "EOControlAssociation.h"

@implementation EOControlAssociation

+ (BOOL)isUsableWithObject:(id)object
{
    return [object isMemberOfClass:[NSControl class]];
}

@end
