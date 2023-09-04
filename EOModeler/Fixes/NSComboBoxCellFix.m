//
//  NSComboBoxCellFix.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/28/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSComboBoxCellFix.h"

#import <objc/objc-class.h>

// Some private Apple API
@interface NSComboBoxCell (ApplePrivate)

- (void)initPopUpWindow;

@end


@implementation NSComboBoxCell (EOModler )

+ (void)load
{
	Method		originalMethod;
	Method		ourMethod;

	//[self poseAsClass:[NSComboBoxCell class]];
	
	//originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(setStringValue:));
	//ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrSetStringValue:));
	//method_exchangeImplementations(originalMethod, ourMethod);
	
	originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(drawWithFrame:inView:));
	ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrDrawWithFrame:inView:));
	method_exchangeImplementations(originalMethod, ourMethod);
	
	//originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(drawInteriorWithFrame:inView:));
	//ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrDrawInteriorWithFrame:inView:));
	//method_exchangeImplementations(originalMethod, ourMethod);

	originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(editWithFrame:inView:editor:delegate:event:));
	ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrEditWithFrame:inView:editor:delegate:event:));
	method_exchangeImplementations(originalMethod, ourMethod);
	
	originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(selectWithFrame:inView:editor:delegate:start:length:));
	ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrSelectWithFrame:inView:editor:delegate:start:length:));
	method_exchangeImplementations(originalMethod, ourMethod);

	originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(initWithCoder:));
	ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrInitWithCoder:));
	method_exchangeImplementations(originalMethod, ourMethod);

	//originalMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(initPopUpWindow));
	//ourMethod = class_getInstanceMethod([NSComboBoxCell class], @selector(_ajrInitPopUpWindow));
	//method_exchangeImplementations(originalMethod, ourMethod);
}

- (void)setStringValue:(NSString *)aString
{
	if (aString == nil) aString = @"";
	[super setStringValue:aString];
}

- (float)minWidth
{
	NSDictionary	*attribs = [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName];
	int				x;
	float				min = 0.0;
    
	
	for (x = 0; x < (const int)self.numberOfItems; x++) {
		NSSize		size = [[self itemObjectValueAtIndex:x] sizeWithAttributes:attribs];
		if (min < size.width) min = size.width;
	}
	
	return min + 30.0;
}

- (void)_ajrDrawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
        NSImage *anImage;
        NSRect imageRect;
        
		cellFrame.size.width -= 10.0;
		cellFrame.origin.x += 2.0;
		[[self attributedStringValue] drawInRect:cellFrame];
		cellFrame.origin.x -= 2.0;
		cellFrame.size.width += 10.0;
		//_controlView = controlView;
        self.controlView = controlView;
		//if (_cellFrame) {
		//	float		min = [self minWidth];
		//	*_cellFrame = cellFrame;
		//	if (_cellFrame->size.width < min) {
		//		_cellFrame->size.width = min;
		//	}
		//}
        anImage = [NSImage imageNamed:@"smallPopupArrows"];
        imageRect.origin.x = cellFrame.origin.x + cellFrame.size.width - 5.0;
        imageRect.origin.y = cellFrame.origin.y + cellFrame.size.height - 2.0;
        imageRect.size = [anImage size];
        [anImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	} else {
		[self _ajrDrawWithFrame:cellFrame inView:controlView];
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		cellFrame.size.height += 1.0;
		cellFrame.size.width += 10.0;
		
		[[self attributedStringValue] drawInRect:cellFrame];
	} else {
		[super drawInteriorWithFrame:cellFrame inView:controlView];
	}
}

- (void)_ajrEditWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		aRect.origin.y -= 1.0;
		aRect.size.height += 3.0;
		aRect.size.width += 10.0;
	}
	[self _ajrEditWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)_ajrSelectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		aRect.origin.y -= 1.0;
		aRect.size.height += 3.0;
		aRect.size.width += 10.0;
	}
	[self _ajrSelectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (id)_ajrInitWithCoder:(NSCoder *)coder
{
	[self _ajrInitWithCoder:coder];
	switch ([self controlSize]) {
		case NSRegularControlSize:
			[self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont systemFontSize]]];
			break;
		case NSSmallControlSize:
			[self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont smallSystemFontSize]]];
			break;
		case NSMiniControlSize:
			[self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont smallSystemFontSize] - 2.0]];
			break;
//        case NSControlSizeLarge:
//            [self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont systemFontSize] + 2.0]];
//            break;
	}
	
	return self;
}

//- (void)_ajrInitPopUpWindow
//{
//	[self  _ajrInitPopUpWindow];
//
//	[[[[_tableView tableColumns] objectAtIndex:0] dataCell] setFont:[self font]];
//}

@end
