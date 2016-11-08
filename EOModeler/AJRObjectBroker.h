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

/*!
 * @class AJRObjectBroker
 *
 * AJRObjectBroker implements a notification mechanism for informing objects within your Application or Tool of the existence of other objects which inherrit from a specified class. This is especially useful for implement plug-in architecture as it helps to remove a lot of the work required in registering classes.
 *
 * Basically, and often in a classes <EM>+initialize</EM> method, you create an object broker. This will immediately cause call backs into your code to inform you about any known subclasses of the class you specify. Subsequently, any time an NSBundle is loaded into the system, a new new message will be sent to your object informing you of the presense on the new class.
 *
 * Here's sample of how to use the AJRObjectBroker. Basically, we'll set up an inspector page super class which will be aware of all of it's subclasses.
 * <PRE>
 * &nbsp;&nbsp;&nbsp;&#64;implementation Inspector
 * &nbsp;&nbsp;&nbsp;
 * &nbsp;&nbsp;&nbsp;static NSMutableDictionary	*inspectors = nil;
 * &nbsp;&nbsp;&nbsp;static AJRObjectBroker     *broker = nil;
 * &nbsp;&nbsp;&nbsp;
 * &nbsp;&nbsp;&nbsp;+ (void)initialize
 * &nbsp;&nbsp;&nbsp;{
 * &nbsp;&nbsp;&nbsp;   // Use this if to avoid recursion, since the call to [self class] will
 * &nbsp;&nbsp;&nbsp;   // actually cause +initialize to be called a second time, assuming Apple
 * &nbsp;&nbsp;&nbsp;   // hasn't fixed that bug.
 * &nbsp;&nbsp;&nbsp;   if (inspectors == nil) {
 * &nbsp;&nbsp;&nbsp;      inspectors = [[NSMutableDictionary alloc] init];
 * &nbsp;&nbsp;&nbsp;      broker = [[AJRObjectBroker alloc] initWithTarget:self
 * &nbsp;&nbsp;&nbsp;                                                action:&#64;selector(registerInspector:)
 * &nbsp;&nbsp;&nbsp;                   requestingClassesInheritedFromClass:[self class]];
 * &nbsp;&nbsp;&nbsp;   }
 * &nbsp;&nbsp;&nbsp;}
 * &nbsp;&nbsp;&nbsp;
 * &nbsp;&nbsp;&nbsp;+ (void)registerInspector:(Class)aClass
 * &nbsp;&nbsp;&nbsp;{
 * &nbsp;&nbsp;&nbsp;   NSString    *inspectedClass = [aClass inspectedClass];
 * &nbsp;&nbsp;&nbsp;   [inspectors setObject:[[[aClass alloc] init] autorelease] forKey:inspectedClass];
 * &nbsp;&nbsp;&nbsp;}
 * &nbsp;&nbsp;&nbsp;
 * &nbsp;&nbsp;&nbsp;+ (Class)inspectorClass
 * &nbsp;&nbsp;&nbsp;{
 * &nbsp;&nbsp;&nbsp;   [NSException raise:NSInternalInconsistencyException
 * &nbsp;&nbsp;&nbsp;               format:&#64;"Subclasses of Inspector should implement +inspector class"];
 * &nbsp;&nbsp;&nbsp;}
 * &nbsp;&nbsp;&nbsp;
 * &nbsp;&nbsp;&nbsp;+ (Inspector *)inspectorForClass:(Class)aClass
 * &nbsp;&nbsp;&nbsp;{
 * &nbsp;&nbsp;&nbsp;   return [inspectors objectForKey:aClass];
 * &nbsp;&nbsp;&nbsp;}
 * &nbsp;&nbsp;&nbsp;
 * &nbsp;&nbsp;&nbsp;&#64;end
 * </PRE>
 * So, what you get is a simple, consistent way to register your inspectors. The nice thing here is that it takes only a little more work in the Inspector superclass, but it means it takes only implemented one method in the subclass.
 */

@interface AJRObjectBroker : NSObject
{
   id			target;
   SEL			action;
   Class		class;

   struct _ajrobFlags {
      BOOL		paused:1;
      unsigned	_reserved:31;
   } ajrobFlags;
}

/*!
 *
 * Creates a new object broker. The object broker registers target and anAction. Then, it will immediately call target with anAction with all classes that are current inherited from aClass in the runtime. Subsequently, whenever a class is loaded via a new framework or bundle being loaded by the runtime, new subclasses of aClass will be registered with target via anAction.
 */
+ (instancetype)objectBrokerWithTarget:(id)target action:(SEL)anAction requestingClassesInheritedFromClass:(Class)aClass;

/*!
 * Creates a new object broker. The object broker registers target and anAction. Then, it will immediately call target with anAction with all classes that are current inherited from aClass in the runtime. Subsequently, whenever a class is loaded via a new framework or bundle being loaded by the runtime, new subclasses of aClass will be registered with target via anAction.
 */
- (instancetype)initWithTarget:(id)target action:(SEL)anAction requestingClassesInheritedFromClass:(Class)aClass;

/*!
 * Causes the AJRObjectBroker to stop sending message. Note, this isn't a true pause in that you will not be notified of any classes that have appeared when you call <EM>-resume</EM>.
 */
- (void)pause;

/*!
 * Resumes sending notification messages about new classes. Call this after having called <EM>-pause</EM>.
 */
- (void)resume;

/*!
 * Changes the target. This may be either an instance or a class. If you pass in a class, make sure the action is a class method.
 *
 * @param aTarget The object designated to receive messages of new classes.
 */
- (void)setTarget:(id)aTarget;

/*!
 * Returns the object currently receiving new class notifications.

 * @result The object receiving new class notifications.
 */
- (id)target;

/*!
 * @method setAction:
 *
 * @discussion Change the selector to call when a class is found. The method will be called with the found subclass as the only parameter, which all means that the called selector should only accept one parameter.
 */
- (void)setAction:(SEL)anAction;

/*!
 * Returns the selected called on <EM>target</EM> when a new class of the appropriate type appears in the runtime.

 * @result The selector called for notification.
 */
- (SEL)action;

/*!
* Changes the class that is being watched. When you call this, target will immediately be called with all subclasses of aClass. Thus, to be notified correctly, you must call setTarget: and setAction: first.

 * @param aClass The name of the class for which to watch. This class is not necessarily the immediate superclass. It could be at any point in the class hierarchy.
 */
- (void)setWatchedClass:(Class)aClass;

/*!
 * @method watchedClass
 *
 * @discussion Returns the name of the watched class. See <EM>setWatchedClass:</EM> for more details.
 */
- (Class)watchedClass;

@end
