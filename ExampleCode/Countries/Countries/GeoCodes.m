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

#import "GeoCodes.h"

@implementation GeoCodes

// (private) validate state code------------------------------------------------------------
+ (RRSState *)validateState:(NSString *)stateCode errorCode:(short *)errorNo
                  inContext:(EOEditingContext *)context
{
    short	codeLen;
    RRSState	*currentState = nil;
    
    *errorNo = msgValid;
    codeLen = stateCode.length;
    if (codeLen == 2)
    {
        currentState = [self objectForStateCode:stateCode inContext:context];
        if (! currentState)
            *errorNo = msgStateNotFound;
    }
    else if (codeLen)
        *errorNo = msgStateInvFmt;
    
    return currentState;
}

// (private) validate country code----------------------------------------------------------
+ (RRSCountry *)validateCountry:(NSString *)countryCode
                      errorCode:(short *)errorNo inContext:(EOEditingContext *)context
{
    short	codeLen;
    RRSCountry	*currentCountry = nil;

    *errorNo = msgValid;
    codeLen = countryCode.length;

    if (codeLen == 3)
    {
        currentCountry = [self objectForCountryCode:countryCode inContext:context];
        if (! currentCountry)
            *errorNo = msgCountryNotFound;
    }
    else if (! codeLen)
        *errorNo = msgCountryLeftBlank;
    else
        *errorNo = msgCountryInvFmt;

    return currentCountry;
}

// return the error message for the corresponding error code--------------------------------
+ (NSString *)messageForCode:(short)errorCode
{
    NSString *messageStr;
    
    switch(errorCode)
    {
        case msgValid:
            messageStr = @"Valid";
        break;
        case msgStateInvFmt:
            messageStr = @"State code must be two characters long and all uppercase";
        break;
        case msgStateNotFound:
            messageStr = @"State code not found in database";
        break;
        case msgCountryInvFmt:
            messageStr = @"Country code must be three characters long, and all uppercase";
        break;
        case msgCountryLeftBlank:
            messageStr = @"Country code cannot be left blank";
        break;
        case msgCountryNotFound:
            messageStr = @"Country code not found in database";
        break;
        case msgStateNotSupplied:
            messageStr = @"State must be supplied for 'USA' or 'CAN'";
        break;
        case msgStateNotInCtry:
            messageStr = @"State entered does not exist in selected country";
        break;
        default:
            messageStr = @"Invalid error code entered";
        break;
    }

    return messageStr;
}

// return the RRSState object for 'stateCode'-----------------------------------------------
+ (RRSState *)objectForStateCode:(NSString *)stateCode inContext:(EOEditingContext *)context
{
    id result;
    NSArray *results;
    EOKeyValueQualifier *aQualifier;
    
    result = nil;
    aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"code"
        operatorSelector:EOQualifierOperatorEqual
        value:stateCode];
    results = [RRSState objectsWithQualifier:aQualifier sortOrderings:nil
                        inContext:context];
    if (results.count)
        result = results[0];
    return result;
}

// return the RRSState object for 'stateName'-----------------------------------------------
+ (RRSState *)objectForStateName:(NSString *)stateName inContext:(EOEditingContext *)context;
{
    id result;
    NSArray *results;
    EOKeyValueQualifier *aQualifier;
    
    result = nil;
    aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"name"
        operatorSelector:EOQualifierOperatorEqual
        value:stateName];
    results = [RRSState objectsWithQualifier:aQualifier sortOrderings:nil
                        inContext:context];
    if (results.count)
        result = results[0];
    return result;
}

// return the RRSCountry object for 'countryCode'-------------------------------------------
+ (RRSCountry *)objectForCountryCode:(NSString *)countryCode inContext:(EOEditingContext *)context
{
    id result;
    NSArray *results;
    EOKeyValueQualifier *aQualifier;
    
    result = nil;
    aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"code"
        operatorSelector:EOQualifierOperatorCaseInsensitiveLike
        value:countryCode];
    results = [RRSCountry objectsWithQualifier:aQualifier sortOrderings:nil
                        inContext:context];
    if (results.count)
        result = results[0];
    return result;
}

// return the RRSCountry object for 'countryName'-------------------------------------------
+ (RRSCountry *)objectForCountryName:(NSString *)countryName inContext:(EOEditingContext *)context
{
    id result;
    NSArray *results;
    EOKeyValueQualifier *aQualifier;
    
    result = nil;
    aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"name"
        operatorSelector:EOQualifierOperatorCaseInsensitiveLike
        value:countryName];
    results = [RRSCountry objectsWithQualifier:aQualifier sortOrderings:nil
                        inContext:context];
    if (results.count)
        result = results[0];
    return result;
}

// return the RRSCountry object for 'countryName'-------------------------------------------
+ (RRSCountry *)objectForCountryISO_2LetterCode:(NSString *)countryCode inContext:(EOEditingContext *)context
{
    id result;
    NSArray *results;
    EOKeyValueQualifier *aQualifier;
    
    result = nil;
    aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"twoCharCode"
										 operatorSelector:EOQualifierOperatorCaseInsensitiveLike
													value:countryCode];
    results = [RRSCountry objectsWithQualifier:aQualifier sortOrderings:nil
									 inContext:context];
    if (results.count)
        result = results[0];
    return result;
}

// return the RRSCountry object with id equal to 'countryNumber'----------------------------
+ (RRSCountry *)objectForCountryNumber:(long)countryNumber inContext:(EOEditingContext *)context
{
    id result;
    NSArray *results;
    EOKeyValueQualifier *aQualifier;
    
    result = nil;
    aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"idNum"
        operatorSelector:EOQualifierOperatorEqual
        value:[NSNumber numberWithLong:countryNumber]];
    results = [RRSCountry objectsWithQualifier:aQualifier sortOrderings:nil
                        inContext:context];
    if (results.count)
        result = results[0];
    return result;
    
}

// return an array containing all of the state objects sorted by code-----------------------
+ (NSArray *)allStateObjectsInContext:(EOEditingContext *)context
{
    return [RRSState objectsInContext:context];
}

// return an array containing all state objects sorted by name------------------------------
+ (NSArray *)allStateObjectsSortedByNameInContext:(EOEditingContext *)context
{
    NSArray *cache = [RRSState objectsInContext:context];
    return [cache sortedArrayUsingComparator:^NSComparisonResult(RRSState *obj1, RRSState *obj2) {
        return [obj1.name compare:obj2.name];
    }];
}

// return an array containing all country objects sorted by idNum---------------------------
+ (NSArray *)allCountryObjectsInContext:(EOEditingContext *)context
{
    return [RRSCountry objectsInContext:context];
}

// return an array containing all country objects sorted by code----------------------------
+ (NSArray *)allCountryObjectsSortedByCodeInContext:(EOEditingContext *)context
{
    NSArray *cache = [RRSCountry objectsInContext:context];
    return [cache sortedArrayUsingComparator:^NSComparisonResult(RRSCountry *obj1, RRSCountry *obj2) {
        return [obj1.code compare:obj2.code];
    }];
}

// return an array containing all country objects sorted by name----------------------------
+ (NSArray *)allCountryObjectsSortedByNameInContext:(EOEditingContext *)context
{
    NSArray *cache = [RRSCountry objectsInContext:context];
    return [cache sortedArrayUsingComparator:^NSComparisonResult(RRSCountry *obj1, RRSCountry *obj2) {
        return [obj1.name compare:obj2.name];
    }];
}

// validate state and country codes and make sure they correspond---------------------------
+ (short)validateState:(NSString *)stateCode andCountry:(NSString *)countryCode inContext:(EOEditingContext *)context
{
    short       errorNo;
    RRSState	*currentState;
    RRSCountry	*currentCountry = nil;

    // first validate the state code
    currentState = [self validateState:stateCode errorCode:&errorNo inContext:context];

    if (! errorNo)
        currentCountry = [self validateCountry:countryCode errorCode:&errorNo inContext:context];

    if (! errorNo)
    {
        if (currentState)
        {
            if ([currentState country] != currentCountry)
                errorNo = msgStateNotInCtry;
        }
        else
            if ([currentCountry isUSA] || [currentCountry isCanada])
                errorNo = msgStateNotSupplied;
    }

    return errorNo;
}

@end
