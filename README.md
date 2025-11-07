# PhpRedis Inspector

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> PhpRedis 环境管理工具 - 能检测、建议、甚至自动修复

PhpRedis Inspector 是一个全面的 PhpRedis 环境管理工具，不仅可以检测 PhpRedis 扩展的安装状态，还能自动诊断问题、提供修复建议，并支持自动安装缺失的扩展。

## 🎯 功能特性

- ✅ **环境检测**: 全面检测 PHP、PhpRedis 扩展和 Redis 服务器状态
- 🔧 **自动修复**: 自动安装缺失的 PhpRedis 扩展
- 📊 **详细报告**: 生成 JSON 格式的详细检测报告
- 🎨 **友好输出**: 彩色终端输出，清晰易读
- 🚀 **多平台支持**: 支持 Ubuntu、Debian、CentOS、Fedora、Arch Linux 等
- 📦 **多种安装方式**: 支持 PECL、系统包管理器、源码编译

## 📁 项目结构

```
phpredis-inspector/
├── phpredis-inspector.sh   # 主检测脚本
├── install-helper.sh       # 自动安装助手
├── phpredis-report.json    # 检测报告示例
└── README.md               # 使用文档
```

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/FurLC/phpredis-inspector.git
cd phpredis-inspector
```

### 2. 添加执行权限

```bash
chmod +x phpredis-inspector.sh install-helper.sh
```

### 3. 运行检测

```bash
./phpredis-inspector.sh
```

## 📖 使用说明

### 基本检测

运行基本的环境检测：

```bash
./phpredis-inspector.sh
```

输出示例：
```
========================================
PhpRedis Environment Inspection
========================================

ℹ Step 1: Checking PHP installation...
✓ PHP is installed: PHP 8.1.2-1ubuntu2.14 (cli)

ℹ Step 2: Checking PHP version compatibility...
✓ PHP version is compatible (7.0+)

ℹ Step 3: Checking PhpRedis extension...
⚠ PhpRedis extension is NOT installed

ℹ Step 4: Checking Redis server...
✓ Redis server is running (version: v=7.0.12)

========================================
Inspection Summary
========================================
⚠ PhpRedis environment needs attention
ℹ → Install PhpRedis extension using: ./install-helper.sh

✓ Report generated: phpredis-report.json
```

### 自动修复模式

自动检测并修复问题：

```bash
./phpredis-inspector.sh --fix
```

或使用短选项：

```bash
./phpredis-inspector.sh -f
```

### 自定义输出文件

指定输出报告的文件名：

```bash
./phpredis-inspector.sh -o my-report.json
```

### 指定 PHP 二进制路径

如果系统中有多个 PHP 版本：

```bash
./phpredis-inspector.sh -p /usr/bin/php8.1
```

### 详细输出模式

启用详细输出：

```bash
./phpredis-inspector.sh -v
```

### 组合使用选项

```bash
./phpredis-inspector.sh -f -v -o report.json -p /usr/bin/php8.1
```

## 🔧 Install Helper 使用

### 自动安装 PhpRedis

```bash
./install-helper.sh
```

### 强制使用特定安装方法

使用 PECL 安装：
```bash
./install-helper.sh -m pecl
```

使用系统包管理器安装：
```bash
./install-helper.sh -m package
```

从源码编译安装：
```bash
./install-helper.sh -m source
```

### 为特定 PHP 版本安装

```bash
./install-helper.sh -p /usr/bin/php8.1
```

## 📊 检测报告格式

检测完成后，会生成 JSON 格式的报告文件 (`phpredis-report.json`)：

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "php": {
    "installed": true,
    "version": "8.1.2",
    "compatible": true,
    "binary": "php"
  },
  "phpredis": {
    "installed": true,
    "version": "5.3.7"
  },
  "redis_server": {
    "installed": true,
    "running": true,
    "version": "v=7.0.12"
  },
  "connection": {
    "successful": true
  },
  "recommendations": [],
  "status": "healthy"
}
```

### 报告字段说明

- **timestamp**: 检测时间戳
- **php**: PHP 相关信息
  - `installed`: PHP 是否已安装
  - `version`: PHP 版本号
  - `compatible`: 版本是否兼容
  - `binary`: PHP 二进制文件路径
- **phpredis**: PhpRedis 扩展信息
  - `installed`: 扩展是否已安装
  - `version`: 扩展版本号
- **redis_server**: Redis 服务器信息
  - `installed`: 服务器是否已安装
  - `running`: 服务器是否正在运行
  - `version`: 服务器版本号
- **connection**: 连接测试结果
  - `successful`: 是否能成功连接到 Redis
- **recommendations**: 修复建议列表
- **status**: 整体状态 (`healthy` 或 `needs_attention`)

## 🎯 检测项目

PhpRedis Inspector 会执行以下检测：

1. ✅ **PHP 安装检测**: 检查 PHP 是否已安装
2. ✅ **PHP 版本兼容性**: 确认 PHP 版本是否支持 PhpRedis (7.0+)
3. ✅ **PhpRedis 扩展检测**: 检查 PhpRedis 扩展是否已安装
4. ✅ **Redis 服务器检测**: 检查 Redis 服务器是否安装和运行
5. ✅ **PHP 配置检测**: 检查 php.ini 中的扩展配置
6. ✅ **连接测试**: 尝试连接到 Redis 服务器

## 🔧 支持的安装方法

Install Helper 支持多种安装方式，会自动选择最适合的方法：

### 1. 包管理器安装（推荐）
- **Ubuntu/Debian**: `apt-get install php-redis`
- **CentOS/RHEL**: `yum install php-redis`
- **Fedora**: `dnf install php-redis`
- **Arch Linux**: `pacman -S php-redis`
- **Alpine**: `apk add php-redis`
- **macOS**: `brew install php-redis`

### 2. PECL 安装
```bash
pecl install redis
```

### 3. 源码编译
从 GitHub 克隆最新源码并编译安装

## 💡 常见问题

### Q: 检测显示 PhpRedis 未安装，如何修复？

A: 运行自动修复命令：
```bash
./phpredis-inspector.sh --fix
```
或手动运行安装助手：
```bash
./install-helper.sh
```

### Q: 为什么连接测试失败？

A: 可能的原因：
1. Redis 服务器未运行 - 运行 `redis-server` 启动
2. 连接配置错误 - 检查 Redis 是否监听 127.0.0.1:6379
3. 防火墙阻止 - 检查防火墙设置

### Q: 支持哪些 PHP 版本？

A: PhpRedis 支持 PHP 7.0 及以上版本，推荐使用 PHP 7.4 或 8.x

### Q: 安装失败怎么办？

A: 尝试以下步骤：
1. 确保有 sudo 权限
2. 尝试不同的安装方法：`./install-helper.sh -m pecl` 或 `-m source`
3. 检查系统是否安装了必要的开发工具（如 php-dev、make、gcc 等）

### Q: 如何卸载 PhpRedis？

A: 根据安装方式：
- **包管理器**: `sudo apt-get remove php-redis` (Ubuntu/Debian)
- **PECL**: `sudo pecl uninstall redis`
- **源码**: 删除扩展文件并从 php.ini 中移除配置

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 👨‍💻 作者

FurLC

## 🔗 相关链接

- [PhpRedis GitHub](https://github.com/phpredis/phpredis)
- [Redis 官网](https://redis.io/)
- [PHP 官网](https://www.php.net/)