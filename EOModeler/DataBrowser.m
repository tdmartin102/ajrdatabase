//
//  DataBrowser.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "DataBrowser.h"

#import <EOAccess/EOAccess.h>


@implementation DataBrowser

- (instancetype)initWithModel:(EOModel *)aModel
{
    NSBundle *bundle;
    NSArray  *anArray;
    
	if ((self =[super init])) {
        model = aModel;
        
        columnAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
            nil];
        
        bundle = [NSBundle bundleForClass:[self class]];
        if (! [bundle loadNibNamed:@"DatabaseQuery" owner:self topLevelObjects:&anArray])
        {
            self = nil;
        }
        else
        {
            uiElements = anArray;
            [window makeKeyAndOrderFront:self];
        }
    }
	return self;
}

- (void)awakeFromNib
{
	[entityTable setDoubleAction:@selector(executeQuery:)];
}

- (void)setMaxRowsToFetch:(id)sender
{
}

- (void)selectEntity:(id)sender
{
	NSArray	*theAttributes	= nil;
	EOFetchSpecification	*aFetchSpec	= nil;
	NSInteger		row;
	
	selectedEntity = nil;
	expression = nil;
	
	row = [entityTable selectedRow];
	if (row >= 0) {
		EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
		
		selectedEntity = [[model entities] objectAtIndex:row];
		
		expression = [[[adaptor expressionClass] alloc] initWithRootEntity:selectedEntity];
		theAttributes = [selectedEntity attributes];
		aFetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:[selectedEntity name] qualifier:nil sortOrderings:nil];
		// william @ swats.org 2005-07-23
		// The method -prepareSelectExpressionWithAttributes: fetchSpecification: has been changed to -prepareSelectExpressionWithAttributes:lock:fetchSpecification:
		[expression prepareSelectExpressionWithAttributes:theAttributes lock:NO fetchSpecification:aFetchSpec];
		[queryText setString:[expression statement]];
	}
}

- (void)selectQuery:(id)sender
{
}

- (void)saveQuery:(id)sender
{
}

- (void)removeQuery:(id)sender
{
}

- (float)widthForColumn:(NSString *)key
{
	int		x;
	float		width = 0.0;
	
	for (x = 0; x < (const int)[rows count]; x++) {
		NSString		*value = [[[rows objectAtIndex:x] objectForKey:key] description];
		float			computed;
		
		computed = [value sizeWithAttributes:columnAttributes].width;
		if (width < computed) width = computed;
	}
	
	if (width > 72.0 * 3.0) width = 72.0 * 3.0;
	
	return width + 3.0;
}

- (void)executeQuery:(id)sender
{
	EOAdaptor			*adaptor;
	EOAdaptorContext	*context;
	EOAdaptorChannel	*channel;
	NSInteger			count = 0, max = [maxFetchField intValue];
	NSDictionary		*row;
	NSString			*error = nil;
	NSDate              *start;
	NSArray				*results = nil;
		
	adaptor = [EOAdaptor adaptorWithModel:model];
	expression = [[[adaptor expressionClass] alloc] initWithStatement:[queryText string]];
	
	if (rows == nil) {
		rows = [[NSMutableArray alloc] init];
	} else {
		[rows removeAllObjects];
	}
	
	context = [adaptor createAdaptorContext];
	channel = [[context channels] lastObject];
	if (!channel) channel = [context createAdaptorChannel];
	
	if (![channel isOpen]) [channel openChannel];
	
	NS_DURING
		start = [[NSDate alloc] init];
		[channel evaluateExpression:expression];
		results = [channel describeResults];
		while ((row = [channel fetchRowWithZone:nil]) != nil) {
			[rows addObject:row];
			count++;
			if (count >= max) break;
		}
	NS_HANDLER
		error = [localException description];
	NS_ENDHANDLER
	
	if (error) {
		[statusField setStringValue:[NSString stringWithFormat:@"Error: %@", error]];
	} else {
		float				seconds;
		int				x;
		
		seconds = [[NSDate date] timeIntervalSinceReferenceDate] - [start timeIntervalSinceReferenceDate];
		[statusField setStringValue:[NSString stringWithFormat:@"%ld row%@ fetched in %.1f second%@", (long)count, count == 1 ? @"" : @"s", seconds, seconds == 1 ? @"" : @"s"]];
		
		while ([[dataTable tableColumns] count]) {
			[dataTable removeTableColumn:[[dataTable tableColumns] lastObject]];
		}
		
		for (x = 0; x < (const int)[results count]; x++) {
			EOAttribute		*attribute = [results objectAtIndex:x];
			NSTableColumn	*column;
			
			column = [[NSTableColumn alloc] initWithIdentifier:[attribute name]];
			[[column headerCell] setStringValue:[attribute name]];
			[[column headerCell] setAlignment:NSCenterTextAlignment];
			[[column dataCell] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
			[[column dataCell] setDrawsBackground:NO];
			[column setWidth:[self widthForColumn:[attribute name]]];
			[column setEditable:NO];
			[dataTable addTableColumn:column];
		}

		[dataTable reloadData];
	}
}

- (void)exportQuery:(id)sender
{
}

- (void)nextQuery:(id)sender
{
}

- (void)previousQuery:(id)sender
{
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == entityTable) {
		return [[model entities] count];
	} else if (tableView == dataTable) {
		return [rows count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if (tableView == entityTable) {
		return [[[model entities] objectAtIndex:row] name];
	} else if (tableView == dataTable) {
		return [[rows objectAtIndex:row] objectForKey:[column identifier]];
	}
	
	return nil;
}

@end
