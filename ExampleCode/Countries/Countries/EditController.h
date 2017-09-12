//
//  EditController.h
//  Countries
//
//  Created by Tom Martin on 9/12/17.
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

#import "AppDelegate.h"
#import "ViewController.h"

@interface EditController : NSViewController

// Flag to indicate we are adding.  If we are NOT adding then we are editing. This must be set by the caller
@property (nonatomic, assign)   BOOL            adding;

// The view controller that OWNS this view controller.  THis must be set by the caller
@property (nonatomic, weak)     ViewController  *mainViewController;

// properties set in viewDidLoad that subclassers can access
@property (nonatomic, weak)     AppDelegate     *mainController;
@property (nonatomic, retain)   EOEditingContext *eoContext;
@property (nonatomic, assign)   BOOL            modified;

// Overridden by subclassers to enable/disable UI elements
- (void)enableUI;

// Overridden by subclassers to save changes
- (IBAction)save:(id)sender;

// Overridden by subclassers cancel / exit (call super)
- (IBAction)cancel:(id)sender;

@end
