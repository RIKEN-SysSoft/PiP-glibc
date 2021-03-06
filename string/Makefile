# Copyright (C) 1991-2002, 2005-2011, 2012 Free Software Foundation, Inc.
# This file is part of the GNU C Library.

# The GNU C Library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# The GNU C Library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with the GNU C Library; if not, see
# <http://www.gnu.org/licenses/>.

#
#	Sub-makefile for string portion of library.
#
subdir	:= string

headers	:= string.h strings.h memory.h endian.h bits/endian.h \
	   argz.h envz.h byteswap.h bits/byteswap.h bits/byteswap-16.h \
	   bits/string.h bits/string2.h bits/string3.h

routines	:= strcat strchr strcmp strcoll strcpy strcspn		\
		   strverscmp strdup strndup				\
		   strerror _strerror strlen strnlen			\
		   strncat strncmp strncpy				\
		   strrchr strpbrk strsignal strspn strstr strtok	\
		   strtok_r strxfrm memchr memcmp memmove memset	\
		   mempcpy bcopy bzero ffs ffsll stpcpy stpncpy		\
		   strcasecmp strncase strcasecmp_l strncase_l		\
		   memccpy memcpy wordcopy strsep strcasestr		\
		   swab strfry memfrob memmem rawmemchr strchrnul	\
		   $(addprefix argz-,append count create ctsep next	\
				     delete extract insert stringify	\
				     addsep replace)			\
		   envz basename					\
		   strcoll_l strxfrm_l string-inlines memrchr		\
		   xpg-strerror strerror_l

# Gcc internally generates calls to unbounded memcpy and memset
# for -fbounded-pointer compiles.  Glibc uses memchr for explicit checks.
o-objects.ob	:= memcpy.o memset.o memchr.o

strop-tests	:= memchr memcmp memcpy memmove mempcpy memset memccpy	\
		   stpcpy stpncpy strcat strchr strcmp strcpy strcspn	\
		   strlen strncmp strncpy strpbrk strrchr strspn memmem	\
		   strstr strcasestr strnlen strcasecmp strncasecmp	\
		   strncat rawmemchr strchrnul bcopy bzero
tests		:= tester inl-tester noinl-tester testcopy test-ffs	\
		   tst-strlen stratcliff tst-svc tst-inlcall		\
		   bug-strncat1 bug-strspn1 bug-strpbrk1 tst-bswap	\
		   tst-strtok tst-strxfrm bug-strcoll1 tst-strfry	\
		   bug-strtok1 $(addprefix test-,$(strop-tests))	\
		   bug-envz1 tst-strxfrm2 tst-endian tst-svc2		\
		   tst-strtok_r

tests-ifunc := $(strop-tests:%=test-%-ifunc)
tests += $(tests-ifunc)

include ../Rules

tester-ENV = LANGUAGE=C
inl-tester-ENV = LANGUAGE=C
noinl-tester-ENV = LANGUAGE=C
CFLAGS-inl-tester.c = -fno-builtin
CFLAGS-noinl-tester.c = -fno-builtin
CFLAGS-tst-strlen.c = -fno-builtin
CFLAGS-stratcliff.c = -fno-builtin
CFLAGS-test-ffs.c = -fno-builtin
CFLAGS-tst-inlcall.c = -fno-builtin
CFLAGS-bug-strstr1.c = -fno-builtin
CFLAGS-bug-strcasestr1.c = -fno-builtin

# Disable any optimization which might result in function calls to the very
# same functions we are trying to compile, thus creating an infinite loop.
CFLAGS-.o += -fno-tree-loop-distribute-patterns
CFLAGS-.os += -fno-tree-loop-distribute-patterns
CFLAGS-.op += -fno-tree-loop-distribute-patterns
CFLAGS-.ob += -fno-tree-loop-distribute-patterns
CFLAGS-.oS += -fno-tree-loop-distribute-patterns

ifeq ($(run-built-tests),yes)
tests: $(objpfx)tst-svc.out
$(objpfx)tst-svc.out: tst-svc.input $(objpfx)tst-svc
	GCONV_PATH=$(common-objpfx)iconvdata LC_ALL=C \
	  $(built-program-cmd) < $(word 1,$^) > $@
	@cmp tst-svc.expect $(objpfx)tst-svc.out
endif
