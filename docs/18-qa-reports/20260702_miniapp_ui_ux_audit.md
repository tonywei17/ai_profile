# 微信小程序 UI/UX 全面审计报告(cn 分支)

- **审计对象**: `aiidphoto-uniapp/`(微信小程序「光影形象馆」,uni-app + Vue3)
- **审计版本**: `cn` 分支 `9fc53c6`,v1.0.2,最后更新 **2026-06-25 00:06:45 (JST)**——为仓库内最新小程序版本(与 `ai_profile_liu` 同指针,远新于 `main` 的 2026-04 提交)
- **审计方式**: 4 个维度并行审计(视觉 UI / 跳转导航 / UX 流程 / 设计一致性),共 20 个审计与复核 agent;所有逻辑类断言均经独立复核员实读代码反驳验证,**全部 CONFIRMED,无一被推翻**
- **审计日期**: 2026-07-02

---

## 一、总体裁决

产品骨架是健康的:`App.vue` 里有一套相当完整的设计 token(颜色/间距/圆角/字号/字重),路由目标全部真实存在,没有跳转到不存在页面的低级错误。**问题不在"没有体系",而在"体系没有被执行"**——token 定义了没人用、暗色模式四段代码互不连通、7 语言只接了 2 种、450 行样式被复制粘贴了两遍。用户反馈的两点体感均被代码证实:

1. **"UI 不够精致"** → 全站约 **55+ 处 emoji 当图标用**,且同一页面内 emoji、纯符号字符(`←` `✓` `›`)、彩色 emoji 三套图标语言混用;订阅/会员这条最重要的转化链路整体使用一套与品牌蓝(`#2464C8`)毫无关系的模板紫渐变(`#667eea→#764ba2`),在 4 个文件里被独立硬编码 6 次。
2. **"页面跳转逻辑有问题"** → 主流程"生成→结果→重拍"的页面栈管理是错的:每做一轮照片,栈里净增一层废弃的 `creation` 页,反复使用会撞上小程序 10 层栈上限,且用户点返回看到的是残留旧状态的"幽灵"创建页而非首页。

---

## 二、确认的问题清单(经裁决定级)

### P0 — 用户可直接感知的缺陷,立即修

| # | 问题 | 位置 | 复核 |
|---|------|------|------|
| 1 | **页面栈线性增长**:生成成功用 `navigateTo` 压栈进 result,「重新拍摄」又用 `redirectTo` 把 result 换成新 creation,旧 creation 永远留在栈里;每轮循环净增 1 层,逼近 10 层上限,返回链路混乱 | `creation.vue:1157` + `result.vue:363` | ✅ CONFIRMED |
| 2 | **结果页 3 个按钮塞进 2 列 grid**:保存/打印/重拍渲染成"上 2 下 1 左对齐",右侧留空,核心页面肉眼可见的排版缺陷 | `result.vue:43-51` vs `:518` | ✅ CONFIRMED |
| 3 | **settings.vue 约 450 行样式整体复制了两遍**(448-687 与 689-903 几乎逐字重复),同名 class 数值互相打架;级联结果导致非会员态的 `.subscription-status` 实际渲染为 16px 深灰字压在紫色渐变背景上(设计原意 22px 白色粗体),存在真实对比度问题 | `settings.vue:460/701/999` | ✅ CONFIRMED |
| 4 | **保存到相册无失败回调**:相册权限被拒或写入失败时用户零反馈,静默失败 | `creation.vue:1204` | ✅ CONFIRMED |
| 5 | **转化链路配色与品牌脱节**:订阅页 hero/价格/勾选/购买按钮、设置页 hero、首页会员徽章整体用模板紫 `#667eea→#764ba2`,像贴了第三方模板 | `subscription.vue:324/391/419/434`、`settings.vue:408`、`index.vue:1112/1157` | 视觉裁决 |

### P1 — 显著损害体验/转化,本迭代内修

| # | 问题 | 位置 | 复核 |
|---|------|------|------|
| 6 | 生成按钮竞态:`isGenerating` 在跳转前 1 秒就复位,窗口内可重复点击造成二次生成/二次扣费/双 result 压栈 | `creation.vue:1189` | ✅ CONFIRMED |
| 7 | 首页 6 个服务分类卡片(证件照/护照/驾照/简历/学生证/头像)全部跳同一个无参 `navigateToCreation`,落地页恒定默认"身份证"——分类点击形同虚设 | `index.vue:55/439` | ✅ CONFIRMED |
| 8 | AI 生成(全流程最长等待)无遮罩、无进度反馈,期间其余控件仍可点击导致状态错乱 | `creation.vue:994` | ✅ CONFIRMED |
| 9 | 免费次数耗尽只弹一次性 toast,无可点的购买入口;而 Pro 锁定项却一点就强跳订阅页——转化力度与时机完全错配 | `creation.vue:1006` vs `:888` | ✅ CONFIRMED |
| 10 | emoji 图标最密集的三处:settings(分区/入口/齿轮/国旗全 emoji,约 12 处)、index(头部+6 分类卡)、result(💾🖨️🔄 三个 32px 主操作) | `settings.vue:48-126`、`index.vue:19/406-431`、`result.vue:44-52` | 视觉裁决 |
| 11 | 字号/圆角/颜色 token 形同虚设:settings.vue 0 处 `var()` 对 73 处硬编码色值;全站十几种未登记字号、12 种圆角 | `App.vue:58/66` vs 各页 | ✅ CONFIRMED(颜色项) |
| 12 | 进度步骤条与真实流程脱节,"选择场景"一步在正常首次使用中从不激活 | `creation.vue:355` | ✅ CONFIRMED |
| 13 | 首页主 CTA 无按压态反馈,其余按钮按压态形同虚设 | `index.vue:1060` | 视觉裁决 |
| 14 | i18n 半成品:`utils/i18n.js` 只注册 zh-Hans/en,locales 里 ja/ko/vi/id/pt 五个语言包是死资产;creation.vue 大量 toast 硬编码中文 | `utils/i18n.js:8`、`creation.vue:279/806` | ✅ CONFIRMED |
| 15 | 隐私同意弹窗在 index 与 creation 逐行复制,应抽组件(components/ 仅 1 个组件对 7000+ 行页面代码) | `index.vue:142` | — |

### P2 — 工程债与打磨项,排期清理

- 暗色模式整条链路是死代码:App.vue 启动强制重置 light、`themeMixin.useTheme()` 零引用、`.dark-theme` 零绑定(`App.vue:7`,✅ CONFIRMED)→ **裁决:降为 P2 决策项**——它不影响当前用户,但必须"要么打通、要么删除",不能继续留尸体
- creation.vue 三套图标语言混用(符号/勾选/彩色 emoji);history 页 📋🗑️(`creation.vue:82`、`history.vue:26`)
- 锁定 Pro 项点击即跳订阅页,无价值预览易误触(`creation.vue:888`)
- 历史页无独立 loading 态,先闪"暂无记录"再出列表(`history.vue:24`);结果页对缺失图片参数无保护(`result.vue:29`);分享功能是从未挂载的死代码(`result.vue:222`)
- 隐私/协议页、`pages.json` 导航标题完全未本地化
- `wechatAuth.js` 是无人引用的转发壳,与 `wechatAuthService.js` 并存;`paymentStandard/paymentVirtual` 的订单轮询逻辑逐行重复;settings/creation 大量 `!important` 补丁
- 首页价格用了第二个未登记橙色;`.close-btn` 在 settings 与 subscription 重复定义且取值不一致;投影使用极不均衡

---

## 三、优化计划(四期)

### 第一期:P0 缺陷修复(~1 天,纯修 bug,无视觉风险)

1. **理顺页面栈**(推荐方案,栈恒定 ≤2 层):
   - `creation.vue:1157` 生成成功改用 `uni.redirectTo` 跳 result(result 替换 creation,返回即回首页);
   - `result.vue:363` 「重新拍摄」同样用 `redirectTo` 回 creation;
   - 顺带修 #6:`isGenerating` 复位移到跳转完成之后(或去掉 1 秒 `setTimeout`,toast 与跳转解耦)。
2. `result.vue:518` grid 改 `repeat(3, 1fr)`。
3. 删除 `settings.vue` 689-903 重复样式块;hero 区 `.subscription-status` 改独立类名 `.hero-subscription-status`。
4. `creation.vue:1204` 与 result 页保存相册补 `fail` 回调:权限被拒时引导去开启(`uni.openSetting`)。

### 第二期:图标系统替换 emoji(2-3 天)

1. 引入一套统一的**线性 SVG 图标集**(建议 uni-icons 或自建 `components/AppIcon.vue` + iconfont),色彩跟随品牌蓝 token;
2. 按密度顺序替换:settings(12 处,含删国旗 emoji 改文字/图片)→ index(头部 2 + 分类卡 6)→ result(3 个主操作)→ creation(约 30 处,统一 `←`/`✓`/`›`/🔒 为同一套组件)→ history(2 处);
3. 分类卡图标改蓝色线性风格,与既有的 `rgba(36,100,200,0.10)` 容器底色呼应(这个容器本身做得不错,保留)。

### 第三期:视觉体系统一(2-3 天)

1. **消灭模板紫**:决策会员/付费视觉是用品牌蓝渐变,还是正式登记一个"会员色"token 进 `App.vue`——之后全局替换 6 处硬编码 `#667eea/#764ba2`;
2. settings.vue 全页接入颜色 token(73 处硬编码 → `var(--color-*)`);index/creation 混用处收敛;
3. 字号收敛到 App.vue 已声明的 9 档、圆角收敛到 5 档;清理 `!important`;
4. 补全按压态(`:active` 统一 opacity/scale 规范)、统一投影层级。

### 第四期:流程与工程债(3-5 天)

1. 首页分类卡带参数直达:`navigateTo('/pages/creation/creation?specId=passport')`,creation 页 `onLoad` 读取并预选规格;
2. 免费次数耗尽改为带"去购买"按钮的弹窗/半屏引导(替换一次性 toast);Pro 锁定项点击改为先展示价值预览再引导;
3. 生成中加全屏遮罩 + 进度文案,锁定其余交互;修正步骤条状态机;
4. **i18n 决策**:小程序若只面向国内,删 5 个死语言包并简化;若保留多语言,把 ja/ko/vi/id/pt 注册进 `i18n.js` 并清理 creation.vue 硬编码中文 toast;
5. **暗色模式决策**:打通(themeMixin 挂到页面 + 移除强制 light)或整体删除四段死代码;
6. 抽组件:隐私同意弹窗、close-btn、规格卡片;删 `wechatAuth.js`;合并两套支付轮询;
7. 历史页补 loading 态;结果页补参数缺失保护;删除或挂载分享功能。

---

## 四、验收标准

- 任意路径连续做 5 轮"生成→重拍",页面栈深度恒定 ≤2,返回一步到首页;
- 全站 `grep -P '[\x{1F300}-\x{1FAFF}]'` 于 pages/ 下零命中(emoji 清零);
- `#667eea` 全仓零命中;settings.vue `var(--` 覆盖率 >90%;
- 相册权限拒绝路径有明确引导;免费额度耗尽路径有可点击购买入口;
- 点击"护照"分类落地页默认选中护照规格。
