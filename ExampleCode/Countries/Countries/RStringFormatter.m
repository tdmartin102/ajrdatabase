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

#import "RStringFormatter.h"

#define SFUpperCaseOnly @"SFUpperCaseOnly"
#define SFStringLengh @"SFStringLength"

// Strip leading and trailing space from a string
NSString *stripString(NSString *srce)
{
    NSRange		r;
    NSUInteger	len;
    NSString	*result;
    NSUInteger	index;
    
    len = [srce length];
    r.location = 0;
    r.length = len;
    result = @"";
    
    if (len)
    {
        // set starting location to the first non blank character
        for (index=0; [srce characterAtIndex:index] <= 0x20; ++index)
        {
            --r.length;
            ++r.location;
            if (r.length == 0)
                break;
        }
        
        if (r.length > 1)
        {
            // find the first non blank character starting from the end of the string
            for (index=len-1; [srce characterAtIndex:index] <= 0x20; --index)
                --r.length;
        }
        
        if (r.length > 0)
        {
            if (r.length != len)
                result = [srce substringWithRange:r];
            else
                result = srce;
        }
    }
    
    return result;
}

@implementation RStringFormatter

+ (void)initialize
{
    if ([self class] == [RStringFormatter class])
        [[self class] setVersion:2];
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _stripString = YES;
    }
    return self;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString
           errorDescription:(NSString **)error
{
    NSString *upString;
    if (self.stringLength > 0)
    {
    	if ([partialString length] > self.stringLength)
        {
            NSBeep();
            *newString = nil;
            return NO;
        }
    }

    if (self.upperCaseOnly)
    {
    	upString = [partialString uppercaseString];
        if ([upString compare:partialString] == NSOrderedSame)
            return YES;
        else
        {
            *newString = upString;
            return NO;
        }
    }
    return YES;
}

//------- Overriding base class methods
- (NSString *)stringForObjectValue:(id)anObject
{
    NSString    *result;
    NSUInteger  len;
    
    result = nil;
    if ([anObject isKindOfClass:[NSString class]])
    {
        if (_stripString)
            result = stripString((NSString *)anObject);
        else
            result = [(NSString *)anObject copy];
    }
    else if ([anObject isKindOfClass:[NSNumber class]])
    {
        result = [(NSNumber *)anObject stringValue];
    }
    if (_stringLength && result)
    {
        len = [result length];
        if (len > _stringLength)
            result = [result substringToIndex:(NSUInteger)_stringLength];
    }
    if (_upperCaseOnly && result)
    {
        result = [result uppercaseString];
    }
    
    return result;
}

//--- This just returns the string unless strip is set, then it returns
//    a string without leading or trailing spaces
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    if (anObject)
    {
        *anObject = [self stringForObjectValue:string];
        // *error = nil;
    }
    return YES;
}

- (id)copyWithZone:(NSZone *)zone
{
    RStringFormatter *newFormatter = [super copyWithZone:zone];
    newFormatter->_upperCaseOnly = _upperCaseOnly;
    newFormatter->_stringLength = _stringLength;
    newFormatter->_stripString = _stripString;
    return newFormatter;
}

@end
