//
//  SQLGenerator.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/8/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "SQLGenerator.h"

#import <EOAccess/EOAccess.h>

@implementation SQLGenerator

- (instancetype)initWithModel:(EOModel *)aModel entities:(NSArray *)someEntities
{
    if ((self = [super init])) {
        entities = [someEntities copy];
        model = aModel;
        options = [[NSMutableDictionary alloc] init];
    }
	return self;
}

- (void)setModel:(EOModel *)aModel entities:(NSArray *)someEntities
{
    entities = [someEntities copy];
    model = aModel;
    options = [[NSMutableDictionary alloc] init];
}

- (void)windowWillClose:(NSNotification *)notification
{
	// [window setDelegate:nil];
	// we realy can't release self here, this might be a leak then
    //[self release];
}

- (void)updateScript
{
	EOAdaptor				*adaptor = [EOAdaptor adaptorWithModel:model];
	EOSchemaGeneration	*generator = [adaptor synchronizationFactory];
	
	statements = [generator schemaCreationStatementsForEntities:entities options:options];
	
	[sqlText setFont:[NSFont userFixedPitchFontOfSize:10.0]];
	[sqlText setString:[[[statements valueForKey:@"statement"] componentsJoinedByString:@";\n"] stringByAppendingString:@";\n"]];
}

- (void)toggleOptions:(id)sender
{
	[options setObject:[dropDatabaseCheck state] ? @"YES" : @"NO" forKey:EODropDatabaseKey];
	[options setObject:[createDatabaseCheck state] ? @"YES" : @"NO" forKey:EOCreateDatabaseKey];
	[options setObject:[dropTablesCheck state] ? @"YES" : @"NO" forKey:EODropTablesKey];
	[options setObject:[createTablesCheck state] ? @"YES" : @"NO" forKey:EOCreateTablesKey];
	[options setObject:[primaryKeyConstraintsCheck state] ? @"YES" : @"NO" forKey:EOPrimaryKeyConstraintsKey];
	[options setObject:[foreignKeyConstraintsCheck state] ? @"YES" : @"NO" forKey:EOForeignKeyConstraintsKey];
	[options setObject:[dropPrimaryKeySupportCheck state] ? @"YES" : @"NO" forKey:EODropPrimaryKeySupportKey];
	[options setObject:[createPrimaryKeySupportCheck state] ? @"YES" : @"NO" forKey:EOCreatePrimaryKeySupportKey];
	
	[self updateScript];
}

- (void)saveAs:(id)sender
{
}

- (void)executeSQL:(id)sender
{
	NSMutableArray		*errors = [[NSMutableArray alloc] init];
	EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
	EOAdaptorContext	*context = [adaptor createAdaptorContext];
	EOAdaptorChannel	*channel = [context createAdaptorChannel];
	
	NS_DURING
		if (![channel isOpen]) [channel openChannel];
	NS_HANDLER
		[errors addObject:localException];
	NS_ENDHANDLER
	
	if ([errors count] == 0) {
		int			x;
		
		for (x = 0; x < (const int)[statements count]; x++) {
			NS_DURING
				[channel evaluateExpression:[statements objectAtIndex:x]];
			NS_HANDLER
				[errors addObject:localException];
			NS_ENDHANDLER
		}
	}
	
	if ([errors count] == 0) {
		[errorText setString:@"No errors occurred during SQL execution."];
	} else {
		NSScrollView		*sv = [errorText enclosingScrollView];
		NSBeep();
		[errorText setString:[NSString stringWithFormat:@"The following errors occurred during SQL execution:\n\n%@\n", [errors componentsJoinedByString:@"\n"]]];
		if ([sv frame].size.height == 0.0) {
			NSRect		frame = [sv frame];
			frame.size.height = 50.0;
			[sv setFrame:frame];
			[[sv superview] setNeedsDisplay:YES];
		}
	}
}

- (void)run
{
	if (window == nil) {
        NSBundle *bundle;
        NSArray  *anArray;
        
        bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:@"SQLGenerator" owner:self topLevelObjects:&anArray];
        uiElements = anArray;

		[self toggleOptions:self];
	}
	
	[window center];
	[window makeKeyAndOrderFront:self];
}

@end
