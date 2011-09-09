# GNUstep makefile

-include ../../config.make
include ../common.make

ifneq ($(frameworks),yes)
LIBRARY_NAME = libEOControl
else
FRAMEWORK_NAME = EOControl
endif

libEOControl_PCH_FILE = EOControl_Prefix.pch
# libEOControl_DLL_DEF = libEOControl.def
libEOControl_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libEOControl_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libEOControl_HEADER_FILES_DIR         = .
libEOControl_HEADER_FILES_INSTALL_DIR = /EOControl

libEOControl_HEADER_FILES = \
	EOControl.h			\
	EODefines.h			\
	EOEnterpriseObject.h		\
	EOFetchSpecification.h		\
	EOFetchSpecificationP.h		\
	EOFormat.h			\
	EOGenericRecord.h		\
	EOGenericRecordP.h		\
	EOKeyValueArchiver.h		\
	EOKeyValueCoding.h		\
	EOLog.h				\
	EONull.h			\
	EOObserver.h			\
	EORelationshipManipulation.h	\
	EOSortOrdering.h		\
	EOValidation.h			\

libEOControl_OBJC_FILES = \
	EODefines.m			\
	EOFetchSpecification.m		\
	EOFormat.m			\
	EOGenericRecord.m		\
	EOKeyValueArchiver.m		\
	EOKeyValueCoding.m		\
	EOLog.m				\
	EONull.m			\
	EOObserver.m			\
	EOSortOrdering.m		\

ADDITIONAL_INCLUDE_DIRS += \
	-I./DataSources/ \
	-I./Faults/			\
	-I./Global\ ID/			\
	-I./Object\ Stores/		\
	-I./Qualifiers/			\
	-I./Support/			\

# framework support
EOControl_PCH_FILE     = $(libEOControl_PCH_FILE)
EOControl_HEADER_FILES = $(libEOControl_HEADER_FILES)
EOControl_OBJC_FILES   = $(libEOControl_OBJC_FILES)


# building

-include GNUmakefile.preamble
ifneq ($(frameworks),yes)
include $(GNUSTEP_MAKEFILES)/library.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
-include GNUmakefile.postamble
-include fhs.make
