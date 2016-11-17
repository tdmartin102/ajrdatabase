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

#import "Preferences.h"
#import "PreferencesModule.h"

#import "PreferencesBundles.h"
#import "PreferencesChecks.h"
#import "PreferencesGeneral.h"
#import "PreferencesModels.h"

NSString *PrefsModelPathsKey = @"PrefsModelPaths";
NSString *PrefsBundlePathsKey = @"PrefsBundlePaths";
NSString *PrefsGeneralLimitKey = @"PrefsGeneralLimit";
NSString *PrefsModelChecksKey = @"PrefsModelChecks";

@implementation Preferences

static Preferences	*SELF = nil;

+ (id)sharedInstance
{
   return SELF;
}

- (instancetype) initUniqueInstance
{
    if ((self = [super init]))
    {
        modules = [[NSMutableDictionary alloc] init];
        preferredModuleNames = [[NSMutableArray alloc] init];
        //objectBroker = [[AJRObjectBroker alloc] initWithTarget:self
        //                                          action:@selector(addPreferencesModule:)
        //             requestingClassesInheritedFromClass:[PreferencesModule class]];
            
        [self addPreferencesModule:[PreferencesBundles class]];
        [self addPreferencesModule:[PreferencesChecks class]];
        [self addPreferencesModule:[PreferencesGeneral class]];
        [self addPreferencesModule:[PreferencesModels class]];
    }
    
    return self;
}

+ (void) initialize {
    // subclassing would result in an instance per class, probably not what we want
    NSAssert([Preferences class] == self, @"Subclassing is not welcome");
    SELF = [[super alloc] initUniqueInstance];
}

- (NSArray *)names
{
   return [[modules allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)update
{
   NSArray					*cells;
   int						x;
   NSArray					*names = [self names];
   NSInteger				moduleCount = [names count];
   PreferencesModule     *module;
   NSButtonCell             *cell;

   cells = [moduleMatrix cells];
   for (x = 0; x < (const int)[cells count]; x++) {
      cell = [cells objectAtIndex:x];
      if (x < moduleCount) {
         module = [modules objectForKey:[names objectAtIndex:x]];
         [cell setTitle:[module name]];
         [cell setImage:[module image]];
         [cell setTransparent:NO];
         [cell setTarget:self];
         [cell setAction:@selector(selectModule:)];
         [cell setRepresentedObject:[module name]];
      } else {
         [cell setTransparent:YES];
         [cell setTarget:nil];
         [cell setAction:NULL];
         [cell setRepresentedObject:nil];
      }
   }

   displayNeedsRefresh = NO;
}

- (void)addPreferencesModule:(Class)moduleClass
{
   PreferencesModule		*module = [[moduleClass alloc] init];

   if ([[module name] hasPrefix:@"_"]) {
      // Ignore these, they're private.
   } else {
      [modules setObject:module forKey:[module name]];
      if ([module isPreferred]) {
         [preferredModuleNames addObject:[module name]];
         [preferredModuleNames sortUsingSelector:@selector(compare:)];
      }
      displayNeedsRefresh = YES;
      if ([panel isVisible]) {
         [self performSelector:@selector(update) withObject:nil afterDelay:0.01];
      }
   }
}

- (void)awakeFromNib
{
   [allView removeFromSuperview];
   [panel setContentView:allView];

   toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preferences Window"];
   [toolbar setDelegate:self];
   [toolbar setAllowsUserCustomization:YES];
   [panel setToolbar:toolbar];
}

- (void)run
{
   [self panel];
   if (displayNeedsRefresh) {
      [self update];
   }
   [panel makeKeyAndOrderFront:self];
}

- (void)runWithModuleNamed:(NSString *)aPanelName
{
   [self run];
   [self selectModuleNamed:aPanelName];
   
}

- (NSPanel *)panel
{
   if (!panel) {
       NSBundle *bundle;
       NSArray  *anArray;
       
       bundle = [NSBundle bundleForClass:[self class]];
       [bundle loadNibNamed:@"PreferencesPanel" owner:self topLevelObjects:&anArray];
       uiElements = anArray;
   }
   return panel;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
   NSToolbarItem			*item;
   PreferencesModule	*module = [modules objectForKey:itemIdentifier];

   item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
   [item setLabel:itemIdentifier];
   [item setPaletteLabel:itemIdentifier];
   [item setAction:@selector(selectModule:)];
   [item setTarget:self];

   if ([itemIdentifier isEqualToString:@"Show All"]) {
      [item setToolTip:@"Show all preferences modules."];
      [item setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
   } else {
      [item setToolTip:[module toolTip]];
      [item setImage:[module image]];
   }

   return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
   NSMutableArray *items = [NSMutableArray arrayWithObjects:
      @"Show All", NSToolbarSeparatorItemIdentifier, nil];
   [items addObjectsFromArray:preferredModuleNames];
   return items;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
   NSMutableArray		*items = [NSMutableArray array];

   [items addObjectsFromArray:[self names]];
   [items addObject:NSToolbarSeparatorItemIdentifier];
   [items addObject:NSToolbarSpaceItemIdentifier];
   [items addObject:NSToolbarFlexibleSpaceItemIdentifier];

   return items;
}

- (void)selectModule:(id)sender
{
   if ([sender isKindOfClass:[NSToolbarItem class]]) {
      [self selectModuleNamed:[sender itemIdentifier]];
   } else {
      [self selectModuleNamed:[[sender selectedCell] representedObject]];
   }
}

- (void)selectModuleNamed:(NSString *)name
{
   NSView		*view;
   NSRect		frame;

   frame = [panel frame];
   if ([name isEqualToString:@"Show All"]) {
      view = allView;
      [panel setDelegate:self];
      [panel setTitle:@"Preferences - All"];
   } else {
      view = [[modules objectForKey:name] view];
      [panel setDelegate:[modules objectForKey:name]];
       [panel setTitle:[NSString stringWithFormat:@"Preferences - %@", name]];
   }

   if (view != [panel contentView]) {
      NSRect		newViewFrame = [view frame];
      NSRect		oldViewFrame = [[panel contentView] frame];
      float			differenceY = newViewFrame.size.height - oldViewFrame.size.height;
      float			differenceX;

      if (newViewFrame.size.width < 400) {
         newViewFrame.size.width = 400;
      }
      differenceX = newViewFrame.size.width - oldViewFrame.size.width;

      if (differenceY != 0.0 || differenceX != 0.0) {
         frame.origin.y -= differenceY;
         frame.size.height += differenceY;
         frame.origin.x -= differenceX / 2.0;
         frame.size.width += differenceX;
         [panel setContentView:[[NSView alloc] initWithFrame:oldViewFrame]];
         [panel setFrame:frame display:YES animate:YES];
         [panel setContentView:view];
      }
      [[modules objectForKey:name] update];
   }

   [panel makeFirstResponder:[view nextKeyView]];
}

@end


@implementation NSResponder (Preferences)

- (void)runPreferencesPanel:(id)sender
{
   [[Preferences sharedInstance] run];
}

@end
