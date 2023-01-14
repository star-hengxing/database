@echo off
adb devices
pause
@REM 禁用智能服务
adb shell pm disable-user com.miui.systemAdSolution
@REM 禁用小米电商
adb shell pm disable-user com.xiaomi.ab
@REM 禁用用户反馈
adb shell pm disable-user com.miui.bugreport
@REM 禁用系统毒瘤
adb shell pm disable-user com.miui.analytics
@REM 删除开屏广告
adb shell rm -f -r /sdcard/Android/data/com.miui.systemAdSolution/files
@REM 防止开屏广告再生
adb shell touch /sdcard/Android/data/com.miui.systemAdSolution/files

@REM 系统更新
pause
@REM 删除系统更新包
adb shell rm -f -r /sdcard/Download/downloaded_rom
@REM 防止系统静默下载更新包
adb shell touch /sdcard/Download/downloaded_rom
@REM 同上
adb shell rm -f -r /sdcard/downloaded_rom
adb shell touch /sdcard/downloaded_rom

@REM 禁用快应用服务框架
adb shell pm disable-user com.miui.hybrid

@REM 精简列表部分采自 -> https://www.bilibili.com/video/BV1hi4y1L7FQ/
pause
@REM 谷歌浏览器收藏插件，接口已废除
adb shell pm disable-user com.miui.BookmarkProvider
@REM 小爱相关，删除不影响小爱
adb shell pm disable-user com.miui.AiAsstVision
@REM 屏保，接口已废除
adb shell pm disable-user com.miui.BasicDreams
@REM 谷歌浏览器收藏插件，接口已废除
adb shell pm disable-user com.miui.BookmarkProvider
adb shell pm disable-user com.miui.CatcherPatch
@REM 收集日志
adb shell pm disable-user com.miui.CatchLog 
@REM 耗电检测
adb shell pm disable-user com.xiaomi.powerchecker
@REM 米币支付
adb shell pm disable-user com.xiaomi.payment
@REM 生活黄页
adb shell pm disable-user com.miui.yellowpage
@REM 小米有品
adb shell pm disable-user com.xiaomi.youpin
@REM 小米画报
adb shell pm disable-user com.mfashiongallery.emag

@REM 小爱同学
adb shell pm disable-user com.miui.voiceassist
@REM 语音唤醒
adb shell pm disable-user com.miui.voicetrigger
