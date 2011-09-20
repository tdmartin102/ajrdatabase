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

#import "EODatabaseContext.h"
// mont_rothstein @ yahoo.com 2004-12-20
// Added #import
#import "EODatabaseContextP.h"

#import "EOAdaptor.h"
#import "EOAdaptorContext.h"
#import "EOAdaptorChannel.h"
#import "EOAdaptorOperationP.h"
#import "EOAttributeP.h"
#import "EODatabase.h"
#import "EODatabaseChannelP.h"
#import "EODatabaseOperation.h"
#import "EODebug.h"
#import "EOEntityClassDescription.h"
#import "EOEntityP.h"
#import "EOJoin.h"
#import "EOModel.h"
#import "EOModelGroup.h"
#import "EORelationship.h"
// mont_rothstein @ yahoo.com 2005-04-03
#import "EORelationshipP.h"
// mont_rothstein @ yahoo.com 2005-07-11
#import "EOObjectFaultHandler.h"

#import <EOControl/EOControl.h>
#import <EOControl/EONumericKeyGlobalID.h>
#import <EOControl/EOKeyGlobalID.h>
#import <EOControl/EOTemporaryGlobalID.h>

#import <objc/objc-class.h>

#include	<Foundation/NSValue.h>
#include	<Foundation/NSKeyValueCoding.h>


NSString *EODatabaseChannelNeededNotification = @"EODatabaseChannelNeededNotification";

NSString *EODatabaseContextKey = @"EODatabaseContextKey";
NSString *EODatabaseOperationsKey = @"EODatabaseOperationsKey";
NSString *EOFailedDatabaseOperationKey = @"EOFailedDatabaseOperationKey";

extern int objc_sizeof_type(const char* type);


// mont_rothstein @ yahoo.com 2004-12-06
// This method was removed.
//@interface NSObject (EOPrivate)
//
//- (void)_setGlobalID:(EOGlobalID *)globalID;
//
//@end


@interface EOFetchSpecification (EOPrivate)

- (void)_setRootEntityName:(NSString *)rootEntityName;
- (NSString *)_rootEntityName;

@end


@interface EOCooperatingObjectStore (EOPrivate)

- (void)_setCoordinator:(EOObjectStoreCoordinator *)aCoordinator;
- (BOOL)_handlesEntityNamed:(NSString *)entityName;

@end


// mont_rothstein @ yahoo.com 2005-01-18
// Added interface declaration so that the EODatabaseContext will know this method exists.
@interface NSObject (EOPrivate) 
- (void)_setEditingContext:(EOEditingContext *)editingContext;
@end

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1030

@interface NSObject (Jag) 
- (void)setValue:(id)value forKey:(NSString *)key;
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (void)setNilValueForKey:(NSString *)key;
@end

#define ASSIGN(object,value)     ({\
     id __value = (id)(value); \
     id __object = (id)(object); \
     if (__value != __object) \
       { \
         if (__value != nil) \
           { \
             [__value retain]; \
           } \
         object = __value; \
         if (__object != nil) \
           { \
             [__object release]; \
           } \
       } \
   })


#define BITS_PER_UNIT	8

int objc_sizeof_type (const char *type)
{
  /* Skip the variable name if any */
  if (*type == '"')
    {
      for (type++; *type++ != '"';)
	/* do nothing */;
    }

  switch (*type) {
  case _C_ID:
    return sizeof (id);
    break;

  case _C_CLASS:
    return sizeof (Class);
    break;

  case _C_SEL:
    return sizeof (SEL);
    break;

  case _C_CHR:
    return sizeof (char);
    break;

  case _C_UCHR:
    return sizeof (unsigned char);
    break;

  case _C_SHT:
    return sizeof (short);
    break;

  case _C_USHT:
    return sizeof (unsigned short);
    break;

  case _C_INT:
    return sizeof (int);
    break;

  case _C_UINT:
    return sizeof (unsigned int);
    break;

  case _C_LNG:
    return sizeof (long);
    break;

  case _C_ULNG:
    return sizeof (unsigned long);
    break;

//  case _C_LNG_LNG:
//    return sizeof (long long);
//    break;

//  case _C_ULNG_LNG:
//    return sizeof (unsigned long long);
//    break;

  case _C_FLT:
    return sizeof (float);
    break;

  case _C_DBL:
    return sizeof (double);
    break;

  case _C_VOID:
    return sizeof (void);
    break;

  case _C_PTR:
//  case _C_ATOM:
  case _C_CHARPTR:
    return sizeof (char *);
    break;

 // case _C_ARY_B:
 //   {
 //     int len = atoi (type + 1);
 //     while (isdigit ((unsigned char)*++type))
	//;
    //  return len * objc_aligned_size (type);
   // }
   // break;

  case _C_BFLD:
    {
      /* The new encoding of bitfields is: b 'position' 'type' 'size' */
      int position, size;
      int startByte, endByte;

      position = atoi (type + 1);
      while (isdigit ((unsigned char)*++type))
	;
      size = atoi (type + 1);

      startByte = position / BITS_PER_UNIT;
      endByte = (position + size) / BITS_PER_UNIT;
      return endByte - startByte;
    }

 // case _C_STRUCT_B:
 //   {
 //     struct objc_struct_layout layout;
//      unsigned int size;

  //    objc_layout_structure (type, &layout);
   //   while (objc_layout_structure_next_member (&layout))
        /* do nothing */ ;
   //   objc_layout_finish_structure (&layout, &size, NULL);

   //   return size;
   // }

 // case _C_UNION_B:
 //   {
 //     int max_size = 0;
 //     while (*type != _C_UNION_E && *type++ != '=')
	/* do nothing */;
 //     while (*type != _C_UNION_E)
//	{
	  /* Skip the variable name if any */
//	  if (*type == '"')
//	    {
//	      for (type++; *type++ != '"';)
		/* do nothing */;
//	    }
//	  max_size = MAX (max_size, objc_sizeof_type (type));
//	  type = objc_skip_typespec (type);
//	}
  //    return max_size;
    //}

  default:
    {
		[NSException raise: @"OBJC_ERR_BAD_TYPE"
			format: @"unknown type %s\n", type];
	  return 0;
    }
  }
}


/**
 * This function is used to locate information about the instance
 * variable of obj called name.  It returns YES if the variable
 * was found, NO otherwise.  If it returns YES, then the values
 * pointed to by type, size, and offset will be set (except where
 * they are null pointers).
 */
BOOL GSObjCFindVariable(id obj, const char *name,
		   const char **type, unsigned int *size, int *offset)
{	
	Class					klass;
	struct objc_ivar_list	*ivars;
	struct objc_ivar		*ivar = 0;

	if (obj == nil) return NO;
	//class = GSObjCClass([obj class]);
    klass = [(NSObject *)obj class];

	while (klass != nil && ivar == 0)
	{
		ivars = klass->ivars;
		klass = klass->super_class;
		if (ivars != 0)
		{
			int	i;

			for (i = 0; i < ivars->ivar_count; i++)
			{
				if (strcmp(ivars->ivar_list[i].ivar_name, name) == 0)
				{
					ivar = &ivars->ivar_list[i];
					break;
				}
			}
		}
	}
	if (ivar == 0)
	{
		return NO;
	}

	if (type)
		*type = ivar->ivar_type;
	if (size)
		*size = objc_sizeof_type(ivar->ivar_type);
	if (offset)
		*offset = ivar->ivar_offset;
  return YES;
}

/**
 * This is used internally by the key-value coding methods, to set a
 * value in an object either via an accessor method (if sel is
 * supplied), or via direct access (if type, size, and offset are
 * supplied).<br />
 * Automatic conversion between NSNumber and C scalar types is performed.<br />
 * If type is null and can't be determined from the selector, the
 * [NSObject-handleTakeValue:forUnboundKey:] method is called to try
 * to set a value.
 */
void GSObjCSetVal(NSObject *self, const char *key, id val, SEL sel,
  const char *type, unsigned size, int offset)
{
  static NSNull	*null = nil;

  if (null == nil)
    {
      null = [NSNull new];
    }
  if (sel != 0)
    {
      NSMethodSignature	*sig = [self methodSignatureForSelector: sel];

      if ([sig numberOfArguments] != 3)
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"key-value set method has wrong number of args"];
	}
      type = [sig getArgumentTypeAtIndex: 2];
    }
  if (type == NULL)
    {
      [self setValue: val forUndefinedKey: [NSString stringWithUTF8String: key]];
    }
  else if ((val == nil || val == null) && *type != _C_ID && *type != _C_CLASS)
    {
      [self setNilValueForKey: [NSString stringWithUTF8String: key]];
    }
  else
    {
      switch (*type)
	{
	  case _C_ID:
	  case _C_CLASS:
	    {
	      id	v = val;

	      if (sel == 0)
		{
		  id *ptr = (id *)((char *)self + offset);

		  ASSIGN(*ptr, v);
		}
	      else
		{
		  void	(*imp)(id, SEL, id) =
		    (void (*)(id, SEL, id))[self methodForSelector: sel];

		  (*imp)(self, sel, val);
		}
	    }
	    break;

	  case _C_CHR:
	    {
	      char	v = [val charValue];

	      if (sel == 0)
		{
		  char *ptr = (char *)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, char) =
		    (void (*)(id, SEL, char))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_UCHR:
	    {
	      unsigned char	v = [val unsignedCharValue];

	      if (sel == 0)
		{
		  unsigned char *ptr = (unsigned char*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, unsigned char) =
		    (void (*)(id, SEL, unsigned char))[self methodForSelector:
		    sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_SHT:
	    {
	      short	v = [val shortValue];

	      if (sel == 0)
		{
		  short *ptr = (short*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, short) =
		    (void (*)(id, SEL, short))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_USHT:
	    {
	      unsigned short	v = [val unsignedShortValue];

	      if (sel == 0)
		{
		  unsigned short *ptr;

		  ptr = (unsigned short*)((char *)self + offset);
		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, unsigned short) =
		    (void (*)(id, SEL, unsigned short))[self methodForSelector:
		    sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_INT:
	    {
	      int	v = [val intValue];

	      if (sel == 0)
		{
		  int *ptr = (int*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, int) =
		    (void (*)(id, SEL, int))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_UINT:
	    {
	      unsigned int	v = [val unsignedIntValue];

	      if (sel == 0)
		{
		  unsigned int *ptr = (unsigned int*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, unsigned int) =
		    (void (*)(id, SEL, unsigned int))[self methodForSelector:
		    sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_LNG:
	    {
	      long	v = [val longValue];

	      if (sel == 0)
		{
		  long *ptr = (long*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, long) =
		    (void (*)(id, SEL, long))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_ULNG:
	    {
	      unsigned long	v = [val unsignedLongValue];

	      if (sel == 0)
		{
		  unsigned long *ptr = (unsigned long*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, unsigned long) =
		    (void (*)(id, SEL, unsigned long))[self methodForSelector:
		    sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

#ifdef	_C_LNG_LNG
	  case _C_LNG_LNG:
	    {
	      long long	v = [val longLongValue];

	      if (sel == 0)
		{
		  long long *ptr = (long long*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, long long) =
		    (void (*)(id, SEL, long long))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;
#endif
#ifdef	_C_ULNG_LNG
	  case _C_ULNG_LNG:
	    {
	      unsigned long long	v = [val unsignedLongLongValue];

	      if (sel == 0)
		{
		  unsigned long long *ptr = (unsigned long long*)((char*)self +
								  offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, unsigned long long) =
		    (void (*)(id, SEL, unsigned long long))[self
		    methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;
#endif

	  case _C_FLT:
	    {
	      float	v = [val floatValue];

	      if (sel == 0)
		{
		  float *ptr = (float*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, float) =
		    (void (*)(id, SEL, float))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  case _C_DBL:
	    {
	      double	v = [val doubleValue];

	      if (sel == 0)
		{
		  double *ptr = (double*)((char *)self + offset);

		  *ptr = v;
		}
	      else
		{
		  void	(*imp)(id, SEL, double) =
		    (void (*)(id, SEL, double))[self methodForSelector: sel];

		  (*imp)(self, sel, v);
		}
	    }
	    break;

	  default:
	    [NSException raise: NSInvalidArgumentException
			format: @"key-value set method has unsupported type"];
	}
    }
}



@implementation NSObject (Jag)

- (void) setValue: (id)anObject forUndefinedKey: (NSString*)aKey
{
	NSDictionary	*dict;
	NSException	*exp; 
	static IMP	o = 0;

	/* Backward compatibility hack */
	if (o == 0)
    {
		o = [NSObject instanceMethodForSelector:@selector(handleTakeValue:forUnboundKey:)];
    }
	if ([self methodForSelector: @selector(handleTakeValue:forUnboundKey:)] != o)
    {
		[self handleTakeValue: anObject forUnboundKey: aKey];
		return;
    }

	dict = [NSDictionary dictionaryWithObjectsAndKeys:
		(anObject ? (id)anObject : (id)@"(nil)"), @"NSTargetObjectUserInfoKey",
		(aKey ? (id)aKey : (id)@"(nil)"), @"NSUnknownUserInfoKey",
		nil];
	exp = [NSException exceptionWithName: NSInvalidArgumentException
				reason: @"Unable to set nil value for key"
			      userInfo: dict];
	[exp raise];
}

- (void) setNilValueForKey: (NSString*)aKey
{
	static IMP	o = 0;

	/* Backward compatibility hack */
	if (o == 0)
	{
      o = [NSObject instanceMethodForSelector:
		@selector(unableToSetNilForKey:)];
    }
	if ([self methodForSelector: @selector(unableToSetNilForKey:)] != o)
    {
		[self unableToSetNilForKey: aKey];
    }

	[NSException raise: NSInvalidArgumentException
	      format: @"%@ -- %@ 0x%x: Given nil value to set for key \"%@\"",
    NSStringFromSelector(_cmd), NSStringFromClass([self class]), self, aKey];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	SEL			sel = 0;
	const char	*type = 0;
	int			off;
	unsigned	size = [key length];

	if (size > 0)
	{
		const char	*name;
		char		buf[size+6];
		char		lo;
		char		hi;

		// make _setKey: from key
		strcpy(buf, "_set");
		[key getCString: &buf[4]];
		lo = buf[4];
		hi = islower(lo) ? toupper(lo) : lo;
		buf[4] = hi;
		buf[size+4] = ':';
		buf[size+5] = '\0';

		name = &buf[1];	// setKey:
		type = NULL;
		sel = sel_getUid(name);
		if (sel == 0 || [self respondsToSelector: sel] == NO)
		{
			name = buf;	// _setKey:
			sel = sel_getUid(name);
			if (sel == 0 || [self respondsToSelector: sel] == NO)
			{
				sel = 0;
				if ([[self class] accessInstanceVariablesDirectly] == YES)
				{
					buf[size+4] = '\0';
					buf[3] = '_';
					buf[4] = lo;
					name = &buf[4];	// key
					if (GSObjCFindVariable(self, name, &type, &size, &off) == NO)
					{
						name = &buf[3];	// _key
						GSObjCFindVariable(self, name, &type, &size, &off);
					}
				}
			}
			
		}
	}
	GSObjCSetVal(self, [key UTF8String], value, sel, type, size, off);
}

@end
#endif

@implementation EODatabaseContext

+ (void)load
{
	// Needs to be registered, regardless of use.
	[[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(_objectStoreNeeded:) name:EOCooperatingObjectStoreNeeded object:nil];
}

+ (void)_objectStoreNeeded:(NSNotification *)notification
{
	EOObjectStoreCoordinator	*aCoordinator = [notification object];
	
	[aCoordinator lock];
	
	NS_DURING
		NSDictionary			*userInfo;
		EOModelGroup			*modelGroup;
		EOModel					*model = nil;
		EOFetchSpecification	*fetch;
		EOGlobalID				*globalID;
		id							object;

		userInfo = [notification userInfo];
		modelGroup = [EOModelGroup defaultModelGroup];
		
		fetch = [userInfo objectForKey:@"fetchSpecification"];
		if (fetch != nil) {
			model = [[modelGroup entityNamed:[fetch entityName]] model];
		}
		if (model == nil && (globalID = [userInfo objectForKey:@"globalID"]) != nil) {
			model = [[modelGroup entityNamed:[globalID entityName]] model];
		}
		if (model == nil && (object = [userInfo objectForKey:@"object"]) != nil) {
			model = [[modelGroup entityNamed:[object entityName]] model];
		}
		
		if (model != nil) {
			// So, something above produced a model, so we can attempt the creation of a database context. This method, if it can, will create and register the database context.
			[[self class] registeredDatabaseContextForModel:model objectStoreCoordinator:aCoordinator];
		}
	NS_HANDLER
		[aCoordinator unlock];
		[localException raise];
	NS_ENDHANDLER
	
	[aCoordinator unlock];
}

- (id)initWithDatabase:(EODatabase *)aDatabase
{
	[super init];
	
   database = [aDatabase retain];
// mont_rothstein @ yahoo.com 2005-1-2
// The database context's objects instance variable was removed
//	objects = [[NSMutableDictionary allocWithZone:[self zone]] init];
   adaptorContext = [[[database adaptor] createAdaptorContext] retain];
	lockedObjects = [[NSMutableSet allocWithZone:[self zone]] init];
	databaseChannels = [[NSMutableArray allocWithZone:[self zone]] init];
	// mont_rothstein @ yahoo.com 2004-12-19
	// Added creation of new instance variable
	tempJoinIDs = [[NSMutableSet allocWithZone: [self zone]] init];
	
	[self setUpdateStrategy:EOUpdateWithOptimisticLocking];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_adaptorContextDidBeginTransaction:) name:EOAdaptorContextBeginTransactionNotification object:adaptorContext];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_adaptorContextDidCommitTransaction:) name:EOAdaptorContextCommitTransactionNotification object:adaptorContext];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_adaptorContextDidRollbackTransaction:) name:EOAdaptorContextRollbackTransactionNotification object:adaptorContext];

   return self;
}

- (void)dealloc
{
	int		x;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Remove our channels one at a time.
	for (x = [databaseChannels count] - 1; x >= 0; x--) {
		[self unregisterChannel:[databaseChannels objectAtIndex:x]];
	}
	
	[lockedObjects release]; lockedObjects = nil;
   [database release]; database = nil;
   [snapshots release]; snapshots = nil;
// mont_rothstein @ yahoo.com 2005-1-2
// The database context's objects instance variable was removed.
//	[objects release]; objects = nil;
   [adaptorContext release]; adaptorContext = nil;
	[lock release];
	// mont_rothstein @ yahoo.com 2004-12-19
	// Added release of new instance variable
	[tempJoinIDs release];

   [super dealloc];
}

+ (EODatabaseContext *)registeredDatabaseContextForModel:(EOModel *)aModel objectStoreCoordinator:(EOObjectStoreCoordinator *)objectStore
{
	NSArray		*objectStores = [objectStore cooperatingObjectStores];
	int			x;
	int numObjectStores;
	EODatabase	*aDatabase;
	id				childObjectStore;
	
	// Loop and try to find a database context.
	numObjectStores = [objectStores count];
	for (x = 0; x < numObjectStores; x++) {
		childObjectStore = [objectStores objectAtIndex:x];
		if ([childObjectStore isKindOfClass:[EODatabaseContext class]] && [[(EODatabaseContext *)childObjectStore database] addModelIfCompatible:aModel]) {
			return (EODatabaseContext *)childObjectStore;
		}
	}
	
	// Couldn't find one, so create one...
	aDatabase = [[EODatabase alloc] initWithModel:aModel];
	childObjectStore = [[[EODatabaseContext contextClassToRegister] alloc] initWithDatabase:aDatabase];
	// And add it to the cooperating object store.
	[objectStore addCooperatingObjectStore:childObjectStore];
	[childObjectStore release];
	[aDatabase release]; // Don't hold on to it.

	return childObjectStore;
}

+ (EODatabaseContext *)registeredDatabaseContextForModel:(EOModel *)aModel editingContext:(EOEditingContext *)anEditingContext;
{
	id			objectStore;
	
	objectStore = [anEditingContext rootObjectStore];
	if ([objectStore isKindOfClass:[EOObjectStoreCoordinator class]]) {
		return [self registeredDatabaseContextForModel:aModel objectStoreCoordinator:objectStore];
	} else if ([objectStore isKindOfClass:[EODatabaseContext class]]) {
		[[(EODatabaseContext *)objectStore database] addModelIfCompatible:aModel];
		return (EODatabaseContext *)objectStore;
	}
	
	[NSException raise:EODatabaseException format:@"Unable to register a database context for model %@", aModel];
	
	return nil;
}

static Class _eoDatabaseContextClass = Nil;

+ (Class)contextClassToRegister
{
	if (_eoDatabaseContextClass == Nil) return [EODatabaseContext class];
	return _eoDatabaseContextClass;
}

+ (void)setContextClassToRegister:(Class)contextClass
{
	_eoDatabaseContextClass = contextClass;
}

- (EOAdaptorContext *)adaptorContext
{
   return adaptorContext;
}

- (void)_assertLock
{
	if (EODatabaseContextDebugEnabled && ![lock isLocking]) {
		[EOLog logDebugWithFormat:@"Attempt to access a database context (%p) when not locked.", self];
	}
}

- (void)_assertSaving:(SEL)sender
{
	[self _assertLock];
	if (savingContext == nil) {
		[NSException raise:EODatabaseException format:@"Attempt to call %@ while not in a save cycle.", NSStringFromSelector(sender)];
	}
}

- (EODatabaseChannel *)availableChannel
{
	EODatabaseChannel		*channel;
	int						precount;
	int						x;
	int numDatabaseChannels;
	
	[self _assertLock];
	
	// See if any of our channels is currently busy.
	numDatabaseChannels = [databaseChannels count];
	for (x = 0; x < numDatabaseChannels; x++) {
		channel = [databaseChannels objectAtIndex:x];
		if (![channel isFetchInProgress]) {
			return channel;
		}
	}
	
	// See if someone else will create a channel for us.
	precount = [databaseChannels count];
	[[NSNotificationCenter defaultCenter] postNotificationName:EODatabaseChannelNeededNotification object:self];
	if (precount != [databaseChannels count] && ![[databaseChannels lastObject] isFetchInProgress]) {
		channel = [databaseChannels lastObject];
		return channel;
	}
	
	// Nope, so create a channel on our very ownsome.
	channel = [[EODatabaseChannel alloc] initWithDatabaseContext:self];
	[self registerChannel:channel];
	[channel release];
	
   return channel;
}

- (void)registerChannel:(EODatabaseChannel *)aChannel
{
	[self _assertLock];
	[databaseChannels addObject:aChannel];
	[aChannel _setDatabaseContext:self];
}

- (NSArray *)registeredChannels
{
	[self _assertLock];
	
	return databaseChannels;
}

- (void)unregisterChannel:(EODatabaseChannel *)aChannel
{
	[self _assertLock];
	if ([databaseChannels indexOfObjectIdenticalTo:aChannel] != NSNotFound) {
		// Only unregister is we contain the channel in the first place.
		[aChannel retain];
		[databaseChannels removeObjectIdenticalTo:aChannel];
		[aChannel _setDatabaseContext:nil];
		[aChannel release];
	}
}

- (void)lock
{
	[super lock];
}

- (void)unlock
{
	[super unlock];
}

- (EODatabase *)database
{
   return database;
}

- (BOOL)_handlesEntityNamed:(NSString *)entityName
{
	return [database entityNamed:entityName] != nil;
}

- (BOOL)handlesFetchSpecification:(EOFetchSpecification *)fetchSpecification
{
	return [database entityNamed:[fetchSpecification entityName]] != nil;
}

- (BOOL)ownsGlobalID:(EOGlobalID *)globalID
{
	return [[self database] entityNamed:[globalID entityName]] != nil;
}

- (BOOL)ownsObject:(id)object
{
	return [self ownsGlobalID:[[object editingContext] globalIDForObject:object]];
}

- (EOGlobalID *)_globalIdFromPrimaryKeyQualifier:(EOQualifier *)aQualifier entity:(EOEntity *)entity
{
	NSMutableDictionary	*pk;
	EOGlobalID			*gid;
	pk = [[NSMutableDictionary allocWithZone:[self zone]] init]; 
	if ([[entity primaryKeyAttributes] count] > 1)
	{
		NSArray				*parts = [(EOAndQualifier *)aQualifier qualifiers];
		EOKeyValueQualifier	*subqualifier; 
		int					numParts = [parts count];
		int					x;         
		
		for (x = 0; x < numParts; x++) 
		{
			subqualifier = [parts objectAtIndex:x];
			[pk setObject:[subqualifier value] forKey:[subqualifier key]];	 
		}
	} 
	else 
	{   
		[pk setObject:[(EOKeyValueQualifier *)aQualifier value] forKey:[(EOKeyValueQualifier *)aQualifier key]];	 
	}
	   
	gid = [entity globalIDForRow:pk]; 
	[pk release];
	return gid;     
}

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)fetchSpecification editingContext:(EOEditingContext *)anEditingContext
{
	NSMutableArray		*fetchedObjects = nil;
	BOOL					refresh;
	EODatabaseChannel	*channel;
	id						object;
	unsigned int fetchedObjectsCount = 0;
	unsigned int fetchLimit = [fetchSpecification fetchLimit];
	BOOL continueFetching = YES;
	NSException *exception = nil;
	
	[self _assertLock];
	refresh = [fetchSpecification refreshesObjects];
	
	// if refresh is NO AND the qualifier is a primary key qualifier, we may avoid a round trip to the database
	// by checking our cache
	if (! refresh)
	{
		EOEntity	*entity;

		entity = [[self database] entityNamed:[fetchSpecification entityName]];
		if ([entity isQualifierForPrimaryKey:[fetchSpecification qualifier]])
		{
			// go for it.
			EOGlobalID *gid = [self _globalIdFromPrimaryKeyQualifier:[fetchSpecification qualifier] entity:entity];
			object = [anEditingContext objectForGlobalID:gid];
			if (object)
				return [NSArray arrayWithObject:object]; 
		}
	}
	
	NS_DURING
		fetchedObjects = [[NSMutableArray allocWithZone:[self zone]] init];
		channel = [self availableChannel];
		if (!channel) {
			[NSException raise:EODatabaseException format:@"Unable to obtain a database channel."];
		}
		
		// mont_rothstein @ yahoo.com 2005-06-27
		// If the update strategy is pessimistic locking then override the setting on the
		// fetch specification to always lock
		if ([self updateStrategy] == EOUpdateWithPessimisticLocking)
		{
			[fetchSpecification setLocksObjects: YES];
		}

		[channel selectObjectsWithFetchSpecification:fetchSpecification inEditingContext:anEditingContext];
		while (continueFetching && (object = [channel fetchObject])) {
// mont_rothstein @ yahoo.com 2005-1-2
// The section below was commented out because the database context has no need for and
// should not have a pointer to the fetched objects.  This was causing problems because
// objects from one WO session were being retrieved from this store by another session.
//			EOGlobalID	*globalID = [[object editingContext] globalIDForObject:object];
//			
//			if (refresh || ![objects objectForKey:globalID]) {
//				[objects setObject:object forKey:globalID];
//			}
			
			[fetchedObjects addObject:object];
			fetchedObjectsCount++;
			if ((fetchLimit >0) && (fetchedObjectsCount % fetchLimit == 0)) {
				// @todo: call editing context message handler
				continueFetching = NO;
			}
		}
	NS_HANDLER
		[fetchedObjects release];
		exception = localException;
	NS_ENDHANDLER
	
	[channel cancelFetch];
	if (exception) {
		[exception raise];
	}
	return [fetchedObjects autorelease];
}

- (NSArray *)_objectsForOneToManyWithGlobalID:(EOGlobalID *)globalID 
								 relationship:(EORelationship *)relationship 
							   editingContext:(EOEditingContext *)editingContext
{
	EOFetchSpecification		*fetch;
	EOQualifier					*qualifier;
	NSDictionary				*snapshot;
	NSArray						*fetchedObjects;
	
	[self _assertLock];
	
	snapshot = [self snapshotForGlobalID:globalID];
	
	// mont_rothstein @ yahoo.com 2005-03-16
	// Added handling of restrictingQualifier
	if ([relationship restrictingQualifier])
	{
		qualifier = [EOAndQualifier qualifierFor:  [relationship qualifierWithSourceRow:snapshot]
											 and: [relationship restrictingQualifier]];
	}
	else
	{
		qualifier = [relationship qualifierWithSourceRow:snapshot];
	}
	
	// mont_rotshtein @ yahoo.com 2004-12-20
	// Added sort orderings parameter
	fetch = [EOFetchSpecification fetchSpecificationWithEntityName:[[relationship destinationEntity] name] qualifier:qualifier sortOrderings: [relationship sortOrderings]];
	[fetch setUsesDistinct:YES];
	
	fetchedObjects = [self objectsWithFetchSpecification:fetch editingContext:editingContext];
	
	return fetchedObjects;
}


- (NSArray *)_objectsForFlattenedOneToManyWithGlobalID:(EOGlobalID *)globalID 
										  relationship:(EORelationship *)relationship 
										editingContext:(EOEditingContext *)editingContext
{
   EOFetchSpecification		*fetch;
   EOQualifier					*qualifier;
   NSDictionary				*snapshot;
	NSArray						*fetchedObjects;
	
	[self _assertLock];
	
   snapshot = [self snapshotForGlobalID:globalID];
	qualifier = [relationship qualifierWithSourceRow:snapshot];
	
	// mont_rotshtein @ yahoo.com 2004-12-20
	// Added sort orderings parameter
   fetch = [EOFetchSpecification fetchSpecificationWithEntityName:[[relationship destinationEntity] name] qualifier:qualifier sortOrderings: [relationship sortOrderings]];
   [fetch setUsesDistinct:YES];
   [fetch _setRootEntityName:[[relationship entity] name]];
	
   fetchedObjects = [self objectsWithFetchSpecification:fetch editingContext:editingContext];
	
	return fetchedObjects;
}

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext
{
   EORelationship		*relationship;
	NSArray				*fetchedObjects;
	
	[self _assertLock];
	
   relationship = [[database entityNamed:[globalID entityName]] relationshipNamed:relationshipName];
   if (relationship == nil) {
      [NSException raise:EODatabaseException format:@"Cannot fire to-many fault because there's no relationship named %@ from entity %@.", relationshipName, [globalID entityName]];
   }
	
   if ([relationship definition] == nil) {
	   fetchedObjects = [self _objectsForOneToManyWithGlobalID:globalID relationship:relationship editingContext:anEditingContext];
   } else {
		fetchedObjects = [self _objectsForFlattenedOneToManyWithGlobalID:globalID relationship:relationship editingContext:anEditingContext];
   }
	
	return fetchedObjects;
}

- (void)batchFetchRelationship:(EORelationship *)relationship forSourceObjects:(NSArray *)objects editingContext:(EOEditingContext *)anEditingContext
{
}

- (void)_initializeObject:(id)object withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	EOEntityClassDescription	*classDescription;
	NSArray							*classProperties;
	NSString							*key;
	id									value;
	int								x, max;
	NSDictionary					*snapshot;
	
	classDescription = (EOEntityClassDescription *)[object classDescription];
	classProperties = [[classDescription entity] _classAttributes];
	snapshot = [self snapshotForGlobalID:globalID];
	
	// We can only initialize the object if we have a snapshot for it. Note, if we don't have a snapshot, then the likely hood is the object was fetch through some database other than our own.
	if (snapshot == nil) {
		[NSException raise:NSInternalInconsistencyException format:@"-[EODatabaseContext initializeObject:withGlobalID:editingContext:]: Unable to find a snapshot for object with globalID: %@", globalID];
	}

	// Go ahead and initialize it's properties.
	for (x = 0, max = [classProperties count]; x < max; x++) {
		key = [classProperties objectAtIndex:x];
		value = [snapshot objectForKey:key];
		// Call the underscore method, since we're fetch from the database. This will give any subclasses the chance to by-pass business logic.
		// mont_rothstein @ yahoo.com 2005-09-11
		// Yet another place where NSNull values weren't being handled properly.
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//if (value != [NSNull null])	[object takeStoredValue:value forKey:key];
		if (value != [NSNull null])	[object setValue:value forKey:key];
	}
}

- (void)initializeObject:(id)object withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	// If the global ID is temporary, then the object is scheduled for insertion. In such a case, we don't increment the snapshot.
	if ([globalID isTemporary]) return;
	
	// Copy the values from the snapshot into the object.
	[self _initializeObject:object withGlobalID:globalID editingContext:anEditingContext];
	
	// And increment the referernce count, since we now officially refer to the object. Note that we increment the reference count here, but we'll also do it for objects that successfully commit, since after commit, they then have a snapshot.
	[database incrementSnapshotCountForGlobalID:globalID];
}

- (void)editingContext:(EOEditingContext *)anEditingContext didForgetObject:(id)object withGlobalID:(EOGlobalID *)globalID
{
	[[self database] decrementSnapshotCountForGlobalID:globalID];
}

- (void)setDelegate:(id)aDelegate
{
	// Delegates are seldom retained.
	delegate = aDelegate;

	// This may seem like a lot of work, but it helps when we're going to call delegate methods a lot to check if it responds to the various selectors just once.
	delegateRespondsToDidFetchObjectsFetchSpecificationEditingContext = 
		[delegate respondsToSelector:@selector(databaseContext:didFetchObjects:fetchSpecification:editingContext:)];
	delegateRespondsToDidSelectObjectsWithFetchSpecificationDatabaseChannel = 
		[delegate respondsToSelector:@selector(databaseContext:didSelectObjectsWithFetchSpecification:databaseChannel:)];
	delegateRespondsToFailedToFetchObjectGlobalID = 
		[delegate respondsToSelector:@selector(databaseContext:failedToFetchObject:globalID:)];
	delegateRespondsToNewPrimaryKeyForObjectEntity = 
		[delegate respondsToSelector:@selector(databaseContext:newPrimaryKeyForObject:entity:)];
	delegateRespondsToShouldFetchArrayFault = 
		[delegate respondsToSelector:@selector(databaseContext:shouldFetchArrayFault:)];
	delegateRespondsToShouldFetchObjectFault = 
		[delegate respondsToSelector:@selector(databaseContext:shouldFetchObjectFault:)];
	delegateRespondsToShouldFetchObjectsWithFetchSpecificationEditingContext = 
		[delegate respondsToSelector:@selector(databaseContext:shouldFetchObjectsWithFetchSpecification:editingContext:)];
	delegateRespondsToShouldInvalidateObjectWithGlobalIDSnapshot = 
		[delegate respondsToSelector:@selector(databaseContext:shouldInvalidateObjectWithGlobalID:snapshot:)];
	delegateRespondsToShouldLockObjectWithGlobalIDSnapshot = 
		[delegate respondsToSelector:@selector(databaseContext:shouldLockObjectWithGlobalID:snapshot:)];
	delegateRespondsToShouldRaiseExceptionForLockFailure = 
		[delegate respondsToSelector:@selector(databaseContext:shouldRaiseExceptionForLockFailure:)];
	delegateRespondsToShouldSelectObjectsWithFetchSpecificationDatabaseChannel = 
		[delegate respondsToSelector:@selector(databaseContext:shouldSelectObjectsWithFetchSpecification:databaseChannel:)];
	delegateRespondsToShouldUpdateCurrentSnapshotNewSnapshotGlobalIDDatabaseChannel = 
		[delegate respondsToSelector:@selector(databaseContext:shouldUpdateCurrentSnapshot:newSnapshot:globalID:databaseChannel:)];
	delegateRespondsToShouldUsePessimisticLockWithFetchSpecificationDatabaseChannel = 
		[delegate respondsToSelector:@selector(databaseContext:shouldUsePessimisticLockWithFetchSpecification:databaseChannel:)];
	delegateRespondsToWillOrderAdaptorOperationsFromDatabaseOperations = 
		[delegate respondsToSelector:@selector(databaseContext:willOrderAdaptorOperationsFromDatabaseOperations:)];
	delegateRespondsToWillPerformAdaptorOperationsAdaptorChannel = 
		[delegate respondsToSelector:@selector(databaseContext:willPerformAdaptorOperations:adaptorChannel:)];
	delegateRespondsToWillRunLoginPanelToOpenDatabaseChannel = 
		[delegate respondsToSelector:@selector(databaseContext:willRunLoginPanelToOpenDatabaseChannel:)];
}

- (id)delegate
{
	return delegate;
}

- (BOOL)hasBusyChannels
{
	int			x;
	int numDatabaseChannels;
	
	numDatabaseChannels = [databaseChannels count];
	for (x = 0; x < numDatabaseChannels; x++) {
		if ([[databaseChannels objectAtIndex:x] isFetchInProgress]) return YES;
	}
	
	return NO;
}

- (void)_cleanUpTransactions
{
	[self forgetAllLocks];
	[snapshots release]; snapshots = nil;
	[forgetSnapshots release]; forgetSnapshots = nil;
	// Anything to clean in the database?
}

- (void)_adaptorContextDidBeginTransaction:(NSNotification *)notification
{
	[self _assertLock];
	if (snapshots) {
		[NSException raise:EODatabaseException format:@"Nesting transactions are not supported."];
	}
	snapshots = [[NSMutableDictionary allocWithZone:[self zone]] init];
	forgetSnapshots = [[NSMutableSet allocWithZone:[self zone]] init];
}

- (void)_adaptorContextDidCommitTransaction:(NSNotification *)notification
{
	[self _assertLock];
	if (snapshots != nil) {
		NSEnumerator		*enumerator = [forgetSnapshots objectEnumerator];
		EOGlobalID			*globalID;
		
		while ((globalID = [enumerator nextObject]) != nil) {
			[database forgetSnapshotForGlobalID:globalID];
		}
		
		[database recordSnapshots:snapshots];
	}
	[self _cleanUpTransactions];
}

- (void)_adaptorContextDidRollbackTransaction:(NSNotification *)notification
{
	[self _assertLock];
	[self _cleanUpTransactions];
}

#define ASSERT_SNAPSHOTS() { \
	if (snapshots == nil) { \
		[NSException raise:NSInternalInconsistencyException format:@"Can't call %@ without a transaction.", NSStringFromSelector(_cmd)]; \
	} \
}

- (void)forgetSnapshotForGlobalID:(EOGlobalID *)globalID
{
	// mont_rothstein @ yahoo.com 2005-08-08
	// Modified this to be a cover for forgetSnapshotsForGlobalIDs:
	[self forgetSnapshotsForGlobalIDs: [NSArray arrayWithObject: globalID]];
//	[self _assertLock];
//	// mont_rothstein @ yahoo.com 2005-07-06
//	// Removed the assert for snapshots.  Instead we pass the call on to the database
//	// if there aren't any snapshots in this database context.
////	ASSERT_SNAPSHOTS();
//	if ([snapshots count]) [forgetSnapshots addObject:globalID];
//	else [database forgetSnapshotForGlobalID: globalID];
}

- (void)forgetSnapshotsForGlobalIDs:(NSArray *)globalIDs
{
	[self _assertLock];
	// mont_rothstein @ yahoo.com 2005-07-06
	// Removed the assert for snapshots.  Instead we pass the call on to the database
	// if there aren't any snapshots in this database context.
//	ASSERT_SNAPSHOTS();
	if ([snapshots count]) 
	{
		[forgetSnapshots addObjectsFromArray:globalIDs];
		// mont_rothstein @ yahoo.com 2005-08-08
		// Added notification if this object is forgetting the objects instead of having the EODatabase do it
		[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:self userInfo:[NSDictionary dictionaryWithObject:globalIDs forKey:EOInvalidatedKey]];
	}
	else [database forgetSnapshotsForGlobalIDs: globalIDs];
}

- (NSDictionary *)localSnapshotForGlobalID:(EOGlobalID *)globalID
{
	NSDictionary	*snapshot;
	
	[self _assertLock];
	snapshot = [snapshots objectForKey:globalID];
	
	return snapshot;
}

- (void)recordSnapshot:(NSDictionary *)snapshot forGlobalID:(EOGlobalID *)globalID
{
	[self _assertLock];
	ASSERT_SNAPSHOTS();
	[snapshots setObject:snapshot forKey:globalID];
}

- (void)recordSnapshots:(NSDictionary *)someSnapshots
{
	[self _assertLock];
	ASSERT_SNAPSHOTS();
	[snapshots addEntriesFromDictionary:someSnapshots];
}

- (NSDictionary *)snapshotForGlobalID:(EOGlobalID *)globalID
{
	NSDictionary	*snapshot;
	
	[self _assertLock];
	if ((snapshot = [snapshots objectForKey:globalID]) == nil) {
		snapshot = [database snapshotForGlobalID:globalID];
	}
	
	return snapshot;
}

- (void)recordSnapshot:(NSArray *)globalIDs forSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name
{
	[self _assertLock];
	ASSERT_SNAPSHOTS();
	[[snapshots objectForKey:globalID] setObject:globalIDs forKey:name];
}

- (NSArray *)snapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name
{
	NSArray		*globalIDs;
	
	[self _assertLock];
	if ((globalIDs = [[snapshots objectForKey:globalID] objectForKey:name]) == nil) {
		globalIDs = [database snapshotForSourceGlobalID:globalID relationshipName:name];
	}
	
	return globalIDs;
}

- (NSArray *)localSnapshotForSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)name
{
	NSArray		*value;
	
	[self _assertLock];
	value = [[snapshots objectForKey:globalID] objectForKey:name];
	
	return value;
}

- (void)recordToManySnapshots:(NSDictionary *)someSnapshots
{
}

- (void)setUpdateStrategy:(EOUpdateStrategy)strategy
{
	if ([[database snapshots] count] != 0) {
		[NSException raise:NSInvalidArgumentException format:@"Cannot change the update strategy once objects have been fetched. Call -invalidateAllObjects before changing the update strategy."];
	}
	updateStrategy = strategy;
}

- (EOUpdateStrategy)updateStrategy
{
	return updateStrategy;
}

- (void)registerLockedObjectWithGlobalID:(EOGlobalID *)globalID
{
	[self _assertLock];
	[lockedObjects addObject:globalID];
}

- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID
{
	[self _assertLock];
	return [lockedObjects containsObject:globalID];
}

- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	return [self isObjectLockedWithGlobalID:globalID];
}

- (void)forgetAllLocks
{
	[self _assertLock];
	[lockedObjects removeAllObjects];
}

- (void)forgetLocksForObjectsWithGlobalIDs:(NSArray *)globalIDs
{
	int				x;
	int numGlobalIDs;
	
	[self _assertLock];
	
	numGlobalIDs = [globalIDs count];
	for (x = 0; x < numGlobalIDs; x++) {
		[lockedObjects removeObject:[globalIDs objectAtIndex:x]];
	}
}


// mont_rothstein @ yahoo.com 2005-06-23
// Added private method build the qualifier for the locking attributes
- (EOQualifier *)_lockingQualifierForEntity:(EOEntity *)entity 
								andSnapshot:(NSDictionary *)snapshot
{
	NSEnumerator *lockingAttributes;
	EOAttribute *lockingAttribute;
	NSMutableArray *qualifiers;
	EOQualifier *qualifier;
	
	lockingAttributes = [[entity attributesUsedForLocking] objectEnumerator];
	qualifier = [NSMutableArray array];

	while (lockingAttribute = [lockingAttributes nextObject])
	{
		qualifier = [EOKeyValueQualifier 
						qualifierWithKey: [lockingAttribute name]
								   value: [snapshot valueForKey: [lockingAttribute name]]];
		[qualifiers addObject: qualifier];
	}
	
	return [EOAndQualifier qualifierWithArray: qualifiers];
}


- (void)lockObjectWithGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	NSDictionary			*snapshot;
	EOEntity				*entity;
	EOFetchSpecification	*fetchSpecification;
	NSArray					*results;
	EOQualifier				*qualifier;
	
	[self _assertLock];
	
	// Can't lock what we don't own.
	snapshot = [snapshots objectForKey:globalID];
	if (snapshot == nil) return;
	
	if (delegateRespondsToShouldLockObjectWithGlobalIDSnapshot && ![delegate databaseContext:self shouldLockObjectWithGlobalID:globalID snapshot:[snapshots objectForKey:globalID]]) {
		// Delegate told us not to lock this object.
		return;
	}
	
	entity = [database entityNamed:[globalID entityName]];
	NS_DURING
		// mont_rothstein @ yahoo.com 2005-06-23
		// Modified to use locking attributes to make sure object has not been modified 
		// before it is locked, instead of using the primary key.
		if (! [[self adaptorContext] hasOpenTransaction])
		{
			[[self adaptorContext] beginTransaction];
		}

		qualifier = [self _lockingQualifierForEntity: entity andSnapshot: snapshot];

		fetchSpecification = [EOFetchSpecification 
			fetchSpecificationWithEntityName: [entity name] 
								   qualifier: qualifier 
							   sortOrderings: nil];
		[fetchSpecification setLocksObjects: YES];
		results = [self objectsWithFetchSpecification:fetchSpecification editingContext:anEditingContext];
		if ([results count] != 1) {
			[NSException raise:NSInternalInconsistencyException format:@"Failed to lock object with GID: %@", globalID];
		}
	NS_HANDLER
		if (delegateRespondsToShouldRaiseExceptionForLockFailure) {
			if ([delegate databaseContext:self shouldRaiseExceptionForLockFailure:localException]) {
				[localException raise];
			}
		} else {
			[localException raise];
		}
	NS_ENDHANDLER
}

- (NSDictionary *)valuesForKeys:(NSArray *)keys object:(id)object
{
	EOEntity		*entity;
	
	[self _assertLock];
	
	entity = [database entityForObject:object];
	if (entity == nil) {
		// Out EO doesn't apparently own this object type, so get the coordinator to do the work.
		return [coordinator valuesForKeys:keys object:object];
	}

	if ([EOFault isFault:object]) {
		NSArray		*pkNames;
		// We can do an good optimization here. There's a fair chance that we're being asked for object's primary key, or at least part of it's primary key. If that's the case, and we have a fault, then there's no need to trip the fault to see those values, since they'll be contained in the EOGlobalID.
		pkNames = [entity primaryKeyAttributeNames];
		if ([keys count] <= [pkNames count]) {
			int			x;
			int numKeys;
			
			// Count if all of keys are contained in pkNames.
			numKeys = [keys count];
			for (x = 0; x < numKeys; x++) {
				if (![pkNames containsObject:[keys objectAtIndex:x]]) break;				
			}
			// If x == [keys count], then all of keys are in pkNames, so we have all the values as part of the primary key and get return our values from the global ID.
			if (x == [keys count]) {
				return [[[object editingContext] globalIDForObject:object] valuesForKeys:keys];
			}
		}
	}
	
	// tom.martin @ riemer.com - 2011-09-16
	// replace depreciated method.  
	return [[self snapshotForGlobalID:[[object editingContext] globalIDForObject:object]] dictionaryWithValuesForKeys:keys];
}

- (void)invalidateAllObjects
{
	NSArray		*globalIDs;
	
	[self _assertLock];
	
	[database invalidateResultCache];
	globalIDs = [[database snapshots] allKeys];
	[self invalidateObjectsWithGlobalIDs:globalIDs];
	// mont_rothstein @ yahoo.com 2005-08-08
	// Modified this notification post to not have a user info dict, but it isn't supposed to.
	[[NSNotificationCenter defaultCenter] postNotificationName:EOInvalidatedAllObjectsInStoreNotification object:self userInfo:nil];
}

- (void)invalidateObjectsWithGlobalIDs:(NSArray *)globalIDs
{
	[self _assertLock];
	
	if (delegateRespondsToShouldInvalidateObjectWithGlobalIDSnapshot) {
		NSMutableArray		*newGlobalIDs = [[NSMutableArray allocWithZone:[self zone]] init];
		int					x;
		int numGlobalIDs;
		
		numGlobalIDs = [globalIDs count];
		for (x = 0; x < numGlobalIDs; x++) {
			EOGlobalID		*globalID = [globalIDs objectAtIndex:x];
			NSDictionary	*snapshot;
			
			snapshot = [self snapshotForGlobalID:globalID];
			if (snapshot && [delegate databaseContext:self shouldInvalidateObjectWithGlobalID:globalID snapshot:snapshot]) {
				[newGlobalIDs addObject:globalID];
			}
		}
		
		if ([newGlobalIDs count]) {
			[self forgetSnapshotsForGlobalIDs:newGlobalIDs];
			[self forgetLocksForObjectsWithGlobalIDs:newGlobalIDs];
			// mont_rothstein @ yahoo.com 2005-08-08
			// Moved this notification to the forgetSnapshotsForGlobalIDs method
//			[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:self userInfo:[NSDictionary dictionaryWithObject:newGlobalIDs forKey:@"globalIDs"]];
		}
		
		[newGlobalIDs release];
	} else {
		[self forgetSnapshotsForGlobalIDs:globalIDs];
		[self forgetLocksForObjectsWithGlobalIDs:globalIDs];
		// mont_rothstein @ yahoo.com 2005-08-08
		// Moved this notification to the forgetSnapshotsForGlobalIDs method
//		[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:self userInfo:[NSDictionary dictionaryWithObject:globalIDs forKey:@"globalIDs"]];
	}
}

- (void)saveChangesInEditingContext:(EOEditingContext *)anEditingContext
{
	NSException		*exception = nil;
	
	[self _assertLock];
	
	NS_DURING
		[self prepareForSaveWithCoordinator:nil editingContext:anEditingContext];
		[self recordChangesInEditingContext];
		[self performChanges];
	NS_HANDLER
		exception = [localException retain];
	NS_ENDHANDLER
	
	NS_DURING
		if (exception) {
			[self rollbackChanges];
		} else {
			[self commitChanges];
		}
	NS_HANDLER
		[exception release];
		exception = [localException retain];
	NS_ENDHANDLER
	
	if (exception) {
		[exception autorelease];
		[exception raise];
	}
}

- (void)_generatePrimaryKeyForObject:(id)object entity:(EOEntity *)entity
{
	NSArray					*pkAttributes = [entity primaryKeyAttributeNames];
	EOTemporaryGlobalID	*currentGlobalID;
	
	currentGlobalID = (EOTemporaryGlobalID *)[[object editingContext] globalIDForObject:object];
	if ([currentGlobalID isTemporary]) {
		// Sanity check: Only do this if we have a temporary ID. If it's not temporary, then a primary has already been set.
		if ([entity _primaryKeyIsPrivate] && [pkAttributes count] == 1) {
			NSDictionary			*primaryKey = nil;
			EOAdaptorChannel		*adaptorChannel;
			
			adaptorChannel = [[self availableChannel] _adaptorChannel:YES]; // Make sure this is created...
			
			NS_DURING
				primaryKey = [[adaptorChannel primaryKeysForNewRowsWithEntity:entity count:1] objectAtIndex:0];
			NS_HANDLER
				[localException raise];
			NS_ENDHANDLER
			[currentGlobalID setNewGlobalID:[entity globalIDForRow:primaryKey]];
		} else {
			[currentGlobalID setNewGlobalID:[entity globalIDForRow:[object primaryKey]]];
		}
	}
}

- (void)_generatePrimaryKeysForObjects:(NSDictionary *)cache
{
	EOAdaptorChannel *channel = [[self availableChannel] _adaptorChannel:YES];
    NSEnumerator *enumerator = [cache keyEnumerator];
	NSString *entityName;
    
	while ((entityName = [enumerator nextObject]) != nil) {
		NSArray *pkObjects = [cache objectForKey:entityName];

		if ([pkObjects count]) { // Just for sanity's sake
            int x, max;
			EOEntity *entity = [database entityNamed:entityName];
            NSArray *pkAttributes = [entity primaryKeyAttributeNames];
            // lon.varscsak @ gmail.com 10/03/2006
            // pkValues only gets assigned and used via primaryKeysForNewRowsWithEntity:count: if the entity's pks are private and it's a single primary key.
			NSArray *pkValues = ([entity _primaryKeyIsPrivate] && [pkAttributes count] == 1) ? [channel primaryKeysForNewRowsWithEntity:entity count:[pkObjects count]] : nil;  
			
			for (x = 0, max = [pkObjects count]; x < max; x++) {
				id object = [pkObjects objectAtIndex:x];
				EOTemporaryGlobalID	*currentGlobalID = (EOTemporaryGlobalID *)[[object editingContext] globalIDForObject:object];
                
                // lon.varscsak @ gmail.com 10/03/2006
                // If the entity's pks are private and it's a single primary key use the PK values that came from primaryKeysForNewRowsWithEntity:count: otherwise just use the -primaryKey values from the object
                if ([entity _primaryKeyIsPrivate] && [pkAttributes count] == 1)
                    [currentGlobalID setNewGlobalID:[entity globalIDForRow:[pkValues objectAtIndex:x]]];
                else
                    [currentGlobalID setNewGlobalID:[entity globalIDForRow:[object primaryKey]]];
			}
		}
	}
}

- (void)prepareForSaveWithCoordinator:(EOObjectStoreCoordinator *)aCoordinator editingContext:(EOEditingContext *)anEditingContext
{
	NSArray					*insertedObjects;
	NSMutableDictionary  *pkCache;
	int						x;
	int numInsertedObjects;
	
	// 0. Make sure we've been locked.
	[self _assertLock];
	
	// 1. Make sure we're not already saving.
	if (savingContext) {
		[NSException raise:EODatabaseException format:@"Attempt to begin a save while a save was already in progress on context %@", self];
	}
	
	// 2. If we already have a coordinator, make sure the passed in coordinator matches.
	if (coordinator) {
		if (coordinator != aCoordinator) {
			[NSException raise:EODatabaseException format:@"Attempt to save on a different object store coordinator."];
		}
	} else {
		[self _setCoordinator:aCoordinator];
	}
	
	// 3. Cache the editing context for future steps in the save process.
	savingContext = [anEditingContext retain];
	
	// 4. Scan the inserted objects and create a list of object's we own that need primary keys. The list is creating by entity, which allows us to request a block of primary keys, saving a lot of round trips to the database.
	insertedObjects = [savingContext insertedObjects];
	pkCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
	numInsertedObjects = [insertedObjects count];
	for (x = 0; x < numInsertedObjects; x++) {
		id					object = [insertedObjects objectAtIndex:x];
		EOGlobalID		*globalID = [[object editingContext] globalIDForObject:object];
		
		if ([globalID isTemporary] && [self ownsGlobalID:globalID]) {
			NSString				*entityName = [globalID entityName];
			NSMutableArray		*cache = [pkCache objectForKey:entityName];

			if (cache == nil) {
				cache = [[NSMutableArray allocWithZone:[self zone]] init];
				[pkCache setObject:cache forKey:entityName];
				[cache release];
			}
			
			[cache addObject:object];
		}
	}
	
	// 5. Creating the primary keys as a single batch.
	[self _generatePrimaryKeysForObjects:pkCache];
	[pkCache release];
}

- (void)_recordDeleteForObject:(id)object
{
	EODatabaseOperation  *operation;
	EOGlobalID				*globalID = [[object editingContext] globalIDForObject:object];
	NSDictionary			*snapshot = [database snapshotForGlobalID:globalID];
	
	if (snapshot == nil) {
		// mont_rothstein @ yahoo.com 2005-02-03
		// Deleting objects that were not saved to the database is perfectly valid, but an 
		// operation does not need to be created.  Commented out exception and added return.
//		[NSException raise:EODatabaseException format:@"Attempt to delete an object (%@) that was not fetched from the database.", object];
		return;
	}
	
	operation = [[EODatabaseOperation allocWithZone:[self zone]] initWithGlobalID:globalID object:object entity:[database entityNamed:[globalID entityName]]];
	[operation setDatabaseOperator:EODatabaseDeleteOperator];
	[operation setEOSnapshot:snapshot];
	[databaseOperations addObject:operation];
	[operation release];
}

- (void)_recordInsertForObject:(id)object
{
	EODatabaseOperation  *operation;
	EOGlobalID				*globalID = [[object editingContext] globalIDForObject:object];
	
	operation = [[EODatabaseOperation allocWithZone:[self zone]] initWithGlobalID:globalID object:object entity:[database entityNamed:[globalID entityName]]];
	[operation setDatabaseOperator:EODatabaseInsertOperator];
	[databaseOperations addObject:operation];
	[operation release];
}

- (void)_recordUpdateForObject:(id)object
{
	EODatabaseOperation  *operation;
	EOGlobalID				*globalID = [[object editingContext] globalIDForObject:object];
	NSDictionary			*snapshot = [database snapshotForGlobalID:globalID];
	
	if (snapshot == nil) {
		[NSException raise:EODatabaseException format:@"Attempt to update an object (%@) that was not fetched from the database.", object];
	}
	
	operation = [[EODatabaseOperation allocWithZone:[self zone]] initWithGlobalID:globalID object:object entity:[database entityNamed:[globalID entityName]]];
	[operation setDatabaseOperator:EODatabaseUpdateOperator];
	[operation setEOSnapshot:snapshot];
	[databaseOperations addObject:operation];
	[operation release];
}

- (void)recordChangesInEditingContext
{
	NSArray		*someObjects;
	int			x;
	int numObjects;
	
	[self _assertSaving:_cmd];

	// Create a container to hold all the changes.
	databaseOperations = [[NSMutableArray allocWithZone:[self zone]] init];
	
	// Record all the deletions. Note that we don't yet worry about ownership, it's up the developer to delete / nullify any object that references the deleted object.
	someObjects = [savingContext deletedObjects];
	numObjects = [someObjects count];
	for (x = 0; x < numObjects; x++) {
		id		object = [someObjects objectAtIndex:x];
		
		if ([self ownsObject:object]) [self _recordDeleteForObject:object];
	}
	
	someObjects = [savingContext insertedObjects];
	numObjects = [someObjects count];
	for (x = 0; x < numObjects; x++) {
		id		object = [someObjects objectAtIndex:x];
		
		if ([self ownsObject:object]) [self _recordInsertForObject:object];
	}
	
	someObjects = [savingContext updatedObjects];
	numObjects = [someObjects count];
	for (x = 0; x < numObjects; x++) {
		id		object = [someObjects objectAtIndex:x];
		
		if ([self ownsObject:object]) [self _recordUpdateForObject:object];
	}
}

- (EOQualifier *)_lockingQualifierForObject:(id)object snapshot:(NSDictionary *)snapshot entity:(EOEntity *)entity
{
	NSMutableArray	*array = [[NSMutableArray allocWithZone:[self zone]] init];
	EOQualifier		*qualifier;
	int				x;
	int numAttributes;
	NSArray			*work;
	NSZone			*zone = [self zone];
	
	// mont_rothstein @ yahoo.com 2005-07-12
	// We only want the attributes used for locking if we are doing optimistic locking, otherwise we simply use the primary key attributes
	if ([self updateStrategy] == EOUpdateWithOptimisticLocking)
		work = [entity attributesUsedForLocking];
	else work = [entity primaryKeyAttributes];
	
	numAttributes = [work count];
	for (x = 0; x < numAttributes; x++) {
		EOAttribute		*attribute = [work objectAtIndex:x];
		NSString			*name = [attribute name];
		id					value = [snapshot valueForKey:name];
		EOQualifier		*subqualifier;
		
		subqualifier = [[EOKeyValueQualifier allocWithZone:zone] initWithKey:name value:value];
		[array addObject:subqualifier];
		[subqualifier release];
	}
	
	qualifier = [[EOAndQualifier allocWithZone:zone] initWithArray:array];
	[array release];
	
	return [qualifier autorelease];
}

// mont_rothstein @ yahoo.com 2004-12-03
//
// Set the join attributes for a relationship on the object passed.  The 
// existing object from which the values originate is passed in.
// Whether the source or destination attribute on the join is being
// set depends on whether the relationship is owned by the new or
// existing object.
- (void)_setJoinAttributesForRelationship:(EORelationship *)relationship
								 onObject:(id)object
					   fromExistingObject:(id)existingObject
{
	NSArray *joins;
	EOJoin *join;
	EOAttribute *sourceAttribute;
	EOAttribute *destinationAttribute;
	EOGlobalID *globalID;
	id value;
	int index;
	int numJoins;
	
	joins = [relationship joins];
	
	// Loop through the joins grabbing the attributes and setting
	// them on our new object.  Depending on which side of the join
	// the new attribute is one we handle this differently.
	numJoins = [joins count];
	for (index = 0; index < numJoins; index++)
	{
		join = [joins objectAtIndex: index];
		sourceAttribute = [join sourceAttribute];
		destinationAttribute = [join destinationAttribute];
		
		// If the existing object's entity is the same as the source object's
		// entity, then we read the source attribute and write it as the
		// destination attribute.
		if ([(EOEntityClassDescription *)[existingObject classDescription] entity] == [sourceAttribute entity])
		{
			if ([sourceAttribute _isClassProperty])
			{
				value = [existingObject valueForKey: [sourceAttribute name]];
			}
			else
			{
				globalID = [existingObject globalID];
				value = [globalID valueForKey: [sourceAttribute name]];
			}
			
			[object setValue: value forKey: [destinationAttribute name]];
		}
		// The existing object's entity must match the destination attributes
		// entity.  Therefore we want to read the destination attribute and
		// write it as the source attribute.
		else
		{
			if ([destinationAttribute _isClassProperty])
			{
				value = [existingObject valueForKey: [destinationAttribute name]];
			}
			else
			{
				globalID = [existingObject globalID];
				value = [globalID valueForKey: [destinationAttribute name]];
			}
			
			[object setValue: value forKey: [sourceAttribute name]];
		}
	}
}


// mont_rothstein @ yahoo.com 2004-12-03
// 
// Create a join object between the source and destination objects using
// the relationships the came from the flattened relationship.  
- (id)_createJoinObjectForComponents:(NSArray *)relationships
					withSourceObject:(id)sourceObject
				andDestinationObject:(id)destinationObject
{
	EORelationship *relationship;
	EOEntity *destinationEntity;
	NSMutableDictionary *joinAttributes;
	EOGlobalID *newGlobalID;
	id joinObject;
	
	joinObject = nil;
	
	if ([relationships count] > 2)
	{
		[NSException raise: NSInvalidArgumentException 
					format: @"Join objects can only be created for relationships with exactly two components.  The components %@ on entity %@ are invalid.", relationships, [(EOEntityClassDescription *)[sourceObject classDescription] entity]];
	}
	
	joinAttributes = [[NSMutableDictionary allocWithZone: [self zone]] init];
	
	// Set the join attributes from the source object to our new object
	relationship = [relationships objectAtIndex: 0];
	[self _setJoinAttributesForRelationship: relationship
								   onObject: joinAttributes
						 fromExistingObject: sourceObject];
	
	// Set the join from the destination object to our new object.
	relationship = [relationships objectAtIndex: 1];
	[self _setJoinAttributesForRelationship: relationship
								   onObject: joinAttributes
						 fromExistingObject: destinationObject];
	
	destinationEntity = [(EORelationship *)[relationships objectAtIndex: 0] destinationEntity];
	
	newGlobalID = [destinationEntity globalIDForRow: joinAttributes];

	// Make sure we don't already have the newn object.  This covers us from objects
	// being added to both sides of relationships.
	if (![tempJoinIDs containsObject: newGlobalID])
	{
		joinObject = [[destinationEntity classDescriptionForInstances] 
						createInstanceWithEditingContext: nil 
												globalID: newGlobalID 
													zone: [self zone]];
		// Here we have to store the globalID directly on the EOGenericRecord
		// because this object doesn't have an editing context.  snapshotForObject:
		// will need to grab this globalID to grab the primary key attributes.
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//[joinObject takeStoredValue: newGlobalID forKey: @"globalID"];
		[joinObject setValue: newGlobalID forKey: @"globalID"];

		// mont_rothstein @ yahoo.com 2005-04-03
		// We need to set the relationship objects (if they are class properties) on the
		// join object.  This is because snapshotForObject: assumes they are there.
		relationship = [relationships objectAtIndex: 0];
		if ([relationship _isClassProperty])
		{
			[joinObject setValue: sourceObject forKey: [relationship name]];
		}
		
		relationship = [relationships objectAtIndex: 1];
		if ([relationship _isClassProperty])
		{
			[joinObject setValue: destinationObject forKey: [relationship name]];
		}
		
		[tempJoinIDs addObject: newGlobalID];
	}

	[joinAttributes release];
	
	return joinObject;
}


// mont_rothstein @ yahoo.com 2004-12-03
//
// Check the object associated with the database operation to see if it has any
// flattened relationships that are not still faults.  If it does then see if
// any join objects need to be created or deleted for the flattened relationship.
// If the operation is an insert then all objects in the flattened relationship
// need join objects created.  If the opeartion is either an update or delete then
// the related objects will need to be re-fetched from the database to compare
// against the existing relationship array.  Any differences between the two
// sets of objects needs to be reconciled by creating or deleting join objects.
- (void)_adaptorOperationsForFlattenedRelationshipsForDatabaseOperation:(EODatabaseOperation *)operation
{
	NSArray *classRelationships;
	EOEntity *entity;
	id object;
	
	object = [operation object];
	entity = [(EOEntityClassDescription *)[object classDescription] entity];
	classRelationships = [entity _classRelationships];
	
	if ([classRelationships count])
	{
		EORelationship *relationship;
		NSArray *relatedObjects;
		int index;
		int numRelationships;
		
		numRelationships = [classRelationships count];
		for (index = 0; index < numRelationships; index++)
		{
			relationship = [entity relationshipNamed: 
				[classRelationships objectAtIndex: index]];
			relatedObjects = [object valueForKey: [relationship name]];
			
			if ((![EOFault isFault: relatedObjects]) && 
				([relationship isFlattened]))
			{
				NSArray *fetchedObjects = nil;
				NSDictionary *fetchedObjectsIndex = nil;
				NSDictionary *relatedObjectsIndex = nil;
				EOAdaptorOperation	*adaptorOperation;
				EOGlobalID *globalID;
				id relatedObject;
				id fetchedObject;
				int index;
				int numRelatedObjects;
				int numFetchedObjects;
				
				// If this database operation is either an update or a delete then
				// we need to re-fetch the related objects from the database to see
				// if any objects have been added or removed from the relationship.
				if (([operation databaseOperator] == EODatabaseUpdateOperator) ||
					([operation databaseOperator] == EODatabaseDeleteOperator))
				{
					fetchedObjects = [self _objectsForFlattenedOneToManyWithGlobalID: [object globalID] 
																		relationship: relationship
																	  editingContext: [object editingContext]];
					fetchedObjectsIndex = [NSDictionary dictionaryWithObjects: fetchedObjects
																	  forKeys: [fetchedObjects valueForKey: @"globalID"]];
					relatedObjectsIndex = [NSDictionary dictionaryWithObjects: relatedObjects
																	  forKeys: [relatedObjects valueForKey: @"globalID"]];
				}
				
				// Loop through the objects currently in the relationship and see
				// if there are any not in the database.  If there are, create
				// inserts for the join objects
				numRelatedObjects = [relatedObjects count];
				for (index = 0; index < numRelatedObjects; index++)
				{
					relatedObject = [relatedObjects objectAtIndex: index];

					// The in-memory object is not in the database so have the join
					// created.
					if (![fetchedObjectsIndex objectForKey: [relatedObject globalID]])
					{
						// Make sure we did not already create the join object earlier 
						id joinObject;
						
						joinObject = [self _createJoinObjectForComponents: [relationship componentRelationships]
														 withSourceObject: object
													 andDestinationObject: relatedObject];

						// We might not have a join operation because it might already have
						// been created (if an object was added to both sides of a relationship
						// then we only need one join object).
						if (joinObject)
						{
							adaptorOperation = [[EOAdaptorOperation allocWithZone:[self zone]] initWithEntity: [(EOEntityClassDescription *)[joinObject classDescription] entity]];
							[adaptorOperation setAdaptorOperator: EOAdaptorInsertOperator];
							[adaptorOperation setChangedValues: [joinObject snapshot]];
							[operation addAdaptorOperation: adaptorOperation];
							[adaptorOperation release];
						}
					}
				}
				
				// Loop through the objects fetched from the database for the
				// relationship.  If there area any that are not in th current
				// relationship create deletes for the joins.
				numFetchedObjects = [fetchedObjects count];
				for (index = 0; index < numFetchedObjects; index++)
				{
					fetchedObject = [fetchedObjects objectAtIndex: index];
										
					// The object from the database is not in the in-memory relationship
					// so have join object deleted.
					if (![relatedObjectsIndex objectForKey: [fetchedObject globalID]])
					{
						NSMutableDictionary *dictionary;
						NSArray *componentRelationships;
						EOAndQualifier *qualifier;
						EOQualifier *subqualifier;
						NSArray *keys;
						NSMutableArray *newQualifiers;
						NSZone *zone;
						int dictIndex;
						NSString *key;
						EOEntity *destinationEntity;
						EOGlobalID *newGlobalID;
						
						zone = [self zone];
						
						dictionary = [[NSMutableDictionary allocWithZone: zone] init];
						componentRelationships = [relationship componentRelationships];
						
						// Set the join attributes from the source object to our new object
						[self _setJoinAttributesForRelationship: [componentRelationships objectAtIndex: 0]
													   onObject: dictionary
											 fromExistingObject: object];
						
						// Set the join from the destination object to our new object.
						[self _setJoinAttributesForRelationship: [componentRelationships objectAtIndex: 1]
													   onObject: dictionary
											 fromExistingObject: fetchedObject];
						
						destinationEntity = [(EORelationship *)[componentRelationships objectAtIndex: 0] destinationEntity];
						newGlobalID = [destinationEntity globalIDForRow: dictionary];

						// Make sure we haven't already created this operation earlier in the process.
						if (![tempJoinIDs containsObject: newGlobalID])
						{
							int numKeys;
							
							newQualifiers = [[NSMutableArray allocWithZone: zone] init];
							keys = [dictionary allKeys];
							
							numKeys = [keys count];
							for (dictIndex = 0; dictIndex < numKeys; dictIndex++)
							{
								key = [keys objectAtIndex: dictIndex];
								
								subqualifier = [[EOKeyValueQualifier allocWithZone:zone] 
							initWithKey: key 
								  value: [dictionary valueForKey: key]];
								[newQualifiers addObject: subqualifier];
								[subqualifier release];
							}
							
							qualifier = [[EOAndQualifier allocWithZone: zone] initWithArray: newQualifiers];
							
							adaptorOperation = [[EOAdaptorOperation allocWithZone: zone] initWithEntity: destinationEntity];
							[adaptorOperation setAdaptorOperator: EOAdaptorDeleteOperator];
							[adaptorOperation setAttributes: keys];
							[adaptorOperation setQualifier: qualifier];
							[operation addAdaptorOperation: adaptorOperation];
							
							[tempJoinIDs addObject: newGlobalID];
							[adaptorOperation release];
							[qualifier release];
							[dictionary release];
						}
					}
				}
			}
		}
	}
}

- (void)_createInsertOperationForDatabaseOperation:(EODatabaseOperation *)operation
{
	EOAdaptorOperation	*adaptorOperation;
	EOEntity					*entity = [operation entity];
	
	adaptorOperation = [[EOAdaptorOperation allocWithZone:[self zone]] initWithEntity:entity];
	[adaptorOperation setAdaptorOperator:EOAdaptorInsertOperator];
	[adaptorOperation setChangedValues:[[operation object] snapshot]];
	[operation addAdaptorOperation:adaptorOperation];
	[adaptorOperation release];
	
	// mont_rothstein @ yahoo.com 2004-12-03
	// Create many-to-many join objects for flattened relationships
	[self _adaptorOperationsForFlattenedRelationshipsForDatabaseOperation: operation];
}

- (void)_createDeleteOperationForDatabaseOperation:(EODatabaseOperation *)operation
{
	EOAdaptorOperation	*adaptorOperation;
	EOEntity					*entity = [operation entity];

	adaptorOperation = [[EOAdaptorOperation allocWithZone:[self zone]] initWithEntity:entity];
	if ([entity storedProcedureForOperation:EODeleteProcedureOperation]) {
		[adaptorOperation setStoredProcedure:[entity storedProcedureForOperation:EODeleteProcedureOperation]];
		[adaptorOperation setAdaptorOperator:EOAdaptorStoredProcedureOperator];
		[adaptorOperation setChangedValues:[operation EOSnapshot]];
	} else {
		[adaptorOperation setAdaptorOperator:EOAdaptorDeleteOperator];
		[adaptorOperation setAttributes:[entity attributesUsedForLocking]];
		[adaptorOperation setQualifier:[self _lockingQualifierForObject:[operation object] snapshot:[operation EOSnapshot] entity:entity]];
	}
	[operation addAdaptorOperation:adaptorOperation];
	[adaptorOperation release];
	
	// mont_rothstein @ yahoo.com 2004-12-03
	// Delete any many-to-many join objects associated with the object in this operation
	[self _adaptorOperationsForFlattenedRelationshipsForDatabaseOperation: operation];
}

- (void)_createUpdateOperationForDatabaseOperation:(EODatabaseOperation *)operation
{
	EOAdaptorOperation	*adaptorOperation;
	EOEntity					*entity = [operation entity];
	NSDictionary			*updates;
	
	updates = [operation rowDiffs];
	// This check is necessary, because the object, even though it thinks it has edits may in fact not have any edits.
	if ([updates count]) {
		adaptorOperation = [[EOAdaptorOperation allocWithZone:[self zone]] initWithEntity:entity];
		[adaptorOperation setAdaptorOperator:EOAdaptorUpdateOperator];
		[adaptorOperation setAttributes:[entity attributesUsedForLocking]];
		[adaptorOperation setQualifier:[self _lockingQualifierForObject:[operation object] snapshot:[operation EOSnapshot] entity:entity]];
		// mont_rothstein @ yahoo.com 2005-08-27
		// Changed this to use the existing copy of rowDiffs in the updates variable instead of calling [operation rowDiffs] again.
		[adaptorOperation setChangedValues:updates];
		[operation addAdaptorOperation:adaptorOperation];
		[adaptorOperation release];
	}
	
	// mont_rothstein @ yahoo.com 2004-12-03
	// Create or Delete many-to-many join objects for flattened relationships, as necessary
	[self _adaptorOperationsForFlattenedRelationshipsForDatabaseOperation: operation];
}

- (void)createAdaptorOperationsForDatabaseOperation:(EODatabaseOperation *)operation
{
	switch ([operation databaseOperator]) {
		case EODatabaseNothingOperator:
			break;
		case EODatabaseInsertOperator:
			[self _createInsertOperationForDatabaseOperation:operation];
			break;
		case EODatabaseUpdateOperator:
			[self _createUpdateOperationForDatabaseOperation:operation];
			break;
		case EODatabaseDeleteOperator:
			[self _createDeleteOperationForDatabaseOperation:operation];
			break;
	}
}

- (void)performChanges
{
	int						x;
	int numDatabaseOperations;
	NSArray					*adaptorOperations = nil;
	EOAdaptorChannel		*adaptorChannel;
	NSException				*exception;
	
	[self _assertSaving:_cmd];
	
	// First, build all of our adaptor operations. These are stored in the database operations.
	numDatabaseOperations = [databaseOperations count];
	for (x = 0; x < numDatabaseOperations; x++) {
		EODatabaseOperation	*operation = [databaseOperations objectAtIndex:x];
		[self createAdaptorOperationsForDatabaseOperation:operation];
	}
	
	//
	// Give our delegate a chance to order the adaptor operations.
	if (delegateRespondsToWillOrderAdaptorOperationsFromDatabaseOperations) {
		adaptorOperations = [[delegate databaseContext:self willOrderAdaptorOperationsFromDatabaseOperations:databaseOperations] retain];
	}
	// The delegate didn't do any work, so build and order the adaptor operations.
	if (adaptorOperations == nil) {
		adaptorOperations = [[NSMutableArray allocWithZone:[self zone]] init];
		for (x = 0; x < numDatabaseOperations; x++) {
			NSArray		*suboperations = [[databaseOperations objectAtIndex:x] adaptorOperations];
			if ([suboperations count]) {
				[(NSMutableArray *)adaptorOperations addObjectsFromArray:suboperations];
			}
		}
		[(NSMutableArray *)adaptorOperations sortUsingSelector:@selector(compareAdaptorOperation:)];
	}
	
	// Get an adaptor channel;
	adaptorChannel = [[self availableChannel] _adaptorChannel:YES];
	if (delegateRespondsToWillPerformAdaptorOperationsAdaptorChannel) {
		NSArray	*newArray = [delegate databaseContext:self willPerformAdaptorOperations:adaptorOperations adaptorChannel:adaptorChannel];
		if ([newArray count]) {
			[adaptorOperations release];
			adaptorOperations = [newArray retain];
		}
	}
	
	// Finally, perform the operations!
	exception = nil;
	NS_DURING
		// mont_rothstein @ yahoo.com 2005-06-23
		// If a transaction hasn't been started then start one.  This is to support
		// locking and the rollback of failed transactions
		if (! [[self adaptorContext] hasOpenTransaction])
		{
			[[self adaptorContext] beginTransaction];
		}
		
		[adaptorChannel performAdaptorOperations:adaptorOperations];
	NS_HANDLER
		exception = [localException retain];
	NS_ENDHANDLER
	
	[adaptorOperations release];
	
	// If an exception occured, add some data to the exception's user info and raise it.
	if (exception != nil) {
		// mont_rothstein @ yahoo.com 2005-06-26
		// Some times a user info dictionary hasn't been set, plus when it has the 
		// exception seems to make a non-mutable copy (go figure).  So, we
		// re-create the exception.
		NSString *name;
		NSString *reason;
		NSMutableDictionary	*info;
		NSException *newException;
		
		name = [exception name];
		reason = [exception reason];
		info = [[exception userInfo] mutableCopy];
		
		if (!info) info = [NSMutableDictionary dictionary];
		
		[info setObject:self forKey:EODatabaseContextKey];
		[info setObject:databaseOperations forKey:EODatabaseOperationsKey];
		[info setObject:[[info objectForKey:EOFailedAdaptorOperationKey] _databaseOperation] forKey:EOFailedDatabaseOperationKey];
			
		newException = [NSException exceptionWithName: name reason: reason userInfo: info];
		[newException raise];
	}
}

// lon.varscsak @ gmail.com 10/03/2006:
//   added _acceptUpdatedGlobalIDs to determine if PK values have been changed on updatedObjects 
//   and then post the EOGlobalIDChangedNotification accordingly
- (void)_acceptUpdatedGlobalIDs
{
    NSArray *updatedObjects = [savingContext updatedObjects];
    NSMutableDictionary *globalIDMappings = [NSMutableDictionary dictionary];
    int x;
	int numberOfUpdatedObjects = [updatedObjects count];

    for (x = 0; x < numberOfUpdatedObjects; x++) {
        id object = [updatedObjects objectAtIndex:x];
        EOGlobalID *oldGlobalID = [[object editingContext] globalIDForObject:object]; //potentially old global ID
        
        if ([self ownsGlobalID:oldGlobalID]) {
            EOGlobalID *newGlobalID = [[database entityNamed:[oldGlobalID entityName]] globalIDForRow:[object snapshot]]; //new global ID from snapshot values
            
            if (![oldGlobalID isEqual:newGlobalID]) { //if our global IDs are different then they have changed and we need to update them
                [globalIDMappings setObject:newGlobalID forKey:oldGlobalID];
                
                [[self database] recordSnapshot:[object snapshot] forGlobalID:newGlobalID];
            }
        }
    }

    if ([globalIDMappings count]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:EOGlobalIDChangedNotification object:nil userInfo:globalIDMappings];
        [[self database] forgetSnapshotsForGlobalIDs:[globalIDMappings allKeys]];
    }
}

- (void)_acceptNewGlobalIDs
{
	NSArray		*insertedObjects = [savingContext insertedObjects];
	int			x;
	int numInsertedObjects;
	NSMutableDictionary *globalIDMappings;
	
	globalIDMappings = [NSMutableDictionary dictionary];
	
	numInsertedObjects = [insertedObjects count];
	for (x = 0; x < numInsertedObjects; x++) {
		id					object = [insertedObjects objectAtIndex:x];
		EOGlobalID		*globalID = [[object editingContext] globalIDForObject:object];
		
		if ([globalID isTemporary] && [self ownsGlobalID:globalID]) {
			// mont_rothstein @ yahoo.com 2005-09-11
			// The below code was only adding an entry for the object with its new global ID, not replacing it, and it was only do it on the primary editing context.  Corrected to use gather the old and new global IDs and then post to proper notification at the end.
//			// mont_rothstein @ yahoo.com 2004-12-06
//			// Added code to replace the temp global ID with the permanent one.
//			[[object editingContext] recordObject: object globalID: [(EOTemporaryGlobalID *)globalID newGlobalID]];
			[globalIDMappings setObject: [(EOTemporaryGlobalID *)globalID newGlobalID] forKey: globalID];
			
			// mont_rothstein @ yahoo.com 2004-12-05
			// Commented out the line below because it is unnecessary.  The objects no longer
			// store their own globalIDs.  The editingContext has them.
//			[object _setGlobalID:[(EOTemporaryGlobalID *)globalID newGlobalID]];
			// mont_rothstein @ yahoo.com 10/27/04
			// We need to record snapshots for any newly inserted objects in the EODatabase.  This is so that things like deletes on newly save objects work.  This is not the right way/place to do this, but it should get us by for now.  It has to be done after the temp globalID has been replaced with a real globalID.
			// mont_rothstein @ yahoo.com 2005-09-11
			// Modified this to get the new globalID from the temp one.  Previously it got it from the object's editing context, but that required the editing context to have already swapped the old for the new, and we've delated that until the end of this method so they can all be done at once.
			[[self database] recordSnapshot:[object snapshot] forGlobalID:[(EOTemporaryGlobalID *)globalID newGlobalID]];
		}
	}
	// mont_rothstein @ yahoo.com 2005-09-11
	// Added post of notification so anyone holding a pointer to the old global ID can change it.  Also, removed snapshots held under temp global IDs.
    if ([globalIDMappings count]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:EOGlobalIDChangedNotification object:nil userInfo: globalIDMappings];
        [[self database] forgetSnapshotsForGlobalIDs: [globalIDMappings allKeys]];
    }
}

// mont_rothstein @ yahoo.com 2005-08-08
// Added post of notification letting peer/nested editing context's know what objects have been changed
- (void)_acceptDatabaseOperations
{
	EODatabase  *aDatabase = [self database];
	int			x;
	int numDatabaseOperations;
	NSMutableArray *globalIDsForInsertedObjects;
	NSMutableArray *globalIDsForUpdatedObjects;
	NSMutableArray *globalIDsForDeletedObjects;
	NSDictionary *userInfo;
	
	globalIDsForInsertedObjects = [[NSMutableArray alloc] init];
	globalIDsForUpdatedObjects = [[NSMutableArray alloc] init];
	globalIDsForDeletedObjects = [[NSMutableArray alloc] init];
	
	numDatabaseOperations = [databaseOperations count];
	for (x = 0; x < numDatabaseOperations; x++) {
		EODatabaseOperation		*operation = [databaseOperations objectAtIndex:x];
		
		switch ([operation databaseOperator]) {
			case EODatabaseNothingOperator:
				break;
			case EODatabaseInsertOperator:
				// We just need to increment the reference count for the snapshot for the newly inserted object. Note that code in _acceptNewGlobalIDs dealt with getting the snapshot into the database.
				// aclark78 2005-12-12
				// _acceptDatabaseOperations was incorrectly handling EODatabaseInsertOperator by manipulating updated objects instead of inserted objects.
//				[aDatabase incrementSnapshotCountForGlobalID:[operation globalID]];
//				[globalIDsForUpdatedObjects addObject: [operation globalID]];
				[aDatabase incrementSnapshotCountForGlobalID:[(EOTemporaryGlobalID *)[operation globalID] newGlobalID]];
				[globalIDsForInsertedObjects addObject:[(EOTemporaryGlobalID *)[operation globalID] newGlobalID]];
				break;
			case EODatabaseUpdateOperator:
				// mont_rothstein @ yahoo.com 2005-02-24
				// This was re-recording the same snapshot that existed before the database operations 
				// processed.  What we want to record is the new state of the object.  This now does that.
				// 2005-05-18 AJR Note that record code in the database is now more intelligent. If the snapshot already exists, it's values are simply replaced with the newly provided values. If it doesn't exist, then the actualy snapshot provided is recorded.
				[aDatabase recordSnapshot:[[operation object] snapshot] forGlobalID:[operation globalID]];
				[globalIDsForUpdatedObjects addObject: [operation globalID]];
				break;
			case EODatabaseDeleteOperator:
				[aDatabase forgetSnapshotForGlobalID:[operation globalID]];
				[globalIDsForDeletedObjects addObject: [operation globalID]];
				break;
		}
	}
	
	userInfo = [[NSDictionary alloc] initWithObjectsAndKeys: globalIDsForInsertedObjects, EOInsertedKey, globalIDsForUpdatedObjects, EOUpdatedKey, globalIDsForDeletedObjects, EODeletedKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:EOObjectsChangedInStoreNotification object:(savingContext != nil) ? (id)savingContext : (id)self userInfo: userInfo];
	[globalIDsForInsertedObjects release];
	[globalIDsForUpdatedObjects release];
	[globalIDsForDeletedObjects release];
	[userInfo release];
}

- (void)_clearNewGlobalIDs
{
	NSArray		*insertedObjects = [savingContext insertedObjects];
	int			x;
	int numInsertedObjects;
	
	numInsertedObjects = [insertedObjects count];
	for (x = 0; x < numInsertedObjects; x++) {
		id					object = [insertedObjects objectAtIndex:x];
		EOGlobalID		*globalID = [[object editingContext] globalIDForObject:object];
		
		if ([globalID isTemporary] && [self ownsGlobalID:globalID]) {
			[(EOTemporaryGlobalID *)globalID setNewGlobalID:nil];
		}
	}
}

- (void)commitChanges
{
	NSException		*exception = nil;
	
	[self _assertSaving:_cmd];

	if ([adaptorContext hasOpenTransaction]) {
		NS_DURING
			[adaptorContext commitTransaction];
			// mont_rothstein @ yahoo.com 2005-06-23
			// Added call to forget all locks
			[self forgetAllLocks];
		NS_HANDLER
			exception = [[localException retain] autorelease];
		NS_ENDHANDLER
	}
	
	if (exception) {
		// Commit failed, so discard. -rollbackChanges might actually raise it's own exception, but it's not a big deal, so let it.
		[self rollbackChanges];
		[exception raise];
	}
	
	[self _acceptNewGlobalIDs];
	[self _acceptUpdatedGlobalIDs];
	[self _acceptDatabaseOperations];
	
	[savingContext release]; savingContext = nil;
	[databaseOperations release]; databaseOperations = nil;
	
	// mont_rothstein @ yahoo.com 2004-12-19
	// Added code to clear out the temporary global IDs of join table objects
	[tempJoinIDs removeAllObjects];
	
	// mont_rothstein @ yahoo.com 2005-07-12
	// Added invalidation of all objects when pessimistic locking is used
	if ([self updateStrategy] == EOUpdateWithPessimisticLocking)
	{
		[self invalidateAllObjects];
	}
	
	if (exception) {
		[exception raise];
	}
}

- (void)rollbackChanges
{
	NSException		*exception = nil;
	
	[self _assertSaving:_cmd];
	
	if ([adaptorContext hasOpenTransaction]) {
		NS_DURING
			[adaptorContext rollbackTransaction];
		NS_HANDLER
			exception = [localException retain];
		NS_ENDHANDLER
	}
	
	// mont_rothstein @ yahoo.com 2005-06-23
	// Added call to forget all locks
	[self forgetAllLocks];

	[self _clearNewGlobalIDs];
	
	[savingContext release]; savingContext = nil;
	[databaseOperations release]; databaseOperations = nil;
	
	// mont_rothstein @ yahoo.com 2004-12-19
	// Added code to clear out the temporary global IDs of join table objects
	[tempJoinIDs removeAllObjects];

	// mont_rothstein @ yahoo.com 2005-07-12
	// Added invalidation of all objects when pessimistic locking is used
	if ([self updateStrategy] == EOUpdateWithPessimisticLocking)
	{
		[self invalidateAllObjects];
	}
	
	if (exception) {
		[exception raise];
	}
}

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)globalID relationshipName:(NSString *)relationshipName editingContext:(EOEditingContext *)anEditingContext
{
	return [EOFault createArrayFaultWithSourceGlobalID:globalID relationshipName:relationshipName inEditingContext:anEditingContext];
}

- (id)faultForGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	id		object;

// mont_rothstein @ yahoo.com 2005-1-2
// The database context should not have a pointer to fetched objects, only editing contexts
// should.
//	// First, let's see if we already have the object
//	object = [objects objectForKey:globalID];
//	if (object) return object;
	
	// Nope, then let's create the object.
	object = [EOFault createObjectFaultWithGlobalID:globalID inEditingContext:anEditingContext];
	
	// mont_rothstein @ yahoo.com 2005-01-18
	// Set the editing context so that it can be retrieved during dealloc and
	// told to forget the object.
	[object _setEditingContext: anEditingContext];
	
// mont_rothstein @ yahoo.com 2005-1-2
// The database context's objects instance variable was removed.
//	// And store that it's now ours.
//	[objects setObject:object forKey:globalID];
	
	return object;
}

- (id)faultForRawRow:(id)row entityNamed:(NSString *)entityName editingContext:(EOEditingContext *)anEditingContext
{
	return [self faultForGlobalID:[[database entityNamed:entityName] globalIDForRow:row] editingContext:anEditingContext];
}


- (void)refaultObject:(id)anObject withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext
{
	EOFaultHandler *faultHandler = [[EOObjectFaultHandler alloc] initWithGlobalID: (EOKeyGlobalID *)globalID databaseContext: self editingContext: anEditingContext];
	[EOFault makeObjectIntoFault:anObject 
					 withHandler: faultHandler];
	[faultHandler release];
}


@end
