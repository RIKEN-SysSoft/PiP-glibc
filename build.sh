#!/bin/sh
#
# $RIKEN_copyright: 2018 Riken Center for Computational Sceience,
# 	  System Software Devlopment Team. All rights researved$
#
# The GNU C Library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# The GNU C Library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with the GNU C Library; if not, see
# <http://www.gnu.org/licenses/>.

# The configure options specified in this script are the same with those of
# RedHat (and CentOS) distribution (By N. Soda at SRA)
#
# ./build.sh PREFIX
# Arguments:
#	PREFIX: the install directory
#

BUILD_TRAP_SIGS='1 2 14 15';

cleanup()
{
    echo;
    echo "cleaning up ..."
    rm -f -r *;
    exit 2;
}

trap cleanup $BUILD_TRAP_SIGS;

cmd=`basename $0`

usage()
{
	echo >&2 "Usage: ./$cmd [-b] [-j<N>] <PREFIX>"
	echo >&2 "       ./$cmd  -i"
	echo >&2 "	-b      : build only, do not install" # for RPM
	echo >&2 "	-j<N>   : make parallelism"
	echo >&2 "	-i      : install only, do not build" # for RPM
	echo >&2 "	<PREFIX>: the install directory"
	exit 2
}

do_build=true
do_install=true
do_piplnlibs=true

dir=`dirname $0`
srcdir=`cd $dir; pwd`

: ${SRCDIR:=${srcdir}}
: ${BUILD_PARALLELISM:=`getconf _NPROCESSORS_ONLN`}
: ${CC:=gcc}
: ${CXX:=g++}

pwd=`pwd`
cwd=`realpath ${pwd}`
rsrcdir=`realpath ${SRCDIR}`
if [ x"${cwd}" == x"${rsrcdir}" ]; then
    echo >&2 "Error: ${cmd} must be invoked at the different directory from the source tree"
    exit 1;
fi
cdir=`ls`
if [ x"${cdir}" != x ]; then
    echo >&2 "Warning: The current directory is not empty"
    echo >&2 "         If build.sh fails with compilation errors,"
    echo >&2 "         remove all files and directoris in this directory"
    echo >&2 "         and then try again."
fi

build_parallelism=

# -b is for %build phase, and -i is for %install phase of rpmbuild(8)
while	case "$1" in
	-b)	do_install=false
		do_piplnlibs=false
		true;;
	-i)	do_build=false
		do_piplnlibs=false
		true;;
	--prefix=*)
		prefix=`expr "$1" : "--prefix=\(.*\)"`; true;;
	-j*)
		build_parallelism=`expr "$1" : "-j\([0-9]*\)"`; true;;
	-*)	usage;;
	'')	false;;
	*)	prefix=$1; true;;
	esac
do
	shift
done

if [ x"$prefix" == x ]; then
    echo >&2 "Error: <PREFIX> must be specifgied"
    usage;
fi

case "$1" in
-*)	usage;;
esac

if [ x"${build_parallelism}" != x ]; then
    BUILD_PARALLELISM=${build_parallelism}
fi

echo "Checking required packages ... "

enable_nss_crypt=
enable_systemtap=

pkg_check=true
nopkg=false
for pkgn in $pkgs_needed; do
    if yum list installed $pkgn >/dev/null 2>&1; then
	case ${pkgn} in
	    nss) nss_config=`which nss-config 2> /dev/null`;
		if [ z"${nss_config}" != z -a -x ${nss_config} ]; then
		     enable_nss_crypt="--enable-nss-crypt"
	         fi;;
	esac
    elif ! [ -d ${SRCDIR}/header-import/${pkgn} ]; then
	    CPPFLAGS="-I${SRCDIR}/header-import/${pkgn}"
    else
        echo "'$pkgn' package is not installed but required"
	pkg_check=false
    fi
    if [ x"${pkgs}" == x"systemtap" ]; then
	if [ -f /usr/include/sys/sdt.h ]; then
	    enable_systemtap="--enable-systemtap"
	fi
    fi
done

if $pkg_check; then
    echo "All required packages found"
else
    echo "Some packages are missing"
    exit 1
fi

case `uname -m` in
aarch64)
	opt_mtune=
	opt_add_ons=nptl,c_stubs,libidn
	opt_build=aarch64-redhat-linux
	opt_multi_arch=
	opt_mflags=PARALLELMFLAGS=
	;;
x86_64)
	opt_mtune=-mtune=generic
	opt_add_ons=nptl,rtkaio,c_stubs,libidn
	opt_build=x86_64-redhat-linux
	opt_multi_arch=--enable-multi-arch
	opt_mflags=
	;;
*)
	echo >&2 "$cmd: unsupported machine type: `uname -m`"
	exit 2
	;;
esac

if [ -f /etc/debian_version ]; then
	opt_distro=--disable-werror
else
	opt_distro=
fi

set -x

if $do_build; then
	set +e
	make clean
	make distclean
	$SRCDIR/configure --prefix=$prefix \
	    CC="${CC}" \
	    CXX="${CXX}" \
	    "CFLAGS=${CFLAGS} ${opt_mtune} -fasynchronous-unwind-tables -DNDEBUG -g -O3 -fno-asynchronous-unwind-tables" \
	    --enable-add-ons=${opt_add_ons} \
	    --with-headers=/usr/include \
	    --enable-kernel=2.6.32 \
	    --enable-bind-now \
	    --build=${opt_build} \
	    ${opt_multi_arch} \
	    --enable-obsolete-rpc \
	    ${enable_systemtap} \
	    --disable-profile \
	    ${enable_nss_crypt} \
	    ${opt_distro}
	make -j${BUILD_PARALLELISM} ${opt_mflags}
	mkst=$?;
	set -e
# workaround
	if [ $mkst != 0 ]; then
	    echo
	    echo '===== workaround ===='
	    if [ -f $SRCDIR/intl/plural.c ]; then
		mv -f $SRCDIR/intl/plural.c $SRCDIR/intl/plural.c.NG
	    fi
	    cp $SRCDIR/intl/plural.c.OK $SRCDIR/intl/plural.c
	    echo '===== try again ===='
	    make clean
	    make distclean
	    $SRCDIR/configure --prefix=$prefix \
		CC="${CC}" \
		CXX="${CXX}" \
		"CFLAGS=${CFLAGS} ${opt_mtune} -fasynchronous-unwind-tables -DNDEBUG -g -O3 -fno-asynchronous-unwind-tables" \
		--enable-add-ons=${opt_add_ons} \
		--with-headers=/usr/include \
		--enable-kernel=2.6.32 \
		--enable-bind-now \
		--build=${opt_build} \
		${opt_multi_arch} \
		--enable-obsolete-rpc \
		${enable_systemtap} \
		--disable-profile \
		${enable_nss_crypt} \
		${opt_distro}
	    make -j${BUILD_PARALLELISM} ${opt_mflags}
	    extval=$?
            if [ $extval != 0 ]; then
		echo >&2 "PiP-glibc build error"
		exit 1;
            fi
	fi
	make localedata/install-locales
fi

# installation should honor ${DESTDIR}, especially for rpmbuild(8)
if $do_install; then
	make install ${opt_mflags}
	# undo workaround
	if [ -f $SRCDIR/intl/plural.c.NG ]; then
	    echo '===== undo workaround ===='
	    mv -f $SRCDIR/intl/plural.c.NG $SRCDIR/intl/plural.c
	fi
	# symbolic link to /usr/share/timezone
	ln -s /usr/share/zoneinfo ${DESTDIR}$prefix/share/zoneinfo
	# make, install and run piplnlibs.sh
	mkdir -p ${DESTDIR}$prefix/bin
	sed "s|@GLIBC_PREFIX@|${prefix}|" < ${SRCDIR}/piplnlibs.sh.in > ${DESTDIR}$prefix/bin/piplnlibs
	chmod +x ${DESTDIR}$prefix/bin/piplnlibs
	if $do_piplnlibs; then
	    # for RPM, this has to be done at "rpm -i" instead of %install phase
	    ( unset LD_LIBRARY_PATH; ${DESTDIR}$prefix/bin/piplnlibs -s )
	fi
fi

if [ x${enable_nss_crypt} == x ]; then
    echo "Warning: '--enable_nns_crypt' has been disabled"
fi
