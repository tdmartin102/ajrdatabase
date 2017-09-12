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

#import "RRSCountry.h"

@implementation RRSCountry
{
    NSMutableArray *_states;
}

+ (NSString *)entityName
{
    return @"COUNTRY";
}

- (instancetype)init
{
	if ((self = [super init]))
	{    
		_region = nil;
		_states = [[NSMutableArray alloc] initWithCapacity:50];
		_name = @"";
		_code = @"";
		_twoCharCode = @"";
	}
    return self;
}

- (void)setCode:(NSString *)value
{
    [self willChange];    
    _code = [value copy];
}

- (void)setTwoCharCode:(NSString *)value
{
    [self willChange];    
    _twoCharCode = [value copy];
}


- (void)setName:(NSString *)value
{
    [self willChange];    
    _name = [value copy];
}

- (void)setStates:(NSArray *)value
{
    [self willChange];
    _states = [value mutableCopy];
}

- (void)addToStates:(id)value
{
    // a to-many relationship
    [self willChange];
    [_states addObject:value];
}

- (void)removeFromStates:(id)value
{
    // a to-many relationship
    [self willChange];
    [_states removeObject:value];
}

- (void)setRegion:(EOGenericRecord *)value
{
    // a to-one relationship
    [self willChange];
    _region = value;
}

- (BOOL) isUSA
{
    return [_code isEqualToString:@"USA"];
}

- (BOOL) isCanada
{
    return [_code isEqualToString:@"CAN"];
}

- (BOOL) isAllLocations
{
    return [_code isEqualToString:@"ALL"];
}

- (BOOL) isUnknown
{
    return [_code isEqualToString:@"UNK"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", _code, _name];
}

@end
