//
//  RegionController.m
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

#import "RegionController.h"
#import "Additions.h"
#import "GeoCodes.h"

@implementation RegionController
{
    IBOutlet NSTextField    *panelTitleField;
    IBOutlet NSTextField     *regionNameField;
    
    IBOutlet NSButton       *cancelButton;
    IBOutlet NSButton       *saveButton;
    
    EOGenericRecord         *_editRegion;
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
    _editRegion = nil;
    
    panelTitleField.stringValue = @"Add Region";
    regionNameField.stringValue = @"";
    [regionNameField selectText:self];
    
    [self enableUI];
}

// ----- Edit the state code/name selected -----
- (void)editMode
{
    self.adding = NO;
    _editRegion = self.mainViewController.selectedRegion;
    
    if (_editRegion)
    {
        panelTitleField.stringValue = @"Edit State";
        regionNameField.stringValue = [_editRegion valueForKey:@"name"];
        [regionNameField selectText:self];
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
    EOGenericRecord *aRegion;
    
    static NSString *errMsg[2] =
    {
        @"Region name may not be left blank.",
        @"Region name may not be more than 34 characters long.",
    };
    
    if (! regionNameField.stringValue.length)
    {
        errorField = regionNameField;
        result = NO;
        errorNo = 1;
    }
    
    
    if (result)
    {
        if (regionNameField.stringValue.length > 34)
        {
            errorField = regionNameField;
            result = NO;
            errorNo = 2;
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
            [_editRegion setValue:regionNameField.stringValue forKey:@"name"];
            [self.eoContext saveChanges];
            aRegion = _editRegion;
        }
        else
            //  we're adding a region, not editing
        {
            aRegion = [[EOClassDescription classDescriptionForEntityName:@"REGION"]
                         createInstanceWithEditingContext:nil
                         globalID:nil zone:nil];
            [aRegion setValue:regionNameField.stringValue forKey:@"name"];
            [self.eoContext insertObject:aRegion];
            [self.eoContext saveChanges];
        }
        [self dismissViewController:self];
        [self.mainViewController updatedRegion:aRegion];

    }
    else
    {
        if (errorNo)
            [NSApp showError:errMsg[errorNo - 1]];
    }
}

- (void)cancel:(id)sender
{
    _editRegion = nil;
    [super cancel:sender];
}

@end
