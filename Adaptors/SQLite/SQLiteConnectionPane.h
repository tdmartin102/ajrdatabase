
#import <EOAccess/EOAccess.h>

#import <AppKit/AppKit.h>

@interface SQLiteConnectionPane : EOConnectionPane
{
	IBOutlet NSTextField		*pathField;
	IBOutlet NSButton			*chooseButton;
	IBOutlet NSTextField		*smallPathField;
	IBOutlet NSButton			*smallChooseButton;
}

- (void)setPath:(id)sender;
- (void)selectPath:(id)sender;

@end
