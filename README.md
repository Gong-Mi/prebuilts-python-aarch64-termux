# Portable aarch64-Termux Python host prebuilt

This repository builds a portable Python host tool on GitHub Actions with the
Android NDK. It does not require `pkg install python` or `dpkg -i` at runtime.

Current experiment target:

- CPython: 3.13.7
- Source SHA256: `5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a`
- Target: `aarch64-linux-android28`
- NDK: r29 `29.0.14206865`
- Build mode: `--disable-shared`, static libpython, dynamic Android system libc only

The first CI artifact is an external-stdlib portable bundle. The next step is
embedding its bytecode archive into a single `py3-cmd` ELF, matching AOSP's
`prebuilts/build-tools/path/linux-x86/python3` model.

The artifact is accepted only after:

- `readelf -h/-l/-d` audit;
- no `libpython` or host glibc dependency;
- execution with system Python and `LD_LIBRARY_PATH` unset;
- moving the entire bundle to a different directory and repeating imports;
- Kleaf `bazel.py` import smoke test.
