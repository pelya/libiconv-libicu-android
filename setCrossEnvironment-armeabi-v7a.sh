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
GCCPREFIX=arm-linux-androideabi
[ -z "$NDK_TOOLCHAIN_VERSION" ] && NDK_TOOLCHAIN_VERSION=4.9
LOCAL_PATH=`dirname $0`
if which realpath > /dev/null ; then
	LOCAL_PATH=`realpath $LOCAL_PATH`
else
	LOCAL_PATH=`cd $LOCAL_PATH && pwd`
fi
ARCH=armeabi-v7a


CFLAGS="
--target=armv7-none-linux-androideabi16
--gcc-toolchain=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64
--sysroot=$NDK/sysroot
-isystem
$NDK/sources/cxx-stl/llvm-libc++/include
-isystem
$NDK/sources/android/support/include
-isystem
$NDK/sources/cxx-stl/llvm-libc++abi/include
-isystem
$NDK/sysroot/usr/include/arm-linux-androideabi
-g
-DANDROID
-ffunction-sections
-funwind-tables
-fstack-protector-strong
-no-canonical-prefixes
-march=armv7-a
-mfloat-abi=softfp
-mfpu=vfpv3-d16
-mthumb
-Wa,--noexecstack
-Wformat
-Werror=format-security
-Oz
-DNDEBUG
-fPIC
$CFLAGS"

CFLAGS="`echo $CFLAGS | tr '\n' ' '`"

LDFLAGS="
--target=armv7-none-linux-androideabi16
--gcc-toolchain=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64
--sysroot=$NDK/sysroot
-fPIC
-isystem
$NDK/sysroot/usr/include/arm-linux-androideabi
-g
-DANDROID
-ffunction-sections
-funwind-tables
-fstack-protector-strong
-no-canonical-prefixes
-march=armv7-a
-mfloat-abi=softfp
-mfpu=vfpv3-d16
-mthumb
-Wa,--noexecstack
-Wformat
-Werror=format-security
-Oz
-DNDEBUG
-Wl,--exclude-libs,libgcc.a
-Wl,--exclude-libs,libatomic.a
-nostdlib++
--sysroot
$NDK/platforms/android-16/arch-arm
-Wl,--build-id
-Wl,--warn-shared-textrel
-Wl,--fatal-warnings
-Wl,--fix-cortex-a8
-Wl,--exclude-libs,libunwind.a
-L$NDK/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a
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
$NDK/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a/libc++_static.a
$NDK/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a/libc++abi.a
$NDK/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a/libandroid_support.a
$NDK/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a/libunwind.a
-ldl
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
