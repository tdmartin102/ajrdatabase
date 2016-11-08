//
//  DataBrowser.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOModel, EOEntity, EOSQLExpression;

@interface DataBrowser : NSObject
{
	IBOutlet NSWindow		*window;
	IBOutlet NSTextField	*statusField;
	IBOutlet NSTableView	*entityTable;
	IBOutlet NSTableView	*dataTable;
	IBOutlet NSTextField	*maxFetchField;
	IBOutlet NSTableView	*queryTable;
	IBOutlet NSTextView	*queryText;
	IBOutlet NSButton		*executeQueryButton;
	IBOutlet NSButton		*exportQueryButton;
	IBOutlet NSButton		*saveQueryButton;
	IBOutlet NSButton		*removeQueryButton;
	IBOutlet NSButton		*nextQueryButton;
	IBOutlet NSButton		*previousQueryButton;
	
	EOModel					*model;
	EOEntity					*selectedEntity;
	EOSQLExpression		*expression;
	NSMutableArray			*rows;
	NSDictionary			*columnAttributes;
    NSArray                 *uiElements;
}

- (instancetype)initWithModel:(EOModel *)aModel;

- (void)setMaxRowsToFetch:(id)sender;
- (void)selectEntity:(id)sender;
- (void)selectQuery:(id)sender;
- (void)saveQuery:(id)sender;
- (void)removeQuery:(id)sender;
- (void)executeQuery:(id)sender;
- (void)exportQuery:(id)sender;
- (void)nextQuery:(id)sender;
- (void)previousQuery:(id)sender;

@end
