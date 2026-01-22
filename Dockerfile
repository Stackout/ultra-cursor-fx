# Dockerfile for WoW Addon Testing
# Uses Lua 5.1 (WoW's Lua version) with Busted testing framework

FROM alpine:3.19

# Install Lua 5.1, LuaRocks, and dependencies
RUN apk add --no-cache \
    lua5.1 \
    lua5.1-dev \
    luarocks5.1 \
    git \
    gcc \
    musl-dev \
    make

# Create symbolic links for easier command usage
RUN ln -sf /usr/bin/lua5.1 /usr/bin/lua && \
    ln -sf /usr/bin/luarocks-5.1 /usr/bin/luarocks

# Install testing dependencies
RUN luarocks install busted && \
    luarocks install luacov && \
    luarocks install luacheck && \
    luarocks install luacov-console

# Set working directory
WORKDIR /app

# Copy addon files
COPY . /app

# Default command runs all tests
CMD ["busted", "--verbose"]
