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

#import "EORelationship.h"

#import "EOAttribute.h"
#import "EOEntityP.h"
#import "EOJoinP.h"
#import "EOJoinQualifier.h"
#import "EOModelP.h"
#import "EOModelGroup.h"
#import "NSString-EOAccess.h"

#import <EOControl/EOControl.h>

NSString *EORelationshipDidChangeNameNotification = @"EORelationshipDidChangeNameNotification";

@implementation EORelationship

- (id)init
{
	if (self = [super init])
		joins = [[NSMutableArray allocWithZone:[self zone]] init];
	return self;
}

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
   NSString		*temp;
   NSArray		*someJoins;
   NSInteger    x, max;
   NSString     *destinationName;
#if !defined(STRICT_EOF)
	// mont_rothstein @ yahoo.com 2004-12-20
	// The following variable is used in the unarchiving of sort orderings
   NSArray		*someOrderings;
#endif

	if ((self = [super init]) == nil)
		return nil;
   
   entity = owner;
   name = [[properties objectForKey:@"name"] retain];

   destinationName = [[properties objectForKey:@"destination"] retain];
   if (destinationName == nil) {
      definition = [[properties objectForKey:@"definition"] retain];
   } else {
      [destinationEntity release];
      destinationEntity = [[[[entity model] modelGroup] entityNamed:destinationName] retain];
      if (destinationEntity == nil) {
			[EOLog logWarningWithFormat:@"No destination entity named \"%@\"\n", destinationName];
      }
       [destinationName release];

      someJoins = [[properties objectForKey:@"joins"] retain];
      max = [someJoins count];
      joins = [[NSMutableArray allocWithZone:[self zone]] init];
      for (x = 0; x < max; x++) {
         NSDictionary	*joinData = [someJoins objectAtIndex:x];
         EOAttribute		*source, *destination;
         EOJoin			*join;

         source = [entity attributeNamed:[joinData objectForKey:@"sourceAttribute"]];
         destination = [destinationEntity attributeNamed:[joinData objectForKey:@"destinationAttribute"]];

         join = [[EOJoin allocWithZone:[self zone]] initWithSourceAttribute:source destinationAttribute:destination];
         [joins addObject:join];
			[EOObserverCenter addObserver:self forObject:join];
         [join release];
      }
       [someJoins release];

      isToMany = [[properties objectForKey:@"isToMany"] hasPrefix:@"Y"];
      ownsDestination = [[properties objectForKey:@"ownsDestination"] hasPrefix:@"Y"];
      propagatesPrimaryKey = [[properties objectForKey:@"propagatesPrimaryKey"] hasPrefix:@"Y"];
   }

   temp = [properties objectForKey:@"joinSemantic"];
   if ([temp isEqualToString:@"EOInnerJoin"])           joinSemantic = EOInnerJoin;
   else if ([temp isEqualToString:@"EOFullOuterJoin"])  joinSemantic = EOFullOuterJoin;
   else if ([temp isEqualToString:@"EOLeftOuterJoin"])  joinSemantic = EOLeftOuterJoin;
   else if ([temp isEqualToString:@"EORightOuterJoin"]) joinSemantic = EORightOuterJoin;
	
   temp = [properties objectForKey:@"deleteRule"];
   if ([temp isEqualToString:@"EODeleteRuleNullify"])			deleteRule = EODeleteRuleNullify;
   else if ([temp isEqualToString:@"EODeleteRuleCascade"])	deleteRule = EODeleteRuleCascade;
   else if ([temp isEqualToString:@"EODeleteRuleDeny"])		deleteRule = EODeleteRuleDeny;
   else if ([temp isEqualToString:@"EODeleteRuleNoAction"])	deleteRule = EODeleteRuleNoAction;
	
	isMandatory = [[properties objectForKey:@"isMandatory"] hasPrefix:@"Y"];
	
	// mont_rothstein@yahoo.com 2006-04-19
	// We have to use an NSScanner to get to unsigned int out of the NSString
	if ([properties objectForKey: @"numberOfToManyFaultsToBatchFetch"]) 
	{
		long long numFaults;
		NSScanner *numberScanner;
		
		numberScanner = [NSScanner scannerWithString: [properties objectForKey: @"numberOfToManyFaultsToBatchFetch"]];
		[numberScanner scanLongLong: &numFaults];
		batchSize = (unsigned int)numFaults;
	}

	userInfo = [[properties objectForKey:@"userInfo"] mutableCopyWithZone:[self zone]];

#if !defined(STRICT_EOF)
	// mont_rothstein @ yahoo.com 2004-12-20
	// Added retrieval of sort orderings from model.  These will be used by array faults 
	// when fetching.
	someOrderings = [properties objectForKey: @"sortOrderings"];
	max = [someOrderings count];
	if (max) sortOrderings = [[NSMutableArray alloc] init];
	
	for (x = 0; x < max; x++)
	{
		NSDictionary *orderingDict;
		EOSortOrdering *sortOrdering;
		
		orderingDict = [someOrderings objectAtIndex: x];
		sortOrdering = [EOSortOrdering sortOrderingWithKey: [orderingDict objectForKey: @"key"]
												  selector: NSSelectorFromString([orderingDict objectForKey: @"selector"])];
		[sortOrderings addObject: sortOrdering];
	}
	
	// mont_rothstein @ yahoo.com 2005-03-16
	// Added retrieval of restricting qualifier from model.  This will be used by array 
	// fault when fetching.
	if ([properties objectForKey:@"restrictingQualifier"]) {
		[self setRestrictingQualifier: [EOQualifier qualifierWithQualifierFormat:[properties objectForKey:@"restrictingQualifier"]]];
	}
#endif
	
   return self;
}

- (void)dealloc
{
   [name release];
   [destinationEntity release];
   [joins release];
   [definition release];
#if !defined(STRICT_EOF)
// mont_rothstein @ yahoo.com 2004-12-20
// Added sortOrderings method to be used by faults when fetching.
   [sortOrderings release];
   [restrictingQualifier release];
#endif
   
   [super dealloc];
}

- (void)awakeWithPropertyList:(NSDictionary *)properties
{
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	if (name) [properties setObject:name forKey:@"name"];
	if (deleteRule != EODeleteRuleNullify) {
		switch (deleteRule) {
			case EODeleteRuleNullify:
				[properties setObject:@"EODeleteRuleNullify" forKey:@"deleteRule"];
				break;
			case EODeleteRuleCascade:
				[properties setObject:@"EODeleteRuleCascade" forKey:@"deleteRule"];
				break;
			case EODeleteRuleDeny:
				[properties setObject:@"EODeleteRuleDeny" forKey:@"deleteRule"];
				break;
			case EODeleteRuleNoAction:
				[properties setObject:@"EODeleteRuleNoAction" forKey:@"deleteRule"];
				break;
		}
	}
	if (definition) [properties setObject:definition forKey:@"definition"];
	if (!definition) {
		NSMutableArray		*joinArray;
		NSInteger			x;
		NSInteger           numJoins;
		
		switch (joinSemantic) {
			case EOInnerJoin:
				[properties setObject:@"EOInnerJoin" forKey:@"joinSemantic"];
				break;
			case EOFullOuterJoin:
				[properties setObject:@"EOFullOuterJoin" forKey:@"joinSemantic"];
				break;
			case EOLeftOuterJoin:
				[properties setObject:@"EOLeftOuterJoin" forKey:@"joinSemantic"];
				break;
			case EORightOuterJoin:
				[properties setObject:@"EORightOuterJoin" forKey:@"joinSemantic"];
				break;
		}
		[properties setObject:isToMany ? @"Y" : @"N" forKey:@"isToMany"];
		if (destinationEntity) [properties setObject:[destinationEntity name] forKey:@"destination"];
      if (ownsDestination) [properties setObject:@"Y" forKey:@"ownsDestination"];
      if (propagatesPrimaryKey) [properties setObject:@"Y" forKey:@"propagatesPrimaryKey"];
		
		joinArray = [[NSMutableArray allocWithZone:[self zone]] init];
		numJoins = [joins count];
		for (x = 0; x < numJoins; x++) {
			EOJoin			*join = [joins objectAtIndex:x];
			NSDictionary	*dictionary;
			
			dictionary = [[NSDictionary allocWithZone:[self zone]] initWithObjectsAndKeys:[[join sourceAttribute] name], @"sourceAttribute", [[join destinationAttribute] name], @"destinationAttribute", nil];
			[joinArray addObject:dictionary];
			[dictionary release];
		}
		[properties setObject:joinArray forKey:@"joins"];
		[joinArray release];
	}
	if (isMandatory) [properties setObject:@"Y" forKey:@"isMandatory"];
	if (batchSize != 0) [properties setObject:[NSNumber numberWithUnsignedInt:batchSize] forKey:@"numberOfToManyFaultsToBatchFetch"];
	if (userInfo) [properties setObject:userInfo forKey:@"userInfo"];
	
#if !defined(STRICT_EOF)
	// mont_rothstein @ yahoo.com 2004-12-20
	// Added encoding of sortOrderings.  sortOrderings are used by faults when fetching.
	if (sortOrderings)
	{
		NSMutableArray *orderingArray;
		NSInteger       index;
		NSInteger       numSortOrderings;
		
		orderingArray = [[NSMutableArray allocWithZone:[self zone]] init];
		
		numSortOrderings = [sortOrderings count];
		for (index = 0; index < numSortOrderings; index++) 
		{
			EOSortOrdering *ordering;
			NSDictionary	*dictionary;
			
			ordering = [sortOrderings objectAtIndex: index];
			dictionary = [[NSDictionary allocWithZone:[self zone]] initWithObjectsAndKeys:[ordering key], @"key", NSStringFromSelector([ordering selector]), @"selector", nil];
			[orderingArray addObject:dictionary];
			[dictionary release];
		}
		[properties setObject:orderingArray forKey:@"sortOrderings"];
		[orderingArray release];
	}
	
	// mont_rothstein @ yahoo.com 2005-03-16
	// Added encoding of restricting qualifier.  Restricting qualifier is used by faults
	// when fetching.
	if (restrictingQualifier) [properties setObject:[restrictingQualifier description] forKey:@"restrictingQualifier"];

#endif	
}

- (void)initializeDefinition
{
   // This is done separately, because we can't determine this feature until our entity has initialized all it's relationships.
   if (definition != nil && !definitionIsInitialized) {
      NSArray		*path;
      NSInteger     x, max;

      definitionIsInitialized = true;

      path = [entity _attributesForKeyPath:definition];
      [destinationEntity release];
      destinationEntity = [[(EORelationship *)[path lastObject] destinationEntity] retain];
      if (destinationEntity == nil) {
			[EOLog logWarningWithFormat:@"No destination for flattened relationship \"%@\"\n", definition];
      }

      isToMany = false;
      for (x = 0, max = [path count]; x < max; x++) {
         if ([[path objectAtIndex:x] isToMany]) {
            isToMany = YES;
            break;
         }
      }
   }
}

- (void)beautifyName
{
	[self setName:[NSString nameForExternalName:name separatorString:@"_" initialCaps:NO]];
}

- (void)setName:(NSString *)aName
{
   if (name != aName && ![name isEqualToString:aName]) {
		NSString		*oldName = [name retain];
		
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[(EORelationship *)[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setName:name];
		}
      [name release];
      name = [aName retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EORelationshipDidChangeNameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
		[oldName release];
   }
}

- (NSString *)name
{
   return name;
}

- (NSException *)validateName:(NSString *)aName
{
	NSString		*error = [EOModel _validateName:aName];
	
	if (!error && [entity attributeNamed:aName] != nil) {
		error = @"Another attribute with that name already exists.";
	}
	if (!error && [[entity model] storedProcedureNamed:aName]) {
		error = @"A stored procedure already exists with that name.";
	}
	
	if (error)  [NSException raise:NSInvalidArgumentException format:@"%@", error];
	
	return nil;
}

- (void)addJoin:(EOJoin *)join
{
	// Only add a join if it's not already in present
	if ([joins indexOfObjectIdenticalTo:join] == NSNotFound) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] removeJoin:join];
		}
		[joins addObject:join];
		[EOObserverCenter addObserver:self forObject:join];
	}
}

- (NSArray *)joins
{
   return joins;
}

- (void)removeJoin:(EOJoin *)join
{
	// Only remove the join if we own it.
	if ([joins indexOfObjectIdenticalTo:join] != NSNotFound) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] addJoin:join];
		}
		[joins removeObjectIdenticalTo:join];
		[EOObserverCenter removeObserver:self forObject:join];
	}
}

- (EOJoinSemantic)joinSemantic
{
   return joinSemantic;
}

- (void)setJoinSemantic:(EOJoinSemantic)aSemantic
{
	if (joinSemantic != aSemantic) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setJoinSemantic:joinSemantic];
		}
		joinSemantic = aSemantic;
	}
}

- (NSArray *)destinationAttributes
{
	return [joins valueForKey:@"destinationAttribute"];
}

- (NSArray *)sourceAttributes
{
	return [joins valueForKey:@"sourceAttribute"];
}

- (NSArray *)componentRelationships
{
	if (definition == nil) return nil;
   [self initializeDefinition];
	return [entity _attributesForKeyPath:definition];
}

- (void)setDefinition:(NSString *)aDefinition
{
   if (definition != aDefinition && ![definition isEqualToString:aDefinition]) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setDefinition:definition];
		}
      [definition release];
      definition = [aDefinition retain];
   }
}

- (NSString *)definition
{
   return definition;
}

- (EORelationship *)anyInverseRelationship
{
	return [self inverseRelationship];
}

- (void)_restoreDestinationEntity:(EOEntity *)anEntity joins:(NSArray *)someJoins
{
   if (destinationEntity != anEntity) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] _restoreDestinationEntity:destinationEntity joins:[[joins copyWithZone:[self zone]] autorelease]];
		}
      [destinationEntity release];
      destinationEntity = [anEntity retain];
		
		// And remove all the joins, since they're no longer valid.
		// NOTE: A possible enhancement would be to leave a join if it's destination attribute existed in the new destination entity.
		[joins removeAllObjects];
		if (someJoins) {
			[joins addObjectsFromArray:someJoins];
		}
	}
}

- (void)_setDestinationEntity:(EOEntity *)anEntity
{
   if (destinationEntity != anEntity) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] _restoreDestinationEntity:destinationEntity joins:[[joins copyWithZone:[self zone]] autorelease]];
		}
      [destinationEntity release];
      destinationEntity = [anEntity retain];

		// And remove all the joins, since they're no longer valid.
		// NOTE: A possible enhancement would be to leave a join if it's destination attribute existed in the new destination entity.
		[joins removeAllObjects];
	}
}

- (EOEntity *)destinationEntity
{
   if (definition != nil) [self initializeDefinition];
   return destinationEntity;
}

- (EOEntity *)entity
{
	return entity;
}

- (EORelationship *)inverseRelationship
{
   NSArray			*relationships;
   EORelationship	*relationship;
   NSInteger		x;
   NSInteger        numRelationships;
	
   // mont_rothstein @ yahoo.com 2004-12-18
   // Added code to teach the inverseRelationship to deal with many-to-many relationships.
   // Not sure this will work in 100% of all cases, but it seems to be ok.  The main worry
   // is that this doesn't use join attributes to determine the inverse, it uses the join
   // entity.  Since many-to-many relationships have to use primary keys for their join
   // attributes I think this will be ok.
   if ([self definition])
   {
	   NSArray *componentRelationships;
	   EOEntity *joinEntity;
	   
	   componentRelationships = [self componentRelationships];
	   joinEntity = [(EORelationship *)[componentRelationships objectAtIndex: 0] destinationEntity];
	   relationships = [[(EORelationship *)[componentRelationships objectAtIndex: 1] destinationEntity] relationships];
	   
	   numRelationships = [relationships count];
	   for (x = 0; x < numRelationships; x++)
	   {
		   relationship = [relationships objectAtIndex: x];
		   
		   if (([relationship definition]) &&
			   ([(EORelationship *)[[relationship componentRelationships] objectAtIndex: 0] destinationEntity] == joinEntity))
		   {
			   return relationship;
		   }
	   }
   }
   else 
   {
	   relationships = [destinationEntity relationships];
	   
	   numRelationships = [relationships count];
	   for (x = 0; x < numRelationships; x++) {
		   relationship = [relationships objectAtIndex:x];
      // First, let's see if the 
		   if ([relationship destinationEntity] == entity &&
			   [EOJoin _joins:joins areEqualToJoins:[relationship joins]]) {
			   return relationship;
		   }
	   }
   }
   
   return nil;
}

- (void)setEntity:(EOEntity *)anEntity
{
	if (entity != anEntity) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[(EORelationship *)[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setEntity:entity];
		}
		entity = anEntity;
	}		
}

- (BOOL)isCompound
{
	return [joins count] > 1;
}

- (BOOL)isFlattened
{
	return definition != nil;
}

- (BOOL)isMandatory
{
	return isMandatory;
}

- (void)setIsMandatory:(BOOL)flag
{
	if (isMandatory != flag) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setIsMandatory:isMandatory];
		}
		isMandatory = flag;
	}
}

- (NSException *)validateValue:(id *)value
{
	if (isMandatory && *value == nil) {
		return [NSException exceptionWithName:EOValidationException reason:EOFormat(@"Property %@ may not be null", name) userInfo:nil];
	}
	
	return nil;
}

- (BOOL)isToMany
{
   if (definition != nil) [self initializeDefinition];
   return isToMany;
}

- (void)setToMany:(BOOL)flag
{
   if (definition != nil) [self initializeDefinition];
	if (isToMany != flag) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setToMany:isToMany];
		}
		isToMany = flag;
	}
}

// mont_rothstein @ yahoo.com 2004-12-03
// I had to make this method a cover method for a more complex
// version that knows how to deal with IN and arrays.
- (EOQualifier *)qualifierWithSourceRow:(NSDictionary *)row
{
	return [self qualifierWithSourceData: row operation: EOQualifierEquals];
}

// mont_rothstein @ yahoo.com 2004-11-09
// Techincally a new method because we need to pass different
// information in.  The data will be either a single row or an array
// of rows.  The operation is needed to pass on to the key value
// qualifiers that are built.
- (EOQualifier *)qualifierWithSourceData:(id)data 
							   operation:(EOQualifierOperation)operation
{
	NSInteger      x, max;
	EOJoin         *join;
	EOQualifier    *qualifier = nil;
	EOQualifier    *subqualifier;
	EOAttribute    *source, *destination;
	id		       joinValue;
	
	if (joins == nil) return [EOJoinQualifier qualifierForRow:(NSDictionary *)data 
											   withDefinition:definition];
	
	for (x = 0, max = [joins count]; x < max; x++) {
		join = [joins objectAtIndex:x];
		source = [join sourceAttribute];
		destination = [join destinationAttribute];
		// mont_rothstein @ yahoo.com 2004-11-09
		// The only changes needed here were to use the new data variable
		// instead of row, call valueForKey: instead of objectForKey:
		// on that variable, and to pass the operation to the key value
		// qualifier.
		//      joinValue = [data objectForKey:[source name]];
		//      subqualifier = [EOKeyValueQualifier qualifierWithKey:[destination name] value:joinValue];
		// mont_rothstein @ yahoo.com 2004-11-19
		// It turns out this always should have been grabbing the data with the destination name
		// because we are looking at destination data.
	  
		// mont_rothstein @ yahoo.com 2005-10-24
		// The method qualifierWithSourceRow: is a tad problematic.  When tripping a fault then the qualifier is 
		// indeed fetched with using the data of the source row.  However, in a select statement the qualifier 
		// is built using what is essentially using the destination row.  This causes as issue when the source 
		// and destination keys do not have the same name.  To address this issue we are going to check for the 
		// source key, and if we don't find that then check for the destination key.  This will cause problems if 
		// the destination row has the a key with the same name as the source key but uses it for a different purpose.
		
		/*! @todo 2005-10-24 Deal with the issue described above, that if the destination row has a key by the same name
		as the source but used for a different purpose it will cause problems.  Probably need to create a 
		qualifierWithDestinationRow: method and use where appropriate. */
		joinValue = [data valueForKey: [source name]];
		if (!joinValue) joinValue = [data valueForKey:[destination name]];
		
		subqualifier = [EOKeyValueQualifier qualifierWithKey:[destination name] 
												   operation:operation
													   value:joinValue];
		if (x == 0) {
			qualifier = subqualifier;
		} else {
			qualifier = [EOAndQualifier qualifierFor:qualifier and:subqualifier];
		}
	}
	
	// mont_rothstein @ yahoo.com 2004-12-12
	// If the destination entity has a restrictingQualifier then we want to and it with this
	// qualifier.
	if ([[self destinationEntity] restrictingQualifier])
	{
		qualifier = [[EOAndQualifier allocWithZone:[self zone]] initWithArray:[NSArray arrayWithObjects:qualifier, [[self destinationEntity] restrictingQualifier], nil]];
        [qualifier autorelease];
	}
	
	return qualifier;
}

- (BOOL)referencesProperty:(id)property
{
	if (definition) {
		NSArray		*parts;
		NSInteger			x;
		NSInteger numParts;
		
		[self initializeDefinition];
		
		parts = [entity _attributesForKeyPath:definition];
		numParts = [parts count];
		for (x = 0; x < numParts; x++) {
			id		part = [parts objectAtIndex:x];
			
			if ([part isKindOfClass:[EOAttribute class]] && part == property) return YES;
			if ([part isKindOfClass:[EORelationship class]] && [part referencesProperty:property]) return YES;
		}
	} else {
		NSInteger			x;
		NSInteger numJoins;
		
		numJoins = [joins count];
		for (x = 0; x < numJoins; x++) {
			EOJoin	*join = [joins objectAtIndex:x];
			
			if ([join sourceAttribute] == property || [join destinationAttribute] == property) return YES;
		}
	}

	return NO;
}

- (unsigned int)numberOfToManyFaultsToBatchFetch
{
	return batchSize;
}

- (void)setNumberOfToManyFaultsToBatchFetch:(unsigned int)size
{
	if (batchSize != size) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setNumberOfToManyFaultsToBatchFetch:batchSize];
		}
		batchSize = size;
	}
}

- (void)setUserInfo:(NSDictionary *)someInfo
{
	if (userInfo != someInfo) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setUserInfo:userInfo];
		}
		[userInfo release];
		userInfo = [someInfo mutableCopyWithZone:[self zone]];
	}
}

- (NSDictionary *)userInfo
{
	return userInfo;
}

- (void)setDeleteRule:(EODeleteRule)rule
{
	if (deleteRule != rule) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[(EORelationship *)[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setDeleteRule:deleteRule];
		}
		deleteRule = rule;
	}
}

- (EODeleteRule)deleteRule
{
	return deleteRule;
}

- (void)setPropagatesPrimaryKey:(BOOL)flag
{
	if (propagatesPrimaryKey != flag) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setPropagatesPrimaryKey:propagatesPrimaryKey];
		}
		propagatesPrimaryKey = flag;
	}
}

- (BOOL)propagatesPrimaryKey
{
   return propagatesPrimaryKey;
}

- (void)setOwnsDestination:(BOOL)flag
{
	if (ownsDestination != flag) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[[self entity] model] undoManager] prepareWithInvocationTarget:self] setOwnsDestination:ownsDestination];
		}
		ownsDestination = flag;
	}
}

- (BOOL)ownsDestination
{
   return ownsDestination;
}

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)expression
{
   NSInteger			x, max;
   EOJoin				*join;
   NSMutableString	*sqlString;

   sqlString = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
   max = [joins count];
   if (max > 1) {
      [sqlString appendString:@"("];
   }
   for (x = 0; x < max; x++) {
      join = [joins objectAtIndex:x];
      if (x > 0) {
         [sqlString appendString:@" AND "];
      }
      [sqlString appendString:[join sqlStringForSQLExpression:expression]];
   }
   if (max > 1) {
      [sqlString appendString:@")"];
   }

   return sqlString;
}

- (NSString *)description
{
   return EOFormat(@"<Relationship: %@>", name);
}

- (int)compare:(id)other
{
	if (![other isKindOfClass:[EORelationship class]]) return NSOrderedAscending;
	return [[self name] caseInsensitiveCompare:[other name]];
}

- (void)_setIsClassProperty:(BOOL)flag
{
	if (isClassProperty != flag) [self willChange];
	isClassProperty = flag;
}

- (BOOL)_isClassProperty
{
	return isClassProperty;
}

- (void)objectWillChange:(id)object
{
	// We get this when one of our joins changes. Just forward it along.
	//[EOLog logDebugWithFormat:@"change (Relationship): %@\n", object];
	[entity objectWillChange:object];
}

#if !defined(STRICT_EOF)
// mont_rothstein @ yahoo.com 2004-12-20
// Added sortOrderings method to be used by faults when fetching.
- (NSArray *)sortOrderings
{
	return sortOrderings;
}

// mont_rothstein @ yahoo.com 2005-03-16
// Added restrictingQualifier to be used by faults when fetching.
- (void)setRestrictingQualifier:(EOQualifier *)qualifier
{
	if (restrictingQualifier != qualifier) {
		[self willChange];
		if ([[[self entity] model] undoManager]) {
			[[[[self entity] model] undoManager] registerUndoWithTarget:self selector:@selector(setRestrictingQualifier:) object:restrictingQualifier];
		}
		[restrictingQualifier release];
		restrictingQualifier = [qualifier retain];
	}
}

- (EOQualifier *)restrictingQualifier {	return restrictingQualifier; }

#endif

@end
