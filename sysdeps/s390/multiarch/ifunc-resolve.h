/* IFUNC resolver function for CPU specific functions.
   32/64 bit S/390 version.
   Copyright (C) 2015 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#include <unistd.h>
#include <dl-procinfo.h>

#define S390_STFLE_BITS_Z10  34 /* General instructions extension */
#define S390_STFLE_BITS_Z196 45 /* Distinct operands, pop ... */

#define S390_IS_Z196(STFLE_BITS)			\
  ((STFLE_BITS & (1ULL << (63 - S390_STFLE_BITS_Z196))) != 0)

#define S390_IS_Z10(STFLE_BITS)				\
  ((STFLE_BITS & (1ULL << (63 - S390_STFLE_BITS_Z10))) != 0)

#define S390_STORE_STFLE(STFLE_BITS)					\
  /* We want just 1 double word to be returned.  */			\
  register unsigned long reg0 asm("0") = 0;				\
									\
  asm volatile(".machine push"        "\n\t"				\
	       ".machine \"z9-109\""  "\n\t"				\
	       ".machinemode \"zarch_nohighgprs\"\n\t"			\
	       "stfle %0"             "\n\t"				\
	       ".machine pop"         "\n"				\
	       : "=QS" (STFLE_BITS), "+d" (reg0)			\
	       : : "cc");

#define s390_libc_ifunc(FUNC)						\
  asm (".globl " #FUNC "\n\t"						\
       ".type  " #FUNC ",@gnu_indirect_function\n\t"			\
       ".set   " #FUNC ",__resolve_" #FUNC "\n\t"			\
       ".globl __GI_" #FUNC "\n\t"					\
       ".set   __GI_" #FUNC "," #FUNC "\n");				\
									\
  /* Make the declarations of the optimized functions hidden in order
     to prevent GOT slots being generated for them. */			\
  extern void *__##FUNC##_z196 attribute_hidden;			\
  extern void *__##FUNC##_z10 attribute_hidden;				\
  extern void *__##FUNC##_default attribute_hidden;			\
									\
  void *__resolve_##FUNC (unsigned long int dl_hwcap)			\
  {									\
    if ((dl_hwcap & HWCAP_S390_STFLE)					\
	&& (dl_hwcap & HWCAP_S390_ZARCH)				\
	&& (dl_hwcap & HWCAP_S390_HIGH_GPRS))				\
      {									\
	unsigned long long stfle_bits;					\
	S390_STORE_STFLE (stfle_bits);					\
									\
	if (S390_IS_Z196 (stfle_bits))					\
	  return &__##FUNC##_z196;					\
	else if (S390_IS_Z10 (stfle_bits))				\
	  return &__##FUNC##_z10;					\
	else								\
	  return &__##FUNC##_default;					\
      }									\
    else								\
      return &__##FUNC##_default;					\
  }

#define s390_vx_libc_ifunc(FUNC)		\
  s390_vx_libc_ifunc2(FUNC, FUNC)

#define s390_vx_libc_ifunc2(RESOLVERFUNC, FUNC)				\
  /* Make the declarations of the optimized functions hidden in order
     to prevent GOT slots being generated for them.  */			\
  extern __typeof (FUNC) RESOLVERFUNC##_vx attribute_hidden;		\
  extern __typeof (FUNC) RESOLVERFUNC##_c attribute_hidden;		\
  extern void *__resolve_##RESOLVERFUNC (unsigned long int) __asm__ (#FUNC); \
									\
  void *__resolve_##RESOLVERFUNC (unsigned long int dl_hwcap)		\
  {									\
    if (dl_hwcap & HWCAP_S390_VX)					\
      return &RESOLVERFUNC##_vx;					\
    else								\
      return &RESOLVERFUNC##_c;						\
  }									\
 __asm__ (".type " #FUNC ", %gnu_indirect_function");

/* Helper / base  macros for indirect function symbols
   (See include/libc-symbols in upstream glibc).  */
#define __ifunc_resolver(type_name, name, expr, arg, init, classifier)	\
  classifier void *name##_ifunc (arg)					\
  {									\
    init ();								\
    __typeof (type_name) *res = expr;					\
    return res;								\
  }

#define __ifunc(type_name, name, expr, arg, init)			\
  extern __typeof (type_name) name __attribute__			\
			      ((ifunc (#name "_ifunc")));		\
  __ifunc_resolver (type_name, name, expr, arg, init, static)

#define s390_libc_ifunc_expr_init()
#define s390_libc_ifunc_expr(TYPE_FUNC, FUNC, EXPR)		\
  __ifunc (TYPE_FUNC, FUNC, EXPR, unsigned long int hwcap,	\
	   s390_libc_ifunc_expr_init);
