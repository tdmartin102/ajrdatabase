
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

- (void)_checkBounds:(unsigned int)index
{
	if (index >= count) {
		[NSException raise:NSRangeException format:@"Index %d is outside of bounds of array [0..%d]", index, count - 1];
	}
}

- (void)_checkSize:(unsigned int)size
{
	if (size >= maxCount) {
		maxCount += 8;
		objects = NSZoneRealloc([self zone], objects, sizeof(id) * maxCount);
	}
}

- (id)objectAtIndex:(unsigned int)index
{
	[self _checkBounds:index];
	return objects[index];
}

- (unsigned int)count
{
	return count;
}

- (void)addObject:(id)anObject
{
	[self _checkSize:count + 1];
	objects[count] = anObject;
	count++;
}

- (void)insertObject:(id)anObject atIndex:(unsigned)index
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

- (void)removeObjectAtIndex:(unsigned)index
{
	[self _checkBounds:index];
	memmove(objects + index, objects + index + 1, sizeof(id) * (count - index - 1));
	count--;
}

- (void)replaceObjectAtIndex:(unsigned)index withObject:(id)anObject
{
	[self _checkBounds:index];
	objects[index] = anObject;
}

@end
