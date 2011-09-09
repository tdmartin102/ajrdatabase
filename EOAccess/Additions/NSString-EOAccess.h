//
//  NSString-EOAccess.h
//  EOAccess/
//
//  Created by Alex Raftis on 10/6/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (EOAccess)

+ (NSString *)externalNameForInternalName:(NSString *)name separatorString:(NSString *)separatorString useAllCaps:(BOOL)useAllCaps;
+ (NSString *)nameForExternalName:(NSString *)name separatorString:(NSString *)separatorString initialCaps:(BOOL)initialCaps;

@end
