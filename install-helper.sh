#!/usr/bin/env bash
# PhpRedis Install Helper — 自动安装缺失扩展

PHP_BIN=$(which php)
PHPIZE=$(which phpize)

if [ -z "$PHP_BIN" ] || [ -z "$PHPIZE" ]; then
  echo "❌ PHP 或 phpize 未找到。"
  exit 1
fi

install_ext() {
  local ext=$1
  if $PHP_BIN -m | grep -q "^$ext$"; then
    echo "✅ $ext 已安装"
  else
    echo "📦 正在安装 $ext..."
    pecl install "$ext" || echo "⚠️ 无法通过 pecl 安装 $ext，请手动编译。"
  fi
}

for ext in igbinary msgpack zstd lz4 lzf; do
  install_ext "$ext"
done

echo "✅ 安装过程完成。"
