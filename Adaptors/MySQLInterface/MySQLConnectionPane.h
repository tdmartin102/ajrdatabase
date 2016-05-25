//
//  MySQLConnectionPane.h
//  Adaptors
//
//  Created by Tom Martin on 5/25/16.
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


#import <EOAccess/EOAccess.h>

#import <AppKit/AppKit.h>

@interface MySQLConnectionPane : EOConnectionPane
{
    IBOutlet NSPopUpButton  *protocolButton;
	IBOutlet NSTextField	*portField;
	IBOutlet NSTextField	*hostnameField;
	IBOutlet NSTextField	*databaseField;
	IBOutlet NSTextField	*userNameField;
	IBOutlet NSTextField	*passwordField;
    
    IBOutlet NSPopUpButton  *smallProtocolButton;
    IBOutlet NSTextField	*smallPortField;
    IBOutlet NSTextField	*smallHostnameField;
    IBOutlet NSTextField	*smallDatabaseField;
    IBOutlet NSTextField	*smallUserNameField;
	IBOutlet NSTextField	*smallPasswordField;
}

- (IBAction)setProtocol:(id)sender;
- (IBAction)setPort:(id)sender;
- (IBAction)setHostname:(id)sender;
- (IBAction)setDatabase:(id)sender;
- (IBAction)setUserName:(id)sender;
- (IBAction)setPassword:(id)sender;

@end
