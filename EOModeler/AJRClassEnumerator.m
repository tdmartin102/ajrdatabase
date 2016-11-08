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
/* AJRClassEnumerator.m created by alex on Sat 19-Aug-2000 */

#import "AJRClassEnumerator.h"

#import <objc/runtime.h>

@implementation AJRClassEnumerator

- (instancetype)init
{
   if ((self = [super init])) {
       index = 0;
       classes = NULL;
       count = 0;
   }
   return self;
}

/*
+ (void)getClasses:(Class **)array count:(unsigned int *)aCount
{
   AJRClassEnumerator	*enumerator = [[[self class] alloc] init];
   Class				next;
   int					maxCount = 256;

   if (!enumerator) {
      *aCount = 0;
      *array = NULL;
      return;
   }
   
   *array = (Class *)malloc(sizeof(Class) * maxCount);
   *aCount = 0;

   while ((next = [enumerator nextObject])) {
      (*array)[*aCount] = next;
      (*aCount)++;
      if (*aCount == maxCount) {
         maxCount += 256;
         *array = (Class *)realloc(*array, sizeof(Class) * maxCount);
      }
   }

}
*/

- (id)nextObject
{
    if (classes == NULL) {
        int		numClasses = 0;
        
        count = objc_getClassList(NULL, 0);
        
        while (numClasses < count) {
            numClasses = count;
            classes = realloc(classes, sizeof(Class) * numClasses);
            count = objc_getClassList(classes, numClasses);
        }
        
        index = 0;
    }
    
    if (index < count) {
        return classes[index++];
    }
    
    if (classes) {
        free(classes);
        classes = NULL;
    }
    
    return nil;
}


@end
