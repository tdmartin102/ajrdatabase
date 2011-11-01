//
//  EOGenericControlAssociation.h
//  EOInterface
//
//  Created by Enrique Zamudio Lopez on 26/10/11.
//  Copyright 2011 Desarrollo de Soluciones Abiertas, S.C.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EOInterface/EOAssociation.h>

@interface EOGenericControlAssociation : EOAssociation {

    id controlTarget;
    SEL controlAction;
    id controlDelegate;
}

- (NSControl *)control;

@end
