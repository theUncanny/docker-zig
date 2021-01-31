# Manual Zig toolchain build inside a Docker/Podman container

Based on: https://github.com/ziglang/docker-zig

## Run an Alpine Linux based container

In the host system CLI:

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

### Install base development tools packages

In the container system CLI:

```bash
apk update && \
apk upgrade && \
apk add \
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
    zlib-static \
    libstdc++ \
    grep \
    git \
    xz
```

## Download and build LLVM, LLD and Clang

In the container system CLI:

```bash
mkdir -p /deps
LLVM_VERSION='11.0.1'
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
MAKE_JOBS="-j(nproc)"
# Based on 'master' branch
COMMIT="master"
# Based on a specific version (uncomment to use)
#COMMIT='0.7.1'

ARCH="$(uname -m)"

cd "/deps" && \
git clone https://github.com/zig-lang/zig && \
cd "/deps/zig" && \
# If you prefer the latest stable version, uncomment the next line
#COMMIT="$(git --no-pager tag | sort -rV | head -1)"
# If you prefer use the master/main branch, uncomment the next line
#COMMIT="$(git --no-pager branch | grep -q 'master' && echo 'master' || echo 'main')"
git checkout "$COMMIT" && \
mkdir -p "/deps/zig/build" && \
cd "/deps/zig/build" && \
cmake .. \
    -DZIG_STATIC=on \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_INSTALL_PREFIX=/deps/install && \
make "$MAKE_JOBS" install && \
cd "/deps/zig/build" && \
./zig build docs && \
mkdir -p "docs" && \
./zig test ../lib/std/std.zig \
    -femit-docs=docs/std \
    -fno-emit-bin \
    --override-lib-dir ../lib && \
mv "docs" "/deps/install/docs" && \
mv "../zig-cache/langref.html" "/deps/install/docs/" && \
mv "../LICENSE" "/deps/install/" && \
cd "/deps" && \
chmod a+x "install/bin/zig" && \
VERSION="$(install/bin/zig version)" && \
DIRNAME="zig-linux-$ARCH-$VERSION" && \
mv install "$DIRNAME" && \
tar cvfJ "$DIRNAME.tar.xz" "$DIRNAME" && \
chmod a+rw "$DIRNAME.tar.xz" && \
mv "$DIRNAME.tar.xz" "/zig-build/"
```

## Optional: Backup the precompiled LLVM Toolchain

> NOTE: Precompiled LLVM toolchain (llvm, llc, lld, clang, clang++) path: `/deps/local`.

In the container system CLI:

```bash
LLVM_VERSION='11.0.1'
LLVM_TARGET="/deps/local/bin/clang --version | grep -o -P "$(uname -m)[\W,\w]+"
#LLVM_TARGET="x86_64-unknown-linux-musl"
cd "/zig-build/" && \
tar cvf \
    "alpine_linux_$(uname -m)_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" \
    -I 'xz -0' \
    -C "/deps" \
    "local" && \
chmod a+rw "alpine_linux_$(uname -m)_local_llvm_clang_lld_$LLVM_VERSION.tar.xz"
```

In the host system CLI:

```bash
LLVM_VERSION='11.0.1'
mkdir -p "$HOME/Dev/Zig/" && \
cp -f "alpine_linux_$(uname -m)_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" "$HOME/Dev/Zig/"
```

To compile a new released toolchain version, in the host system CLI:

```bash
LLVM_VERSION='11.0.1'
mkdir -p "/tmp/zig-build" && \
cp -f "$HOME/Dev/Zig/alpine_linux_$(uname -m)_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" "/tmp/zig-build/" && \
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
LLVM_VERSION='11.0.1'
mkdir -p "/deps" && \
tar xvf "/zig-build/alpine_linux_$(uname -m)_local_llvm_clang_lld_$LLVM_VERSION.tar.xz" -C "/deps"
```

## Extra info

### LLVM info (glibc based build)

In the container system CLI:

```bash
/deps/local/bin/llc --version
```

Output:

```bash
LLVM (http://llvm.org/):
  LLVM version 11.0.1
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
clang version 11.0.1
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
LLD 11.0.1 (compatible with GNU linkers)
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
  LLVM version 11.0.1
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
clang version 11.0.1
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
LLD 11.0.1 (compatible with GNU linkers)
```

The linker `ld.lld` is a symbolic link to `lld`:

```bash
ls -la /deps/local/bin/ld.lld
```

Output:

```bash
lrwxrwxrwx    1 root     root             3 Jan 31 20:14 /deps/local/bin/ld.lld -> lld
```
