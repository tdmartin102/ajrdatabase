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

#import <AppKit/AppKit.h>

extern NSString *PrefsModelPathsKey;
extern NSString *PrefsBundlePathsKey;
extern NSString *PrefsGeneralLimitKey;
extern NSString *PrefsModelChecksKey;

@interface Preferences : NSObject <NSToolbarDelegate, NSWindowDelegate>
{
    IBOutlet NSPanel         *panel;
    IBOutlet NSView          *allView;
    IBOutlet NSMatrix		*moduleMatrix;

    NSMutableDictionary      *modules;
    NSToolbar				*toolbar;
    NSMutableArray			*preferredModuleNames;
   
    BOOL					displayNeedsRefresh:1;
    NSArray                 *uiElements;
}

+ (instancetype)sharedInstance;

//+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

- (void)run;
- (void)runWithModuleNamed:(NSString *)aPanelName;
- (NSPanel *)panel;

- (IBAction)selectModule:(id)sender;
- (IBAction)selectModuleNamed:(NSString *)name;

@end


@interface NSResponder (Preferences)

- (IBAction)runPreferencesPanel:(id)sender;

@end
