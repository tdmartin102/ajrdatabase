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

#import "EOAndQualifier.h"
#import "EODefines.h"
#import "EOKeyValueQualifier.h"
#import "EOOrQualifier.h"
#import "EOQualifierParser.h"

EOQualifierOperation EOQualifierEquals;
EOQualifierOperation EOQualifierNotEquals;
EOQualifierOperation EOQualifierLessThan;
EOQualifierOperation EOQualifierLessThanOrEqual;
EOQualifierOperation EOQualifierGreaterThan;
EOQualifierOperation EOQualifierGreaterThanOrEqual;
EOQualifierOperation EOQualifierIn;
EOQualifierOperation EOQualifierLike;
EOQualifierOperation EOQualifierCaseInsensitiveLike;
EOQualifierOperation EOQualifierNotLike;
EOQualifierOperation EOQualifierCaseInsensitiveNotLike;

// mont_rothstein@yahoo.com 2006-01-22
// Added support for EOQualifierCaseInsensitiveEqual and EOQualifierCaseInsensitiveNotEqual.  Note: These are extensions to the WO 4.5 API.
EOQualifierOperation EOQualifierCaseInsensitiveEqual;
EOQualifierOperation EOQualifierCaseInsensitiveNotEqual;


@implementation EOQualifier

+ (void)load
{
   if (EOQualifierEquals == NULL) {
      EOQualifierEquals							= @selector(qualifierEquals:);
      EOQualifierNotEquals						= @selector(qualifierNotEquals:);
      EOQualifierLessThan						= @selector(qualifierLessThan:);
      EOQualifierLessThanOrEqual				= @selector(qualifierLessThanOrEqual:);
      EOQualifierGreaterThan					= @selector(qualifierGreaterThan:);
      EOQualifierGreaterThanOrEqual			= @selector(qualifierGreaterThanOrEqual:);
      EOQualifierIn								= @selector(qualifierIn:);
      EOQualifierLike							= @selector(qualifierLike:);
      EOQualifierCaseInsensitiveLike		= @selector(qualifierCaseInsensitiveLike:);
      EOQualifierNotLike						= @selector(qualifierNotLike:);
      EOQualifierCaseInsensitiveNotLike	= @selector(qualifierCaseInsensitiveNotLike:);
	  // mont_rothstein@yahoo.com 206-01-22
	  // Added support for EOQualifierCaseInsensitiveEqual and EOQualifierCaseInsensitiveNotEqual.  Note: These are extensions to the WO 4.5 API.
	  EOQualifierCaseInsensitiveEqual = @selector(qualifierCaseInsensitiveEqual:);
	  EOQualifierCaseInsensitiveNotEqual = @selector(qualifierCaseInsensitiveNotEqual:);
   }
}

+ (id)qualifierWithQualifierFormat:(NSString *)format, ...
{
	id			result;
	va_list	ap;
	
	va_start(ap, format);
	result = [self qualifierWithQualifierFormat:format varargList:ap];
	va_end(ap);
	
	return result;
}

// mont_rothsetin @ yahoo.com 2004-12-02
// Renamed this method to comply with WO 4.5 API.
+ (id)qualifierWithQualifierFormat:(NSString *)format varargList:(va_list)args
{
	EOQualifierParser	*parser;
	EOQualifier			*qualifier;
	
	parser = [[EOQualifierParser alloc] initWithString:format varargList:args];
	qualifier = [parser qualifier];
	[parser release];
	
	return qualifier;
}

+ (id)qualifierWithQualifierFormat:(NSString *)format arguments:(NSArray *)args
{
	EOQualifierParser	*parser;
	EOQualifier			*qualifier;
	
	parser = [[EOQualifierParser alloc] initWithString:format arguments:args];
	qualifier = [parser qualifier];
	[parser release];
	
	return qualifier;
}

+ (id)qualifierToMatchAllValues:(NSDictionary *)values
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	NSEnumerator		*enumerator = [values keyEnumerator];
	NSString				*key;
	
	while ((key = [enumerator nextObject])) {
		id				value = [values objectForKey:key];
		EOQualifier	*qualifier;
		
		qualifier = [[EOKeyValueQualifier alloc] initWithKey:key value:value];
		[array addObject:qualifier];
		[qualifier release];
	}
	
	return [EOAndQualifier qualifierWithArray:[array autorelease]];
}

+ (id)qualifierToMatchAnyValue:(NSDictionary *)values
{
	NSMutableArray		*array = [[NSMutableArray alloc] init];
	NSEnumerator		*enumerator = [values keyEnumerator];
	NSString				*key;
	
	while ((key = [enumerator nextObject])) {
		id				value = [values objectForKey:key];
		EOQualifier	*qualifier;
		
		qualifier = [[EOKeyValueQualifier alloc] initWithKey:key value:value];
		[array addObject:qualifier];
		[qualifier release];
	}
	
	return [EOOrQualifier qualifierWithArray:[array autorelease]];
}

- (EOQualifier *)qualifierWithBindings:(NSDictionary *)bindings requiresAllVariables:(BOOL)requiresAll
{
/*! @todo Implement */
	return nil;
}

+ (SEL)operatorSelectorForString:(NSString *)aString
{
	if ([aString isEqualToString:@"="]) return EOQualifierEquals;
	if ([aString isEqualToString:@"=="]) return EOQualifierEquals;
	if ([aString isEqualToString:@"!="]) return EOQualifierNotEquals;
	if ([aString isEqualToString:@"<>"]) return EOQualifierNotEquals;
	if ([aString isEqualToString:@"<"]) return EOQualifierLessThan;
	if ([aString isEqualToString:@"<="]) return EOQualifierLessThanOrEqual;
	if ([aString isEqualToString:@">"]) return EOQualifierGreaterThan;
	// mont_rothstein @ yahoo.com 2004-12-19
	// This greater than or equal had a typo, it was <=, fixed it.
	if ([aString isEqualToString:@">="]) return EOQualifierGreaterThanOrEqual;
	if ([aString caseInsensitiveCompare:@"IN"] == NSOrderedSame) return EOQualifierIn;
	if ([aString caseInsensitiveCompare:@"LIKE"] == NSOrderedSame) return EOQualifierLike;
	if ([aString caseInsensitiveCompare:@"CASEINSENSITIVELIKE"] == NSOrderedSame) return EOQualifierCaseInsensitiveLike;
	// mont_rothstein@yahoo.com 206-01-22
	// Added support for EOQualifierCaseInsensitiveEqual and EOQualifierCaseInsensitiveNotEqual.  Note: These are extensions to the WO 4.5 API.
	if ([aString caseInsensitiveCompare:@"CASEINSENSITIVEEQUAL"] == NSOrderedSame) return EOQualifierCaseInsensitiveEqual;
	if ([aString caseInsensitiveCompare:@"CASEINSENSITIVENOTEQUAL"] == NSOrderedSame) return EOQualifierCaseInsensitiveNotEqual;
	
	return NULL;
}

+ (NSString *)stringForOperatorSelector:(SEL)aSelector
{
	if (aSelector == EOQualifierEquals) return @"=";
	if (aSelector == EOQualifierNotEquals) return @"!=";
	if (aSelector == EOQualifierLessThan) return @"<";
	if (aSelector == EOQualifierLessThanOrEqual) return @"<=";
	if (aSelector == EOQualifierGreaterThan) return @">";
	if (aSelector == EOQualifierGreaterThanOrEqual) return @">=";
	if (aSelector == EOQualifierIn) return @"IN";
	if (aSelector == EOQualifierLike) return @"LIKE";
	if (aSelector == EOQualifierCaseInsensitiveLike) return @"CASEINSENSITIVELIKE";
	// mont_rothstein@yahoo.com 206-01-22
	// Added support for EOQualifierCaseInsensitiveEqual and EOQualifierCaseInsensitiveNotEqual.  Note: These are extensions to the WO 4.5 API.
	if (aSelector == EOQualifierCaseInsensitiveEqual) return @"CASEINSENSITIVEEQUAL";
	if (aSelector == EOQualifierCaseInsensitiveNotEqual) return @"CASEINSENSITIVENOTEQUAL";
	
	if (aSelector == @selector(isEqualTo:)) return @"=";
	if (aSelector == @selector(isNotEqualTo:)) return @"!=";
	if (aSelector == @selector(isLessThan:)) return @"<";
	if (aSelector == @selector(isLessThanOrEqualTo:)) return @"<=";
	if (aSelector == @selector(isGreaterThan:)) return @">";
	if (aSelector == @selector(isGreaterThanOrEqualTo:)) return @">=";
	if (aSelector == @selector(doesContain:)) return @"IN";
	if (aSelector == @selector(isLike:)) return @"LIKE";
	if (aSelector == @selector(isCaseInsensitiveLike:)) return @"CASEINSENSITIVELIKE";

    [NSException raise: NSGenericException format: @"Unsupported selector: %@", NSStringFromSelector(aSelector)];
	return nil;
}

static NSArray		*_eoAllOperators = nil;
static NSArray		*_eoRelationalOperators = nil;

+ (NSArray *)allQualifierOperators
{
	if (_eoAllOperators == nil) {
		// mont_rothstein@yahoo.com 2006-01-22
		// Added support for CASEINSENSITIVEEQUAL and CASEINSENSITIVENOTEQUAL.  Note: These are extensions to the WO 4.5 API.
			_eoAllOperators = [[NSArray alloc] initWithObjects:@"=", @"!=", @"<", @"<=", @">", @">=", @"IN", @"LIKE", @"CASEINSENSITIVELIKE", @"CASEINSENSITIVEEQUAL", @"CASEINSENSITIVENOTEQUAL", nil];
	}
	return _eoAllOperators;
}

+ (NSArray *)relationalQualifierOperators
{
	if (_eoRelationalOperators == nil) {
			_eoRelationalOperators = [[NSArray alloc] initWithObjects:@"=", @"!=", @"<", @"<=", @">", @">=", nil];
	}
	return _eoRelationalOperators;
}

- (BOOL)evaluateWithObject:(id)object
{
   [NSException raise:EOException format:@"Subclasses of EOQualifier must implement %@.", NSStringFromSelector(_cmd)];
   return NO;
}

- (NSString *)description
{
   [NSException raise:EOException format:@"Subclasses of EOQualifier must implement %@.", NSStringFromSelector(_cmd)];
}

- (id)initWithCoder:(NSCoder *)coder
{
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
}

@end
