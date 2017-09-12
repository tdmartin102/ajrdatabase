//
//  ViewController.m
//  Countries
//
//  Created by Tom Martin on 8/28/17.
//  Copyright © 2017 Riemer Reporting Services, Inc. All rights reserved.
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

#import "ViewController.h"

#import "Additions.h"
#import "AppDelegate.h"
#import "GeoCodes.h"
#import "RRSCountry.h"
#import "RRSState.h"

#import "EditController.h"

#define regionName       	0

#define threeCharacterCode      0
#define twoCharacterCode    	1
#define countryName      	2

#define stateCode	 	0
#define stateName	 	1

@implementation ViewController
{
    IBOutlet NSTableView    *regionTableView;
    IBOutlet NSTableView    *countryTableView;
    IBOutlet NSTableView    *stateTableView;
    
    IBOutlet NSButton   *addRegionButton;
    IBOutlet NSButton   *editRegionButton;
    IBOutlet NSButton   *deleteRegionButton;
    IBOutlet NSButton   *addCountryButton;
    IBOutlet NSButton   *editCountryButton;
    IBOutlet NSButton   *deleteCountryButton;
    IBOutlet NSButton   *addStateButton;
    IBOutlet NSButton   *editStateButton;
    IBOutlet NSButton   *deleteStateButton;
    
    NSArray	*regionList;
    NSArray	*countryList;
    NSArray	*stateList;
    
    AppDelegate  *controller;
    EOEditingContext *eoContext;
}

//========================================================================================
//                        Private Methods
//========================================================================================

//--(Private)----- set up the ui according to current conditions -------------------------
- (void)enableUI
{
    int regionCount = (int)regionList.count;
    int countryCount = (int)countryList.count;
    int stateCount = (int)stateList.count;
    
    BOOL hasRegions = (regionCount) ? YES : NO;
    BOOL hasCountries = (countryCount) ? YES : NO;
    BOOL hasStates = (stateCount) ? YES : NO;
    
    addRegionButton.enabled = YES;;
    editRegionButton.enabled =  hasRegions;
    deleteRegionButton.enabled = hasRegions;
    
    addCountryButton.enabled = hasRegions;
    editCountryButton.enabled = hasCountries;
    deleteCountryButton.enabled = hasCountries;
    
    addStateButton.enabled = hasCountries;
    editStateButton.enabled = hasStates;
    deleteStateButton.enabled = hasStates;
    
    [regionTableView reloadData];
    [countryTableView reloadData];
    [stateTableView reloadData];
}

//------------ fetch region rows from database in region name sort order -------------
- (void)fetchRegions:(id)sender
{
    NSArray   *tempArray;
    int count;
    EOFetchSpecification  *fetchSpecification;
    
    //      [[self editingContext] refaultObjects];
    [eoContext invalidateAllObjects];
    
    fetchSpecification = [EOFetchSpecification fetchSpecificationWithEntityName:@"REGION" qualifier:nil sortOrderings:nil];
    
    tempArray = [eoContext objectsWithFetchSpecification:fetchSpecification];
    
    
    count = (int)tempArray.count;
    regionList = [[NSMutableArray alloc] initWithCapacity:MAX(1,count)];
    
    if (count > 1)
    {
        regionList = [tempArray sortedArrayUsingComparator:^NSComparisonResult(EOGenericRecord *obj1, EOGenericRecord *obj2) {
            return [(NSString*)[obj1 valueForKey:@"name"] compare:(NSString*)[obj2 valueForKey:@"name"]];
                    }];
    }
    else
        regionList = tempArray;
}

//----- fetch country rows from database for selected region, in country name sort order -----
- (void)fetchCountries:(EOGenericRecord *)region
{
    NSArray  *countries;
    
    countries = [region valueForKey:@"countries"];
    if (countries.count > 1)
    {
        countryList = [countries sortedArrayUsingComparator:^NSComparisonResult(RRSCountry *obj1, RRSCountry *obj2) {
            return [obj1.name compare:obj2.name];
        }];
    }
    else
        countryList = countries;
}


//------------ fetch state rows from database for selected country, in state name sort order -----
- (void)fetchStates:(RRSCountry *)selectedCountry
{
    int count;
    
    count = (int)selectedCountry.states.count;
    if (count > 1)
    {
        stateList = [selectedCountry.states sortedArrayUsingComparator:^NSComparisonResult(RRSState *obj1, RRSState *obj2) {
            return [obj1.name compare:obj2.name];
        }];
        [stateTableView reloadData];
    }
    else
        stateList = [selectedCountry states];
}

//===========================================================================================
//                       Public Methods
//===========================================================================================

- (void)viewDidLoad {
    [super viewDidLoad];
    
    controller = [AppDelegate defaultController];
    eoContext = [controller editingContext];
    
    [self fetchRegions:self];
    
    regionTableView.allowsEmptySelection = NO;
    regionTableView.allowsMultipleSelection = NO;
    
    countryTableView.allowsEmptySelection = NO;
    countryTableView.allowsMultipleSelection = NO;
    stateTableView.allowsEmptySelection = NO;
    stateTableView.allowsMultipleSelection = NO;
    
    if (regionList.count)
        [self fetchCountries:regionList[0]];
    if (countryList.count)
        [self fetchStates:countryList[0]];
    
    [self enableUI];
    
    [regionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [countryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [stateTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    
    // Set up for table selection changes
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(regionTableSelectionChanged:)
     name:NSTableViewSelectionDidChangeNotification
     object:regionTableView];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(countryTableSelectionChanged:)
     name:NSTableViewSelectionDidChangeNotification
     object:countryTableView];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

//--------- Return the selected Region if there was one, nil otherwise-------------
- (EOGenericRecord *)selectedRegion
{
    EOGenericRecord  *result = nil;
    NSInteger row = 0;
    if (regionList.count)
    {
        row = regionTableView.selectedRow;
        if (row >=0)
            result = regionList[row];
    }
    return result;
}

//--------- Return the selected Country if there was one, nil otherwise-------------
- (RRSCountry *)selectedCountry
{
    RRSCountry *result = nil;
    NSInteger row = 0;
    if (countryList.count)
    {
        row = countryTableView.selectedRow;
        if (row >=0)
            result = countryList[row];
    }
    
    [countryTableView scrollRowToVisible:row];
    return result;
}

//--------- Return the selected State if there was one, nil otherwise-------------
- (RRSState *)selectedState
{
    RRSState *result = nil;
    NSInteger row = 0;
    if (stateList.count)
    {
        row = stateTableView.selectedRow;
        if (row >=0)
            result = stateList[row];
    }
    
    [stateTableView scrollRowToVisible:row];
    return result;
}

- (void)deleteRegion:(id)sender
{
    EOGenericRecord     *region;
    NSInteger           row;
    NSModalResponse		option;
    NSAlert             *alert;
    
    if (! regionList.count)
        return;
    
    row = regionTableView.selectedRow;
    region = regionList[row];
    
    if (countryList.count)
    {
        [NSApp showError:@"You may not delete a region that has countries in the database."];
        return;
    }
    
    alert = [[NSAlert alloc] init];
    alert.messageText = [NSApp appName];
    alert.informativeText = @"Are you sure you wish to delete the selected region?";
    [alert addButtonWithTitle: @"Yes"];
    [alert addButtonWithTitle: @"No"];
    option = [alert runModal];
    if ( option != NSAlertFirstButtonReturn )
        return;
    
    [eoContext deleteObject:region];
    
    [controller saveChanges];
    [self fetchRegions:self];
    
    if (regionList.count)
    {
        [regionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN(row, regionList.count - 1)] byExtendingSelection:NO];
        [regionTableView scrollRowToVisible:MIN(row, regionList.count - 1)];
    }
    
    [self fetchCountries:[self selectedRegion]];
    
    [self enableUI];
}

- (void)deleteCountry:(id)sender
{
    RRSCountry          *country;
    EOGenericRecord     *region;
    NSModalResponse		option;
    NSAlert             *alert;
    NSInteger           row;
    
    if (! countryList.count)
        return;
    
    row = countryTableView.selectedRow;
    country = countryList[row];
    
    if (stateList.count)
    {
        [NSApp showError:@"You may not delete a country that has states in the database."];
        return;
    }
    
    alert = [[NSAlert alloc] init];
    alert.messageText = [NSApp appName];
    alert.informativeText = @"Are you sure you wish to delete the selected country?";
    [alert addButtonWithTitle: @"Yes"];
    [alert addButtonWithTitle: @"No"];
    option = [alert runModal];
    if ( option != NSAlertFirstButtonReturn )
        return;
    
    [eoContext deleteObject:country];
    
    region = [self selectedRegion];
    [(NSMutableArray *)[region valueForKey:@"countries"] removeObject:country];
    
    [controller saveChanges];
    [self fetchCountries:region];
    
    if (countryList.count)
    {
        [countryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN(row, countryList.count - 1)] byExtendingSelection:NO];
        [countryTableView scrollRowToVisible:MIN(row, countryList.count - 1)];
    }
    
    [self fetchStates:[self selectedCountry]];
    [self enableUI];
}

- (void)deleteState:(id)sender
{
    RRSState   *state;
    NSModalResponse		option;
    NSAlert             *alert;
    NSInteger           row;
    
    if (! stateList.count)
        return;
    
    alert = [[NSAlert alloc] init];
    alert.messageText = [NSApp appName];
    alert.informativeText = @"Are you sure you wish to delete the selected state?";
    [alert addButtonWithTitle: @"Yes"];
    [alert addButtonWithTitle: @"No"];
    option = [alert runModal];
    if ( option != NSAlertFirstButtonReturn )
        return;
    
    row = stateTableView.selectedRow;
    state = stateList[row];
    
    [[self selectedCountry] removeObject:state fromBothSidesOfRelationshipWithKey:@"states"];
    [eoContext deleteObject:state];
    
    [controller saveChanges];
    [self fetchStates:[self selectedCountry]];
    [self enableUI];
    
    
    if (stateList.count)
        [stateTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN(row, stateList.count - 1)] byExtendingSelection:NO];
    [stateTableView scrollRowToVisible:MIN(row, stateList.count - 1)];
}

//------------ fetch state rows from database for selected country, in state name sort order -----
- (void)updatedState:(RRSState *)aState
{
    NSInteger i;
    
    if (! aState)
        return;
    
    [self fetchStates:[self selectedCountry]];
    if (stateList.count)
    {
        [stateTableView reloadData];
        // find the edited / added state and select it
        i = [stateList indexOfObject:aState];
        [stateTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [stateTableView scrollRowToVisible:i];
    }
    [self enableUI];
}

- (void)updatedCountry:(RRSCountry *)aCountry
{
    NSInteger i;
    
    if (! aCountry)
        return;
    
    [self fetchCountries:[self selectedRegion]];
    if (countryList.count)
    {
        [countryTableView reloadData];
        // find the edited / added country and select it
        i = [countryList indexOfObject:aCountry];
        [countryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [countryTableView scrollRowToVisible:i];
    }
    [self enableUI];
}

- (void)updatedRegion:(EOGenericRecord *)aRegion
{
    NSInteger i;
    
    if (! aRegion)
        return;
    
    [self fetchRegions:self];
    if (regionList.count)
    {
        [regionTableView reloadData];
        // find the edited / added region and select it
        i = [regionList indexOfObject:aRegion];
        [regionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [regionTableView scrollRowToVisible:i];
    }
    [self enableUI];
}

//-------- Clear out the country & states fetches if the region changes ----------------------
- (void)regionTableSelectionChanged:(NSNotification *)aNotification
{
    EOGenericRecord   *region;
    
    region = [self selectedRegion];
    if (region)
    {
        [countryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [countryTableView scrollRowToVisible:0];
        [stateTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [stateTableView scrollRowToVisible:0];
        [self fetchCountries:region];
        [self fetchStates:[self selectedCountry]];
        [self enableUI];
    }
    else
    {
        countryList = @[];
        stateList = @[];
    }
}

//-------- Clear out the states fetch if the selected country changes ----------------------
- (void)countryTableSelectionChanged:(NSNotification *)aNotification
{
    RRSCountry *country;
    
    country = [self selectedCountry];
    if (country)
        [self fetchStates:country];
    else
    {
        stateList = @[];
    }
    [self enableUI];
    [stateTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [stateTableView scrollRowToVisible:0];
    
}

//--- Table View Data Source Methods -----------------------------
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count;
    
    if (tableView == regionTableView)
        count = regionList.count;
    else
    {
        if (tableView == countryTableView)
            count = countryList.count;
        else
            count = stateList.count;
    }
    return count;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    EditController *editController = segue.destinationController;
    if ([segue.identifier isEqualToString:@"Add"])
    {
        editController.mainViewController = self;
        editController.adding = YES;
    }
    else if ([segue.identifier isEqualToString:@"Edit"])
    {
        editController.mainViewController = self;
        editController.adding = NO;
    }
}

//----------- TableView dataSource method to return cell values --------------------------
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)
tableColumn row:(NSInteger)row
{
    NSString *cellString = @"";
    EOGenericRecord   *region;
    RRSCountry *country;
    RRSState *state;
    
    if (tableView == regionTableView)
    {
        region = regionList[row];
        
        switch (tableColumn.identifier.intValue)
        {
            case regionName:
                cellString = [region valueForKey:[NSString stringWithFormat:@"name"]];
                break;
            default :
                break;
        }
    }
    
    else if (tableView == countryTableView)
    {
        country =countryList[row];
        switch (tableColumn.identifier.intValue)
        {
            case threeCharacterCode:
                cellString = country.code;
                break;
            case twoCharacterCode:
                cellString = country.twoCharCode;
                break;
            case countryName:
                cellString = country.name;
                break;
            default :
                break;
        }
    }
    else
    {
        state = stateList[row];
        switch (tableColumn.identifier.intValue)
        {
            case stateCode:
                cellString = state.code;;
                break;
            case stateName:
                cellString = state.name;
                break;
            default :
                break;
        }
    }
    
    return cellString;
}

@end
