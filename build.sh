#!/bin/sh

set -x

export BUILDDIR=`pwd`

NCPU=4
uname -s | grep -i "linux" && NCPU=`cat /proc/cpuinfo | grep -c -i processor`

NDK=`which ndk-build`
NDK=`dirname $NDK`
NDK=`readlink -f $NDK`

for ARCH in armeabi armeabi-v7a; do

cd $BUILDDIR
mkdir -p $ARCH
cd $BUILDDIR/$ARCH

# =========== libandroid_support.a ===========

[ -e libandroid_support.a ] || {
mkdir -p android_support
cd android_support
ln -sf $NDK/sources/android/support jni

ndk-build -j$NCPU APP_ABI=$ARCH || exit 1
ln -sf android_support/obj/local/$ARCH/libandroid_support.a ../

} || exit 1

cd $BUILDDIR/$ARCH

# =========== libiconv.so ===========

[ -e libiconv.so ] || {

[ -d libiconv-1.14 ] || curl http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz | tar xvz || exit 1

cd libiconv-1.14

cp -f $BUILDDIR/config.sub build-aux/
cp -f $BUILDDIR/config.guess build-aux/
cp -f $BUILDDIR/config.sub libcharset/build-aux/
cp -f $BUILDDIR/config.guess libcharset/build-aux/

env CFLAGS="-I$NDK/sources/android/support/include" \
LDFLAGS="-L$BUILDDIR/$ARCH -landroid_support" \
$BUILDDIR/setCrossEnvironment-$ARCH.sh \
./configure \
--host=arm-linux-androideabi \
--prefix=`pwd`/.. \
--enable-static --enable-shared \
|| exit 1

env PATH=`pwd`:$PATH \
$BUILDDIR/setCrossEnvironment-$ARCH.sh \
make -j$NCPU V=1 || exit 1

env PATH=`pwd`:$PATH \
$BUILDDIR/setCrossEnvironment-$ARCH.sh \
make V=1 install || exit 1

ln -sf lib/libiconv.so ../
ln -sf lib/libcharset.so ../

} || exit 1

cd $BUILDDIR/$ARCH

# =========== libicu.so ===========

[ -e libicudata.so ] || {

[ -d icu ] || curl http://download.icu-project.org/files/icu4c/52.1/icu4c-52_1-src.tgz | tar xvz || exit 1

cd icu/source

cp -f $BUILDDIR/config.sub .
cp -f $BUILDDIR/config.guess .

[ -d cross ] || {
mkdir cross
cd cross
../configure || exit 1
make -j$NCPU VERBOSE=1 || exit 1
cd ..
} || exit 1

env CFLAGS="-I$NDK/sources/android/support/include -frtti -fexceptions" \
LDFLAGS="-frtti -fexceptions" \
LIBS="-L$BUILDDIR/$ARCH -landroid_support -lgnustl_static -lstdc++" \
$BUILDDIR/setCrossEnvironment-$ARCH.sh \
./configure \
--host=arm-linux-androideabi \
--prefix=`pwd`/../.. \
--with-cross-build=`pwd`/cross \
--enable-static --enable-shared \
|| exit 1

env PATH=`pwd`:$PATH \
$BUILDDIR/setCrossEnvironment-$ARCH.sh \
make -j$NCPU VERBOSE=1 || exit 1

env PATH=`pwd`:$PATH \
$BUILDDIR/setCrossEnvironment-$ARCH.sh \
make V=1 install || exit 1

for f in libicudata libicui18n libicuio libicule libiculx libicutest libicutu libicuuc; do
ln -sf lib/$f.so ../../
ln -sf lib/$f.a ../../
done

} || exit 1

done # for ARCH in armeabi armeabi-v7a

exit 0
