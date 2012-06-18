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
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import "EOObjectFaultHandler.h"

#import "EOAdaptorChannel.h"
#import "EOAdaptorContext.h"
#import "EOEntityClassDescription.h"
#import "EODatabase.h"
#import "EODatabaseChannel.h"
#import "EODatabaseContext.h"
#import "EOEntityP.h"

#import <EOControl/EOAndQualifier.h>
#import <EOControl/EOEnterpriseObject.h>
#import <EOControl/EOEditingContext.h>
#import <EOControl/EOFetchSpecification.h>
#import <EOControl/EOGlobalID.h>
#import <EOControl/EOKeyGlobalID.h>
#import <EOControl/EOFaultP.h>

#import <objc/objc-class.h>

@implementation EOObjectFaultHandler

- (id)initWithGlobalID:(EOGlobalID *)aGlobalID editingContext:(EOEditingContext *)aContext;
{
	if (self = [super init])
	{
		editingContext = [aContext retain];
		globalID = [aGlobalID retain];
	}
	return self;
}

// mont_rothstein @ yahoo.com 2005-07-11
// Added method as per 4.5 API.
- initWithGlobalID:(EOKeyGlobalID *)aGlobalID 
   databaseContext:(EODatabaseContext *)aDatabaseContext 
	editingContext:(EOEditingContext *)anEditingContext;
{
	if (self = [super init])
	{
		editingContext = [anEditingContext retain];
		globalID = [aGlobalID retain];
		databaseContext = [aDatabaseContext retain];
	}
	return self;
}


- (void)dealloc
{
	// mont_rothstein @ yahoo.com 2005-07-11
	// Added dealloc of new instance variable
	[databaseContext release];
	[super dealloc];
}

- (void)faultObject:(id)object
{
	EOFetchSpecification			*fetch;
	EOEntityClassDescription	*classDescription;
	EODatabaseContext				*aDatabaseContext;
	EODatabaseChannel				*databaseChannel;
	EOAdaptorChannel				*adaptorChannel;
	NSDictionary					*row = nil;
    EOEditingContext                *ec;
	
	// Tom.Martin @ Riemer.com 2011-08-31
	// We need to lock the context, added lock, unlock and unlock on thrown exception
	// Tom.Martin @ Riemer.com 2011-12-1
	// moved this to beore accessing the database context.
    ec = editingContext;
	[editingContext lockObjectStore];

	classDescription = (EOEntityClassDescription *)[EOEntityClassDescription classDescriptionForEntityName:[globalID entityName]];
	aDatabaseContext = [EODatabaseContext registeredDatabaseContextForModel:[[classDescription entity] model] editingContext:editingContext];
	databaseChannel = [aDatabaseContext availableChannel];
	adaptorChannel = [databaseChannel adaptorChannel];
	
	if (![adaptorChannel isOpen]) {
		[adaptorChannel openChannel];
	}
	fetch = [EOFetchSpecification fetchSpecificationWithEntityName:[globalID entityName] qualifier:[(EOKeyGlobalID *)globalID buildQualifier] sortOrderings:nil];
	
	// mont_rothstein @ yahoo.com 2005-06-27
	// If the update strategy is pessimistic locking then override the setting on the
	// fetch specification to always lock
	if ([aDatabaseContext updateStrategy] == EOUpdateWithPessimisticLocking)
	{
		[fetch setLocksObjects: YES];
	}

	NS_DURING
		// mont_rothstein @ yahoo.com 2004-12-05
		// The select method was missing, added it.
		[adaptorChannel selectAttributes: [[classDescription entity] attributes] fetchSpecification: fetch lock: NO entity: [classDescription entity]];
	
		// mont_rothstein @ yahoo.com 2004-12-05
		// This while loop wasn't doing the job.  It had no way to exit.  Replaced it with
		// the code immediately follwoing.
		//	while (1) {
		//		if (row) {
		//			[NSException raise:EODatabaseException format:@"Faulting object with global ID %@ brought back more then one database row.", globalID];
		//		}
		//		row = [adaptorChannel fetchRowWithZone:[object zone]];
		//	}
		row = [adaptorChannel fetchRowWithZone:[object zone]];
		// Tom.Martin @ riemer.com 2011-08-18
		// if there was no row then the fetch is no longer in progress and the next fetch will throw an exception.
		// Added test for fetchInProgress so that we can deal with no row returned here.
		if ([adaptorChannel isFetchInProgress]) {
			if ([adaptorChannel fetchRowWithZone:[object zone]]) {
				[NSException raise:EODatabaseException format:@"Faulting object with global ID %@ brought back more then one database row.", globalID];
			}
		}
	
		if (row == nil) {
			/*! @todo This needs to deal with optional vs. mandatory to one relationships. The problem with it being optional is that we can't return a "null" for the fault, since we've alread allocated memory for the fault when it was created. We might try to do something funky, like return a "null" object, ie, an object that always returns null, no matter what message is sent to it, but that'd be weird. */
			// mont_rothstein @ yahoo.com 2005-01-03
			// For new we are just going to throw an exception, otherwise EOFault goes into an infinite loop.
			[NSException raise: EODatabaseException format: @"Faulting object with global ID %@ brought back no rows.", globalID];
		} else {
			[self faultObject:object withRawRow:row databaseContext:aDatabaseContext];
		}
	NS_HANDLER
		[ec unlockObjectStore];
		[localException raise];
	NS_ENDHANDLER
	[ec unlockObjectStore];
}

- (void)faultObject:(id)object withRawRow:(NSDictionary *)row databaseContext:(EODatabaseContext *)aDatabaseContext
{
	EOEntityClassDescription	*classDescription;
	NSException *exception = nil;
	
	classDescription = (EOEntityClassDescription *)[EOEntityClassDescription classDescriptionForEntityName:[globalID entityName]];

	// mont_rothstein @ yahoo.com 2004-12-05
	// We have to set the handler pointer on the object to nil, otherwise KVC will try
	// and autorelese it as we set the data on the object.
	// jean_alexis @ sourceforge.net 2005-11-23
	// replaced by clearFault:
	// we need to retain ourselve, because the clear fault will release the handler
	[self retain];
	[EOFault clearFault: object];
	// mont_rothstein @ yahoo.com 2004-12-02
	// Added initialization of object.  We allocated it, so we have to initialize it.
	// jean_alexis @ sourceforge.net 2005-11-22
	// do not initialize the object twice (or we should have deallocated it first)
	if ([EOFault isFault: object]) 
	{
		//object->isa = [self faultedClass];
		// tom.martin @ riemer.com 2011-12-5
		// using object_setClass is just a hair safer.
		object_setClass(object, [self faultedClass]);
		[object initWithEditingContext:editingContext classDescription:classDescription globalID:globalID];
	}
	
	// And register the snapshot with the recordSnapshot context.
	[[aDatabaseContext database] recordSnapshot:row forGlobalID:globalID];
	// Allow the object to initialize itself. This is normally done in EOGenericRecord.
	// (ja @ sente.ch) Observing fault must be disabling while initalizing with current data because
	// else the object will be marked as updated
	[EOObserverCenter suppressObserverNotification];

	NS_DURING
		[aDatabaseContext initializeObject:object withGlobalID:globalID editingContext:editingContext];
	NS_HANDLER
		exception = [localException retain];
	NS_ENDHANDLER
	
	[EOObserverCenter enableObserverNotification];

	if (exception != nil) {
		[exception autorelease];
		[exception raise];
	}
	// mont_rothstein @ yahoo.com 2005-03-30
	// Object faults are already in the editing context, but they are not observed.  
	// Therefore, unlike with other objects, we don't have to call the editingContext's
	// recordObjectLglobalID: but we do need to register the editingContext to observe
	// the object.
	[EOObserverCenter addObserver:editingContext forObject:object];

	// And make sure the object completes initialization. This is normally called -[EOEditingContext recordObject:withGlobalID:]
	[object awakeFromFetchInEditingContext:editingContext];
	
	// Finally, free ourself, since we're no longer references by anything.
	[self release];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [NSString stringWithFormat:@"[EOObjectFault (0x%x): %@]", self, globalID];
}

- (Class)faultedClass
{
   return [[(EOEntityClassDescription *)[EOEntityClassDescription classDescriptionForEntityName:[globalID entityName]] entity] _objectClass];
}

- (id)autorelease
{
	return [super autorelease];
}
- (id)retain
{
	return [super retain];
}
- (oneway void)release
{
	[super release];
}
@end
