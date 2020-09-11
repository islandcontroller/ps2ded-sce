# -----------------------------------------------------------------------------
# PS2DED - PlayStation 2 DevEnv for Docker
#                                                Sony PlayStation 2 SDK variant
# -----------------------------------------------------------------------------

# [ Builder stage ] - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FROM ubuntu:16.04 AS builder

# Install required packages for unpacking
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        p7zip \
        unzip

# Copy installation files
COPY install /tmp

# Unpack dsnet binaries
RUN mkdir -p /tmp/dsnet && \
    mv /tmp/*dsnet*.7z /tmp/dsnet && \
    cd /tmp/dsnet && \
    p7zip -d *dsnet*.7z

# Unpack Sony PlayStation 2 SDK
RUN cd /tmp && \
    unzip sce.zip && \
    chmod +x \
        sce/bin/* \
        sce/ee/gcc/bin/* \
        sce/iop/gcc/bin/* \
        sce/ee/gcc/ee/bin/* \
        sce/iop/gcc/mipsel-scei-elfl/bin/* \
        sce/ee/gcc/lib/gcc-lib/ee/3.2-ee-040921/* \
        sce/iop/gcc/lib/gcc-lib/mipsel-scei-elfl/2.8.1/*

# [ Application stage ] - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FROM ubuntu:16.04

# Install required packages for the SDK
RUN dpkg --add-architecture i386 && \
    apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        inotify-tools \
        lib32z1 \
        lib32ncurses5 \
        libx11-6:i386 \
        make \
        netbase \
        patch \
        rsync \
        tmux

# Set up environment variables
ENV DSNET=/usr/local/dsnet \
    SCESDKPATH=/usr/local/sce/bin:/usr/local/sce/ee/gcc/bin:/usr/local/sce/iop/gcc/bin \
    PS2DEDPATH=/usr/local/ps2ded
ENV PATH=$PATH:$SCESDKPATH:$DSNET:$PS2DEDPATH
ENV PS2IP=192.168.1.100

# Copy select Sony PlayStation 2 SDK folders from builder stage
RUN mkdir -p /usr/local/sce
COPY --from=builder /tmp/sce /usr/local/sce

# Copy dsnetm binary from builder stage
RUN mkdir -p ${DSNET}
COPY --from=builder /tmp/dsnet/dsnetm ${DSNET}/

# Copy ps2ded scripts
RUN mkdir -p ${PS2DEDPATH}
COPY script ${PS2DEDPATH}
RUN chmod +x ${PS2DEDPATH}/*

# Expose DSNET server port
EXPOSE 8510

# Set working directory
WORKDIR /work