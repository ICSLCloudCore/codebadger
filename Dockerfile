# Dockerfile for Joern Server Container
# Contains Joern CLI for CPG generation and caching

FROM eclipse-temurin:21-jdk-jammy

# 核心优化1：替换Ubuntu国内阿里云源（解决apt-get下载慢/失败）
RUN sed -i.bak \
    -e 's/archive.ubuntu.com/mirrors.aliyun.com/g' \
    -e 's/security.ubuntu.com/mirrors.aliyun.com/g' \
    /etc/apt/sources.list && \
    # 核心优化2：更新源+安装依赖，增加--no-install-recommends减小镜像体积
    apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set Joern version
ENV JOERN_VERSION=4.0.499
ENV JOERN_HOME=/opt/joern

# Download and install Joern from joernio/joern GitHub releases
RUN mkdir -p ${JOERN_HOME} && \
    cd /tmp && \
    wget -q https://github.com/joernio/joern/releases/download/v${JOERN_VERSION}/joern-install.sh && \
    chmod +x joern-install.sh && \
    sed -i 's/sudo //g' joern-install.sh && \
    ./joern-install.sh && \
    rm -rf joern-install.sh joern-cli.zip

# RUN mkdir -p ${JOERN_HOME} && \
#     cd /tmp && \
#     # 改用GitHub镜像站下载安装脚本（解决访问问题）
#     wget -q --timeout=30 --tries=3 https://ghproxy.com/https://github.com/joernio/joern/releases/download/v${JOERN_VERSION}/joern-install.sh || \
#     wget -q --timeout=30 --tries=3 https://mirror.ghproxy.com/https://github.com/joernio/joern/releases/download/v${JOERN_VERSION}/joern-install.sh && \
#     chmod +x joern-install.sh && \
#     sed -i 's/sudo //g' joern-install.sh && \
#     # 给安装脚本也配置镜像源（关键：解决joern-cli.zip下载失败）
#     sed -i 's|https://github.com|https://ghproxy.com/https://github.com|g' joern-install.sh && \
#     ./joern-install.sh && \
#     rm -rf joern-install.sh joern-cli.zip

# Add Joern CLI tools to PATH
ENV PATH="${JOERN_HOME}/joern-cli:${JOERN_HOME}/joern-cli/bin:${PATH}"

# Create playground directory for CPG storage
RUN mkdir -p /playground

# Verify Joern installation
RUN joern --help

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Run entrypoint script
CMD ["/entrypoint.sh"]
