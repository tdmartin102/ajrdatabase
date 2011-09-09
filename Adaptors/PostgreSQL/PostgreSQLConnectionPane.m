
#import "PostgreSQLConnectionPane.h"

@implementation PostgreSQLConnectionPane

- (void)updateURL
{
	NSDictionary		*connection = [[self model] connectionDictionary];
	NSString				*hostName = [connection objectForKey:@"hostname"];
	NSString				*userName = [connection objectForKey:@"username"];
	NSString				*port = [connection objectForKey:@"port"];
	NSString				*databaseName = [connection objectForKey:@"databaseName"];
	
	if (hostName == nil) hostName = @"localhost";
	if (databaseName == nil) databaseName = NSUserName();
	if (port) hostName = EOFormat(@"%@:%@", hostName, port);
	if (userName) hostName = EOFormat(@"%@@%@", userName, hostName);
	
	[self setConnectionValue:EOFormat(@"postgres://%@/%@", hostName, databaseName) forKey:@"URL"];
	[EOLog logDebugWithFormat:@"URL: %@\n", [[[self model] connectionDictionary] objectForKey:@"URL"]];
}

- (void)setModel:(EOModel *)aModel
{
	[super setModel:aModel];
	
	if (aModel) {
		NSDictionary		*connection = [model connectionDictionary];
		
		[model setAdaptorName:@"PostgreSQL"];
		
		if ([connection objectForKey:@"hostname"]) {
			[hostNameField setStringValue:[connection objectForKey:@"hostname"]];
			[smallHostNameField setStringValue:[connection objectForKey:@"hostname"]];
		} else {
			[hostNameField setStringValue:@""];
			[[hostNameField cell] setPlaceholderString:@"localhost"];
			[smallHostNameField setStringValue:@""];
			[[smallHostNameField cell] setPlaceholderString:@"localhost"];
		}

		if ([connection objectForKey:@"port"]) {
			[portField setIntValue:[[connection objectForKey:@"port"] intValue]];
			[smallPortField setIntValue:[[connection objectForKey:@"port"] intValue]];
		} else {
			[portField setStringValue:@""];
			[[portField cell] setPlaceholderString:@"5432"];
			[smallPortField setStringValue:@""];
			[[smallPortField cell] setPlaceholderString:@"5432"];
		}
		
		if ([connection objectForKey:@"username"]) {
			[userNameField setStringValue:[connection objectForKey:@"username"]];
			[smallUserNameField setStringValue:[connection objectForKey:@"username"]];
		} else {
			[userNameField setStringValue:@""];
			[[userNameField cell] setPlaceholderString:NSUserName()];
			[smallUserNameField setStringValue:@""];
			[[smallUserNameField cell] setPlaceholderString:NSUserName()];
		}
		
		if ([connection objectForKey:@"databaseName"]) {
			[databaseNameField setStringValue:[connection objectForKey:@"databaseName"]];
			[smallDatabaseNameField setStringValue:[connection objectForKey:@"databaseName"]];
		} else {
			[databaseNameField setStringValue:@""];
			[[databaseNameField cell] setPlaceholderString:NSUserName()];
			[smallDatabaseNameField setStringValue:@""];
			[[smallDatabaseNameField cell] setPlaceholderString:NSUserName()];
		}
		
		if ([connection objectForKey:@"password"]) {
			[passwordField setStringValue:[connection objectForKey:@"password"]];
			[smallPasswordField setStringValue:[connection objectForKey:@"password"]];
		} else {
			[passwordField setStringValue:@""];
			[smallPasswordField setStringValue:@""];
		}
		
		[self updateURL];
	}
}

- (void)setHostName:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:@"hostname"];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:@"hostname"];
	}
	
	[self updateURL];
}

- (void)setPort:(id)sender
{
	if ([sender intValue] == 0) {
		[self setConnectionValue:nil forKey:@"port"];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:@"port"];
	}
	
	[self updateURL];
}

- (void)setDatabaseName:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:@"databaseName"];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:@"databaseName"];
	}
	
	[self updateURL];
}

- (void)setUserName:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:@"username"];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:@"username"];
	}
	
	[self updateURL];
}

- (void)setPassword:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:@"password"];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:@"password"];
	}
	
	[self updateURL];
}

@end
