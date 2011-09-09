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

#import <Foundation/Foundation.h>

@interface NSObject (EOObserver)

- (void)willChange;
// Called by a subject to message all of its observers. Convenience for [EOObserverCenter notifyObserversObjectWillChange:self]

@end

@protocol EOObserving <NSObject>

- (void)objectWillChange:(id)subject;
// called when object being observed is about to change

@end

@interface EOObserverCenter : NSObject

+ (void)addObserver:(id <EOObserving>)observer forObject:(id)object;
+ (void)removeObserver:(id <EOObserving>)observer forObject:(id)object;
+ (void)notifyObserversObjectWillChange:(id)object;
+ (NSArray *)observersForObject:(id)object;
+ (id)observerForObject:(id)object ofClass:(Class)targetClass;
+ (void)suppressObserverNotification;
+ (void)enableObserverNotification;
+ (unsigned)observerNotificationSuppressCount;

+ (void)addOmniscientObserver:(id <EOObserving>)observer;
+ (void)removeOmniscientObserver:(id <EOObserving>)observer;

+ (void)removeObserversForObject:(id)object;

@end


@class EODelayedObserverQueue;

typedef enum {
   EOObserverPriorityImmediate,
   EOObserverPriorityFirst,
   EOObserverPrioritySecond,
   EOObserverPriorityThird,
   EOObserverPriorityFourth,
   EOObserverPriorityFifth,
   EOObserverPrioritySixth,
   EOObserverPriorityLater
} EOObserverPriority;
#define EOObserverNumberOfPriorities ((unsigned)EOObserverPriorityLater + 1)


@interface EODelayedObserver : NSObject <EOObserving> {
    @public
    EODelayedObserver *_next;
}
- (void)objectWillChange:(id)subject;

- (EOObserverPriority)priority;
- (EODelayedObserverQueue *)observerQueue;

- (void)subjectChanged;

- (void)discardPendingNotification;

@end

enum {
    EOFlushDelayedObserversRunLoopOrdering = 400000
};


@interface EODelayedObserverQueue : NSObject
{
    EODelayedObserver	*_queue[EOObserverNumberOfPriorities];
    unsigned				_highestNonEmptyQueue;
    BOOL						_haveEntryInNotificationQueue;
    NSArray					*_modes;
}

+ (EODelayedObserverQueue *)defaultObserverQueue;

- (void)enqueueObserver:(EODelayedObserver *)observer;
- (void)dequeueObserver:(EODelayedObserver *)observer;
- (void)notifyObserversUpToPriority:(EOObserverPriority)lastPriority;

- (void)setRunLoopModes:(NSArray *)modes;
- (NSArray *)runLoopModes;

@end


@interface EOObserverProxy : EODelayedObserver {
    id						_target;
    SEL						_action;
    EOObserverPriority _priority;
}

- (id)initWithTarget:(id)target action:(SEL)action priority:(EOObserverPriority)priority;

@end
