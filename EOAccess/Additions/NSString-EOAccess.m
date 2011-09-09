//
//  NSString-EOAccess.m
//  EOAccess/
//
//  Created by Alex Raftis on 10/6/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSString-EOAccess.h"

@implementation NSString (EOAccess)

+ (NSString *)externalNameForInternalName:(NSString *)name separatorString:(NSString *)separatorString useAllCaps:(BOOL)useAllCaps
{
	int					x;
	int					length = [name length];
	NSMutableString	*work = [[[NSMutableString alloc] init] autorelease];
	BOOL					isLower, first;
	NSRange				range;
	NSCharacterSet		*lower = [NSCharacterSet lowercaseLetterCharacterSet];
	NSCharacterSet		*upper = [NSCharacterSet uppercaseLetterCharacterSet];
	
	range.location = 0;
	range.length = 0;
	isLower = NO;
	first = YES;
	for (x = 0; x <= length; x++) {
		unichar		c = 0;
		
		if (x < length) c = [name characterAtIndex:x];
		
		if ([lower characterIsMember:c] && x != length) {
			isLower = YES;
		} else if ([upper characterIsMember:c] || x == length) {
			if (isLower) {
				range.length = x - range.location;
				if (first) {
					first = NO;
				} else {
					[work appendString:separatorString];
				}
				[work appendString:[name substringWithRange:range]];
				range.location = x;
			}
			isLower = NO;
		}
	}
	
	if (useAllCaps) return [work uppercaseString];
	return [work lowercaseString];
}

+ (NSString *)nameForExternalName:(NSString *)name separatorString:(NSString *)separatorString initialCaps:(BOOL)initialCaps;
{
	NSArray				*parts = [[name lowercaseString] componentsSeparatedByString:separatorString];
	NSMutableString	*work = [[[NSMutableString allocWithZone:[name zone]] init] autorelease];
	int					x;
	int numParts;
	
	numParts = [parts count];
	
	for (x = 0; x < numParts; x++) {
		if (x == 0 && !initialCaps) {
			[work appendString:[parts objectAtIndex:x]];
		} else {
			[work appendString:[[parts objectAtIndex:x] capitalizedString]];
		}
	}
	
	return work;
}

@end
