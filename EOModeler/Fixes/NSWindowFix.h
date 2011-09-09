//
//  NSWindowFix.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindowFix : NSWindow

@end


@interface NSObject (NSWindowFix)

- (BOOL)processKeyDown:(NSEvent *)event;

@end
