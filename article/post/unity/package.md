---
title: "Unity hello world 打包"
date: 2024-12-30
lastmod: 2024-12-30
draft: false
tags:
    - Unity
    - Xmake
---

本文仅测试了 Windows 平台。

团结引擎版本：1.3.5

# 编辑器安装

从官网上我们可以直接下载 `UnitySetup64` ，如果是团结引擎，那么还需要登录后下载。

命令很简单，无交互安装 + 指定安装位置

```console
$ UnitySetup64.exe /S /D="C:\Program Files\Unity"
$ TuanjieSetup64.exe /S /D="C:\Program Files\Tuanjie"
```

不过执行完命令后就立刻返回，然后单独打开了一个安装程序，那这样脚本怎么知道安装是否成功。。

执行完安装后，在 `C:\Program Files` 发现了一个 `Tuanjie 2022.3.48t2`

。。。

看起来命令 `/D` 根本没用。

# 项目打包

谷歌了一轮命令，看起来主要是这些参数。

- `-nographics`
- `-batchmode`
- `-logfile`
- `-projectpath`

对着只有 `Assets` 和 `ProjectSettings` 两个目录的项目执行。

```console
$ "C:/Program Files/Tuanjie/Editor/Tuanjie.exe" -nographics -batchmode -logfile package.log -projectpath path/to/project
```

然后发现两个问题。

- 编辑器构建成功后没有结束。
- 构建产物在哪呢。

再去谷歌一轮，第一个问题是少了 `-quit` 参数。。这语义根本对不上好吧。


第二个问题查了很久，发现，unity 确实没有指定构建产物目录的参数。。要解决这个问题，必须手写一个 c# 脚本。

从网上帖子抄了个脚本改造一下

```c#
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditor.Build.Reporting;

public class UnityBuildForMultiplePlatforms : MonoBehaviour
{
    static List<SupportedPlatform> platforms = new List<SupportedPlatform> {
        new SupportedPlatform(BuildTarget.StandaloneWindows64, "windows/demo.exe")
        // new SupportedPlatform(BuildTarget.StandaloneLinux64, "linux/demo")
        // new SupportedPlatform(BuildTarget.StandaloneOSX, "macos/demo.app"),
    };

    // https://discussions.unity.com/t/specify-build-output-path-via-command-line-or-edit-project-settings-files/858589/5
    private static string GetBuildDir()
    {
        var args = Environment.GetCommandLineArgs().ToList();
        var outputPathIndex = args.IndexOf("-builddir");
        if (outputPathIndex == -1)
        {
            throw new Exception("-builddir parameter missing!");
        }
        return args[outputPathIndex + 1];
    }

    public static void Build() {
        string firstScene = "Assets/Scenes/SampleScene.scene";
        BuildForAllPlatforms(firstScene);
    }

    static void BuildForAllPlatforms(string firstScene) {
        List<string> allScenes = CollectScenes();
        string[] scenes = MoveSceneToTop(allScenes, firstScene).ToArray();

        foreach (var platform in platforms) {
            Debug.Log($"build.release {platform.executablePath}");
            BuildForPlatform(scenes, platform.target, platform.executablePath);
        }
    }

    static void BuildForPlatform(string[] scenes, BuildTarget target, string platformPath, BuildOptions options = BuildOptions.None) {
        BuildPlayerOptions buildPlayerOptions = new BuildPlayerOptions();
        buildPlayerOptions.scenes = scenes;
        buildPlayerOptions.locationPathName = $"{GetBuildDir()}/{platformPath}";
        buildPlayerOptions.target = target;
        buildPlayerOptions.options = options;

        BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
        BuildSummary summary = report.summary;
        if (summary.result == BuildResult.Succeeded) {
            EditorApplication.Exit(0);
            // Debug.Log("Build succeeded: " + summary.totalSize + " bytes");
        } else if (summary.result == BuildResult.Failed) {
            EditorApplication.Exit(-1);
        }
    }

    static List<string> CollectScenes() {
        var projectScenes = new List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
        var scenePaths = projectScenes.Select(s => s.path).ToList();
        return scenePaths;
    }

    static List<string> MoveSceneToTop(List<string> scenes, string firstScenePath) {
        var scenesWithoutFirst = scenes.FindAll(i => i != firstScenePath);
        scenesWithoutFirst.Insert(0, firstScenePath);
        return scenesWithoutFirst;
    }
}

class SupportedPlatform {
    public BuildTarget target;
    public string executablePath;

    public SupportedPlatform(BuildTarget _target, string _executablePath) {
        target = _target;
        executablePath = _executablePath;
    }
}
```

现在我们可以使用 `-builddir` 参数了。

# 错误处理

打包的时候编辑器没有返回 0 退出，那大概是失败了。看了一下 build 目录也没有编译产物。

但它一声真不吭，那只能去翻 `package.log` 了。

果然，我看到了一些 c# 编译报错，是编辑器代码没有用 `UNITY_EDITOR` 条件编译。

但每次这样翻 log 也很麻烦，于是用 [xmake](https://xmake.io) 写了个脚本来找这个报错。

```lua
local outdata, errdata = try {
    function()
        return os.iorunv(unity, argv)
    end,
    catch
    {
        function (errors)
            print(errors)
            print(argv)
            if not os.isfile(log_file) then
                -- TODO
                return
            end
            for _, line in ipairs(io.readfile(log_file):split("\n")) do
                if line:match("error CS") then
                    print(line)
                end
            end
        end
    }
}
```

嗯，还不错。

```console
Assets\src\test.cs(7,33): error CS0246: The type or namespace name 'EditorWindow' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(104,6): error CS0246: The type or namespace name 'MenuItemAttribute' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(104,6): error CS0246: The type or namespace name 'MenuItem' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(7,33): error CS0246: The type or namespace name 'EditorWindow' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(104,6): error CS0246: The type or namespace name 'MenuItemAttribute' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(104,6): error CS0246: The type or namespace name 'MenuItem' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(7,33): error CS0246: The type or namespace name 'EditorWindow' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(104,6): error CS0246: The type or namespace name 'MenuItemAttribute' could not be found (are you missing a using directive or an assembly reference?)
Assets\src\test.cs(104,6): error CS0246: The type or namespace name 'MenuItem' could not be found (are you missing a using directive or an assembly reference?)
```

不过 log 还有各种信息，等日后让 llm 写个 regex 来匹配吧。

# 结语

感觉每个操作都能完美地不符合人体工程学，哎 unity 怎么这么坏啊。

想想 mac 要处理 xcode ，移动端要处理微信小程序和鸿蒙，维护 unity 打包机的人真能负重前行。

# misc

如果使用 personal license，要安装 hub 三天更新一次，然后放到 `C:/ProgramData/Tuanjie/Tuanjie_lic.ulf` ，否则编辑器直接不给用。
