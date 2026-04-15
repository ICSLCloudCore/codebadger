# CodeBadger Docker 部署指南

## 快速启动
1. 首次启动服务（自动构建镜像并后台运行）：
```bash
docker-compose up -d --build
```

2. 查看服务运行状态：
```bash
docker-compose ps
```

## 服务访问
- MCP 服务地址：http://localhost:4242
- 健康检查接口：http://localhost:4242/health
- Joern 服务端口范围：13371-13399（由MCP自动管理）

## 常用命令
### 停止服务
```bash
docker-compose stop
```

### 重启服务
```bash
docker-compose restart
```

### 查看服务日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 仅查看MCP服务日志
docker-compose logs -f codebadger-mcp-server

# 仅查看Joern服务日志
docker-compose logs -f codebadger-joern-server
```

### 关闭并删除服务
```bash
docker-compose down
```

## 自定义配置
### 1. 修改默认端口
编辑`docker-compose.yml`中对应服务的`ports`配置即可。

### 2. 自定义配置文件
将`config.example.yaml`复制为`config.yaml`，修改配置后，取消`docker-compose.yml`中MCP服务下的`- ./config.yaml:/app/config.yaml`挂载注释，重启服务生效。

### 3. 调整Joern内存限制
在`docker-compose.yml`的MCP服务`environment`配置中添加：
```yaml
- JOERN_MEMORY_LIMIT=8g
- JOERN_JAVA_OPTS=-Xmx8G -Xms4G -XX:+UseG1GC -Dfile.encoding=UTF-8
```

## 数据持久化
- 分析结果/CPG文件：存储在`./playground`目录
- 服务数据库：`./codebadger.db`文件
- 以上数据不会随容器删除丢失

## 升级服务
```bash
# 拉取最新代码
git pull

# 重新构建镜像并启动
docker-compose up -d --build
```
