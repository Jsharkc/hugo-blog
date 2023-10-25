---
title: "修复 dyld: Library not loaded"
description: '通过 otool 修复 dyld: Library not loaded 问题'
date: 2021-10-16T14:37:03+08:00
tags: ["Mac", "环境"]
author: "Jacobc"
---

`flutter` 最新版 `2.5.3` 安装 `CocoaPods` 需要 `ruby 2.6` 以上，而我 MAC 上 `ruby` 只有 `2.5` 所以需要更新 `ruby`，`brew install ruby` 后，就碰到了这个问题。

报错信息：

```shell
dyld: Library not loaded: 
/usr/local/opt/ruby/lib/libruby.2.5.dylib
  Referenced from: /usr/local/bin/vi
  Reason: image not found
```

也就是说，现在 `ruby 2.6` 所以找不到 `ruby 2.5` 了

首先

```shell
> which vi
找到 vi 所在的位置，/usr/local/bin/vi，然后 通过 otool 找到该命令依赖的库
> otool -L /usr/local/bin/vi 
/usr/local/bin/vi:
	...
	/usr/local/opt/ruby/lib/libruby.dylib (compatibility version 2.5.0, current version 2.5.1)
	/usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)
	...
	有很多内容，为了能看清楚，我用 ... 省略掉了，然后通过 install_name_tool 修改依赖
> install_name_tool -change /usr/local/opt/ruby/lib/libruby.2.5.dylib /usr/local/opt/ruby/lib/libruby.dylib /usr/local/bin/vi
install_name_tool 命令格式是：
install_name_tool -change 原依赖 需要换成的依赖 命令位置
```

修改之后，就能正常使用了。

希望各位都能解决问题。
