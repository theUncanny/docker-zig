FROM alpine:latest as builder

ENV LLVM_VERSION='11.0.1'

RUN apk update && \
    apk upgrade && \
    apk add \
        gcc \
        g++ \
        automake \
        autoconf \
        pkgconfig \
        python3-dev \
        cmake \
        samurai \
        tar \
        libc-dev \
        binutils \
        zlib-static \
        libstdc++

RUN mkdir -p /deps

# llvm
WORKDIR /deps
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/llvm-$LLVM_VERSION.src.tar.xz
RUN tar xf llvm-$LLVM_VERSION.src.tar.xz
RUN mkdir -p /deps/llvm-$LLVM_VERSION.src/build
WORKDIR /deps/llvm-$LLVM_VERSION.src/build
RUN cmake .. \
    -DCMAKE_INSTALL_PREFIX=/deps/local \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_MAKE_PROGRAM=samu \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -G Ninja
RUN samu install

# lld
WORKDIR /deps
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/lld-$LLVM_VERSION.src.tar.xz
RUN tar xf lld-$LLVM_VERSION.src.tar.xz
RUN mkdir -p /deps/lld-$LLVM_VERSION.src/build
WORKDIR /deps/lld-$LLVM_VERSION.src/build
RUN cmake .. \
    -DCMAKE_INSTALL_PREFIX=/deps/local \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_MAKE_PROGRAM=samu \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja
RUN samu install

# clang
WORKDIR /deps
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/clang-$LLVM_VERSION.src.tar.xz
RUN tar xf clang-$LLVM_VERSION.src.tar.xz
RUN mkdir -p /deps/clang-$LLVM_VERSION.src/build
WORKDIR /deps/clang-$LLVM_VERSION.src/build
RUN cmake .. \
    -DCMAKE_INSTALL_PREFIX=/deps/local \
    -DCMAKE_PREFIX_PATH=/deps/local \
    -DCMAKE_MAKE_PROGRAM=samu \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja
RUN samu install

FROM alpine:latest
RUN apk update && \
    apk upgrade && \
    apk add \
        gcc \
        g++ \
        cmake \
        make \
        libc-dev \
        binutils \
        zlib-static \
        libstdc++ \
        git \
        xz
COPY \
    --from=builder \
    /deps/local/lib \
    /deps/local/lib
COPY \
    --from=builder \
    /deps/local/include \
    /deps/local/include
COPY \
    --from=builder \
    /deps/local/bin/llvm-config \
    /deps/local/bin/llvm-config
COPY build /deps/build

ENTRYPOINT ["/deps/build"]
