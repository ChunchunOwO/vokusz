# 中英双语复核与部署

Web 与 Windows 客户端共用 `lib/` 中的 Flutter 界面，默认简体中文，保留英文切换。

## 本次发现与处理

- 大量界面文案绕过语言资源，造成两端中英混杂。已将管理、认证、频道、消息、成员、私信、设置、语音、更新与引导等文案接入 `AppStrings` / `UiCopy`。
- 统一“社区、频道、角色、表情回应、两步验证”等术语；固定目录标签通过 `static_copy.dart` 翻译，协议字段、用户昵称及消息正文保留原值。
- 消息时间增加中文表达；网页 `lang` 和启动文案跟随上次语言选择。
- 修改密码页面原先允许 6 位密码，与后端最低 8 位要求不符；现已对齐 8–128 位校验及提示。
- 错误弹窗不再直接显示 `AccordError(...)` 调试包装；已知错误显示中文，未知服务端错误保留原文，避免丢失诊断信息。

## 验证

- `dart analyze lib --format machine`：无错误、无警告。
- 设置、引导、消息时间及错误反馈：199 项通过，1 项跳过。
- 双语切换、草稿保留、语音设置及频道权限布局：19 项通过。
- 全量测试初跑：1546 项通过、2 项跳过、4 项失败。其中 3 项旧文案断言已更新并经定向重跑通过；尚余 1 项触屏长按菜单测试失败（`voice_text_panel_parity_test.dart:255`）。换回汉化前的消息组件代码并仅补充其他已翻译组件所需的导入后，同一断言仍失败；当前源码已恢复。未宣称全量测试全部通过。
- `dart run build_runner build -d`：完成代码生成。`scripts/codegen.sh --check` 已执行；因 6 个生成文件相对 HEAD 有未提交差异而返回失败，生成内容保留供审阅。
- Web：`flutter build web --release --no-tree-shake-icons --no-wasm-dry-run` 成功。
- 浏览器检查：中文登录页正常渲染。未使用生产账号进行登录后全流程验收。
- Windows Release 构建已成功，输出 `build/windows/x64/runner/Release/vokusz.exe`。
- Windows 构建须设置 PowerShell `$env:CL='/utf-8'`，避免第三方 WebRTC 源文件触发 C4819/C2220。

## 部署位置

- 站点：https://vokusz.shiinasuki.com
- 服务器：43.248.10.56，Windows Server 2022。
- Web 根目录：`C:\accord\web`，Caddy 提供 HTTPS；API 和 LiveKit 沿用原配置。
- 更新前保存完整站点备份；上传压缩包及更新后的各文件均核对 SHA-256。
- 本次部署完成；回滚备份：`C:\accord\web-backup-20260923-132624`。
- 公网首页及 `/health` 均返回 HTTP 200；公网 `main.dart.js` 与本地 Release 产物 SHA-256 一致（`9cd2eb488bfefaec5f7337b6fa874b5c38dd2361198d56e6908196fac81f488e`）。
- 登录凭据不写入仓库或部署文档。

## 复核边界

未知服务端错误、管理员自定义服务条款、用户内容以及外部发布说明保留原文。它们不能通过翻译固定界面资源保证中文。公网访问偶有连接重置，需与界面文案问题分开排查。
