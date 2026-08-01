# 隐私说明

ClassBell 是纯本地应用，不需要账号，也不连接 ClassBell 自己的服务器。

- 日程、音箱 UID 和音量保存在当前 Mac 的 `Application Support/ClassBell/settings.json`。
- 系统语音生成的临时文件保存在当前 Mac 的 `Caches/ClassBell`。
- 用户选择自己的录音时，应用只记录本机文件路径，不上传、不复制、不分析录音。
- 应用读取 macOS 当前可用的音频输出设备，用于把提醒绑定到用户选择的设备。
- 应用不会修改系统默认输出设备。目标音箱离线时，本次提醒直接失败，不会从其他扬声器播放。

删除应用不会自动删除个人设置。需要完全清理时可运行 `scripts/uninstall.sh --purge`，脚本会先显示将删除的具体目录并要求确认。
