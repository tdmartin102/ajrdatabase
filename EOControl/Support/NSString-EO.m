
#import "NSString-EO.h"

#import "EOFormat.h"

@implementation NSString (EO)

- (NSString *)capitalizedName
{
   if ([self length] > 1) {
      return EOFormat(@"%@%@", [[self substringToIndex:1] capitalizedString], [self substringFromIndex:1]);
   }
   
   return [self capitalizedString];
}

@end
