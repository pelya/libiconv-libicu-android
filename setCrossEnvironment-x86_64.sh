#!/bin/sh

IFS='
'

NDK=`which ndk-build`
NDK=`dirname $NDK`

if uname -s | grep -i "linux" > /dev/null ; then
	MYARCH=linux-$(arch)
  NDK=`readlink -f $NDK`
elif uname -s | grep -i "darwin" > /dev/null ; then
	MYARCH=darwin-x86_64
elif uname -s | grep -i "windows" > /dev/null ; then
	MYARCH=windows-x86_64
fi

#echo NDK $NDK
GCCPREFIX=x86_64-linux-android
[ -z "$NDK_TOOLCHAIN_VERSION" ] && NDK_TOOLCHAIN_VERSION=4.9
LOCAL_PATH=`dirname $0`
if which realpath > /dev/null ; then
	LOCAL_PATH=`realpath $LOCAL_PATH`
else
	LOCAL_PATH=`cd $LOCAL_PATH && pwd`
fi
ARCH=x86_64


CFLAGS="
--target=x86_64-none-linux-android21
--gcc-toolchain=$NDK/toolchains/x86_64-4.9/prebuilt/linux-x86_64
--sysroot=$NDK/sysroot
-isystem
$NDK/sources/cxx-stl/llvm-libc++/include
-isystem
$NDK/sources/cxx-stl/llvm-libc++abi/include
-isystem
$NDK/sysroot/usr/include/x86_64-linux-android
-g
-DANDROID
-ffunction-sections
-funwind-tables
-fstack-protector-strong
-no-canonical-prefixes
-Wa,--noexecstack
-Wformat
-Werror=format-security
-O2
-DNDEBUG
-fPIC
$CFLAGS"

CFLAGS="`echo $CFLAGS | tr '\n' ' '`"

LDFLAGS="
--target=x86_64-none-linux-android21
--gcc-toolchain=$NDK/toolchains/x86_64-4.9/prebuilt/linux-x86_64
--sysroot=$NDK/sysroot
-fPIC
-isystem
$NDK/sysroot/usr/include/x86_64-linux-android
-g
-DANDROID
-ffunction-sections
-funwind-tables
-fstack-protector-strong
-no-canonical-prefixes
-Wa,--noexecstack
-Wformat
-Werror=format-security
-O2
-DNDEBUG
-Wl,--exclude-libs,libgcc.a
-Wl,--exclude-libs,libatomic.a
-nostdlib++
--sysroot
$NDK/platforms/android-21/arch-x86_64
-Wl,--build-id
-Wl,--warn-shared-textrel
-Wl,--fatal-warnings
-L$NDK/sources/cxx-stl/llvm-libc++/libs/x86_64
-Wl,--no-undefined
-Wl,-z,noexecstack
-Qunused-arguments
-Wl,-z,relro
-Wl,-z,now
-shared
-landroid
-llog
-latomic
-lm
$NDK/sources/cxx-stl/llvm-libc++/libs/x86_64/libc++_static.a
$NDK/sources/cxx-stl/llvm-libc++/libs/x86_64/libc++abi.a
$LDFLAGS
"

LDFLAGS="`echo $LDFLAGS | tr '\n' ' '`"

CC="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/clang"
CXX="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/clang++"
CPP="$CC -E $CFLAGS"

env PATH=$NDK/toolchains/$ARCH-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin:$LOCAL_PATH:$PATH \
CFLAGS="$CFLAGS" \
CXXFLAGS="$CXXFLAGS $CFLAGS -frtti -fexceptions" \
LDFLAGS="$LDFLAGS" \
CC="$CC" \
CXX="$CXX" \
RANLIB="$NDK/toolchains/$ARCH-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-ranlib" \
LD="$CC" \
AR="$NDK/toolchains/$ARCH-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-ar" \
CPP="$CPP" \
NM="$NDK/toolchains/$ARCH-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-nm" \
AS="$NDK/toolchains/$ARCH-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-as" \
STRIP="$NDK/toolchains/$ARCH-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-strip" \
"$@"
