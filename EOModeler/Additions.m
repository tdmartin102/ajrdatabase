//
//  Additions.m
//  EOModeler
//
//  Created by Tom Martin on 1/17/12.
//  Copyright 2012 Riemer Reporting Service, Inc. All rights reserved.
//

#import "Additions.h"

#import <objc/runtime.h>

static char myAddedValues;

@implementation NSObject (EOModler)

- (void)setInstanceObject:(id)anObject forKey:(id)aKey
{
	// get the dictiony
	NSMutableDictionary	*aDict;
	
	aDict = objc_getAssociatedObject(self, &myAddedValues);
	// if there was none then create a new one
	if (! aDict)
	{
		aDict = [[NSMutableDictionary alloc] initWithCapacity:10];
		// and associate that dictionary with our object
		objc_setAssociatedObject(self, &myAddedValues, aDict, OBJC_ASSOCIATION_RETAIN);
		[aDict release];
	}
	
	// now set the value
	[aDict setObject:anObject forKey:aKey];
}

- (id)instanceObjectForKey:(id)aKey
{
	NSDictionary	*aDict;
	id	result;
	result = nil;
	aDict = objc_getAssociatedObject(self, &myAddedValues);
	if (aDict)
		result = [aDict objectForKey:aKey];
	return result;
}

@end


@implementation NSTableColumn (EOModler)

- (id)morphDataCellToClass:(Class)aCellClass
{
	NSCell *newCell;
	NSCell *oldCell;
	
	oldCell = [self dataCell];
	newCell = [[aCellClass alloc] init];
	[newCell setTarget:[oldCell target]];
	[newCell setTag:[oldCell tag]];
	[newCell setState:[oldCell state]];
	[newCell setShowsFirstResponder:[oldCell showsFirstResponder]];
	[newCell setAction:[oldCell action]];
	[newCell setSendsActionOnEndEditing:[oldCell sendsActionOnEndEditing]];
	[newCell setSelectable:[oldCell isSelectable]];
	[newCell setScrollable:[oldCell isScrollable]];
	[newCell setRepresentedObject:[oldCell representedObject]];
	[newCell setLineBreakMode:[oldCell lineBreakMode]];
	[newCell setFormatter:[oldCell formatter]];
	[newCell setFont:[oldCell font]];
	[newCell setEnabled:[oldCell isEnabled]];
	[newCell setEditable:[oldCell isEditable]];
	[newCell setWraps:[oldCell wraps]];
	[newCell setAlignment:[oldCell alignment]];

	[self setDataCell:newCell];
	[newCell release];
	return newCell;
}


- (id)morphHeaderCellToClass:(Class)aCellClass
{
	NSCell *newCell;
	NSCell *oldCell;
	
	oldCell = [self headerCell];
	newCell = [[aCellClass alloc] init];
	[newCell setTarget:[oldCell target]];
	[newCell setTag:[oldCell tag]];
	[newCell setState:[oldCell state]];
	[newCell setShowsFirstResponder:[oldCell showsFirstResponder]];
	[newCell setAction:[oldCell action]];
	[newCell setSendsActionOnEndEditing:[oldCell sendsActionOnEndEditing]];
	[newCell setSelectable:[oldCell isSelectable]];
	[newCell setScrollable:[oldCell isScrollable]];
	[newCell setRepresentedObject:[oldCell representedObject]];
	[newCell setLineBreakMode:[oldCell lineBreakMode]];
	[newCell setFormatter:[oldCell formatter]];
	[newCell setFont:[oldCell font]];
	[newCell setEnabled:[oldCell isEnabled]];
	[newCell setEditable:[oldCell isEditable]];
	[newCell setWraps:[oldCell wraps]];
	[newCell setAlignment:[oldCell alignment]];

	[self setHeaderCell:newCell];
	[newCell release];
	return newCell;

}

@end

@implementation AJRPreferencesModule : NSResponder
- (IBAction)showInspector:(id)sender
{
	//
	// put our view into some sort of inspectore I am thinking
}
@end


static AJRObjectBroker *broker = nil;

@implementation AJRObjectBroker : NSObject


// I am really not sure what the point of all this is, but here is my swing and a miss.
- (id)initWithTarget:(id)aTarget action:(SEL)anAction requestingClassesInheritedFromClass:(Class)aClass
{
	NSInteger i;
	if (! broker)
	{
		// load ALL clases and save that
		[super init];
		broker = self;
		numClasses = objc_getClassList(NULL, 0);
		classes = malloc(sizeof(Class) * numClasses);
		numClasses = objc_getClassList(classes, numClasses);
	}
	
	// we COULD cache things.  save the subclasses of (aClass) then if
	// aClass were asked for again, we would already have the result at hand.
	// This gits ONLY the first level subclasses.  If you wanted the whole tree
	// then this would need to be re-entrent or something like that.
	// in testing it seems that this method is only called ONCE for each passed class
	// in which case there is no point in doing caching now is there.
	for (i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != aClass);
         
        if (superClass == nil)
        {
            continue;
        }         
		[aTarget performSelector:anAction withObject:classes[i]];
    }		
			
	return self;
}


- (oneway void)release
{
    // do nothing as we DO NOT whish to release
    // we are a singleton
}

- (id)autorelease
{
    // do nothing
    return self;
}

@end

void AJRPrintf(NSString *format, ...)
{
	#ifdef VERBOSE

    va_list ap;
    NSString *buffer;

    va_start(ap, format);
    buffer = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
	NSLog(buffer);
	
	#endif
}
