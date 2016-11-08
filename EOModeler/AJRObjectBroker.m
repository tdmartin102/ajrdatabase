/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/
/* AJRObjectBroker.m created by alex on Thu 15-Oct-1998 */

#import "AJRObjectBroker.h"
#import "AJRClassEnumerator.h"

#import <objc/runtime.h>

@implementation AJRObjectBroker

+ (instancetype)objectBrokerWithTarget:(id)aTarget action:(SEL)anAction requestingClassesInheritedFromClass:(Class)aClass
{
   return [[self alloc] initWithTarget:aTarget action:anAction requestingClassesInheritedFromClass:aClass];
}

- (instancetype)initWithTarget:(id)aTarget action:(SEL)anAction requestingClassesInheritedFromClass:(Class)aClass
{
   self = [super init];

   [self setTarget:aTarget];
   [self setAction:anAction];
   [self setWatchedClass:aClass];

   ajrobFlags.paused = NO;
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:) name:NSBundleDidLoadNotification object:nil];

   return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)pause
{
   if (!ajrobFlags.paused) {
      ajrobFlags.paused = YES;
      [[NSNotificationCenter defaultCenter] removeObserver:self];
   }
}

- (void)resume
{
   if (ajrobFlags.paused) {
      ajrobFlags.paused = NO;
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:) name:NSBundleDidLoadNotification object:nil];
   }
}

- (void)setTarget:(id)aTarget
{
   target = aTarget;
}

- (id)target
{
   return target;
}

- (void)setAction:(SEL)anAction
{
   if (action != anAction) {
      action = anAction;
   }
}

- (SEL)action
{
   return action;
}

- (void)sendActionWithObject:(id)anObject

{
    NSMethodSignature * mySignature = [target methodSignatureForSelector:action];
    NSInvocation * myInvocation = [NSInvocation
                                   invocationWithMethodSignature:mySignature];
    myInvocation.target = target;
    myInvocation.selector = action;
    [myInvocation setArgument:&anObject atIndex:2];
    [myInvocation invoke];
}

- (void)setWatchedClass:(Class)aClass
{
    if (class != aClass) {
        AJRClassEnumerator	*enumerator;
        __unsafe_unretained Class	workClass;
        NSString *className;

        if (class && !aClass && ajrobFlags.paused) {
            ajrobFlags.paused = NO;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:)
                                                         name:NSBundleDidLoadNotification object:nil];
        }

        class = aClass;

        if (!class) {
            ajrobFlags.paused = YES;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            return;
        }

        // Now let's register all loaded modules...
        enumerator = [[AJRClassEnumerator alloc] init];
        while ((workClass = [enumerator nextObject])) {
            //AJRPrintf(@"%@\n", NSStringFromClass(workClass));
            if (workClass == class)
                continue;
            
            // filter out root classes
            if (class_respondsToSelector(workClass, @selector(methodSignatureForSelector:)))
            {
                // filter out Apple classes
                className = [NSString stringWithUTF8String:object_getClassName(workClass)];
                if (! (([className hasPrefix:@"NS"]) ||
                    ([className hasPrefix:@"_NS"])||
                    ([className hasPrefix:@"__NS"])))
                {
                    if ([workClass respondsToSelector:@selector(isSubclassOfClass:)]) {
                        if ([workClass isSubclassOfClass:class]) {
                            [self sendActionWithObject:workClass];
                        }
                    }
                }
            }
        }
        [enumerator release];
    }   
}

- (Class)watchedClass
{
   return class;
}

- (void)bundleDidLoad:(NSNotification *)notification
{
    NSArray		*classes = [[notification userInfo] objectForKey:NSLoadedClasses];
    int			x;
    Class		workClass;
    
    for (x = 0; x < (const int)[classes count]; x++) {
      // Apparently, the classes we get out of the notification aren't necessarily valid.  However, the following line gives us the valid class the corresponds to what we got out of the notification.  Do NOT "fix" the following line by removing the NSClassFromString call.
        workClass = NSClassFromString([[classes objectAtIndex:x] description]);
        if (workClass == class)
            continue;
        
        if ([workClass isSubclassOfClass:class])
            [self sendActionWithObject:workClass];
    }
}

@end
