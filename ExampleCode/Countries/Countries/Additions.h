/*! 
 * @file Additions.h
 * Adds handy category methods to various Framework classes 
 *
 */

/*
  Copyright (c) 2017 Thomas D Martin
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
 */

#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>

/*!
 @category NSApplication(RRS)
 Adds a couple of handy methods
 */
@interface NSApplication(RRS)

/*!
 * This will allow NSApp to do a simple alert panel with the greatest of ease.
 *
 * This method brings up an alert panel with the application name as the title.  The arguments is
 * simply a formated string.  It presents one buton entitle 'OK'  This method is used EVERYWHERE.
 * A very very handy method.
 */
- showError:(NSString *)errorStr, ...;

/*!
 * Return the application name.
 */
@property (nonatomic, readonly) NSString *appName;

@end

/*! @category EOEditingContext(RRS) */
@interface EOEditingContext(RRS)
/*!
 * Returns the associated database context 
 */
@property (nonatomic, readonly) EODatabaseContext *databaseContext;

/*!
 * Returns the associated adaptor channel 
 */
@property (nonatomic, readonly) EOAdaptorChannel *adaptorChannel;

/*!
 * This is a delegate message for EODatabaseContext. It is implemented here so that you can 
 * set EOEditingContext as the delegate to EODatabaseContext. If you do this then this method 
 * will handle the special case of creating a primary key for any table which has a compound 
 * primary key that could contain a zero, which EOF will not handle correctly. Any table that 
 * contains a key like this must be added to this routine!!!! Making the EOEditingContext a 
 * delegate of the EODatabaseContext is not done automatically by the likes of EOAppController 
 * or any other standard Riemer class. If you will be inserting rows for any entity that has 
 * primary keys of this nature the programmer must specifically set up the delegate 
 * relationship. 
 */
- (NSDictionary *)databaseContext:(EODatabaseContext *)context
           newPrimaryKeyForObject:(id)object entity:(EOEntity *)entity;

@end
