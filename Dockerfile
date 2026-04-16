# All-in-one Dockerfile for CodeBadger (Joern + MCP Service)
# 基于Joern镜像整合MCP服务，单容器承载所有业务能力
FROM eclipse-temurin:21-jdk-jammy

# 替换国内镜像源加速安装
RUN sed -i.bak \
    -e 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' \
    -e 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' \
    /etc/apt/sources.list && \
    # 安装基础依赖
    apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    git \
    ca-certificates \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update -y && \
    # 安装Python 3.12
    apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 配置Python3.12为默认python
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.12 1 && \
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

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

# Add Joern CLI tools to PATH
ENV PATH="${JOERN_HOME}/joern-cli:${JOERN_HOME}/joern-cli/bin:${PATH}"

# Create playground directory for CPG storage
RUN mkdir -p /playground

# Verify Joern installation
RUN joern --help

# 设置工作目录
WORKDIR /app

# 复制MCP服务依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制MCP服务代码
COPY main.py .
COPY src/ ./src/

# 设置环境变量
ENV MCP_HOST=0.0.0.0
ENV WORKSPACE_ROOT=/playground
ENV PYTHONUNBUFFERED=1

# 暴露端口
EXPOSE 4242
EXPOSE 13371-13399

# 启动服务，直接使用MCP服务作为入口
CMD ["python", "main.py"]