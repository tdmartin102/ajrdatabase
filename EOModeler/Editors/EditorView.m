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
#import "EditorEntity.h"
#import "EditorEntities.h"
#import "EditorStoredProcedure.h"
#import "EditorStoredProcedures.h"

@implementation EditorView

- (instancetype)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
        editors = [[NSMutableDictionary alloc] init];
    }
	return self;
}

- (void)registerEditor:(Class)EditorClass
{
	Editor		*editor = [(Editor *)[EditorClass alloc] initWithDocument:document];
	
	[editors setObject:editor forKey:[EditorClass name]];
}

- (void)setDocument:(Document *)aDocument
{
	document = aDocument;
    
    // Lets eleiminate AJRBroker and just hard code the editors.  No matter what I do, AJRBroker
    // just is kind of flacky. Sometimes it works just fine, and then it will just crash.
    // Bottom line, it is complex and we REALLY do not need it as these editors are NOT plug ins and
    // they are NOT dynamic.
	// Don't create until now, since we want to make sure our document is connected before we do this.
	//broker = [[AJRObjectBroker alloc] initWithTarget:self action:@selector(registerEditor:)
    //             requestingClassesInheritedFromClass:[Editor class]];
    
    [self registerEditor:[EditorEntity class]];
    [self registerEditor:[EditorEntities class]];
    [self registerEditor:[EditorStoredProcedure class]];
    [self registerEditor:[EditorStoredProcedures class]];
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
		
		currentEditor = editor;
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
	NSEnumerator		*enumerator = [editors objectEnumerator];
	Editor				*editor;
	
	while ((editor = [enumerator nextObject]) != nil) {
		[editor objectDidChange:object];
	}
}

- (Editor *)currentEditor
{
	return currentEditor;
}

@end
