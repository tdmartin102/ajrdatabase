//
//  NSArray-EO.h
//  EOControl
//
//  Created by Alex Raftis on 11/8/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EOQualifier;

@interface NSArray (EO)

// Filtering and sorting objects
// mont_rothstein @ yahoo.com 2005-01-08
// Moved declaration of filteredArraysUsingQualifier: to EOQualifier.h as per WO 4.5 API
//- (NSArray *)filteredArrayUsingQualifier:(EOQualifier *)qualifier;
// mont_rothstein @ yahoo.com 2005-01-08
// Moved declaration of sortedArrayUsingKeyOrderArray: to EOSortOrdering.h as per WO 4.5 API
//- (NSArray *)sortedArrayUsingKeyOrderArray:(NSArray *)order;

// Aggregate functions
- (id)computeAvgForKey:(NSString *)key;
- (id)computeCountForKey:(NSString *)key;
- (id)computeMaxForKey:(NSString *)key;
- (id)computeMinForKey:(NSString *)key;
- (id)computeSumForKey:(NSString *)key;

// Key Value Coding
- (id)valueForKey:(NSString *)key;

// Making copies
// tom.Martin @ riemer.com 2017-05-19
// PLEASE PLEASE NOTE:!!!!
// This NOW returns an autoreleased object so that ARC just might work.
- (id)shallowCopy;

@end


@interface NSMutableArray (EOSortOrdering)

- (void)sortUsingKeyOrderArray:(NSArray *)sortOrderings;

@end


