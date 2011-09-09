//
//  EOInspectorPanel.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPanel.h"

#import "EOInspector.h"
#import "Document.h"

static EOInspectorPanel		*SELF = nil;

@implementation EOInspectorPanel

+ (id)allocWithZone:(NSZone *)zone
{
	if (SELF == nil) SELF = [super allocWithZone:[self zone]];
	return SELF;
}

- (void)orderFront:(id)sender
{
	if (!nothingView) {
		[NSBundle loadNibNamed:@"EOInspectorPanel" owner:self];
		
		nothingToolbar = [[NSToolbar allocWithZone:[self zone]] initWithIdentifier:@"Inspector - Nothing"];
		[nothingToolbar setDelegate:self];
		[nothingToolbar setAllowsUserCustomization:NO];
		[nothingToolbar setAutosavesConfiguration:YES];
		[nothingToolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
		[self setToolbar:nothingToolbar];
		
		[self setFrameAutosaveName:@"EOInspectorPanel"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentSelectionDidChange:) name:DocumentSelectionDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDidChange:) name:DocumentDidBecomeKeyNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"InspectorOpen"];
		
	[self updateInspector];
	
	[super orderFront:sender];
}

- (void)orderOut:(id)sender
{
	[super orderOut:sender];
	[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"InspectorOpen"];
}

- (void)setContentView:(NSView *)aView
{
	if (aView == nil) aView = nothingView;
	
	if ([self contentView] != aView) {
		[super setContentView:aView];
	}
}

- (void)updateInspector
{
	Document		*document = [Document currentDocument];
	
	if (document == nil) {
		[self setContentView:nothingView];
		[self setToolbar:nothingToolbar];
	} else {
		id				item = [document selectedObject];
		EOInspector	*inspector = [item inspector];
		
		if (inspector) {
			[inspector activateInPanel:self];
		} else {
			if ([[document selectedObject] isKindOfClass:[NSArray class]]) {
				[self setContentView:multipleView];
			} else {
				[self setContentView:nothingView];
			}
			[self setToolbar:nothingToolbar];
		}
	}
}

- (void)documentSelectionDidChange:(NSNotification *)notification
{
	[self updateInspector];
}

- (void)documentDidChange:(NSNotification *)notification
{
	[self updateInspector];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self performSelector:@selector(updateInspector) withObject:nil afterDelay:0.001];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
   return [NSArray arrayWithObject:@""];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
   return [NSArray arrayWithObject:@""];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
   NSToolbarItem        *item;
	
   item = [[NSToolbarItem allocWithZone:[self zone]] initWithItemIdentifier:itemIdentifier];
   [item setLabel:itemIdentifier];
   [item setPaletteLabel:itemIdentifier];
   [item setTarget:nil];
	
	return [item autorelease];
}

- (void)deleteSelection:(id)sender
{
	if ([[self firstResponder] isKindOfClass:[NSTextView class]]) {
		[NSApp sendAction:@selector(delete:) to:nil from:sender];
	} else {
		[[Document currentDocument] deleteSelection:self];
	}
}

@end


@implementation NSObject (EOInspectorPanel)

- (void)showInspector:(id)sender
{
	[[[EOInspectorPanel alloc] initWithContentRect:(NSRect){{50.0, 100.0}, {280.0, 428.0}} styleMask:NSTitledWindowMask | NSClosableWindowMask | NSUtilityWindowMask backing:NSBackingStoreBuffered defer:NO] orderFront:self];
}

@end
