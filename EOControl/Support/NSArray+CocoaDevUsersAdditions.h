#import <Foundation/Foundation.h>

@interface NSArray(CocoaDevUsersAdditions)

- (NSIndexSet *) indexesForObjects: (NSArray *) array; // returns the indexes which match objects

+ (NSArray *)arrayWithObjectsFromArrays:(NSArray *)arrays; //for handiness, especially with HigherOrderMessages
+ (NSArray *)arrayWithClonesOf:(id)object count:(unsigned)count; //for things like FlywheelPattern or maybe a RunArray implementation.

/* please criticize these.... */
+ (NSArray *)arrayWithCRLFLinesOfFile:(NSString *)filePath; // assumes CRLF
+ (NSArray *)arrayWithLinesOfFile:(NSString *)filePath lineEnding:(NSString *)lineEnding;


- (BOOL)isEmpty;
- (id)firstObject;

// Unnecessary; can use -doesContain from NSComparisonMethods.
- (BOOL)containsObjectIdenticalTo:(id)anObject;

- (NSArray *)arrayByRemovingObjectAtIndex:(unsigned)index;
- (NSArray *)arrayByRemovingObjectsInRange:(NSRange)range;
- (NSArray *)arrayByRemovingObject:(id)anObject;
- (NSArray *)arrayByRemovingObjectsFromArray:(NSArray *)unwanted;

- (NSArray *)choppedAtCount:(unsigned)count;
- (NSArray *)reversedArray;

// NOTE: results array contains instance of NSNull where result of performing selector is nil
// a collection here is anything responding to -objectEnumerator
- (NSArray *)resultsOfMakeObjectsPerformSelector:(SEL)aSelector;
- (NSArray *)resultsOfMakeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject;
- (void)makeObjectsPerformSelector:(SEL)aSelector withRespectiveObjectsFrom:(id)collection;
- (NSArray *)resultsOfMakeObjectsPerformSelector:(SEL)aSelector withRespectiveObjectsFrom:(id)collection;

@end
