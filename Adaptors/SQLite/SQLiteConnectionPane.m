
#import "SQLiteConnectionPane.h"

@implementation SQLiteConnectionPane

- (void)updateURL
{
	NSString		*path = [[[self model] connectionDictionary] objectForKey:@"path"];
	
	if (path == nil) path = @"$(appSupport)/$(appName).EO";
	
	[self setConnectionValue:EOFormat(@"sqlite://%@", path) forKey:@"URL"];
}

- (void)setModel:(EOModel *)aModel
{
	[super setModel:aModel];
	
	if (aModel) {
		NSDictionary	*connection = [model connectionDictionary];
		
		[model setAdaptorName:@"SQLite"];
		
		if ([connection objectForKey:@"path"]) {
			[pathField setStringValue:[connection objectForKey:@"path"]];
			[smallPathField setStringValue:[connection objectForKey:@"path"]];
		} else {
			[pathField setStringValue:@""];
			[smallPathField setStringValue:@""];
			[[pathField cell] setPlaceholderString:@"$(appSupport)/$(appName).EO"];
			[[smallPathField cell] setPlaceholderString:@"$(appSupport)/$(appName).EO"];
		}
		
		[self updateURL];
	}
}

- (void)setPath:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:@"path"];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:@"path"];
	}
	[self updateURL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)sender
{
	if (returnCode == NSOKButton) {
		NSRange				range;
		NSMutableString	*string = [[sheet filename] mutableCopy];
		
		if ((range = [string rangeOfString:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"]]).location != NSNotFound) {
			[string replaceCharactersInRange:range withString:@"$(appSupport)"];
		}
		if ((range = [string rangeOfString:@"/Library/Application Support"]).location != NSNotFound) {
			[string replaceCharactersInRange:range withString:@"$(globalSupport)"];
		}
		[pathField setStringValue:string];
		[smallPathField setStringValue:string];
		[string release];
		
		[self setPath:[sender previousKeyView]];
	}
}

- (void)selectPath:(id)sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setRequiredFileType:@"EO"];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel beginSheetForDirectory:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] file:nil modalForWindow:[sender window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:sender];
}

@end
