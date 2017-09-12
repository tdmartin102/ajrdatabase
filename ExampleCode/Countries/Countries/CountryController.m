//
//  CountryController.m
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

#import "Additions.h"
#import "CountryController.h"
#import "GeoCodes.h"

@implementation CountryController
{
    IBOutlet NSTextField    *panelTitleField;
    IBOutlet NSTextField    *regionNameField;
    IBOutlet NSTextField    *threeCharCodeField;
    IBOutlet NSTextField    *twoCharCodeField;
    IBOutlet NSTextField    *countryNameField;
    
    IBOutlet NSButton       *cancelButton;
    IBOutlet NSButton       *saveButton;
    
    RRSCountry              *_editCountry;
    EOGenericRecord         *_selectedRegion;
}

//===========================================================
//               Private Methods
//===========================================================

- (void)enableUI
{
    [saveButton setEnabled:self.modified];
}

- (void)addMode
{
    self.adding = YES;
    _editCountry = nil;
    panelTitleField.stringValue = @"Add Country";
    twoCharCodeField.stringValue = @"";
    threeCharCodeField.stringValue = @"";
    [countryNameField setStringValue:@""];
    regionNameField.stringValue = [_selectedRegion valueForKey:@"name"];
    
    
    [threeCharCodeField selectText:self];
    [self enableUI];
}

// ----- Edit the country name/code selected -----
- (void)editMode
{
    
    self.adding = NO;
    _editCountry = self.mainViewController.selectedCountry;

    panelTitleField.stringValue = @"Edit Country";
    threeCharCodeField.stringValue = _editCountry.code;
    twoCharCodeField.stringValue = _editCountry.twoCharCode;
    countryNameField.stringValue = _editCountry.name;
    regionNameField.stringValue = [_selectedRegion valueForKey:@"name"];
    
    [threeCharCodeField selectText:self];
    [self enableUI];
}

//===========================================================
//               Public Methods
//===========================================================

- (void)viewDidLoad
{
    [super viewDidLoad];
    _selectedRegion = self.mainViewController.selectedRegion;

    if (self.adding)
        [self addMode];
    else
        [self editMode];
}

- (IBAction)save:(id)sender
{
    BOOL            result = YES;
    RRSCountry      *aCountry;
    NSArray         *anArray = nil;
    NSString	    *aString = nil;
    EOQualifier	    *aQualifier = nil;
    int             errorNo = 0;
    NSTextField     *errorField = nil;
    static NSString *errMsg[7] =
    {
        @"3-character Country code may not be left blank.",
        @"3-character Country code must consist of 3 characters.",
        @"Entered 3-character Country code duplicates an existing 3-character Country code.",
        @"2-character Country code must consist of 2 characters.",
        @"Entered 2-character Country code duplicates an existing 2-character Country code.",
        @"Country name may not be left blank.",
        @"Country name may not be more than 34 characters long.",
    };
    
    if (! threeCharCodeField.stringValue.length)
    {
        errorField = threeCharCodeField;
        result = NO;
        errorNo = 1;
    }
    
    if (result)
    {
        if (threeCharCodeField.stringValue.length != 3)
        {
            errorField = threeCharCodeField;
            result = NO;
            errorNo = 2;
        }
    }
    
    if (result)
    {
        aCountry = [GeoCodes objectForCountryCode:threeCharCodeField.stringValue inContext:self.eoContext];
        if (aCountry)
        {
            if (! self.adding)
            {
                if (aCountry != _editCountry)
                    result = NO;
            }
            else
                result = NO;
        }
        if (result == NO)
        {
            errorField = threeCharCodeField;
            result = NO;
            errorNo = 3;
        }
    }
    
    if (result)
    {
        // if country is not AllLocations or Unknown, a 2-char country code
        // must also be entered
        aString = threeCharCodeField.stringValue;
        if ((! [aString isEqualToString:@"ALL"]) &&
            (! [aString isEqualToString:@"UNK"]))
        {
            if (twoCharCodeField.stringValue.length != 2)
            {
                errorField = twoCharCodeField;
                result = NO;
                errorNo = 4;
            }
        }
    }
    
    if (result)
    {
        aString = threeCharCodeField.stringValue;
        if ((! [aString isEqualToString:@"ALL"]) &&
            (! [aString isEqualToString:@"UNK"]))
        {
            aQualifier = [EOQualifier qualifierWithQualifierFormat:@"twoCharCode = %@", twoCharCodeField.stringValue];
            anArray = [RRSCountry objectsWithQualifier:aQualifier sortOrderings:nil inContext:self.eoContext];
            if (anArray.count)
                aCountry =anArray[0];
            if (aCountry)
            {
                if (! self.adding)
                {
                    if (aCountry != _editCountry)
                        result = NO;
                }
                else
                    result = NO;
            }
            if (result == NO)
            {
                errorField = twoCharCodeField;
                result = NO;
                errorNo = 5;
            }
        }
    }
    
    if (result)
    {
        if (! countryNameField.stringValue.length)
        {
            errorField = countryNameField;
            result = NO;
            errorNo = 6;
        }
    }
    
    if (result)
    {
        if (countryNameField.stringValue.length > 34)
        {
            errorField = countryNameField;
            result = NO;
            errorNo = 7;
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
            _editCountry.code = threeCharCodeField.stringValue;
            _editCountry.twoCharCode = twoCharCodeField.stringValue;
            _editCountry.name = countryNameField.stringValue;
            aCountry = _editCountry;
        }
        else
            //  we're adding a country, not editing
        {
            aCountry = [[RRSCountry alloc] init];
            [self.eoContext insertObject:aCountry];
            aCountry.code = threeCharCodeField.stringValue;
            aCountry.twoCharCode = twoCharCodeField.stringValue;
            aCountry.name = countryNameField.stringValue;
            aCountry.region =_selectedRegion;
            [(NSMutableArray *)[_selectedRegion valueForKey:@"countries"] addObject:aCountry];
            
        }
        [self.eoContext saveChanges];

        [self dismissViewController:self];
        [self.mainViewController updatedCountry:aCountry];
    }
    
    else
    {
        if (errorNo)
            [NSApp showError:errMsg[errorNo - 1]];
    }

}
- (IBAction)cancel:(id)sender
{
    _editCountry = nil;
    [super cancel:self];
}

@end
