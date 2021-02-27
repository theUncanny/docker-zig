# Manual Zig toolchain build inside a Docker/Podman container

Based on: https://github.com/ziglang/docker-zig

## Run an Alpine Linux based containerz

In the host system CLI:

```bash
mkdir -p "/tmp/zig-build" && \
cd "/tmp/zig-build" && \
docker run \
    --rm \
    -it \
    --mount type=bind,source="$(pwd)",target=/zig-build \
    alpine:latest
```

----

**[TO-DO] Check use the current user and group from host system in the container system**

```bash
mkdir -p "/tmp/zig-build" && \
cd "/tmp/zig-build" && \
docker run \
    --rm \
    -it \
    -u "$(id -u):$(id -g)" \
    --mount type=bind,source="$(pwd)",target=/zig-build \
    alpine:latest
```
----

### Install base development tools packages

In the container system CLI:

```bash
apk update && \
apk upgrade --no-cache && \
apk add \
    --update \
    --no-cache \
    --virtual build-dependencies \
    alpine-sdk \
    build-base \
    musl \
    musl-dev \
    gcc \
    g++ \
    automake \
    autoconf \
    pkgconfig \
    python3-dev \
    cmake \
    make \
    samurai \
    tar \
    libc-dev \
    binutils \
    zlib-dev \
    zlib-static \
    readline-dev \
    readline-static \
    libstdc++ \
    libffi-dev \
    openssl-dev \
    bash \
    curl \
    nano \
    grep \
    file \
    git \
    xz
```

----

**[NOTE] Alpine Linux `build-dependencies` "virtual meta package"**

The `apk` option, `--virtual`, "tag" the argument immediately following is what the group is named so, in the previous block, `apk` creates a group named `build-dependencies` such as "virtual meta package" (consisting of `alpine-sdk`, `build-base`, `musl-dev`, `gcc`, `git`, etc.), and then `apk` installs all the packages now grouped by the `build-dependencies` virtual meta package:

To find the installed virtual meta package `build-dependencies`:

```bash
apk list *build* | grep 'build-dependencies'
```

Output:

```bash
build-dependencies-20210227.181655 noarch {build-dependencies} () [installed]
```

Package info:

```bash
apk info build-dependencies
```

Output:

```bash
build-dependencies-20210227.181655 description:
virtual meta package

build-dependencies-20210227.181655 webpage:


build-dependencies-20210227.181655 installed size:
0 B
```

----

----

**[TIP] Check the Musl version and dynamic linker**

Check standard dynamic linker (dynamic program loader) with `ldd` (`ldd` invokes the _standard dynamic linker_):

```bash
ldd
```

Output:

```bash
musl libc (x86_64)
Version 1.2.2
Dynamic Program Loader
Usage: /lib/ld-musl-x86_64.so.1 [options] [--] pathname
```

Show `musl` Alpine Linux info package:

```bash
apk info musl
```

Output:

```bash
musl-1.2.2-r0 description:
the musl c library (libc) implementation

musl-1.2.2-r0 webpage:
https://musl.libc.org/

musl-1.2.2-r0 installed size:
608 KiB
```

----

## Download and build LLVM, LLD and Clang

- https://llvm.org/
- https://releases.llvm.org/
- https://github.com/llvm/llvm-project
- https://github.com/llvm/llvm-project/releases
- https://www.phoronix.com/scan.php?page=news_item&px=LLVM-11.1-Released
- http://www.linuxfromscratch.org/blfs/view/svn/general/llvm.html


In the container system CLI:

```bash
mkdir -p /deps
LLVM_VERSION='11.1.0'
# Linux x86-64 based on GNU standard C library implementation (glibc)
#LLMV_HOST='x86_64-unknown-linux-gnu'
#LLVM_TARGET='x86_64-unknown-linux-gnu'
# Linux x86-64 based on Musl standard C library implementation (musl)
LLMV_HOST='x86_64-unknown-linux-musl'
LLVM_TARGET='x86_64-unknown-linux-musl'
```

### Build LLVM

In the container system CLI:

```bash
cd /deps && \
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-"$LLVM_VERSION"/llvm-"$LLVM_VERSION".src.tar.xz && \
tar xvf llvm-"$LLVM_VERSION".src.tar.xz && \
mkdir -p /deps/llvm-"$LLVM_VERSION".src/build && \
cd /deps/llvm-"$LLVM_VERSION".src/build && \
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/deps/local \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_MAKE_PROGRAM=samu \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_BUILD_DOCS=NO \
    -DLLVM_BUILD_EXAMPLES=NO \
    -DLLVM_BUILD_TESTS=NO \
    -DLLVM_DEFAULT_TARGET_TRIPLE="$LLVM_TARGET" \
    -DLLVM_HOST_TRIPLE="$LLMV_HOST" \
    -G Ninja && \
samu install
```

### Build LLD (Linker)

In the container system CLI:

```bash
cd /deps && \
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-"$LLVM_VERSION"/lld-"$LLVM_VERSION".src.tar.xz && \
tar xf lld-"$LLVM_VERSION".src.tar.xz && \
mkdir -p /deps/lld-"$LLVM_VERSION".src/build && \
cd /deps/lld-"$LLVM_VERSION".src/build && \
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/deps/local \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_MAKE_PROGRAM=samu \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_BUILD_DOCS=NO \
    -DLLVM_BUILD_EXAMPLES=NO \
    -DLLVM_BUILD_TESTS=NO \
    -DLLVM_DEFAULT_TARGET_TRIPLE="$LLVM_TARGET" \
    -DLLVM_HOST_TRIPLE="$LLMV_HOST" \
    -G Ninja && \
samu install
```

### Build Clang (C and C++ Compiler)

In the container system CLI:

```bash
cd /deps && \
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-"$LLVM_VERSION"/clang-"$LLVM_VERSION".src.tar.xz && \
tar xf clang-"$LLVM_VERSION".src.tar.xz && \
mkdir -p /deps/clang-"$LLVM_VERSION".src/build && \
cd /deps/clang-"$LLVM_VERSION".src/build && \
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/deps/local \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_MAKE_PROGRAM=samu \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_BUILD_DOCS=NO \
    -DLLVM_BUILD_EXAMPLES=NO \
    -DLLVM_BUILD_TESTS=NO \
    -DLLVM_DEFAULT_TARGET_TRIPLE="$LLVM_TARGET" \
    -DLLVM_HOST_TRIPLE="$LLMV_HOST" \
    -G Ninja && \
samu install
```

## Download and build Zig toolchain

> NOTE: Instructions (same content as Bash script `build`).

In the container system CLI:

```bash
CC="/deps/local/bin/clang"
CXX="/deps/local/bin/clang++"

# Flags for clang: Insert your arch here instead of k8 and have a look at the manpage of clang for flag descriptions.
# Some gcc flags like -pipe and -pthread also work, though they might be ignored by clang.
CFLAGS="-O2 -pipe -march=native"
CXXFLAGS="$CFLAGS"
```

```bash
# Maximum number of parallel 'make' build jobs
MAKE_JOBS="-j$(nproc)"
# Based on 'master' branch
COMMIT="master"
# Based on a specific version (uncomment to use)
#COMMIT='0.7.1'
# Host (and container) architecture
ARCH="$(uname -m)"
# Zig prefix install directory
ZIG_INSTALL_PREFIX='/deps/install'

cd "/deps" && \
git clone https://github.com/zig-lang/zig && \
cd "/deps/zig" && \
# If you prefer the latest stable version, uncomment the next line
#COMMIT="$(git --no-pager tag | sort -rV | head -1)" && \
# If you prefer use the master/main branch, uncomment the next line
#COMMIT="$(git --no-pager branch | grep -q 'master' && echo 'master' || echo 'main')" && \
git checkout "$COMMIT" && \
mkdir -p "$ZIG_INSTALL_PREFIX" && \
mkdir -p "/deps/zig/build" && \
cd "/deps/zig/build" && \
cmake .. \
    -DZIG_STATIC=on \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_INSTALL_PREFIX="$ZIG_INSTALL_PREFIX" && \
make "$MAKE_JOBS" install && \
cd "/deps/zig/build" && \
./zig build docs && \
mkdir -p "docs" && \
./zig test ../lib/std/std.zig \
    -femit-docs=docs/std \
    -fno-emit-bin \
    --override-lib-dir ../lib && \
mv "docs" "$ZIG_INSTALL_PREFIX/docs" && \
mv "../zig-cache/langref.html" "$ZIG_INSTALL_PREFIX/docs/" && \
mv "../LICENSE" "$ZIG_INSTALL_PREFIX/" && \
chmod a+x "$ZIG_INSTALL_PREFIX/bin/zig" && \
cd "/deps"
```

Compress (in a `.tar.xz` file) the `zig` toolchain build in a package (to backup, copy and distribute it) from the container systm to the host system:

```bash
VERSION="$(/deps/install/bin/zig version)" && \
DIRNAME="zig-linux-$ARCH-$VERSION" && \
cd "/deps" && \
mv install "$DIRNAME" && \
tar cvfJ "$DIRNAME.tar.xz" "$DIRNAME" && \
chmod a+rw "$DIRNAME.tar.xz" && \
mv "$DIRNAME.tar.xz" "/zig-build/"
```

In the host system CLI:

```bash
mkdir -p "$HOME/Dev/Zig" && \
cd "/tmp/zig-build/" && \
cp -f -v zig-linux-x86_64-*.tar.xz "$HOME/Dev/Zig/"
```

----

**[TIP]**

To restore a Zig toolchain precompiled, in the host system CLI:

```bash
LLVM_VERSION='11.1.0'
LLVM_TARGET="x86_64-unknown-linux-musl"
mkdir -p "/tmp/zig-build" && \
cp -f -v "$HOME/Dev/Zig/alpine_linux_${LLVM_TARGET}_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" "/tmp/zig-build/" && \
cd "/tmp/zig-build" && \
docker run \
    --rm \
    -it \
    -u "$(id -u):$(id -g)" \
    --mount type=bind,source="$(pwd)",target=/zig-build \
    alpine:latest
```

Copy the Zig toolchain precompiled package to host-container mount binded path (`/tmp/zig-build/`): 

```bash
cp -f -v "$HOME/Dev/Zig/zig-linux-x86_64-*.tar.xz" "/tmp/zig-build/"
```

In the container system CLI:

```bash
tar xvf /zig-build/zig-linux-x86_64-*.tar.xz -C /deps && \
cd /deps && \
ln -sf zig-linux-x86_64-* install
```

----

## Optional: Build `zls` (Zig Language Server)

- https://github.com/zigtools/zls
- https://github.com/zigtools/zls/wiki/Downloading-and-Building-ZLS
- https://github.com/zigtools/zls/blob/master/README.md#configuration-options
- https://github.com/zigtools/zls/blob/master/README.md#usage
- https://github.com/zigtools/zls/wiki/Installing-for-Kakoune
- https://github.com/ziglibs/known-folders#folder-list

In the container system CLI:

```bash
# Zig prefix install directory
ZIG_INSTALL_PREFIX='/deps/install'
# Data version string (select one from src/data/)
ZIG_VERSION='master'
#ZIG_VERSION='0.7.0'
cd "/deps" && \
git clone --recurse-submodules https://github.com/zigtools/zls.git && \
cd "/deps/zls" && \
rm -Rf "$HOME/.cache/zig" ; \
/deps/zig/build/zig build -Drelease-safe -Ddata_version="$ZIG_VERSION"
#"$ZIG_INSTALL_PREFIX"/bin/zig build -Drelease-safe -Ddata_version="$ZIG_VERSION"
```

To create a `zls` configuration file (`zls.json`):

```bash
tee "/deps/zls/zig-cache/bin/zls.json" <<E_O_F > /dev/null 2>&1
{
  "zig_exe_path": null,
  "zig_lib_path": null,
  "build_runner_path": null,
  "build_runner_cache_path": null, 
  "enable_snippets": true,
  "warn_style": true,
  "enable_semantic_tokens": true,
  "operator_completions": true
}

E_O_F
```

Copy `zls` binary and `zls.json` config file to the Zig toolchain install prefix path:

```bash
cp 'zig-cache/bin/zls' "$ZIG_INSTALL_PREFIX/bin/" && \
cp 'zig-cache/bin/zls.json' "$ZIG_INSTALL_PREFIX/bin/" && \
chmod a+x "$ZIG_INSTALL_PREFIX/bin/zls"
```

----

**[INFO] The `zls` config file (JSON format)**

- `zls.json`:

```json
{
  "zig_exe_path": null,
  "zig_lib_path": null,
  "build_runner_path": null,
  "build_runner_cache_path": null, 
  "enable_snippets": true,
  "warn_style": true,
  "enable_semantic_tokens": true,
  "operator_completions": true
}
```

- `zig_exe_path`: Set to `null` value so the `zls` look up the `zig` binary in `PATH` environment variable (when it is setup, the `zig` binary absolute path must be `$ZIG_TOOLCHAIN_PATH/bin/zig`). Will be used to infer the zig standard library path if none is provided.
- `zig_lib_path`: Set to `null` because `zig` binary will be used to infer the zig standard library path if none is provided.

----

----

**[NOTE]**

Generate a `zls` configuration file (`zls.json`):

```bash
/deps/zig/build/zig build config
```

Output:

```bash
Welcome to the ZLS configuration wizard! (insert mage emoji here)
Looking for 'zig' in PATH...
Could not find 'zig' in PATH
? What is the path to the 'zig' executable you would like to use? > /deps/zig/build/zig
? Do you want to enable snippets? (y/n) > y
? Do you want to enable style warnings? (y/n) > y
? Do you want to enable semantic highlighting? (y/n) > y
? Do you want to enable .* and .? completions (y/n) > y
Writing to config...
Successfully saved configuration options!
? Which code editor do you use? (select one)

  - VSCode
  - Sublime
  - Kate
  - Neovim
  - Vim8
  - Emacs
  - Other

> Other

We might not *officially* support your editor, but you can definitely still use ZLS!
Simply configure your editor for use with language servers and point it to the ZLS executable!
You can find the ZLS executable in the "zig-cache/bin" by default.
NOTE: Make sure that if you move the ZLS executable, you move the `zls.json` config file with it as well!

And finally: Thanks for choosing ZLS!
```

Check `zls` binary:

```bash
file zig-cache/bin/zls
```

Output:

```bash
zig-cache/bin/zls: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

----

----

**[TO-DO]**

When try to compile `zls` using a `zig` binary based on `0.7.0` or `0.7.1` version release, the build process fail: 

```bash
zig build -Drelease-safe -Ddata_version="0.7.0"
```

Output:

```bash
./src/document_store.zig:110:36: error: no member named 'shrinkAndFree' in struct 'std.array_list.ArrayListAlignedUnmanaged(document_store.Pkg,null)'
                build_file.packages.shrinkAndFree(allocator, 0);
                                   ^
./src/document_store.zig:419:12: note: referenced here
        }) catch |err| {
           ^
./src/main.zig:1193:5: note: referenced here
    try document_store.applySave(handle);
    ^
./src/analysis.zig:202:26: error: expected optional type, found '*std.zig.ast.Node'
            return ((decl.name orelse return null).castTag(.StringLiteral) orelse return null).token;
                         ^
./src/analysis.zig:202:32: note: referenced here
            return ((decl.name orelse return null).castTag(.StringLiteral) orelse return null).token;
                               ^
zls...The following command exited with error code 1:
/deps/zig/build/zig build-exe /deps/zls/src/main.zig --pkg-begin build_options /deps/zls/zig-cache/zls_build_options.zig --pkg-end -OReleaseSafe --cache-dir /deps/zls/zig-cache --global-cache-dir /root/.cache/zig --name zls --pkg-begin known-folders /deps/zls/src/known-folders/known-folders.zig --pkg-end --enable-cache
error: the following build command failed with exit code 1:
/deps/zls/zig-cache/o/46f7a20dc6466be02aa2463bd1ddc27d/build /deps/zig/build/zig /deps/zls /deps/zls/zig-cache /root/.cache/zig -Drelease-safe -Ddata_version=0.7.0
```

----

## Optional: Backup the precompiled LLVM Toolchain

> NOTE: Precompiled LLVM toolchain (llvm, llc, lld, clang, clang++) path: `/deps/local`.

In the container system CLI:

```bash
LLVM_VERSION='11.1.0'
LLVM_TARGET="$(/deps/local/bin/clang --version | grep -e 'Target:' | cut -d' ' -f2)"
#LLVM_TARGET="x86_64-unknown-linux-musl"
cd "/zig-build/" && \
tar cvf \
    "alpine_linux_$(uname -m)_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" \
    -I 'xz -0' \
    -C "/deps" \
    "local" && \
chmod a+rw "alpine_linux_${LLVM_TARGET}_local_llvm_clang_lld_$LLVM_VERSION.tar.xz"
```

In the host system CLI:

```bash
LLVM_VERSION='11.1.0'
#LLVM_TARGET="x86_64-unknown-linux-musl"
mkdir -p "$HOME/Dev/Zig/" && \
cp -f -v alpine_linux_*_local_llvm_clang_lld_$LLVM_VERSION.tar.xz "$HOME/Dev/Zig/"
```

----

**[TIP] Restore a precompiled LLVM/Clang/LLD to build a new Zig toolchain release**

To compile a new Zig toolchain version released, in the host system CLI:

```bash
LLVM_VERSION='11.1.0'
LLVM_TARGET="x86_64-unknown-linux-musl"
mkdir -p "/tmp/zig-build" && \
cp -f -v "$HOME/Dev/Zig/alpine_linux_${LLVM_TARGET}_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" "/tmp/zig-build/" && \
cd "/tmp/zig-build" && \
docker run \
    --rm \
    -it \
    -u "$(id -u):$(id -g)" \
    --mount type=bind,source="$(pwd)",target=/zig-build \
    alpine:latest
```

In the container system CLI:

```bash
LLVM_VERSION='11.1.0'
LLVM_TARGET="/deps/local/bin/clang --version | grep -o -P "$(uname -m)[\W,\w]+"
mkdir -p "/deps" && \
tar xvf "/zig-build/alpine_linux_${LLVM_TARGET}_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" -C "/deps"
```

----

## Extra info

### Zig build info

```bash
cd /deps/zig-linux*/bin && \
ldd zig
```

Output:

```bash
/lib/ld-musl-x86_64.so.1: zig: Not a valid dynamic program
```

Check `zig` binary info with `file`:

```bash
file zig
```

Output:

```bash
zig: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, with debug_info, not stripped
```

With `objdump`:

```bash
objdump -s --section .comment zig
```

Output:

```bash
zig:     file format elf64-x86-64

Contents of section .comment:
 0000 4743433a 2028416c 70696e65 2031302e  GCC: (Alpine 10.
 0010 322e315f 70726531 29203130 2e322e31  2.1_pre1) 10.2.1
 0020 20323032 30313230 3300                20201203.
```

With `readelf`:

```bash
readelf -p .comment zig
```

Output:

```bash
String dump of section '.comment':
  [     0]  GCC: (Alpine 10.2.1_pre1) 10.2.1 20201203
```

- Info: https://unix.stackexchange.com/questions/719/can-we-get-compiler-information-from-an-elf-binary

### LLVM info (glibc based build)

In the container system CLI:

```bash
/deps/local/bin/llc --version
```

Output:

```bash
LLVM (http://llvm.org/):
  LLVM version 11.1.0
  Optimized build.
  Default target: x86_64-unknown-linux-gnu
  Host CPU: skylake

  Registered Targets:
    aarch64    - AArch64 (little endian)
    aarch64_32 - AArch64 (little endian ILP32)
    aarch64_be - AArch64 (big endian)
    amdgcn     - AMD GCN GPUs
    arm        - ARM
    arm64      - ARM64 (little endian)
    arm64_32   - ARM64 (little endian ILP32)
    armeb      - ARM (big endian)
    avr        - Atmel AVR Microcontroller
    bpf        - BPF (host endian)
    bpfeb      - BPF (big endian)
    bpfel      - BPF (little endian)
    hexagon    - Hexagon
    lanai      - Lanai
    mips       - MIPS (32-bit big endian)
    mips64     - MIPS (64-bit big endian)
    mips64el   - MIPS (64-bit little endian)
    mipsel     - MIPS (32-bit little endian)
    msp430     - MSP430 [experimental]
    nvptx      - NVIDIA PTX 32-bit
    nvptx64    - NVIDIA PTX 64-bit
    ppc32      - PowerPC 32
    ppc64      - PowerPC 64
    ppc64le    - PowerPC 64 LE
    r600       - AMD GPUs HD2XXX-HD6XXX
    riscv32    - 32-bit RISC-V
    riscv64    - 64-bit RISC-V
    sparc      - Sparc
    sparcel    - Sparc LE
    sparcv9    - Sparc V9
    systemz    - SystemZ
    thumb      - Thumb
    thumbeb    - Thumb (big endian)
    wasm32     - WebAssembly 32-bit
    wasm64     - WebAssembly 64-bit
    x86        - 32-bit X86: Pentium-Pro and above
    x86-64     - 64-bit X86: EM64T and AMD64
    xcore      - XCore
```

Check `clang`:

```bash
/deps/local/bin/clang --version
```

Output:

```bash
clang version 11.1.0
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /deps/local/bin
```

Check `ldd` (LLVM generic linker):

```bash
/deps/local/bin/lld --version
```

Output:

```bash
lld is a generic driver.
Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
```

Check `ld.lld` (UNIX/Linux LLVM linker):

```bash
/deps/local/bin/ld.lld --version
```

Output:

```bash
LLD 11.1.0 (compatible with GNU linkers)
```

The linker `ld.lld` is a symbolic link to `lld`:

```bash
ls -la /deps/local/bin/ld.lld
```

Output:

```bash
lrwxrwxrwx    1 root     root             3 Jan 31 20:14 /deps/local/bin/ld.lld -> lld
```

### LLVM info (musl based build)

In the container system CLI:

```bash
/deps/local/bin/llc --version
```

Output:

```bash
LLVM (http://llvm.org/):
  LLVM version 11.1.0
  Optimized build.
  Default target: x86_64-unknown-linux-musl
  Host CPU: skylake

  Registered Targets:
    aarch64    - AArch64 (little endian)
    aarch64_32 - AArch64 (little endian ILP32)
    aarch64_be - AArch64 (big endian)
    amdgcn     - AMD GCN GPUs
    arm        - ARM
    arm64      - ARM64 (little endian)
    arm64_32   - ARM64 (little endian ILP32)
    armeb      - ARM (big endian)
    avr        - Atmel AVR Microcontroller
    bpf        - BPF (host endian)
    bpfeb      - BPF (big endian)
    bpfel      - BPF (little endian)
    hexagon    - Hexagon
    lanai      - Lanai
    mips       - MIPS (32-bit big endian)
    mips64     - MIPS (64-bit big endian)
    mips64el   - MIPS (64-bit little endian)
    mipsel     - MIPS (32-bit little endian)
    msp430     - MSP430 [experimental]
    nvptx      - NVIDIA PTX 32-bit
    nvptx64    - NVIDIA PTX 64-bit
    ppc32      - PowerPC 32
    ppc64      - PowerPC 64
    ppc64le    - PowerPC 64 LE
    r600       - AMD GPUs HD2XXX-HD6XXX
    riscv32    - 32-bit RISC-V
    riscv64    - 64-bit RISC-V
    sparc      - Sparc
    sparcel    - Sparc LE
    sparcv9    - Sparc V9
    systemz    - SystemZ
    thumb      - Thumb
    thumbeb    - Thumb (big endian)
    wasm32     - WebAssembly 32-bit
    wasm64     - WebAssembly 64-bit
    x86        - 32-bit X86: Pentium-Pro and above
    x86-64     - 64-bit X86: EM64T and AMD64
    xcore      - XCore
```

Check `clang`:

```bash
/deps/local/bin/clang --version
```

Output:

```bash
clang version 11.1.0
Target: x86_64-unknown-linux-musl
Thread model: posix
InstalledDir: /deps/local/bin
```

Check `ldd` (LLVM generic linker):

```bash
/deps/local/bin/lld --version
```

Output:

```bash
lld is a generic driver.
Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
```

Check `ld.lld` (UNIX/Linux LLVM linker):

```bash
/deps/local/bin/ld.lld --version
```

Output:

```bash
LLD 11.1.0 (compatible with GNU linkers)
```

The linker `ld.lld` is a symbolic link to `lld`:

```bash
ls -la /deps/local/bin/ld.lld
```

Output:

```bash
lrwxrwxrwx    1 root     root             3 Jan 31 20:14 /deps/local/bin/ld.lld -> lld
```
