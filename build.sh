#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_NDK_HOME:?ANDROID_NDK_HOME is required}"
: "${PYTHON_SRC:?PYTHON_SRC is required}"
: "${OUT:?OUT is required}"

API="${ANDROID_API:-28}"
TRIPLE="aarch64-linux-android${API}"
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
BUILD="$OUT/build"
STAGE="$OUT/stage"
BUNDLE="$OUT/bundle"
mkdir -p "$BUILD" "$STAGE" "$BUNDLE"

export PATH="$TOOLCHAIN/bin:$PATH"
export CC="$TOOLCHAIN/bin/clang"
export CXX="$TOOLCHAIN/bin/clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export PKG_CONFIG=false
export READELF="/usr/bin/readelf"
export CFLAGS="--target=$TRIPLE -O2 -fPIC"
export LDFLAGS="--target=$TRIPLE -fPIE -pie -llog"

cd "$PYTHON_SRC"
if [[ ! -f Makefile ]]; then
  ./configure \
    --build=x86_64-linux-gnu \
    --host="$TRIPLE" \
    --prefix=/opt/python \
    --with-build-python="${BUILD_PYTHON:-python3}" \
    --disable-shared \
    --without-ensurepip \
    --disable-test-modules \
    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no \
    ac_cv_func_wcsftime=no \
    ac_cv_func_ftime=no \
    ac_cv_func_faccessat=no \
    ac_cv_func_link=no \
    ac_cv_func_linkat=no \
    ac_cv_buggy_getaddrinfo=no \
    ac_cv_little_endian_double=yes \
    ac_cv_posix_semaphores_enabled=yes \
    ac_cv_func_sem_open=yes \
    ac_cv_func_sem_timedwait=yes \
    ac_cv_func_sem_getvalue=yes \
    ac_cv_func_sem_unlink=yes \
    ac_cv_func_shm_open=yes \
    ac_cv_func_shm_unlink=yes \
    ac_cv_working_tzset=yes \
    ac_cv_header_sys_xattr_h=no \
    ac_cv_header_ffi_h=no \
    ac_cv_lib_ffi_ffi_call=no \
    py_cv_module__ctypes=disabled \
    py_cv_module__ctypes_test=disabled \
    py_cv_module__dbm=disabled \
    py_cv_module__gdbm=disabled \
    py_cv_module__lzma=disabled \
    py_cv_module__ssl=disabled \
    py_cv_module__sqlite3=disabled \
    py_cv_module__tkinter=disabled \
    py_cv_module__curses=disabled \
    py_cv_module__bz2=disabled \
    py_cv_module__zstd=disabled \
    py_cv_module_zlib=disabled \
    py_cv_module_readline=disabled
fi
make -j"${JOBS:-2}"
make install DESTDIR="$STAGE"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE"
cp -a "$STAGE/opt/python" "$BUNDLE/"
mkdir -p "$BUNDLE/bin"
cat > "$BUNDLE/bin/python3" <<'WRAPPER'
#!/system/bin/sh
set -eu
SELF=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SELF/.." && pwd)
export PYTHONHOME="$ROOT/opt/python"
unset PYTHONPATH
exec "$ROOT/opt/python/bin/python3.13" "$@"
WRAPPER
chmod 755 "$BUNDLE/bin/python3"
ln -s python3 "$BUNDLE/bin/python"

# The target is Android/aarch64 and must not be executed on the x86_64 CI runner.
file "$BUNDLE/opt/python/bin/python3.13"
readelf -d "$BUNDLE/opt/python/bin/python3.13" | grep NEEDED || true
