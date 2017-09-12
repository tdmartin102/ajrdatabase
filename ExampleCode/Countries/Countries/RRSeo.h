/*!
 * @file RRSeo.h
 * This defines the superclass for all our Enterprise Objects that are implemented 
 * as custom objects.  This defines factory methods and any template instance methods 
 * that should be in every RRS Enterprise object.
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

/*! 
 * This method will always return a string; if you pass in a nil value or an EONull
 * object, then it will return an empty string.  Use this when you need to guarantee 
 * having a value.
 * @param value The value to check
 * @result If the value is not null, the value will be returned unchanged.  Otherwise, an empty string will be returned.
 */
extern NSString *eoString(id value);

/*!
 * @class RRSeo
 * This defines the superclass for all Riemer Enterprise Objects that are implemented 
 * as custom objects.  This defines factory methods and any template instance methods 
 * that should be in every RRS Enterprise object.
 */
@interface RRSeo : EOEnterpriseObject <NSCopying>

/*!
 *  This is a means to attach information to an EO for application-specific usage.
 * This data is not persistent.
 */
@property (nonatomic, copy) NSDictionary *userInfo;

/*!
 * This returns the name of the database entity for the class.  This is VERY handy as EOF 
 * uses <code>entityName</code> a lot.  While it is easy enough to get the entity name from 
 * an instance that is already in a context, it is tricky for EOF to get the entity name
 * from a class object, so this is a handy way of accessing the entity name without having 
 * to do a lot.  Each subclass of RRSeo <strong>MUST</strong> override this 
 * method and return the entity name for that class.  Remember that the entity name is 
 * what is defined in the <strong>MODEL</strong>, NOT the table name.  They are usually the 
 * same, but not always.
 */
@property (class, nonatomic, readonly) NSString *entityName;

/*!
 * This returns the <code>EOEntity</code> associated with this EO.  It gets
 * the entity using @ref entityName.
 */
@property (class, nonatomic, readonly) EOEntity *entity;

/*!
 * This method can be overridden on a class to enable accessing instance variables first when using 
 * <code>takeStoredValue:forKey:</code>.  Default is <code>YES</code>.
 */
@property (class, nonatomic, readonly) BOOL useStoredAccessor;

/*!
 * This is a convenience method.  If an EO has a primary key with a <code>keyValue</code> 
 * of <code>idNum</code>, this method will fetch the object with the specified key.  If refresh 
 * is set to YES, then the cache will be refreshed.
 */
+ (id)loadObjectWithId:(long)objectId inContext:(EOEditingContext *)context refresh:(BOOL)refresh;

/*!
 * This calls @ref loadObjectWithId:inContext:refresh: with refresh set to <code>&#91;NO&#93;</code>
 */
+ (id)loadObjectWithId:(long)objectId inContext:(EOEditingContext *)context;

/*!
 * Return an array of EO's given a qualifier and an array of sort orderings for the specified context.
 * @param aQualifier Defines the parameters for the fetch; may be nil
 * @param order An array of EOSortOrdering objects; see @ref addOrderingTo:forAttributeNamed:order: 
 * may also be nil
 * @param context The EOEditingContext to be used for the fetch
 */
+ (NSArray *)objectsWithQualifier:(EOQualifier *)aQualifier sortOrderings:(NSArray *)order
                        inContext:(EOEditingContext *)context;

/*!
 * This simply fetches all objects in the database for this class.
*/
+ (NSArray *)objectsInContext:(EOEditingContext *)context;

/*!
 * This method fetches all the objects described by the specified qualifier and then deletes 
 * them.  This does <strong>NOT</strong> send raw SQL and therefore will keep the object 
 * graph clean.
 */
+ (void)deleteObjectsDescribedByQualifier:(EOQualifier *)aQualifier inContext:(EOEditingContext *)aContext;

/*!
 * Create sort orderings for fetch specifications.  Use <code>EOCompareAscending</code> 
 * and <code>EOCompareDescending</code> for ordering.
 */
+ (void)addOrderingTo:(NSMutableArray *)anArray forAttributeNamed:(NSString *)attribName order:(SEL)anOrder;

/*!
 * This method is depreciated in 10.3.  This is here to handle a problem in which a null 
 * value is being set to a numeric field.  Because of the existance of this method, any 
 * database column that is set to NULL and is mapped to an <code>int</code> or <code>long</code> 
 * ivar, the ivar will silently be set to 0.  Otherwise an exception would be thrown.
 */
- (void)unableToSetNilForKey:(NSString *)key;

/*!
 * This is here to handle a problem in which a null value is being set to a numeric field.  
 * Because of the existance of this method, any database column that is set to NULL and 
 * is mapped to an <code>int</code> or <code>long</code> ivar, the ivar will silently be 
 set to 0.  Otherwise an exception would be thrown.
 */
- (void)setNilValueForKey:(NSString *)key;

/*!
 * Most EO's that have a primary key of a sequence number, use the attribute name
 * of 'idNum' in the model to describe that field.  In many EO's this attribute is NOT 
 * an ivar of the EO.  This method may be used to access the value of this attribute even 
 * though it is not an ivar.  This call is expensive so it should not be used unless 
 * it is really needed.
 */
- (long)idNum;

/*!
 * A careful routine to catch exceptions on an optional to-one relationship.  You should use this routine
 * when the foreign key may contain a value (even 0) but there is a posibility that no corresponding row
 * exists in the foreign table.  
 *
 * Of course, this would not be such a big deal if our database had nulls in the foreign key.  In this
 * case no fault would be generated. But, because of legacy code, this is not the case and there is no
 * way we can make it so without an extraordinary effort.
 */
- (EOEnterpriseObject *)toOneObject:(EOEnterpriseObject *)eo;

/*!
 * Get the next sequence number/primary key for this entity.  This can only be called if the object 
 * has been inserted into the editing context.  If you would like to generate the sequence number 
 * yourself instead of letting the EOF do it, this is what you need to call.
 */
- (unsigned long)nextSequence;

/*!
 * This method is called by the EODatabaseContext delegate method that is implemented in
 * Additions.m under a category of EOEditingContext.  EOEditingContext MUST be set to 
 * be the delegate of the EODatabaseContext in order for this method to be called.
 * 
 * The default implementation in RRSeo simply returns nil.  If an EO object needs to override 
 * the primary key generation behaviour, it should override this method to return a primary 
 * key to be used when rows are inserted into the database.  The most likely need for this 
 * is if it is valid for the primary key to be zero, or the EO has a compound primary key 
 * and one of the elements may be zero.  There are also some other conditions where the kit 
 * will fail to generate a primary key correctly.  If this method returns nil, then the 
 * delegate method will simply use the built-in kit method to generate the primary key.
 */
- (NSDictionary *)primaryKeyForNewRow;

@end
