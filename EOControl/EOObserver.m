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

#import "EOObserver.h"
#import "NSObject-EOEnterpriseObject.h"

#import <Foundation/Foundation.h>

@implementation NSObject (EOObserver)

- (void)willChange
{
   [EOObserverCenter notifyObserversObjectWillChange:self];
}

@end


static NSZone		*observerZone;
static NSMapTable	*observed; // Lightweight version of dictionaries - no need to use NSValues
static NSMutableSet *omnicientObservers;
static int			suppressionCount;

@implementation EOObserverCenter

+ (void)initialize
{
   observerZone = NSCreateZone(NSPageSize(), NSPageSize(), YES);
   NSSetZoneName(observerZone, @"EOObserverZone");
   
   // (ja @ sente.ch) Avoid calling isEqual: this can result in dispatching to other editing contexts
   NSMapTableKeyCallBacks observedInstanceCallBacks = NSNonRetainedObjectMapKeyCallBacks;
   observedInstanceCallBacks.isEqual = NULL;
   
   observed = NSCreateMapTableWithZone(observedInstanceCallBacks, NSObjectMapValueCallBacks, 100, observerZone);
   omnicientObservers = [[NSMutableSet allocWithZone:observerZone] init];
   suppressionCount = 0;
}

+ (void)addObserver:(id <EOObserving>)observer forObject:(id)object
{
    NSMutableSet	*observers;
	
    observers = NSMapGet(observed, object);
    if (observers == nil) {
		observers = [[NSMutableSet allocWithZone:observerZone] init];
		NSMapInsertKnownAbsent(observed, object, observers);
		[observers release];
    }
/*	if ([observer isKindOfClass: NSClassFromString(@"EOEditingContext")]) {
		id objectEC = [object editingContext];
		if ((objectEC != nil) && (objectEC != observer)) {
			NSLog(@"Starting to observe non belonging object");
		}
	}*/
	
    [observers addObject:observer];
}

+ (void)removeObserver:(id <EOObserving>)observer forObject:(id)object
{
   NSMutableSet	*observers;

   if (object == nil) {
      NSMapEnumerator	enumerator;

      enumerator = NSEnumerateMapTable(observed);
      while (NSNextMapEnumeratorPair(&enumerator, (void **)&object, (void **)&observers)) {
         if ([observers count] <= 1) {
             NSMapRemove(observed, object);
         } else {
            [observers removeObject:observer];
         }
      }
      NSEndMapTableEnumeration(&enumerator);
   } else {
      observers = NSMapGet(observed, object);
      if (observers != nil) {
         if ([observers count] <= 1) {
             NSMapRemove(observed, object);
         } else {
             [observers removeObject:observer];
         }
      }
   }
}

+ (void)removeObserversForObject:(id)object
{
	NSMutableSet	*observers;

	observers = NSMapGet(observed, object);
	if (observers != nil) {
		NSMapRemove(observed, object);
	}
}

+ (void)notifyObserversObjectWillChange:(id)object
{
   // TODO: avoid notifying several times in a row with the same object
   if (suppressionCount == 0) {
      NSMutableSet	*observers;

      observers = NSMapGet(observed, object);
      if (observers != nil) {
         [observers makeObjectsPerformSelector:@selector(objectWillChange:)
                                    withObject:object];
      }
      [omnicientObservers makeObjectsPerformSelector:@selector(objectWillChange:)
                                          withObject:object];
   }
}

+ (NSArray *)observersForObject:(id)object
{
    return [(NSMutableSet *)NSMapGet(observed, object) allObjects];
}

+ (id)observerForObject:(id)object ofClass:(Class)targetClass
{
   NSMutableSet	*observers;

   observers = NSMapGet(observed, object);
   if (observers != nil) {
      NSEnumerator  *observerEnum = [observers objectEnumerator];
      id            eachObserver;
      
      while (eachObserver = [observerEnum nextObject]) {
         if ([eachObserver isKindOfClass:targetClass]) {
            return eachObserver;
         }
      }
   }

   return nil;
}

+ (void)suppressObserverNotification
{
   suppressionCount++;
}

+ (void)enableObserverNotification
{
   if (suppressionCount == 0) {
      [NSException raise:NSInternalInconsistencyException format:@"Not paired with a prior suppressObserverNotification message"];
   }
   suppressionCount--;
}

+ (unsigned)observerNotificationSuppressCount
{
   return suppressionCount;
}

+ (void)addOmniscientObserver:(id <EOObserving>)observer
{
   [omnicientObservers addObject:observer];
}

+ (void)removeOmniscientObserver:(id <EOObserving>)observer
{
   [omnicientObservers removeObject:observer];
}

@end


// TODO:
@implementation EODelayedObserver

- (void)objectWillChange:(id)subject
{
}

- (EOObserverPriority)priority
{
   return 0;
}

- (EODelayedObserverQueue *)observerQueue
{
   return nil;
}

- (void)subjectChanged
{
}

- (void)discardPendingNotification
{
}

@end


// TODO:
@implementation EODelayedObserverQueue

+ (EODelayedObserverQueue *)defaultObserverQueue
{
   return nil;
}

- (void)enqueueObserver:(EODelayedObserver *)observer
{
}

- (void)dequeueObserver:(EODelayedObserver *)observer
{
}

- (void)notifyObserversUpToPriority:(EOObserverPriority)lastPriority
{
}

- (void)setRunLoopModes:(NSArray *)modes
{
}

- (NSArray *)runLoopModes
{
   return nil;
}

@end


// TODO:
@implementation EOObserverProxy

- (id)initWithTarget:(id)target action:(SEL)action priority:(EOObserverPriority)priority
{
   return nil;
}

- (EOObserverPriority)priority
{
   return 0;
}

- (void)subjectChanged
{
}

@end
