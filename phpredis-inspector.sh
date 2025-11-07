#!/usr/bin/env bash
# PhpRedis Inspector — PHP Redis 环境检测与性能分析器

set -e

PHP_BIN=$(which php)
if [ -z "$PHP_BIN" ]; then
  echo "❌ 未找到 PHP，请确保 PHP 已正确安装。"
  exit 1
fi

echo "🔍 正在检测 PhpRedis 环境..."
echo "============================================================"

# 基础信息
PHP_VER=$($PHP_BIN -r "echo PHP_VERSION;")
REDIS_VER=$($PHP_BIN -r "echo extension_loaded('redis') ? phpversion('redis') : '未安装';")

declare -A status

status["php_version"]=$PHP_VER
status["phpredis_version"]=$REDIS_VER

echo "📦 PHP 版本: $PHP_VER"
echo "📦 PhpRedis 版本: $REDIS_VER"
echo "============================================================"

check_ext() {
  local ext=$1
  if $PHP_BIN -m | grep -q "^$ext$"; then
    echo "✅ $ext 扩展已安装"
    status["ext_$ext"]="enabled"
  else
    echo "❌ $ext 扩展未安装"
    status["ext_$ext"]="missing"
  fi
}

echo "🔧 检测扩展..."
for ext in redis igbinary msgpack lzf lz4 zstd lzma; do
  check_ext "$ext"
done
echo "============================================================"

# PhpRedis 特性
check_phpredis_feature() {
  local name=$1
  local const=$2
  if $PHP_BIN -r "var_dump(defined('$const'));" 2>/dev/null | grep -q "bool(true)"; then
    echo "✅ 支持 $name"
    status["feature_${name}"]="enabled"
  else
    echo "❌ 不支持 $name"
    status["feature_${name}"]="missing"
  fi
}

echo "🧠 检测 PhpRedis 功能..."
check_phpredis_feature "igbinary 序列化" "Redis::SERIALIZER_IGBINARY"
check_phpredis_feature "msgpack 序列化" "Redis::SERIALIZER_MSGPACK"
check_phpredis_feature "json 序列化" "Redis::SERIALIZER_JSON"
check_phpredis_feature "LZF 压缩" "Redis::COMPRESSION_LZF"
check_phpredis_feature "LZ4 压缩" "Redis::COMPRESSION_LZ4"
check_phpredis_feature "ZSTD 压缩" "Redis::COMPRESSION_ZSTD"
echo "============================================================"

# 检查压缩函数
for func in zstd_compress lz4_compress lzf_compress; do
  if $PHP_BIN -r "var_dump(function_exists('$func'));" 2>/dev/null | grep -q "bool(true)"; then
    echo "✅ $func 函数可用"
    status["func_$func"]="enabled"
  else
    echo "❌ $func 函数不可用"
    status["func_$func"]="missing"
  fi
done
echo "============================================================"

# 性能建议逻辑
HAS_IGBINARY=$($PHP_BIN -m | grep -q igbinary && echo 1 || echo 0)
HAS_MSGPACK=$($PHP_BIN -m | grep -q msgpack && echo 1 || echo 0)
HAS_ZSTD=$($PHP_BIN -m | grep -q zstd && echo 1 || echo 0)
HAS_LZ4=$($PHP_BIN -m | grep -q lz4 && echo 1 || echo 0)
HAS_LZF=$($PHP_BIN -m | grep -q lzf && echo 1 || echo 0)

echo "🧮 性能建议:"
if [ $HAS_IGBINARY -eq 1 ] && [ $HAS_ZSTD -eq 1 ]; then
  echo "✅ 推荐组合: igbinary + zstd —— 高压缩率、低 CPU 占用。"
  status["recommend"]="igbinary + zstd"
elif [ $HAS_MSGPACK -eq 1 ] && [ $HAS_LZ4 -eq 1 ]; then
  echo "✅ 推荐组合: msgpack + lz4 —— 快速、跨语言兼容性好。"
  status["recommend"]="msgpack + lz4"
elif [ $HAS_IGBINARY -eq 1 ]; then
  echo "⚙️ 推荐组合: igbinary —— 提升序列化性能。"
  status["recommend"]="igbinary"
elif [ $HAS_MSGPACK -eq 1 ]; then
  echo "⚙️ 推荐组合: msgpack —— 数据结构紧凑。"
  status["recommend"]="msgpack"
else
  echo "⚠️ 当前仅使用原生序列化，性能有限。"
  status["recommend"]="default"
fi
echo "============================================================"

# JSON 输出
output_json="{
  \"php_version\": \"${status[php_version]}\",
  \"phpredis_version\": \"${status[phpredis_version]}\",
  \"extensions\": {
    \"redis\": \"${status[ext_redis]}\",
    \"igbinary\": \"${status[ext_igbinary]}\",
    \"msgpack\": \"${status[ext_msgpack]}\",
    \"lz4\": \"${status[ext_lz4]}\",
    \"zstd\": \"${status[ext_zstd]}\",
    \"lzf\": \"${status[ext_lzf]}\"
  },
  \"recommendation\": \"${status[recommend]}\"
}"

echo "$output_json" > phpredis-report.json
echo "📄 已生成报告文件: phpredis-report.json"
echo "✅ 检测完成。"
