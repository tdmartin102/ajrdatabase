//
//  NSTableView-ColumnVisibility.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <AJRInterface/AJRInterface.h>

@interface NSTableView (ColumnVisibility)

- (NSArray *)hiddenColumns;
- (void)setColumn:(NSTableColumn *)column visible:(BOOL)flag;
- (BOOL)isColumnVisible:(NSTableColumn *)column;
- (BOOL)isColumnWithIdentifierVisible:(id)identifier;
- (NSTableColumn *)anyTableColumnWithIdentifier:(id)identifier;
- (void)setCanHideColumns:(BOOL)flag;

@end
