/**
 * 微信小程序自动上传（miniprogram-ci）
 *
 * 用法：
 *   npm run build:mp-weixin            # 先构建产物
 *   node scripts/upload-wechat.mjs [version] [desc]
 *   # 或 npm run upload:mp-weixin -- 1.0.1 "修复生成超时"
 *
 * 环境变量：
 *   WX_PRIVATE_KEY_PATH  上传私钥路径（默认 ./private.<appid>.key，已被 .gitignore 忽略）
 *   WX_CI_ROBOT          CI 机器人编号 1-30（默认 1，不同流水线/人用不同编号便于区分）
 *   WX_UPLOAD_VERSION    版本号（也可用第 1 个参数）
 *   WX_UPLOAD_DESC       版本备注（也可用第 2 个参数）
 *
 * 私钥获取：微信公众平台 → 管理 → 开发管理 → 开发设置 → 小程序代码上传 →
 *           生成并下载「代码上传密钥」，并按需配置 IP 白名单（推荐）。
 */
import ci from 'miniprogram-ci'
import { existsSync, readFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const projectPath = resolve(root, 'dist/build/mp-weixin')

if (!existsSync(resolve(projectPath, 'project.config.json'))) {
  console.error(`✖ 未找到构建产物：${projectPath}\n  请先执行：npm run build:mp-weixin`)
  process.exit(1)
}

const appid = JSON.parse(
  readFileSync(resolve(projectPath, 'project.config.json'), 'utf8')
).appid

// 私钥查找优先级：环境变量 > 系统安全目录(repo 外) > 仓库内 gitignored 兜底。
// 安全目录是推荐位置，密钥不应放在仓库内。
const keyCandidates = [
  process.env.WX_PRIVATE_KEY_PATH && resolve(root, process.env.WX_PRIVATE_KEY_PATH),
  resolve(homedir(), '.config/foyli/wechat', `${appid}.key`),
  resolve(root, `private.${appid}.key`),
].filter(Boolean)
const privateKeyPath = keyCandidates.find((p) => existsSync(p))
if (!privateKeyPath) {
  console.error(
    `✖ 未找到上传私钥，已查找：\n` +
      keyCandidates.map((p) => `    - ${p}`).join('\n') +
      `\n  从微信公众平台下载「代码上传密钥」放到 ~/.config/foyli/wechat/${appid}.key，` +
      `或用 WX_PRIVATE_KEY_PATH 指定。`
  )
  process.exit(1)
}

const version =
  process.argv[2] ||
  process.env.WX_UPLOAD_VERSION ||
  JSON.parse(readFileSync(resolve(root, 'package.json'), 'utf8')).version ||
  '1.0.0'
const desc =
  process.argv[3] || process.env.WX_UPLOAD_DESC || `CI 上传 ${new Date().toISOString()}`
const robot = Number(process.env.WX_CI_ROBOT || 1)

const project = new ci.Project({
  appid,
  type: 'miniProgram',
  projectPath,
  privateKeyPath,
  ignores: ['node_modules/**/*'],
})

console.log(`→ 上传小程序 appid=${appid} version=${version} robot=${robot}`)
console.log(`  产物：${projectPath}`)
console.log(`  备注：${desc}`)

try {
  const result = await ci.upload({
    project,
    version,
    desc,
    setting: {
      es6: true,
      es7: true,
      minifyJS: true,
      minifyWXML: true,
      minifyWXSS: true,
      minify: true,
      autoPrefixWXSS: true,
      codeProtect: false,
    },
    robot,
    onProgressUpdate: () => {},
  })
  console.log('✓ 上传成功')
  if (result?.subPackageInfo) {
    for (const pkg of result.subPackageInfo) {
      console.log(`  ${pkg.name || 'main'}: ${pkg.size} bytes`)
    }
  }
  console.log('  到微信公众平台 → 版本管理，将「开发版」设为体验版或提交审核。')
} catch (err) {
  console.error('✖ 上传失败：', err?.message || err)
  process.exit(1)
}
