//
//  Controller.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Document;

@interface Controller : NSObject

+ (Controller *)defaultCountroller;

- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;

- (void)closeDocument:(Document *)doc;
-(NSArray *)documents;
- (void)addModelsAtPath:(NSString *)path;
@end
