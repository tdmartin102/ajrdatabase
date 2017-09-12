/*!
 * @file GeoCodes.h
 * This header contains the definition of the GeoCodes class
*/

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

#import "RRSState.h"
#import "RRSCountry.h"

/*!
 * These codes are returned when validating the state and country object
 */
typedef enum __GeoCodeMessageStatus
{
    msgValid		= 0,        /*!< Valid */
    msgStateInvFmt	= 1,        /*!< Invalid state code provided */
    msgStateNotFound	= 2,    /*!< State Code provided was not found in the database */
    msgCountryInvFmt	= 3,    /*!< Invalid country code provided */
    msgCountryLeftBlank	= 4,    /*!< No country code provided */
    msgCountryNotFound	= 5,    /*!< Country Code provided was not found in the database */
    msgStateNotSupplied	= 6,    /*!< State code was left blank */
    msgStateNotInCtry	= 7     /*!< The state entered does not exist in the selected country */
} GeoCodeMessageStatus;

/*!
 * @class GeoCodes
 * Class for managing state and country objects
 *
 */
@interface GeoCodes : NSObject

/*!
 * Return the state object given the state code
 */
+ (RRSState *)objectForStateCode:(NSString *)stateCode inContext:(EOEditingContext *)context;

/*!
 * Return the state object given the state name
 */
+ (RRSState *)objectForStateName:(NSString *)stateName inContext:(EOEditingContext *)context;

/*!
 * Return the country object given the three letter country code
 *
 * This method does a case insensative compare.  Also, Riemer has made a strong effort 
 * to make sure that our 3 letter codes match the ISO 3166 3 letter codes.
 */
+ (RRSCountry *)objectForCountryCode:(NSString *)countryCode inContext:(EOEditingContext *)context;

/*!
 * Return the country object given the two letter country code.
 *
 * This method does a case insensative compare.  Also, Riemer has made a strong effort
 * to make sure that our 2 letter codes match the ISO 3166 2 letter codes.
 */
+ (RRSCountry *)objectForCountryISO_2LetterCode:(NSString *)countryCode inContext:(EOEditingContext *)context;

/*!
 * Return the country object given the country name.
 *
 * It performs a case insensitive compare, but it must be an exact match otherwise.
 */
+ (RRSCountry *)objectForCountryName:(NSString *)countryName inContext:(EOEditingContext *)context;

/*!
 * Return the country object given the country id number
 *
 * The internal country code that Riemer uses.  This has NOTHING to do with the three
 * digit ISO 3166 country codes.
 */
+ (RRSCountry *)objectForCountryNumber:(long)countryNumber inContext:(EOEditingContext *)context;

/*!
 * Return all states in the database
 *
 * Returns an array of RRSState objects representing all states in the database.  
 * These objects are not sorted in any particular order.
 */
+ (NSArray *)allStateObjectsInContext:(EOEditingContext *)context;

/*!
 * Return all states in the database sorted by name
 *
 * Returns an array of RRSState objects representing all states in the database.  
 * The states are sorted in ascending order by name.
 */
+ (NSArray *)allStateObjectsSortedByNameInContext:(EOEditingContext *)context;

/*!
 * Return all countries in the database
 *
 * Returns an array of RRSCountry objects representing all countries in the database.  
 * The objects are not sorted in any particular order.
 */
+ (NSArray *)allCountryObjectsInContext:(EOEditingContext *)context;

/*!
 * Return all countries in the database, sorted by code
 *
 * Returns an array of RRSCountry objects representing all countries in the database.  
 * The objects are sorted in ascending order by the country code.
 */
+ (NSArray *)allCountryObjectsSortedByCodeInContext:(EOEditingContext *)context;

/*!
 * Return all countries in the database, sorted by name
 *
 * Returns an array of RRSCountry objects representing all countries in the database.  
 * The objects are sorted in ascending order by the country name.
 */
+ (NSArray *)allCountryObjectsSortedByNameInContext:(EOEditingContext *)context;

/*!
 * Returns a string that describes the error code passed in
 */
+ (NSString *)messageForCode:(short)errCode;

/*!
 * Validate the state and country
 * This method will make sure that the state and country are both present and 
 * that the state exists in the country.  It will return one of the 
 * GeoCodeMessageStatus constants.
 */
+ (short)validateState:(NSString *)stateCode andCountry:(NSString *)countryCode inContext:(EOEditingContext *)context;

@end
