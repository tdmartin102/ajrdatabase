/*!
 * @file GeoCodes.h
 * This header contains the definition of the RRSCountry class
 * which represents the database table COUNTRY
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

#import "RRSeo.h"

#define CountryCodeLen  3  /*!< The number of characters in @ref RRSCountry::code  */
#define CountryNameLen  34 /*!< The maximum number of characters allowed in @ref RRSCountry::name  */

/*! @class RRSCountry
 *  This class represents a country and is used with objects than contain an address such
 *  as @ref RRSAccount and @ref RRSCuAddress.
 */
@interface RRSCountry : RRSeo

/*!
 * Returns the name of the Enterprise Objects entity for this class, which is \@"COUNTRY".  This is also
 * the name of the table in the database.
 */
@property (class, nonatomic, readonly) NSString *entityName;

/*!  A three-letter, uppercase identifier for the country.  It conforms to the ISO published three-character codes */
@property (nonatomic, copy) NSString    *code;
/*!  A two-letter, uppercase identifier for the country.  It conforms to the ISO published two-character codes */
@property (nonatomic, copy) NSString    *twoCharCode;
@property (nonatomic, copy) NSString    *name;          /*!< The name of the country */

//--- Relationships
/*! If the country is US or Canada, this is an array of related @ref RRSState objects */
@property (nonatomic, copy) NSArray *states;
- (void)addToStates:(id)value;
- (void)removeFromStates:(id)value;

@property (nonatomic, retain) EOGenericRecord *region; /*!< Relationship to an object that represents a geographical region */

//====================================================================================
/*!  @name Convenience */
///@{
/*! Returns <code>YES</code> if the receiver is the representation for the United States of America; returns <code>NO</code> otherwise */
@property (nonatomic, readonly) BOOL isUSA;

/*! Returns <code>YES</code> if the receiver is the reprsentation for Canada; returns <code>NO</code> otherwise */
@property (nonatomic, readonly) BOOL isCanada;
/*! 
 * Returns <code>YES</code> if the receiver is not actually a country, but a holder that we use for accounts that 
 * represent all of the locations of a particular company.  Returns <code>NO</code> otherwise. 
 */
@property (nonatomic, readonly) BOOL isAllLocations;

/*!  
 * Returns <code>YES</code> if the receiver is not actually a country, but a holder that we use for unknown
 * countries.  Returns <code>NO</code> otherwise. 
 */
@property (nonatomic, readonly) BOOL isUnknown;

@end
