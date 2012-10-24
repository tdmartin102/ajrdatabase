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

#import "EOKeyValueQualifier-EOAccess.h"

#import "EOAttribute.h"
#import "EODatabase.h"
#import "EOEntityP.h"
#import "EOQualifier-EOAccess.h"
#import "EORelationshipP.h"
#import "EOSQLExpression.h"
#import "EOSQLFormatter.h"
#import "NSObject-EOAccess.h"
#import "EOJoin.h"

#import <EOControl/EOFault.h>
#import <EOControl/EOGenericRecord.h>
#import <EOControl/NSObject-EOEnterpriseObject.h>

@interface EOSQLExpression (Private)

- (void)_setRootEntity:(EOEntity *)entity;

@end

@implementation EOKeyValueQualifier (EOAccess)

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
	NSMutableString		*sql;
	NSString			*aString;
	EOEntity			*entity;
	id					aValue;
	NSArray				*aPath;
	NSObject			*property;
   
	// First, we're going to start looping over the key and pick out '.' separators
	// to determine our key path.
	entity = [expression rootEntity];
   
	// key may be an attribute, or it may be a relationship
	// lets standardize it before we do ANYTHING else
	aPath = [entity _attributesForKeyPath:key];
	if ([aPath count] == 0)
		[NSException raise:NSInternalInconsistencyException format:@"Cannot reach key \"%@\" from entity \"%@\".", key, [entity name]];
	
	sql = [[[NSMutableString alloc] init] autorelease];
	property = [aPath lastObject];
	if ([property isKindOfClass:[EOAttribute class]])
	{
		EOAttribute			*attrib;
		BOOL				isLike;

		// this is an attribute;
		attrib = (EOAttribute *)property;
		aString = [expression sqlStringForAttributePath:aPath];
		if (! [aString length])
			[NSException raise:NSInternalInconsistencyException format:@"Cannot reach key \"%@\" from entity \"%@\".", key, [entity name]];
		
		// since this is a READ we also need to add the read format if any
		if ([[attrib readFormat] length])
			aString = [[expression class] formatSQLString:aString format:[attrib readFormat]];
		
		[sql appendString:[expression sqlPrefixForQualifierOperation:operation value:value]];
		[sql appendString:aString];
		[sql appendString:[expression sqlSuffixForQualifierOperation:operation value:value]];
            
		// Next, we append the operator, but we have to take special case for
		// null values.
		[sql appendString:@" "];
		[sql appendString:[expression sqlStringForQualifierOperation:operation value:value]];
		[sql appendString:@" "];
            
		// Finally, we can append the value. Obviously, we special case null
		// again.
		// IMPORTANT NOTE: All values should be handled by the SQL formatters, and
		// this include array values. If, for some reason, array values aren't being
		// handled correctly, the fix does not belong here, but in the formatters.
		// If this is a like we need to munge the value BEFORE we convert it to SQL
		// so that it can be placed into a bind variable if that option is on.
		isLike = NO;
		if (operation == EOQualifierLike ||
			operation == EOQualifierCaseInsensitiveLike ||
			operation == EOQualifierNotLike ||
			operation == EOQualifierCaseInsensitiveNotLike)
		{
			isLike = YES;
			// a Like HAS to compare to a string.
			if (! [value isKindOfClass:[NSString class]])
				[NSException raise:NSInternalInconsistencyException format:
					@"LIKE operator used on value that is not a string is not allowed for key \"%@\" from entity \"%@\".", 
					key, [entity name]];
			aValue = [[expression class] sqlPatternFromShellPattern:(NSString *)value];
		}
		else
			aValue = value;
		
		// NOW get the sql for the value and create the bind if binding is on	
		aString = [expression sqlStringForValue:aValue attribute:attrib];
	
		[sql appendString:[expression sqlPrefixForQualifierOperation:operation value:value]];
		[sql appendString:aString];
		[sql appendString:[expression sqlSuffixForQualifierOperation:operation value:value]];
	
		// if this is a like operation we need to append the escape clause
		if (isLike)
			[sql appendString:@" ESCAPE '\\'"];
	}
	else
	{
		EORelationship	*r;
		NSArray			*joins;
		EOJoin			*j;
		BOOL			first;
		int				count;
		id				rValue;
		id				enumArray;
		
		// this is a relationship in which case the value should be the destination entity OBJECT
		// I STILL need to register the path, in order to build the join
		[expression sqlStringForAttributePath:aPath];
		// now we need destination attribute = value for destinary key, for all joins
		// this could fail on several levels.  if the operation was no equals then it is invalid yet
		// we are ignoring it.  If the value is not THE destination entity object then...  it 
		// should be invalid, yet we did not check.
		r = (EORelationship *)property;
		joins = [r joins];
		count = [joins count];
		first = YES;
		if (count != 1) [sql appendString:@"("];
		enumArray = [joins objectEnumerator];
		while ((j = [enumArray nextObject]) != nil)
		{
			if (! first)
				[sql appendString:@" AND "];
			first = NO;
            // Tom.Martin @ Riemer.com 2012-10-24
            // This may or may not be a fault.  If it IS a fault, then there is no snapshot.
            // The most likely case it that this is to-one relationship.  If so, then
            // the EOFault can supply the value from the fault without firing as the value
            // would be part of the primary key.  If this is a to-many, then the fault may have to fire.
            // In any case, we would get the value from the object not the snapshot.
            // Note:  I am not certain whether firing a fault at this level is okay.  In
            // other words, Could this method be called while doing a fetch.  I don't think so.
            if ([EOFault isFault:value])
                rValue = [value valueForKey:[[j destinationAttribute] name]];
            else
                rValue = [[value snapshot] valueForKey:[[j destinationAttribute] name]];
			[sql appendString:[expression sqlStringForAttribute:[j sourceAttribute]]];
			[sql appendString:@" "];
			[sql appendString:[expression sqlStringForQualifierOperation:EOQualifierEquals value:rValue]];
			[sql appendString:@" "];
			[sql appendString:[expression sqlStringForValue:rValue withQualifierOperation:EOQualifierEquals inAttribute:[j destinationAttribute]]];

		}
		if (count != 1) [sql appendString:@")"];
	}

	return sql;
}

// mont_rothstein @ yahoo.com 2004-12-02
// Major re-work of this method to handle flattened attributes,
// IN operations, and generally clean it up.
// 2006-10-13 AJR
// Once again, this method needed some major work. Mont actually seems to have
// misunderstood how some of the joining works. The end effect was that when
// you were search for relationship = object, it didn't produce the correct
// results. It was actually over joining when it only needs to check the 
// foreign keys. Plus, in that case, you don't need to add the destination entity,
// since you're not actually joining to it.
//
// I also moved a bunch of the logic for generating SQL out of the qualifier and
// into the expression. This will more easily allow the adaptors to override 
// behavior as needed.
/*
- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
   int               x, length, start;
   char              character;
   NSMutableString   *sql;
   EOEntity          *entity;
   
   // First, we're going to start looping over the key and pick out '.' separators
   // to determine our key path.
   length = [key length];
   start = 0;
   sql = [[[NSMutableString alloc] init] autorelease];
   entity = [expression rootEntity];
   for (x = 0; x <= length; x++) {
      if (x == length || (character = [key characterAtIndex:x]) == '.') {
         NSString    *subkey = [key substringWithRange:(NSRange){start, x - start}];
         id          property;
         
         start = x + 1;
         
         if ((property = [entity attributeNamed:subkey]) != nil) 
		 {
            // This is the fairly easy case, where we just append the subkey, operation,
            // and value.
            
            // First, append the subkey
            [sql appendString:[expression sqlPrefixForQualifierOperation:operation value:value]];
            [sql appendString:[expression sqlStringForAttributeNamed:subkey inEntity:entity]];
            [sql appendString:[expression sqlSuffixForQualifierOperation:operation value:value]];
            [sql appendString:@" "];
            
            // Next, we append the operator, but we have to take special case for
            // null values.
            [sql appendString:[expression sqlStringForQualifierOperation:operation value:value]];
            [sql appendString:@" "];
            
            // Finally, we can append the value. Obviously, we special case null
            // again.
            // IMPORTANT NOTE: All values should be handled by the SQL formatters, and
            // this include array values. If, for some reason, array values aren't being
            // handled correctly, the fix does not belong here, but in the formatters.
            [sql appendString:[expression sqlPrefixForQualifierOperation:operation value:value]];
            [sql appendString:[expression sqlStringForValue:value withQualifierOperation:operation inAttribute:property]];
            [sql appendString:[expression sqlSuffixForQualifierOperation:operation value:value]];
         } 
		 else if ((property = [entity relationshipNamed:subkey]) != nil) 
		 {
            if (x == length) {
               // In this case, we're just appending the "join" information.
               NSArray     *joins = [(EORelationship *)property joins];
               int         y, count = [joins count];
               id          rValue;
               EOJoin      *join;
               
               if (count != 1) [sql appendString:@"("];
               for (y = 0; y < count; y++) {
                  join = [joins objectAtIndex:y];
                  if (y >= 1) {
                     [sql appendString:@" AND "];
                  }
                  rValue = [value snapshot];
                  rValue = [rValue valueForKey:[[join destinationAttribute] name]];
                  [sql appendString:[expression sqlStringForAttributeNamed:[[join sourceAttribute] name] inEntity:entity]];
                  [sql appendString:@" "];
                  [sql appendString:[expression sqlStringForQualifierOperation:EOQualifierEquals value:rValue]];
                  [sql appendString:@" "];
                  [sql appendString:[expression sqlStringForValue:rValue withQualifierOperation:EOQualifierEquals inAttribute:[join destinationAttribute]]];
               }
               if (count != 1) [sql appendString:@")"];
            } else {
               // This is actually a fairly easy case, at least within this code
               // block. Basically, we just add the destination entity to the join,
               // which will make sure we get the correct names/aliases for each entity
               // (or table) we're adding to the over all expression.
               
               // First, switch our entity to the relationship's destination entity
               entity = [(EORelationship *)property destinationEntity];
               // Second, add the entity to the expression
               [expression addEntity:entity];
            }
         } else 
		 {
            [NSException raise:NSInternalInconsistencyException format:@"Cannot reach subkey \"%@\" from entity \"%@\".", subkey, [entity name]]; 
         }
      }
   }
   
   return sql;
}


- (NSString *)sqlJoinForSQLExpression:(EOSQLExpression *)expression
{
   int               x, length, start;
   char              character;
   NSMutableString   *sql = nil;
   EOEntity          *entity;
   
   // First, we're going to start looping over the key and pick out '.' separators
   // to determine our key path.
   length = [key length];
   start = 0;
   entity = [expression rootEntity];
   // NOTE: Unlike the preceeding method, we do < length, since in this case,
   // we never care about the last key in the path, only the keys leading up to
   // the last key.
   for (x = 0; x < length; x++) {
      if (x == length || (character = [key characterAtIndex:x]) == '.') {
         NSString       *subkey = [key substringWithRange:(NSRange){start, x - start}];
         EORelationship *relationship;
         
         start = x + 1;
         
         if ((relationship = [entity relationshipNamed:subkey]) != nil) {
            if (sql == nil) {
               sql = [[[NSMutableString alloc] init] autorelease];
            } else {
               [sql appendString:@" AND "];
            }
            [sql appendString:[relationship sqlStringForSQLExpression:expression]];
            // And make sure to advance the entity to the current relationship's
            // destination entity
            entity = [relationship destinationEntity];
         }
      }
   }
   
   return sql;
}
*/

@end
