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

#import <AppKit/AppKit.h>

/*!
 @class RStringFormatter

 A class that extends the functionality of NSFormatter.
 
 This class implements some options for display strings. 
 This class defines the following string attributes:
 <dl>
   <dt>upperCase</dt>
     <dd>uppper case text only.  Strings are converted to upper case.</dd>
   <dt>stripString</dt>
     <dd>All leading and trailing whitespace is stripped out</dd>
   <dt>stringLength</dt>
     <dd>Strings are truncated to the specified length.</dd>
 </dl>
 */


@interface RStringFormatter :  NSFormatter <NSCoding, NSCopying>

/*!
 * If upperCaseOnly is set then the formatter will convert the string to uppercase when asking
 * for the object value.
 */
@property (assign) BOOL upperCaseOnly;

/*!
 * If stripString is set then the formatter strip out any leading and trailing white space from the input string.
 * By default stripString is YES.
 */
@property (assign) BOOL stripString;

/*!
 * If stringLength is set then the formatter will truncate the string to the specified length if
 * it exceeds the length.  Length is not bytes but rather characters.
 */
@property (assign) int stringLength;


@end
