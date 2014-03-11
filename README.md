libiconv-libicu-android
=======================

Port of libiconv and libicu to Android

You will need NDK r9b, curl, autoconf, automake, libtool, and git installed.

There are no sources and no patches - everything is done with magical build scripts,
just run build.sh and enjoy.
Don't forget to strip them, because they are huge with debug info included.

If you need libintl, you may download it here:
https://github.com/pelya/commandergenius/tree/sdl_android/project/jni/intl
