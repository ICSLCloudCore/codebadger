# Dockerfile for Joern Server Container
# Contains Joern CLI for CPG generation and caching

FROM eclipse-temurin:21-jdk-jammy

# 核心优化：替换为中科大+网易双源（阿里云源失效替代）
RUN sed -i.bak \
    # 替换Ubuntu官方源为中科大源（优先）
    -e 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' \
    -e 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' \
    # 兜底：若中科大源不可用，替换为网易源
    -e 's/mirrors.ustc.edu.cn/mirrors.163.com/g' \
    /etc/apt/sources.list && \
    # 更新源（修复缺失包）+ 安装依赖
    apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set Joern version
ENV JOERN_VERSION=4.0.516
ENV JOERN_HOME=/opt/joern

# Copy local Joern installation files
COPY docker_copy/joern-install.sh /tmp/
COPY docker_copy/joern-cli.zip /tmp/

# Install Joern using local files with joern-install.sh
RUN mkdir -p ${JOERN_HOME} && \
    cd /tmp && \
    chmod +x joern-install.sh && \
    sed -i 's/sudo //g' joern-install.sh && \
    ./joern-install.sh --version=v${JOERN_VERSION} && \
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
