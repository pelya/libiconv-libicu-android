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
GCCPREFIX=aarch64-linux-android
[ -z "$NDK_TOOLCHAIN_VERSION" ] && NDK_TOOLCHAIN_VERSION=4.9
LOCAL_PATH=`dirname $0`
if which realpath > /dev/null ; then
	LOCAL_PATH=`realpath $LOCAL_PATH`
else
	LOCAL_PATH=`cd $LOCAL_PATH && pwd`
fi
ARCH=arm64-v8a


CFLAGS="
--target=aarch64-none-linux-android21
--gcc-toolchain=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64
--sysroot=$NDK/sysroot
-isystem
$NDK/sources/cxx-stl/llvm-libc++/include
-isystem
$NDK/sources/cxx-stl/llvm-libc++abi/include
-isystem
$NDK/sysroot/usr/include/aarch64-linux-android
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
--target=aarch64-none-linux-android21
--gcc-toolchain=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64
--sysroot=$NDK/sysroot
-fPIC
-isystem
$NDK/sysroot/usr/include/aarch64-linux-android
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
$NDK/platforms/android-21/arch-arm64
-Wl,--build-id
-Wl,--warn-shared-textrel
-Wl,--fatal-warnings
-L$NDK/sources/cxx-stl/llvm-libc++/libs/arm64-v8a
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
$NDK/sources/cxx-stl/llvm-libc++/libs/arm64-v8a/libc++_static.a
$NDK/sources/cxx-stl/llvm-libc++/libs/arm64-v8a/libc++abi.a
$LDFLAGS"

LDFLAGS="`echo $LDFLAGS | tr '\n' ' '`"

CC="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/clang"
CXX="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/clang++"
CPP="$CC -E $CFLAGS"

env PATH=$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin:$LOCAL_PATH:$PATH \
CFLAGS="$CFLAGS" \
CXXFLAGS="$CXXFLAGS $CFLAGS -frtti -fexceptions" \
LDFLAGS="$LDFLAGS" \
CC="$CC" \
CXX="$CXX" \
RANLIB="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-ranlib" \
LD="$CC" \
AR="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-ar" \
CPP="$CPP" \
NM="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-nm" \
AS="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-as" \
STRIP="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-strip" \
"$@"
