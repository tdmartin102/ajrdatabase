//
//  AppDelegate.m
//  Countries
//
//  Created by Tom Martin on 8/28/17.
//

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

#import "AppDelegate.h"
#import "Additions.h"

static id localInstance;

@implementation AppDelegate
{
    /*! setupComplete  doPostloadSetup completed */
    BOOL	setupComplete;
    /*! terminating  A flag to trap that the application is in the process of terminating.  If you do not catch this you ca easily fall into an endless loop. */
    BOOL	terminating;
    /*!
     * The Editing Context. You SHOULD <b>NOT</b> use this ivar directly.  <b>ALWAYS</b> access
     * this through the instance accessor method.
     */
    EOEditingContext	*eoContext;
    BOOL                _saveError;
}

//========================================================================================
//                      Public Methods
//========================================================================================

+ defaultController
{
    return localInstance;
}

// initialize the class------------------------------------------------------------------
- (instancetype)init
{
    if (self = [super init])
    {
        terminating = NO;
        setupComplete = NO;
        localInstance = self;
    }
    return self;
}

// perform any initialization required after the eomodel is loaded-----------------------
- (void)doPostLoadSetup
{
    // this method is intended to be overridden is subclasses
}

- (EOEditingContext *)editingContext
{
    if (! eoContext )
    {
        eoContext = [[EOEditingContext alloc] init];
        // I never use the undo manager.  There is a lot of overhead
        // and I like to have greater control over what changes are being queued
        [eoContext setUndoManager:nil];
    }
    return eoContext;
}


- (BOOL)saveChangesInContext:(EOEditingContext *)aContext
{
    BOOL ok = YES;
    id oldMessageHandler;
    
    // save changes and handle error messages
    oldMessageHandler = [aContext messageHandler];
    [aContext setMessageHandler:self];
    _saveError = NO;
    [aContext saveChanges:self];
    if (_saveError)
    {
        _saveError = NO;
        ok = NO;
        [NSApp showError:
         @"Error occurred saving changes.\nTransaction will be rolled back."];
        [aContext revert];
        [aContext invalidateAllObjects];
    }
    [aContext setMessageHandler:oldMessageHandler];
    
    return ok;
}

//------ Save changes and trap any errors ---------------------------------
- (BOOL)saveChanges
{
    return [self saveChangesInContext:[self editingContext]];
}

// (delegate) catch eoContext error messages -------------------------------------------------------
- (void)editingContext:(EOEditingContext *)aContext presentErrorMessage:(NSString *)message
{
    [NSApp showError:message];
    _saveError = YES;
}

// return whether or not the application should be allowed to terminate------------------
- (BOOL)allowApplicationTermination
{
    // this method will be overridden in subclasses where required
    return YES;
}

// return whether or not the appliation is in the terminate loop at this time------------
- (BOOL)terminating { return terminating; }

// send message to the key window if its delegate responds to it-------------------------
- (void)dispatchMessage:(SEL)aMessage
{
    id	keyWindowDelegate;
    IMP imp;
    void (*func)(id, SEL, id);
    
    keyWindowDelegate = [[NSApp keyWindow] delegate];
    if ([keyWindowDelegate respondsToSelector:aMessage])
    {
        imp = [keyWindowDelegate methodForSelector:aMessage];
        func = (void *)imp;
        func(keyWindowDelegate, aMessage, self);
    }
    else
        NSBeep();
}

// user hit the print button on the menu.  Deal With It!!!-------------------------------
- (void)menuPrint:(id)sender
{
    NSWindow	*aWindow;
    id		activeModule;
    
    aWindow = [NSApp keyWindow];
    activeModule = [aWindow delegate];
    
    if (! activeModule)
        [aWindow print:sender];
    else
    {
        if ([activeModule respondsToSelector:@selector(print:)])
            [self dispatchMessage:@selector(print:)];
        else
            [aWindow print:sender];
    }
}

// (delegate) application has finished loading.  Attempt to init the eomodel-------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //    NXSetTopLevelErrorHandler(errorHandler);
    
    // here do any set up functions that must be done after the database is loaded.
    [self doPostLoadSetup];
    
    setupComplete = YES;
}

// (delegate) application is going to terminate.  Save changes if necessary--------------
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    BOOL status;
    
    terminating = YES;
    status = [self allowApplicationTermination];
    
    if (! status)
        terminating = NO;
    else
        [[NSUserDefaults standardUserDefaults] synchronize];
    
    return (status) ? NSTerminateNow : NSTerminateCancel;
}



@end
