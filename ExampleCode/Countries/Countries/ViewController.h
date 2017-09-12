//
//  ViewController.h
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

#import <Cocoa/Cocoa.h>

@class RRSCountry;
@class RRSState;
@class EOGenericRecord;

@interface ViewController : NSViewController <NSTableViewDataSource>

// Action methods that we handle
- (IBAction)deleteRegion:(id)sender;
- (IBAction)deleteCountry:(id)sender;
- (IBAction)deleteState:(id)sender;

// Return the currently selected objects
@property (nonatomic, readonly) EOGenericRecord *selectedRegion;
@property (nonatomic, readonly)RRSCountry *selectedCountry;
@property (nonatomic, readonly) RRSState *selectedState;

// update the views after something has been edited or added.
- (void)updatedState:(RRSState *)aState;
- (void)updatedCountry:(RRSCountry *)aCountry;
- (void)updatedRegion:(EOGenericRecord *)aRegion;

@end

