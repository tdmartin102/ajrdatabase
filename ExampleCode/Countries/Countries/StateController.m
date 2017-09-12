//
//  StateController.m
//  Countries
//
//  Created by Tom Martin on 9/8/17.
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

#import "Additions.h"
#import "StateController.h"
#import "GeoCodes.h"

@implementation StateController
{
    IBOutlet NSTextField    *panelTitleField;
    IBOutlet NSTextField    *regionNameField;
    IBOutlet NSTextField    *countryNameField;
    IBOutlet NSTextField    *stateCodeField;
    IBOutlet NSTextField    *stateNameField;
    
    IBOutlet NSButton       *cancelButton;
    IBOutlet NSButton       *saveButton;
    
    RRSState                *_editState;
    RRSCountry              *_selectedCountry;
}

//========================================================================================
//                        Private Methods
//========================================================================================

- (void)enableUI
{
    [saveButton setEnabled:self.modified];
}

- (void)addMode
{
    self.adding = YES;
    _editState = nil;
    
    panelTitleField.stringValue = @"Add State";
    stateCodeField.stringValue = @"";
    stateNameField.stringValue = @"";
    regionNameField.stringValue = [_selectedCountry.region valueForKey:@"name"];
    countryNameField.stringValue = _selectedCountry.name;

    [stateCodeField selectText:self];
    
    [self enableUI];
}

// ----- Edit the state code/name selected -----
- (void)editMode
{
    self.adding = NO;
    _editState = self.mainViewController.selectedState;
    
    if (_editState)
    {
        panelTitleField.stringValue = @"Edit State";
        stateCodeField.stringValue = _editState.code;
        stateNameField.stringValue = _editState.name;
        regionNameField.stringValue = [_selectedCountry.region valueForKey:@"name"];
        countryNameField.stringValue= _selectedCountry.name;
        
        [stateCodeField selectText:self];
    }
    else
    {
        NSBeep();
        [self performSelector:@selector(dismissViewController:)
                         withObject:self
                         afterDelay:0.2];
    }

    [self enableUI];
}

//========================================================================================
//                        Public Methods
//========================================================================================

- (void)viewDidLoad {
    [super viewDidLoad];
    _selectedCountry = self.mainViewController.selectedCountry;
  
    if (self.adding)
        [self addMode];
    else
        [self editMode];
}

- (void)save:(id)sender
{
    BOOL            result = YES;
    int             errorNo = 0;
    NSTextField     *errorField = nil;
    RRSState        *aState;
    static NSString *errMsg[5] =
    {
        @"State code may not be left blank.",
        @"State code must consist of 2 characters.",
        @"Entered state code duplicates an existing state code.",
        @"State name may not be left blank.",
        @"State name may not be more than 34 characters long.",
    };
    
    if (! stateCodeField.stringValue.length)
    {
        errorField = stateCodeField;
        result = NO;
        errorNo = 1;
    }
    
    if (result)
    {
        if (stateCodeField.stringValue.length != 2)
        {
            errorField = stateCodeField;
            result = NO;
            errorNo = 2;
        }
    }
    
    if (result)
    {
        
        aState = [GeoCodes objectForStateCode:stateCodeField.stringValue inContext:self.eoContext];
        if (aState)
        {
            if (! self.adding)
            {
                if (aState != _editState)
                    result = NO;
            }
            else
                result = NO;
        }
        if (result == NO)
        {
            errorField = stateCodeField;
            result = NO;
            errorNo = 3;
            
        }
    }
    
    if (result)
    {
        if (! stateNameField.stringValue.length)
        {
            errorField = stateNameField;
            result = NO;
            errorNo = 4;
        }
    }
    
    
    if (result)
    {
        if (stateNameField.stringValue.length > 34)
        {
            errorField = stateNameField;
            result = NO;
            errorNo = 5;
        }
    }
    
    
    if (! result)
    {
        [errorField performSelector:@selector(selectText:)
                         withObject:self
                         afterDelay:0.2];
    }
    
    if (result)
    {
        
        if (! self.adding)
        {
            _editState.code = stateCodeField.stringValue;
            _editState.name = stateNameField.stringValue;
            [self.eoContext saveChanges];
            aState = _editState;
        }
        else
            //  we're adding a state, not editing
        {
            aState = [[RRSState alloc] init];
            [self.eoContext insertObject:aState];
            aState.code = stateCodeField.stringValue;
            aState.name = stateNameField.stringValue;
            aState.country = _selectedCountry;
            [_selectedCountry addToStates:aState];
            [self.eoContext saveChanges];
        }
        
        [self dismissViewController:self];
        [self.mainViewController updatedState:aState];
    }
    else
    {
        if (errorNo)
            [NSApp showError:errMsg[errorNo - 1]];
    }
}

- (void)cancel:(id)sender
{
    _editState = nil;
    [super cancel:sender];
}

@end
