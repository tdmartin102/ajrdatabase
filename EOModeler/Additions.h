//
//  Additions.h
//  EOModeler
//
//  Created by Tom Martin on 1/17/12.
//  Copyright 2012 Riemer Reporting Service, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (EOModler)

- (void)setInstanceObject:(id)anObject forKey:(id)aKey;
- (id)instanceObjectForKey:(id)aKey;

@end

@interface NSTableColumn (EOModler)

- (id)morphDataCellToClass:(Class)aCellClass;
- (id)morphHeaderCellToClass:(Class)aCellClass;

@end

@interface AJRPreferencesModule : NSResponder
{
	IBOutlet	NSView	*view;
}

- (IBAction)showInspector:(id)sender;
@end

extern void AJRPrintf(NSString *format, ...);
