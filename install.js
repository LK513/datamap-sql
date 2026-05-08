#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const targetDir = path.join(homeDir, '.claude', 'commands');
const targetFile = path.join(targetDir, 'datamap-sql.md');

// 源文件在包内
const sourceFile = path.join(__dirname, 'datamap-sql.md');

console.log('');
console.log('  ╔══════════════════════════════════════╗');
console.log('  ║   datamap-sql Skill Installer v2.0   ║');
console.log('  ╚══════════════════════════════════════╝');
console.log('');

// 创建目标目录
if (!fs.existsSync(targetDir)) {
  fs.mkdirSync(targetDir, { recursive: true });
  console.log('  [+] Created: ' + targetDir);
}

// 备份旧版本
if (fs.existsSync(targetFile)) {
  const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14);
  const backupFile = path.join(targetDir, `datamap-sql.md.bak.${timestamp}`);
  fs.copyFileSync(targetFile, backupFile);
  console.log('  [~] Backed up old version to: ' + path.basename(backupFile));
}

// 复制新版本
fs.copyFileSync(sourceFile, targetFile);
console.log('  [✓] Installed: ' + targetFile);
console.log('');
console.log('  Usage: /datamap-sql "你的查数需求"');
console.log('');
console.log('  飞书共享库: https://mi.feishu.cn/base/CWXTbLpxOaBe1PsZE8Cc8Suvn6g');
console.log('');
