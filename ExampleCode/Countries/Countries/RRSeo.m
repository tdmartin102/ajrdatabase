//==========================================================================================
//	Module Name:	RRSeo.m 
//	
//	Description:	This defines the superclass for all Riemer Enterprise objects that
//			are implemented as custom objects.  This defines factory methods and
//			any template instance methods that should be in every RRS Enterprise
//			object.
//
//==========================================================================================

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

#import "RRSeo.h"
#import <EOControl/EOControl.h>
#import "Additions.h"

#import <string.h>
#import "AvailabilityMacros.h"

NSString *eoString(id value)
{
    if (! value)
        return @"";
    if (value == [EONull null])
        return @"";
    return value;
}

@implementation RRSeo

//---- This method needs to be overridden by subclasses ----
+ (NSString *)entityName
{
    return nil;
}

+ (EOEntity *)entity
{
    return [[EOModelGroup globalModelGroup] entityNamed:[self entityName]];
}

+ (BOOL)useStoredAccessor
{
    return YES;
}

// return an instance of this object with id equal to objectId------------------------------
+ loadObjectWithId:(long)objectId inContext:(EOEditingContext *)context refresh:(BOOL)refresh
{
    RRSeo *anObject;
    EOKeyValueQualifier *aQualifier;
    EOFetchSpecification *fs;
    NSArray *objects;

    anObject = nil;

    if ([[self entity] attributeNamed:@"idNum"])
    {
        aQualifier = [[EOKeyValueQualifier alloc] initWithKey:@"idNum"
            operatorSelector:EOQualifierOperatorEqual
            value:[NSNumber numberWithLong:objectId]];
        fs = [EOFetchSpecification fetchSpecificationWithEntityName:[self entityName]
            qualifier:aQualifier sortOrderings:nil];
        [fs setRefreshesObjects:refresh];
        objects = [context objectsWithFetchSpecification:fs];
        
        if ([objects count])
            anObject = [objects objectAtIndex:0];
    }

    return anObject;
}

// return an instance of this object with id equal to objectId------------------------------
+ loadObjectWithId:(long)objectId inContext:(EOEditingContext *)context
{
    return [self loadObjectWithId:objectId inContext:context refresh:NO];
}

// fetch objects using qualifier and orderings ---------------------------------------
+ (NSArray *)objectsWithQualifier:(EOQualifier *)aQualifier sortOrderings:(NSArray *)order
                        inContext:(EOEditingContext *)context
{
    EOFetchSpecification *fetchSpec;
    NSArray *results;
    fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:[self entityName]
                                                             qualifier:aQualifier
                                                         sortOrderings:order];
    results = [context objectsWithFetchSpecification:fetchSpec];
    return results;
}

// Fetching ALL objects
+ (NSArray *)objectsInContext:(EOEditingContext *)context
{
    return [self objectsWithQualifier:nil sortOrderings:nil inContext:context];
}

+ (void)deleteObjectsDescribedByQualifier:(EOQualifier *)aQualifier inContext:(EOEditingContext *)aContext
{
    NSArray	*eoArray;
    id eo;
    
    eoArray = [self objectsWithQualifier:aQualifier sortOrderings:nil inContext:aContext];
    for (eo in eoArray)
        [aContext deleteObject:eo];
}

// add ordering clause to order array as specified------------------------------------------
+ (void)addOrderingTo:(NSMutableArray *)anArray 
	forAttributeNamed:(NSString *)attribName order:(SEL)anOrder
{
    [anArray addObject:[EOSortOrdering sortOrderingWithKey:attribName selector:anOrder]];
}

- (instancetype)init
{
    if ((self = [super init]))
        ;
    return self;
}

// (EOKeyValueCodingEONull) handle a null numeric value-------------------------------------
- (void)unableToSetNilForKey:(NSString *)key
{
    // just do nothing
}

- (void)setNilValueForKey:(NSString *)key
{
    // set the value to ZERO, don't just do nothing .... duh
    [self setPrimitiveValue:[NSNumber numberWithInt:0] forKey:key];
}

// (NSCopying) return a copy of this enterprise object created in 'aZone'-------------------
- copyWithZone:(NSZone *)aZone
{
    RRSeo *aCopy = [[[self class] allocWithZone:aZone] init];
    aCopy->_userInfo = [_userInfo copy];
    return aCopy;
}

// This is a means to access information that was attached to an EO for
// application specific usage.  This data is not persistant.
- (NSDictionary *)userInfo
{
    if ( !_userInfo )
        _userInfo = @{};
    return _userInfo;
}

- (long)idNum
{
    NSNumber *num = nil;
    long result = 0;
    id gid;
    NSDictionary *dict = nil;
    
    gid = [[self editingContext] globalIDForObject:self];
    if (gid)
        dict = [[[self class] entity] primaryKeyForGlobalID:gid];
    if (dict)
        num = [dict objectForKey:@"idNum"];
    if (num != nil)
        result = [num longValue];
    return result;
}

// This is pretty simple now since arjdatabase does not do wanky things like the old EOF did
// also there are no double release issues, so ARC will work with this.
- (EOEnterpriseObject *)toOneObject:(EOEnterpriseObject *)eo
{
    EOEnterpriseObject *result;
    
    // ARC does a retain here of eo
    result = eo;
    @try {
        [eo self];
    }
    @catch (NSException *exception) {
        // ARC does a autorelease here of eo
        result = nil;
    }
    // ARC would do an autorelease of eo if catch did not happen
    return result;
}

// getting the next sequence number for a primary key
// this can only be called if the object has been inserted into the editingContext
// this is ONLY going to work if the primary key is a number and its attribute name is idNum
// Pretty big assumption, but... almost ALWAYS the case.
- (unsigned long)nextSequence
{
    EOEditingContext    *eoContext;
    unsigned long       sequenceNumber = 0;
    NSDictionary        *primaryKeyDict;

    eoContext = [self editingContext];
    if (! eoContext)
        [NSException raise:@"Sequence Number Generation"
                    format:@"Next Sequence message recieved by EO %@ without an editingContext set.",
            [[self class] entityName]];
    else
    {
        primaryKeyDict =  [[eoContext adaptorChannel] primaryKeyForNewRowWithEntity:[[self class] entity]];
        sequenceNumber = [primaryKeyDict[@"idNum"] unsignedLongValue];
    }
    return sequenceNumber;
}

//-- Override description to get something more helpful
- (NSString *)description
{
    return [self eoDescription];
}

- (NSDictionary *)primaryKeyForNewRow
{
    return nil;
}

@end
