//
//  SQLGenerator.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/8/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOModel;

@interface SQLGenerator : NSObject
{
	IBOutlet NSWindow			*window;
	IBOutlet NSButton			*dropDatabaseCheck;
	IBOutlet NSButton			*createDatabaseCheck;
	IBOutlet NSButton			*dropTablesCheck;
	IBOutlet NSButton			*createTablesCheck;
	IBOutlet NSButton			*primaryKeyConstraintsCheck;
	IBOutlet NSButton			*foreignKeyConstraintsCheck;
	IBOutlet NSButton			*dropPrimaryKeySupportCheck;
	IBOutlet NSButton			*createPrimaryKeySupportCheck;
	IBOutlet NSTextView         *sqlText;
	IBOutlet NSButton			*saveAsButton;
	IBOutlet NSButton			*executeSQLButton;
	IBOutlet NSTextView         *errorText;
	
	EOModel						*model;
	NSArray						*entities;
	NSMutableDictionary         *options;
	NSArray						*statements;
    NSArray                     *uiElements;
}

- (instancetype)initWithModel:(EOModel *)aModel entities:(NSArray *)someEntities;

- (void)setModel:(EOModel *)aModel entities:(NSArray *)someEntities;
- (void)run;

- (void)toggleOptions:(id)sender;
- (void)saveAs:(id)sender;
- (void)executeSQL:(id)sender;

@end
