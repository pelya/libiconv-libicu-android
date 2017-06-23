#!/bin/sh

set -x

export BUILDDIR=`pwd`

NCPU=4
uname -s | grep -i "linux" && NCPU=`cat /proc/cpuinfo | grep -c -i processor`

NDK=`which ndk-build`
NDK=`dirname $NDK`
NDK=`readlink -f $NDK`

export CLANG=1

for ARCH in armeabi armeabi-v7a arm64-v8a x86 x86_64; do

cd $BUILDDIR

GCCPREFIX="`env CLANG= ./setCrossEnvironment-$ARCH.sh sh -c 'basename $CC | sed s/-gcc//'`"
echo "ARCH $ARCH GCCPREFIX $GCCPREFIX"

mkdir -p $ARCH
cd $BUILDDIR/$ARCH

# =========== libandroid_support.a ===========

[ -e libandroid_support.a ] || {
mkdir -p android_support
cd android_support
ln -sf $NDK/sources/android/support jni

#ndk-build -j$NCPU APP_ABI=$ARCH APP_MODULES=android_support LIBCXX_FORCE_REBUILD=true CLANG=1 || exit 1
#cp -f obj/local/$ARCH/libandroid_support.a ../
ln -sf $NDK/sources/cxx-stl/llvm-libc++/libs/$ARCH/libandroid_support.a ../

} || exit 1

cd $BUILDDIR/$ARCH

# =========== libiconv.so ===========

[ -e libiconv.so ] || {

	rm -rf libiconv-1.15

	tar xvf ../libiconv-1.15.tar.gz

	cd libiconv-1.15

	cp -f $BUILDDIR/config.sub build-aux/
	cp -f $BUILDDIR/config.guess build-aux/
	cp -f $BUILDDIR/config.sub libcharset/build-aux/
	cp -f $BUILDDIR/config.guess libcharset/build-aux/

	env CFLAGS="-I$NDK/sources/android/support/include" \
		LDFLAGS="-L$BUILDDIR/$ARCH -landroid_support" \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		./configure \
		--host=$GCCPREFIX \
		--prefix=`pwd`/.. \
		--enable-static --enable-shared \
		|| exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 || echo "Libtool is a miserable pile of shit, linking libcharset.so manually"

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		sh -c '$LD $CFLAGS $LDFLAGS -shared libcharset/lib/.libs/*.o -o libcharset/lib/.libs/libcharset.so' || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 || echo "Libtool works worse than cat /dev/urandom | head 10000 > library.so, because this will at least generate a target file, linking libiconv.so manually"

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		sh -c '$LD $CFLAGS $LDFLAGS -shared lib/.libs/*.o -o lib/.libs/libiconv.so' || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 || echo "Did you know that libtool contributes to global warming by overheating your CPU?"

	cp -f lib/.libs/libiconv.so preload/preloadable_libiconv.so

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 install || exit 1

	cd ..

	for f in libiconv libcharset; do
		cp -f lib/$f.so ./
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
			sh -c '$STRIP'" $f.so"
	done

} || exit 1

# =========== libharfbuzz ===========

cd $BUILDDIR/$ARCH

[ -e libharfbuzz.a ] || {
	rm -rf harfbuzz-1.4.6
	tar xvf ../harfbuzz-1.4.6.tar.bz2
	cd harfbuzz-1.4.6

	cp -f $BUILDDIR/config.sub .
	cp -f $BUILDDIR/config.guess .

	env CFLAGS="-I$NDK/sources/android/support/include -frtti -fexceptions -I$BUILDDIR/$ARCH/include" \
		LDFLAGS="-frtti -fexceptions -L$BUILDDIR/$ARCH/lib" \
		LIBS="-L$BUILDDIR/$ARCH -landroid_support -lgnustl_static -lstdc++ -latomic" \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		./configure \
		--host=$GCCPREFIX \
		--prefix=`pwd`/../ \
		--enable-static --disable-shared \
		--with-glib=no --with-gobject=no \
		--with-cairo=no --with-fontconfig=no \
		--with-icu=no --with-freetype=no \
		|| exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make -j$NCPU V=1 || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 install || exit 1

	cd ..
	cp -f lib/libharfbuzz.a ./
}

# =========== libicuuc ===========

cd $BUILDDIR/$ARCH

[ -e libicuuc.a ] || {

	rm -rf icu

	tar xvf ../icu4c-59_1-src.tgz

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

	sed -i "s@LD_SONAME *=.*@LD_SONAME =@g" config/mh-linux
	sed -i "s%ln -s *%cp -f \$(dir \$@)/%g" config/mh-linux

	env CFLAGS="-I$NDK/sources/android/support/include -frtti -fexceptions -include $BUILDDIR/ndk-r15-64-bit-fix.h" \
		LDFLAGS="-frtti -fexceptions -L$BUILDDIR/$ARCH/lib" \
		LIBS="-L$BUILDDIR/$ARCH -landroid_support -lgnustl_static -lstdc++ -latomic" \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		./configure \
		--host=$GCCPREFIX \
		--prefix=`pwd`/../../ \
		--with-cross-build=`pwd`/cross \
		--enable-static --disable-shared \
		--with-data-packaging=archive \
		|| exit 1

#		ICULEHB_CFLAGS="-I$BUILDDIR/$ARCH/include" \
#		ICULEHB_LIBS="-licu-le-hb" \
#		--enable-layoutex \

	sed -i "s@^prefix *= *.*@prefix = .@" icudefs.mk || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make -j$NCPU VERBOSE=1 || exit 1

	sed -i "s@^prefix *= *.*@prefix = `pwd`/../../@" icudefs.mk || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 install || exit 1

	for f in libicudata libicutest libicui18n libicuio libicutu libicuuc; do
		#cp -f -H ../../lib/$f.so ../../
		cp -f ../../lib/$f.a ../../
		#$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		#	sh -c '$STRIP'" ../../$f.so"
	done

} || exit 1

# =========== libicu-le-hb ===========

cd $BUILDDIR/$ARCH

[ -e libicu-le-hb.a ] || {
	rm -rf icu-le-hb-1.0.3
	tar xvf ../icu-le-hb-1.0.3.tar.gz
	cd icu-le-hb-1.0.3

	cp -f $BUILDDIR/config.sub .
	cp -f $BUILDDIR/config.guess .

	env CFLAGS="-I$NDK/sources/android/support/include -frtti -fexceptions" \
		CXXFLAGS="-std=c++11" \
		LDFLAGS="-frtti -fexceptions" \
		LIBS="-L$BUILDDIR/$ARCH -landroid_support -lgnustl_static -lstdc++ -latomic" \
		HARFBUZZ_CFLAGS="-I$BUILDDIR/$ARCH/include/harfbuzz" \
		HARFBUZZ_LIBS="-L$BUILDDIR/$ARCH/lib -lharfbuzz" \
		ICU_CFLAGS="-I$BUILDDIR/$ARCH/include" \
		ICU_LIBS="-L$BUILDDIR/$ARCH/lib" \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		./configure \
		--host=$GCCPREFIX \
		--prefix=`pwd`/../ \
		--enable-static --disable-shared \
		|| exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 install || exit 1

	cd ..
	cp -f lib/libicu-le-hb.a ./
}

# =========== We are building libicu twice, because libiculx depends on libicu-le-hb wcich depends on libicudata ===========

cd $BUILDDIR/$ARCH

[ -e libiculx.a ] || {

	cd icu/source

	env CFLAGS="-I$NDK/sources/android/support/include -frtti -fexceptions -include $BUILDDIR/ndk-r15-64-bit-fix.h" \
		LDFLAGS="-frtti -fexceptions -L$BUILDDIR/$ARCH/lib" \
		LIBS="-L$BUILDDIR/$ARCH -landroid_support -lgnustl_static -lstdc++ -latomic" \
		ICULEHB_CFLAGS="-I$BUILDDIR/$ARCH/include/icu-le-hb" \
		ICULEHB_LIBS="-licu-le-hb" \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		./configure \
		--host=$GCCPREFIX \
		--prefix=`pwd`/../../ \
		--with-cross-build=`pwd`/cross \
		--enable-static --disable-shared \
		--with-data-packaging=archive \
		--enable-layoutex \
		|| exit 1

	sed -i "s@^prefix *= *.*@prefix = .@" icudefs.mk || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make -j$NCPU VERBOSE=1 || exit 1

	sed -i "s@^prefix *= *.*@prefix = `pwd`/../../@" icudefs.mk || exit 1

	env PATH=`pwd`:$PATH \
		$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		make V=1 install || exit 1

	for f in libicudata libicutest libicui18n libicuio libicutu libicuuc libiculx; do
		#cp -f -H ../../lib/$f.so ../../
		cp -f ../../lib/$f.a ../../ || exit 1
		#$BUILDDIR/setCrossEnvironment-$ARCH.sh \
		#	sh -c '$STRIP'" ../../$f.so"
	done

} || exit 1


done # for ARCH in ...

exit 0
