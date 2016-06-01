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


#define ProtocolKey  @"protocol"
#define PortKey     @"port"
#define DatabaseKey @"databaseName"
#define HostNameKey @"hostName"
#define UserNameKey @"userName"
#define PasswordKey @"password"

#define SocketIndex  0
#define PortIndex    1

#import "MySQLConnectionPane.h"

@implementation MySQLConnectionPane

- (void)setModel:(EOModel *)aModel
{
    NSString        *value;
    BOOL            isSocket;
    
    isSocket = YES;
	[super setModel:aModel];
	
    [protocolButton selectItemAtIndex:SocketIndex];
    [smallProtocolButton selectItemAtIndex:SocketIndex];

	[portField setStringValue:@""];
    [smallPortField setStringValue:@""];

    [hostnameField setStringValue:@""];
    [smallHostnameField setStringValue:@""];

    [databaseField setStringValue:@""];
    [smallDatabaseField setStringValue:@""];

	[userNameField setStringValue:@""];
	[smallUserNameField setStringValue:@""];
    
	[passwordField setStringValue:@""];
	[smallPasswordField setStringValue:@""];
    
	if (aModel) 
	{
		NSDictionary	*connection = [model connectionDictionary];
		
		[model setAdaptorName:@"MySQL"];
    
        value = [connection objectForKey:ProtocolKey];
        if (value)
        {
            if ([value  isEqualToString:@"TCP"])
            {
                isSocket = NO;
                [protocolButton selectItemAtIndex:PortIndex];
                [smallProtocolButton selectItemAtIndex:PortIndex];
                [hostnameField setEnabled:YES];
                [portField setEnabled:YES];
                [smallHostnameField setEnabled:YES];
                [smallPortField setEnabled:YES];
            }
        }
        
        // if isSocket  then hostname and portName should be disabled
        // otherwise we need to set them
        if (isSocket)
        {
            // clear hostname and port
            [[hostnameField cell] setPlaceholderString:@"localhost"];
            [[smallHostnameField cell] setPlaceholderString:@"localhost"];
            
            // disable hostname and port
            [hostnameField setEnabled:NO];
            [portField setEnabled:NO];
            [smallHostnameField setEnabled:NO];
            [smallPortField setEnabled:NO];
            
            // update the connection dictionary to agree with the protocol
            [self setConnectionValue:@"localhost" forKey:HostNameKey];
            [self setConnectionValue:@"" forKey:PortKey];
        }
        else
        {
            // This is TCP
            value = [connection objectForKey:PortKey];
            if (value)
            {
                [portField setStringValue:value];
                [smallPortField setStringValue:value];
            }
            else
            {
                [[portField cell] setPlaceholderString:@"3306"];
                [[smallPortField cell] setPlaceholderString:@"3306"];
            }
            
            value = [connection objectForKey:HostNameKey];
            if (value)
            {
                [hostnameField setStringValue:value];
                [smallHostnameField setStringValue:value];
            }
            else
            {
                [[hostnameField cell] setPlaceholderString:@"localhost"];
                [[smallHostnameField cell] setPlaceholderString:@"localhost"];
            }
        }
        
        connection = [model connectionDictionary];
        value = [connection objectForKey:DatabaseKey];
        if (! value)
            value = @"";
        [databaseField setStringValue:value];
        [databaseField setStringValue:value];

        value = [connection objectForKey:UserNameKey];
		if (value)
		{
			[userNameField setStringValue:value];
			[smallUserNameField setStringValue:value];
		}
        else
        {
            [[userNameField cell] setPlaceholderString:@"username"];
            [[smallUserNameField cell] setPlaceholderString:@"username"];
        }

        value = [connection objectForKey:PasswordKey];
		if (value)
		{
			[passwordField setStringValue:value];
			[smallPasswordField setStringValue:value];
		} 
	}
}

- (IBAction)setProtocol:(id)sender
{
    if ([(NSPopUpButton *)sender indexOfSelectedItem] == PortIndex)
    {
        [self setConnectionValue:@"TCP" forKey:ProtocolKey];
        [hostnameField setEnabled:YES];
        [portField setEnabled:YES];
        [smallHostnameField setEnabled:YES];
        [smallPortField setEnabled:YES];
    }
    else
    {
        [self setConnectionValue:@"SOCKET" forKey:ProtocolKey];
        // clear hostname and port
        [hostnameField setStringValue:@""];
        [smallHostnameField setStringValue:@""];
        [portField setStringValue:@""];
        [smallPortField setStringValue:@""];
        [[hostnameField cell] setPlaceholderString:@"localhost"];
        [[smallHostnameField cell] setPlaceholderString:@"localhost"];
        
        // disable hostname and port
        [hostnameField setEnabled:NO];
        [portField setEnabled:NO];
        [smallHostnameField setEnabled:NO];
        [smallPortField setEnabled:NO];
        
        // update the connection dictionary to agree with the protocol
        [self setConnectionValue:@"localhost" forKey:HostNameKey];
        [self setConnectionValue:@"" forKey:PortKey];
    }
}

- (IBAction)setPort:(id)sender
{
    if ([[sender stringValue] length] == 0) {
        [self setConnectionValue:nil forKey:PortKey];
    } else {
        [self setConnectionValue:[sender stringValue] forKey:PortKey];
    }
}

- (IBAction)setHostname:(id)sender
{
    if ([[sender stringValue] length] == 0) {
        [self setConnectionValue:nil forKey:HostNameKey];
    } else {
        [self setConnectionValue:[sender stringValue] forKey:HostNameKey];
    }
}

- (IBAction)setDatabase:(id)sender
{
    if ([[sender stringValue] length] == 0) {
        [self setConnectionValue:nil forKey:DatabaseKey];
    } else {
        [self setConnectionValue:[sender stringValue] forKey:DatabaseKey];
    }
}

- (IBAction)setUserName:(id)sender
{
	if ([[sender stringValue] length] == 0) {
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
