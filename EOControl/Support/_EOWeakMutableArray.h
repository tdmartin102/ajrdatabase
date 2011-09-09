
#import <Foundation/Foundation.h>

@interface _EOWeakMutableArray : NSMutableArray
{
	int	maxCount;
	int	count;
	id		*objects;
}

- (id)objectAtIndex:(unsigned int)index;
- (unsigned int)count;
- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(unsigned)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(unsigned)index;
- (void)replaceObjectAtIndex:(unsigned)index withObject:(id)anObject;

@end
