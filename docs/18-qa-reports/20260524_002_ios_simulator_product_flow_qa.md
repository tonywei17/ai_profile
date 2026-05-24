# 2026-05-24 iOS 模拟器产品功能流 QA

状态：BLOCKED

测试对象：光影形象馆 / AI 证件照中国大陆版
测试设备：iPhone 17 Pro Simulator, iOS 26.5
测试方式：XcodeBuildMCP + 一张人像照片 `/tmp/aiidphoto-qa-portrait-clean.png`

## 结论

产品主流程在“本地模拟已购买 3 次机会”的条件下跑通：

- 首页进入制作页：PASS
- 相册导入人像照片：PASS
- 生成证件照：PASS，阿里云后端真实返回结果
- 成功生成后扣次数：PASS，App 容器偏好值从 3 变为 2
- 保存高清图：PASS，系统弹出“添加到照片”权限
- 打印排版页：PASS，可生成 6 寸 12 张、300 DPI 排版图
- 保存排版照片按钮：PASS，可点击并触发保存流程

但当前仍不能推荐上线。原因是购买链路和 App Store 审核材料仍未完全闭环。

## 阻断项

1. StoreKit / 沙盒购买仍需真机闭环
   - 本轮使用 UserDefaults 注入 3 次机会继续测下游流程，不等同于真实购买通过。
   - 必须补真机 Sandbox：购买 -> 获得 3 次机会 -> 生成 -> 扣 1 次 -> 保存高清图 -> 保存打印排版。

2. StoreKit 测试价格显示异常
   - 修复后商品能加载，但运行日志显示：
     `[PurchaseManager] loaded: com.yufeicn.aiidphoto.photo_task_3 -> $0.99`
   - 预期中国大陆价格应为 `¥3.80`。
   - 该问题会影响审核截图和沙盒验证，需要用真实 App Store Connect Sandbox 中国区商品确认；若继续走本地 StoreKit 测试，也需要确认 scheme 是否实际使用了 `.storekit` 配置。

3. App Store Connect 仍缺内购审核截图
   - `com.yufeicn.aiidphoto.photo_task_3` 已创建，但仍需上传新的消耗型内购审核截图。
   - 旧 Pro 订阅、广告、每日免费次数相关截图/文案不能再进入审核。

4. ICP / App 备案号仍未确认
   - 法务页已部署在 `https://aiphoto-cn.foyli.cloud/legal/`，但备案号仍需最终填写。

## 本轮已修复

1. 购买页主 CTA 默认不可见
   - 问题：购买弹层打开时，主按钮原本在 y=928，屏幕高度 874，首屏不可点击。
   - 修复：将购买 CTA 和法律说明固定到底部区域，首屏默认可见。
   - 文件：`ios/AIIDPhoto/Views/SubscriptionSheetView.swift`

2. 商品未加载时购买点击无反馈
   - 问题：`Product.products` 没加载到商品时，`purchasePhotoTask()` 直接 `return`，用户没有任何错误提示。
   - 修复：点击购买会先刷新商品；仍未加载时弹出“购买商品暂时不可用，请稍后重试。”
   - 文件：`ios/AIIDPhoto/Managers/SubscriptionManager.swift`

## 产品体验发现

P1 已修复：购买按钮首屏不可见。

P1 已修复：StoreKit 商品不可用时无错误提示。

P2 待优化：结果页底部“分享照片”固定按钮会遮挡“打印排版”入口的下半部分。打印入口仍可点击，但视觉上像被压住，建议把分享降级到结果内容区，或让底部栏只在步骤 1-2 出现。

P2 待优化：首页右上角按钮辅助功能标签仍是 `gearshape`、`clock.arrow.circlepath`。建议改为“设置”“历史记录”，否则 VoiceOver 和自动化测试都不友好。

P2 待确认：StoreKit 测试环境加载到 `$0.99`，这可能是测试店面、沙盒账号地区或本地配置未生效导致；真实上线价格应以 App Store Connect 中国大陆商品为准。

## 证据与产物

- Debug 构建通过：`build_sim_2026-05-24T12-06-09-151Z_pid20992_9783893f.log`
- 修复后 Build & Run 通过：`build_run_sim_2026-05-24T12-06-18-736Z_pid21067_850e9037.log`
- 生成流程运行日志：`com.yufeicn.aiidphoto_2026-05-24T12-00-37-727Z_helperpid19751_ownerpid19718_b980e91a.log`
- StoreKit 价格异常日志：`com.yufeicn.aiidphoto_2026-05-24T12-08-16-574Z_helperpid22058_ownerpid22026_c2be7dbe.log`
- 生成中截图：`/var/folders/k8/v2tb77w176b0_8jgh5mlddb80000gn/T/screenshot_optimized_f5ad3d51-1723-4b21-8017-898b07df8fbd.jpg`
- 生成成功截图：`/var/folders/k8/v2tb77w176b0_8jgh5mlddb80000gn/T/screenshot_optimized_a4bbced7-3f4e-4a71-9482-e40b2bce53fa.jpg`
- 保存权限截图：`/var/folders/k8/v2tb77w176b0_8jgh5mlddb80000gn/T/screenshot_optimized_a3206750-b095-45a4-bc21-51553dc305d6.jpg`
- 打印排版截图：`/var/folders/k8/v2tb77w176b0_8jgh5mlddb80000gn/T/screenshot_optimized_bee84982-78f2-45b3-9cd1-ea60a26183e4.jpg`
- 修复后购买页截图：`/var/folders/k8/v2tb77w176b0_8jgh5mlddb80000gn/T/screenshot_optimized_927404f6-8c82-4e62-86fe-29ba9d66200a.jpg`

## 安全 / 成本 / 性能备注

- 本轮触发了 1 次真实阿里云后端生成，会产生一次实际模型/后端成本。
- 生成约 25 秒内完成，未观察到崩溃。
- 生成成功后才扣次数；失败不会扣次数的代码路径仍需单独用后端错误场景验证。
- 保存相册权限文案合理，说明用于保存证件照和打印排版。

## 下一步

1. 处理 StoreKit 测试价格 `$0.99` 与中国大陆 `¥3.80` 的不一致。
2. 用真机 Sandbox 完成真实购买闭环。
3. 生成新的内购审核截图并上传 App Store Connect。
4. 修复结果页底部分享栏遮挡打印排版入口。
5. 补 ICP / App 备案号后再进入最终 release gate。
