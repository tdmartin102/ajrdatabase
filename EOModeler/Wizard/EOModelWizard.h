//
//  EOModelWizard.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EOModel, EOWizardPane;

@interface EOModelWizard : NSObject
{
	IBOutlet NSWindow		*window;
	IBOutlet NSBox			*view;
	IBOutlet NSButton		*finishButton;
	IBOutlet NSButton		*nextButton;
	IBOutlet NSButton		*previousButton;
	IBOutlet NSButton		*cancelButton;
	IBOutlet NSMatrix		*stepMatrix;
	
	EOModel					*model;
		
	NSMutableArray			*steps;
	EOWizardPane			*step;
	int						stepIndex;
	
	BOOL						assignPrimaryKeys:1;
	BOOL						assignRelationships:1;
	BOOL						assignStoredProcedures:1;
	BOOL						assignCustomObjects:1;
}

- (EOModel *)run;

- (void)finish:(id)sender;
- (void)next:(id)sender;
- (void)previous:(id)sender;
- (void)cancel:(id)sender;

- (NSButton *)cancelButton;
- (NSButton *)nextButton;
- (NSButton *)previousButton;
- (NSButton *)finishButton;

- (EOModel *)model;

- (void)setAssignPrimaryKeys:(BOOL)flag;
- (BOOL)assignPrimaryKeys;
- (void)setAssignRelationships:(BOOL)flag;
- (BOOL)assignRelationships;
- (void)setAssignStoredProcedures:(BOOL)flag;
- (BOOL)assignStoredProcedures;
- (void)setAssignCustomObjects:(BOOL)flag;
- (BOOL)assignCustomObjects;


@end
