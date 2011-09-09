//
//  NSPredicate-EOInterface.m
//  EOInterface
//
//  Created by Alex Raftis on 5/12/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NSPredicate-EOInterface.h"

@implementation NSPredicate (EOInterface)

- (NSPredicate *)predicateFromQualifier:(EOQualifier *)qualifier
{
	if ([qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
		return [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:[(EOKeyValueQualifier *)qualifier key]]
																rightExpression:[NSExpression expressionForConstantValue:[(EOKeyValueQualifier *)qualifier value]]
																		 modifier:0 
																			  type:0
																		  options:0];
	} else if ([qualifier isKindOfClass:[EONotQualifier class]]) {
		return nil;
	} else if ([qualifier isKindOfClass:[EOAndQualifier class]]) {
		return nil;
	} else if ([qualifier isKindOfClass:[EOOrQualifier class]]) {
		return nil;
	}
	
	[EOLog logWarningWithFormat:@"Unknown qualifier type: %@", NSStringFromClass([qualifier class])];
	
	return nil;
}

@end
