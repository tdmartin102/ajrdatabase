
#import <EOAccess/EOAccess.h>

#import <AppKit/AppKit.h>

@interface PostgreSQLConnectionPane : EOConnectionPane
{
	IBOutlet NSTextField		*hostNameField;
	IBOutlet NSTextField		*portField;
	IBOutlet NSTextField		*databaseNameField;
	IBOutlet NSTextField		*userNameField;
	IBOutlet NSTextField		*passwordField;
	IBOutlet NSTextField		*smallHostNameField;
	IBOutlet NSTextField		*smallPortField;
	IBOutlet NSTextField		*smallDatabaseNameField;
	IBOutlet NSTextField		*smallUserNameField;
	IBOutlet NSTextField		*smallPasswordField;
}

- (void)setHostName:(id)sender;
- (void)setPort:(id)sender;
- (void)setDatabaseName:(id)sender;
- (void)setUserName:(id)sender;
- (void)setPassword:(id)sender;

@end
