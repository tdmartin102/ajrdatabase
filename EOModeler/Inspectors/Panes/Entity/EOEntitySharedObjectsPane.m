//
//  EOEntitySharedObjectsPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOEntitySharedObjectsPane.h"

@implementation EOEntitySharedObjectsPane

- (NSString *)name
{
	return @"Shared Objects";
}

- (void)selectSharedMethod:(id)sender
{
}

- (void)selectFetchSpecification:(id)sender
{
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return @"?";
}

@end
