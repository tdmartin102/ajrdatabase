//
//  EditorView.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EditorView.h"

#import "Document.h"
#import "Editor.h"
#import "Additions.h"

@implementation EditorView

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	
	editors = [[NSMutableDictionary allocWithZone:[self zone]] init];
	
	return self;
}

- (void)dealloc
{
	[broker release];
	[editors release];
	[currentEditor release];
	
	[super dealloc];
}

- (void)registerEditor:(Class)EditorClass
{
	Editor		*editor = [(Editor *)[EditorClass allocWithZone:[self zone]] initWithDocument:document];
	
	[editors setObject:editor forKey:[EditorClass name]];
}

- (void)setDocument:(Document *)aDocument
{
	document = aDocument;
	// Don't create until now, since we want to make sure our document is connected before we do this.
	broker = [[AJRObjectBroker allocWithZone:[self zone]] initWithTarget:self action:@selector(registerEditor:) requestingClassesInheritedFromClass:[Editor class]];
}

- (void)displayEditorNamed:(NSString *)name
{
	Editor		*editor = [editors objectForKey:name];
	
	if (editor != currentEditor) {
		NSView		*current = [[self subviews] lastObject];
		NSView		*new = [editor view];
		
		if (current != new) {
			[current removeFromSuperview];
			[new setFrame:[self bounds]];
			[self addSubview:new];
		}
		
		[currentEditor release];
		currentEditor = [editor retain];
		[currentEditor update];
	}
}

- (void)update
{
	[currentEditor update];
}

- (void)deleteSelection:(id)sender
{
	[currentEditor deleteSelection:sender];
}

- (void)objectWillChange:(id)object
{
	[currentEditor objectWillChange:object];
}

- (void)objectDidChange:(id)object
{
	[currentEditor objectDidChange:object];
//	NSEnumerator		*enumerator = [editors objectEnumerator];
//	Editor				*editor;
//	
//	while ((editor = [enumerator nextObject]) != nil) {
//		[editor objectDidChange:object];
//	}
}

- (Editor *)currentEditor
{
	return currentEditor;
}

@end
