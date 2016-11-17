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
alex@raftis.net

 *%*%*%*%*/

#import "PreferencesModule.h"

@implementation PreferencesModule

- (NSString *)name
{
   [NSException raise:NSInternalInconsistencyException format:@"Subclasses of Preferences panel must implement -[PreferencesModule %@].", NSStringFromSelector(_cmd)];
   return nil;
}

- (NSString *)toolTip
{
   return [self name];
}

- (NSView *)view
{
	if (!view)  {
        NSBundle *bundle;
        NSArray  *anArray;
        
        bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:NSStringFromClass([self class])  owner:self topLevelObjects:&anArray];
        uiElements = anArray;
	}

   if (!view) {
      [NSException raise:NSInternalInconsistencyException format:@"Unable to load view for preferences module %@\n", [self name]];
   }
	
	return view;
}

- (NSImage *)image
{
   if (!image) {
      NSBundle      *bundle = [NSBundle bundleForClass:[self class]];
      NSString		*path;
      NSSize		size;

      path = [bundle pathForResource:NSStringFromClass([self class]) ofType:@"tiff"];
      if (path) {
         image = [[NSImage alloc] initWithContentsOfFile:path];
      }
      if (!image) image = [NSImage imageNamed:@"NSApplicationIcon"];

      size = [image size];
      if (size.width > 32 || size.height > 32) {
         image = [image copy];
         [image setSize:(NSSize){32.0, 32.0}];
      }
   }

   return image;
}

- (BOOL)isPreferred
{
   return NO;
}

- (void)update
{
}

@end

