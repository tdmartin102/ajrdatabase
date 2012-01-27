/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import "EOQualifier.h"

#import "EOFormat.h"
#import "EOGenericRecord.h"
#import "NSObject-EOEnterpriseObject.h"
#import "EOFault.h"

#import <Foundation/Foundation.h>

static EOQualifierOperation EOEOFQualifierEquals;
static EOQualifierOperation EOEOFQualifierLike;
static EOQualifierOperation EOEOFQualifierNotEqual;


@implementation EOKeyValueQualifier

+ (void)initialize
{
   [EOKeyValueQualifier setVersion:2];
	EOEOFQualifierEquals = @selector(isEqualTo:);
	EOEOFQualifierLike = @selector(isLike:);
	EOEOFQualifierNotEqual = @selector(isNotEqualTo:);

}

+ (EOQualifier *)qualifierWithKey:(NSString *)aKey value:(id)aValue
{
   return [[[self alloc] initWithKey:aKey operation:EOQualifierEquals value:aValue] autorelease];
}

+ (EOQualifier *)qualifierWithKey:(NSString *)aKey operation:(EOQualifierOperation)anOperation value:(id)aValue
{
   return [[[self alloc] initWithKey:aKey operation:anOperation value:aValue] autorelease];
}

- (id)initWithKey:(NSString *)aKey value:(id)aValue
{
   return [self initWithKey:aKey operation:EOQualifierEquals value:aValue];
}

- (id)initWithKey:(NSString *)aKey operatorSelector:(SEL)operator value:(id)aValue
{
	return [self initWithKey: aKey operation: (EOQualifierOperation)operator value:aValue];
}

- (void)_checkOperationShouldSetCaseSensitive: (BOOL)shouldSetCaseSensitive
{
	   // ja@sente.ch 2007-11-01
	   // check for supported qualifier operations and convert from EOF selectors
	if (operation == EOEOFQualifierEquals) {
		operation = EOQualifierEquals;
	} else if (operation == EOEOFQualifierNotEqual) {
		operation = EOQualifierNotEquals;
	} else if (operation == EOEOFQualifierLike) {
		operation = EOQualifierLike;
	} else if (
			   (operation == EOQualifierCaseInsensitiveEqual) ||
			   (operation == EOQualifierCaseInsensitiveLike) ||
			   (operation == EOQualifierCaseInsensitiveNotEqual) ||
			   (operation == EOQualifierCaseInsensitiveNotLike)) {
		if (shouldSetCaseSensitive)
			caseSensitive = YES;
	} else if (
			   (operation == EOQualifierEquals) ||
			   (operation == EOQualifierNotEquals) ||
			   (operation == EOQualifierLessThan) ||
			   (operation == EOQualifierLessThanOrEqual) ||
			   (operation == EOQualifierGreaterThanOrEqual) ||
			   (operation == EOQualifierGreaterThan) ||
			   (operation == EOQualifierIn) ||
			   (operation == EOQualifierLike) ||
			   (operation == EOQualifierNotLike)) {
	} else {
		NSLog (@"Warning while initializing EOKeyValueQualifier: unsupported operation: %@", NSStringFromSelector(operation));
	}
	
}

- (void)setOperation: (SEL)anOperation
{
	operation = anOperation;
	[self _checkOperationShouldSetCaseSensitive: YES];
}

- (id)initWithKey:(NSString *)aKey operation:(EOQualifierOperation)anOperation value:(id)aValue
{
	// 2005-05-11 AJR This isn't the correct fix. You've probably just encountered a quirk of Postgres where value=NULL is not the same as value IS null. So, what you actually encountered is an error in the SQL generation, not in the qualifier. Anyways, I've fixed the SQL generation to output "value is null" or "value is not null" where appropriate. Although, we're still left with the question, what happens with greater/less than and null values.
	// mont_rothstein @ yahoo.com 2004-12-03
	// If there is no right hand value, return nil.  Having a qualifier for
	// nil objects causes selects that should return everything to return
	// nothing.  This is true if the value is an array as well, it must
	// have at least one item in the array.
	if ([aValue isKindOfClass:[NSArray class]] && [aValue count] == 0) return nil;
	
	if (self = [super init])
    {
        key = [aKey retain];
        operation = anOperation;
        [self _checkOperationShouldSetCaseSensitive: YES];
        // mont_rothstein @ yahoo.com 2005-07-24
        // If the value is a NSNull then we want to store it as nil
        value = [aValue isKindOfClass: [NSNull class]] ? nil : [aValue retain];
      
        // mont_rothstein @ yahoo.com 2005-05-15
        // If the value is a fault then we need to trip it.  If we don't trip it now then it
        // will be tripped during the fetch, and that could result in an attempt to perform a
        // fetch while one is already in process.
        if ([EOFault isFault: value]) [value self];
    }

   return self;
}

- (void)dealloc
{
   [key release];
   [value release];

   [super dealloc];
}

- (NSString *)stringForOperation:(EOQualifierOperation)op
{
   if (op == EOQualifierEquals) {
      return @"=";
   } else if (op == EOQualifierNotEquals) {
      return @"!=";
   } else if (op == EOQualifierLessThan) {
      return @"<";
   } else if (op == EOQualifierLessThanOrEqual) {
      return @"<=";
   } else if (op == EOQualifierGreaterThan) {
      return @">";
   } else if (op == EOQualifierGreaterThanOrEqual) {
      return @">=";
   } else if (op == EOQualifierIn) {
      return @"IN";
   } else if (op == EOQualifierLike) {
      return @"LIKE";
   } else if (op == EOQualifierCaseInsensitiveLike) {
      return @"LIKE";
   } else if (op == EOQualifierNotLike) {
      return @"NOT LIKE";
   } else if (op == EOQualifierCaseInsensitiveNotLike) {
      return @"NOT LIKE";
   // mont_rothstein@yahoo.com 2006-01-22
   // Added support for EOQualifierCaseInsensitiveEqual.  Note: This is an extension to the WO 4.5 API
   } else if (op == EOQualifierCaseInsensitiveEqual) {
	   return @"=";
   // mont_rothstein@yahoo.com 2006-01-22
   // Added support for EOQualifierCaseInsensitiveNotEqual.  Note: This is an extension to the WO 4.5 API
   } else if (op == EOQualifierCaseInsensitiveNotEqual) {
	   return @"!=";
   }

   return @"NO-OP";
}

// jean_alexis @ users.sourceforge.net 2005-09-08
// Added method
- (EOQualifier *)qualifierWithBindings:(NSDictionary *)_bindings
				  requiresAllVariables:(BOOL)_reqAll
{
	static Class VarClass = Nil;
	id       newValue;
	id myValue = [self value];
	
	if (VarClass == Nil) 
        VarClass = [EOQualifierVariable class];
	
	if ([myValue class] == VarClass) {
		newValue =
		[_bindings objectForKey:[(EOQualifierVariable *)myValue key]];
		if (newValue == nil) {
			if (_reqAll)
				// throw exception
				;
			else
				return nil;
		}
	} else {
		return self;
	}
		
	return [[[[self class] alloc]
                         initWithKey: [self key]
						operatorSelector: [self selector]
								value: newValue]
		autorelease];
}

- (BOOL)evaluateWithObject:(id)object
{
   id otherValue = [object valueForKeyPath: key];

   if (value == nil || otherValue == nil) {
      if (operation == EOQualifierEquals) {
         return value == otherValue;
      } else if (operation == EOQualifierNotEquals) {
         return value != otherValue;
      }
      return NO;
   }

   if ([otherValue isKindOfClass: [NSArray class]]) {
       if ([otherValue count] == 1) {
           otherValue = [otherValue objectAtIndex: 0];
       } else {
           [NSException raise: NSGenericException format: @"keyPath qualifier returned multiples values"];
       }
   }
   
   return [otherValue performSelector:operation withObject:value] != 0;
}

- (NSString *)description
{
	/*! @todo EOKeyValueQualifier: properly format value in description method? */
	if ([value isKindOfClass:[NSNumber class]])
		return EOFormat(@"%@ %@ %@", key, [EOQualifier stringForOperatorSelector:operation], value);
	else
		return EOFormat(@"%@ %@ '%@'", key, [EOQualifier stringForOperatorSelector:operation], value);
}


- (NSString *)key
{
	return key;
}

- (SEL)selector
{
	return (SEL)operation;
}

- (id)value
{
	return value;
}

- (void)setCaseSensitive:(BOOL)flag
{
   caseSensitive = flag;
}

- (BOOL)isCaseSensitive
{
   return caseSensitive;
}

- (id)initWithCoder:(NSCoder *)coder
{
    int   version = [coder versionForClassName:@"EOKeyValueQualifier"];
    BOOL  setCaseSensitiveFromOperation = NO;
   
	self = [super initWithCoder:coder];
    if (! self)
        return nil;
	
	if ([coder allowsKeyedCoding]) {
		key = [[coder decodeObjectForKey:@"key"] retain];
		value = [[coder decodeObjectForKey:@"value"] retain];
		operation = NSSelectorFromString([coder decodeObjectForKey:@"operation"]);
      if (version >= 2) {
         caseSensitive = [coder decodeBoolForKey:@"caseSensitive"];
      } else {
         setCaseSensitiveFromOperation = YES;
      }
	} else {
		key = [[coder decodeObject] retain];
		value = [[coder decodeObject] retain];
		operation = NSSelectorFromString([coder decodeObject]);
      if (version >= 2) {
         [coder decodeValueOfObjCType:@encode(BOOL) at:&caseSensitive];
      } else {
         setCaseSensitiveFromOperation = YES;
      }
	}
   
	[self _checkOperationShouldSetCaseSensitive: setCaseSensitiveFromOperation];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:key forKey:@"key"];
		[coder encodeObject:value forKey:@"value"];
		[coder encodeObject:NSStringFromSelector(operation) forKey:@"operation"];
		[coder encodeBool:caseSensitive forKey:@"caseSensitive"];
	} else {
		[coder encodeObject:key];
		[coder encodeObject:value];
		[coder encodeObject:NSStringFromSelector(operation)];
      [coder encodeValueOfObjCType:@encode(BOOL) at:&caseSensitive];
	}
}

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)unarchiver
{
    NSString *s;
    
    key = [[unarchiver decodeObjectForKey:@"key"] copy];
    value = [[unarchiver decodeObjectForKey:@"value"] retain];
    
    if ((s = [unarchiver decodeObjectForKey:@"selectorName"]) != nil) {
        if (![s hasSuffix:@":"]) s = [s stringByAppendingString:@":"];
        operation = NSSelectorFromString(s);
    }
    else if ((s = [unarchiver decodeObjectForKey:@"selector"]) != nil)
        operation = NSSelectorFromString(s);
    else {
        NSLog(@"WARNING(%s): decoded no selector/selectorName for kv qualifier "
              @"(key=%@)", 
              __PRETTY_FUNCTION__, key);
        operation = EOQualifierOperatorEqual;
    }
    
    if (operation == NULL) {
        NSLog(@"WARNING(%s): decoded no selector for kv qualifier (key=%@)", 
              __PRETTY_FUNCTION__, key);
        operation = EOQualifierOperatorEqual;
    }

	[self _checkOperationShouldSetCaseSensitive: YES];

    return self;
}

- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)archiver
{
    NSString *s;
    
    [archiver encodeObject:[self key] forKey:@"key"];
    [archiver encodeObject:[self value] forKey:@"value"];
    
    s = NSStringFromSelector([self selector]);
//    if ([s hasSuffix:@":"]) s = [s substringToIndex:[s length] - 1];
    [archiver encodeObject:s forKey:@"selectorName"];
}

@end
