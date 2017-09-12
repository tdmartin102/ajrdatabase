//
//  AppDelegate.h
//  Countries
//
//  Created by Tom Martin on 8/28/17.
//
//  @file AppDelegate.h

/*
 Copyright (c) 2017 Thomas D Martin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import <Cocoa/Cocoa.h>
#import <EOAccess/EOAccess.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

/*!
 * This is a factory method that will return the ONE instance of controller from ANYWHERE in your app.  
 * Very, very handy method.  Instead of tryting to connect EVERYTHING to controller use this.
 */
+ defaultController;

/*!
 * This is a very important method.  This is where a subclasser would put any setup code that needs to happen
 * before the app is ready to go.  ALWAYS call super.  This implementation does nothing but if you are using 
 * EOAppController as your subclass IT is what creates your editingContext.  Always call super.
*/
- (void)doPostLoadSetup;

/*!
 * This does a careful save changes on the editing context.  It catches any error messages
 * and will display them in an alert panel if they occur.  If an error DOES occur it will
 * call invalidateAllObjects and also revert.
 */
- (BOOL)saveChanges;

/*!
 * This does a careful save changes on the SPECIFIED editing context.  It catches any
 * error messages and will display them in an alert panel if they occur.  If an error
 * DOES occur it will call invalidateAllObjects and also revert.
 */
- (BOOL)saveChangesInContext:(EOEditingContext *)aContext;

/*!
 * This is the *ONLY* way you should be accessing the editing context!!  The editingContext
 * is not created until this method is called.
 */
- (EOEditingContext *)editingContext;

/*!
 * This is what you should connect your menu 'Print' button to.  It forwards the selector 'print:' to the 
 * delegate of the window that is currently the key winodw.  Further, if there IS no delegate to the key 
 * window it will send 'print:' to the window itself.  If the delegate does not respond to 'print:' then it 
 * will send the key window 'print:'
 */
- (IBAction)menuPrint:(id)sender;

@end

