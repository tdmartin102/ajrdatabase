//
//  EONotQualifier.m
//  EOAccess/
//
//  Created by Alex Raftis on 10/7/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EONotQualifier-EOAccess.h"

#import "EOQualifier-EOAccess.h"
#import "EOSQLExpression.h"

@implementation EONotQualifier (EOAccess)

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
   NSMutableString		*string;
	
	string = [[[NSMutableString allocWithZone:[self zone]] initWithString:@"NOT ("] autorelease];
	[string appendString:[qualifier sqlStringForSQLExpression:expression]];
   [string appendString:@")"];
	
   return string;
}

- (NSString *)sqlJoinForSQLExpression:(EOSQLExpression *)expression
{
	// mont_rothstein @ yahoo.com 2005-04-26
	// This was simply calling sqlStringForSQLExpression: on self, which caused the 
	// resulting SQL to be in the final string more than once.  Instead this need to ask its 
	// qualifier for it's sql join.
	return [qualifier sqlJoinForSQLExpression:expression];
}

@end
