import { cpSync, existsSync, mkdirSync } from 'node:fs'
import { resolve } from 'node:path'

const source = resolve('dist/build/mp-weixin')
const target = resolve('unpackage/dist/dev/mp-weixin')

if (!existsSync(source)) {
  throw new Error(`微信小程序构建目录不存在：${source}`)
}

mkdirSync(target, { recursive: true })
cpSync(source, target, { recursive: true, force: true })
console.log(`微信小程序产物已同步：${target}`)
