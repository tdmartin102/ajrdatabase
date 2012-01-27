
#import <Foundation/Foundation.h>

@interface _EOWeakMutableArray : NSMutableArray
{
	NSUInteger  maxCount;
	NSUInteger	count;
	id          *objects;
}

- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)count;
- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

@end
