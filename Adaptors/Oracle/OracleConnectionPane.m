//
//  OracleConnectionPane.m
//  Adaptors
//
//  Created by Tom Martin on 8/4/11.
/*  Copyright (C) 2011 Riemer Reporting Service, Inc.

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

Tom Martin
24600 Detroit Road
Westlake, OH 44145
mailto:tom.martin@riemer.com
*/


#import "OracleConnectionPane.h"
#import "OracleAdaptor.h"

@implementation OracleConnectionPane

- (void)setModel:(EOModel *)aModel
{
	[super setModel:aModel];
	
	
	[serverIdField setStringValue:@""];
	[smallServerIdField setStringValue:@""];
	[userNameField setStringValue:@""];
	[smallUserNameField setStringValue:@""];
	[passwordField setStringValue:@""];
	[smallPasswordField setStringValue:@""];
	if (aModel) 
	{
		NSDictionary	*connection = [model connectionDictionary];
		
		[model setAdaptorName:@"Oracle"];
		
		if ([connection objectForKey:ServerIdKey])
		{
			[serverIdField setStringValue:[connection objectForKey:ServerIdKey]];
			[smallServerIdField setStringValue:[connection objectForKey:ServerIdKey]];
		} 
		
		if ([connection objectForKey:UserNameKey])
		{
			[userNameField setStringValue:[connection objectForKey:UserNameKey]];
			[smallUserNameField setStringValue:[connection objectForKey:UserNameKey]];
		} 

		if ([connection objectForKey:PasswordKey])
		{
			[passwordField setStringValue:[connection objectForKey:PasswordKey]];
			[smallPasswordField setStringValue:[connection objectForKey:PasswordKey]];
		} 
	}
}

- (IBAction)setServerId:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:ServerIdKey];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:ServerIdKey];
	}	
}

- (IBAction)setUserName:(id)sender
{
	if ([sender intValue] == 0) {
		[self setConnectionValue:nil forKey:UserNameKey];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:UserNameKey];
	}	
}

- (IBAction)setPassword:(id)sender
{
	if ([[sender stringValue] length] == 0) {
		[self setConnectionValue:nil forKey:PasswordKey];
	} else {
		[self setConnectionValue:[sender stringValue] forKey:PasswordKey];
	}	
}

@end
