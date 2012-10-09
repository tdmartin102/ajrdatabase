
#import "_EOWeakMutableArray.h"


@implementation _EOWeakMutableArray

- (id)init
{
	if (self = [super init])
	{
		maxCount = 8;
		objects = (id *)NSZoneMalloc([self zone], sizeof(id) * maxCount);
		count = 0;
	}
	return self;
}

- (void)dealloc
{
	NSZoneFree([self zone], objects);
	[super dealloc];
}

- (void)_checkBounds:(NSUInteger)index
{
	if (index >= count) {
		[NSException raise:NSRangeException format:@"Index %lu is outside of bounds of array [0..%lu]", (unsigned long)index, (unsigned long)(count - 1)];
	}
}

- (void)_checkSize:(NSUInteger)size
{
	if (size >= maxCount) {
		maxCount += 8;
		objects = NSZoneRealloc([self zone], objects, sizeof(id) * maxCount);
	}
}

- (id)objectAtIndex:(NSUInteger)index
{
	[self _checkBounds:index];
	return objects[index];
}

- (NSUInteger)count
{
	return count;
}

- (void)addObject:(id)anObject
{
	[self _checkSize:count + 1];
	objects[count] = anObject;
	count++;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
	if (index == count) {
		[self addObject:anObject];
	} else {
		[self _checkBounds:index];
		[self _checkSize:count + 1];
		memmove(objects + index + 1, objects + index, sizeof(id) * (count - index));
		objects[index] = anObject;
		count++;
	}
}

- (void)removeLastObject
{
	// Makes no effort to reclaim memory;
	count--;
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
	[self _checkBounds:index];
	memmove(objects + index, objects + index + 1, sizeof(id) * (count - index - 1));
	count--;
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
	[self _checkBounds:index];
	objects[index] = anObject;
}

@end
