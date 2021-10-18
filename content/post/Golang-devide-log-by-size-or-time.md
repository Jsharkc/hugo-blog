---
title: Golang 按大小 or 时间切割日志
date: 2021-09-26T19:05:03+08:00
tags: ["Golang"]
author: "Jsharkc"
---

Log 用的 `go.uber.org/zap` 库。

## 按大小切割日志

按大小切割日志，用到 `github.com/natefinch/lumberjack` 库，代码如下：

```go
package log

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/natefinch/lumberjack"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var Sugar *zap.SugaredLogger = nil
var Raw *zap.Logger = nil


// LogInit 初始化日志库
// dev 开发模式，日志不入文件
// logPath 日志文件存放路径
// logName 日志文件名称
// maxSize 单个文件大小，超过后切割，单位 M
// maxBackups 旧的日志文件最多保留个数，0 为保存所有
// maxAge 旧的日志文件最多保留天数，0 为保存所有
// MaxBackups 和 maxAge 只要有一个不满足，就不再保留
func LogInit(dev bool, logPath, logName string, maxSize, maxBackups, maxAge int) (err error) {
  if dev {
    Raw, _ = zap.NewDevelopment()
    Sugar = Raw.Sugar()
    return
  }

  if !strings.HasSuffix(logPath, "/") {
    logPath += "/"
  }

  if !strings.HasSuffix(logName, ".log") {
    logName += ".log"
  }

  _, err = os.Stat(logPath)
  if os.IsNotExist(err) {
    // Create parent directory if it does not exist
    if err = os.MkdirAll(logPath, 0744); err != nil {
      fmt.Println("os.MkdirAll failed, err=", err)
      return
    }
  }
  
  if err != nil {
    fmt.Println("os.Stat failed, err=", err)
    return
  }

  w := zapcore.AddSync(&lumberjack.Logger{
    Filename:   logPath + logName,
    MaxSize:    maxSize,
    MaxBackups: maxBackups,
    MaxAge:     maxAge,
  })

  core := zapcore.NewCore(
    zapcore.NewConsoleEncoder(zap.NewProductionEncoderConfig()),
    w,
    zap.InfoLevel,
  )
  Raw = zap.New(core)
  Sugar = Raw.Sugar()

  return
}
```

`zap.NewProductionEncoderConfig()` 产生的日志，事件格式为时间戳，人类不方便读，如果想自定义时间格式的话，只需要替换 `core := zapcore.NewCore` 即可，代码如下：

```go
core := zapcore.NewCore(
  zapcore.NewConsoleEncoder(MyEncoderConfig()),
  w,
  zap.InfoLevel,
)

func MyEncoderConfig() zapcore.EncoderConfig {
  return zapcore.EncoderConfig{
    TimeKey:       "ts",
    LevelKey:      "level",
    NameKey:       "logger",
    CallerKey:     "caller",
    FunctionKey:   zapcore.OmitKey,
    MessageKey:    "msg",
    StacktraceKey: "stacktrace",
    LineEnding:    zapcore.DefaultLineEnding,
    EncodeLevel:   zapcore.LowercaseLevelEncoder,
    EncodeTime: func(t time.Time, enc zapcore.PrimitiveArrayEncoder) {
      enc.AppendString(t.Format("2006/01/02T15:04:05"))
    },
    EncodeDuration: zapcore.SecondsDurationEncoder,
    EncodeCaller:   zapcore.ShortCallerEncoder,
  }
}
```

## 按时间切割日志

按时间切割日志，用到 `github.com/lestrrat/go-file-rotatelogs` 库，代码如下：

```go
package log

import (
	"fmt"
	"os"
	"strings"
	"time"

	rotatelogs "github.com/lestrrat/go-file-rotatelogs"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var Sugar *zap.SugaredLogger = nil
var Raw *zap.Logger = nil

// LogInit 初始化日志库
// logPath 日志文件存放路径
// logName 日志文件名称
// rotationTime 按时间分割，分割的时间长度
func LogInit(logPath, logName string, rotationTime time.Duration) (err error) {
  if !strings.HasSuffix(logPath, "/") {
    logPath += "/"
  }

  if !strings.HasSuffix(logName, ".log") {
    logName += ".log"
  }

  _, err = os.Stat(logPath)
  if os.IsNotExist(err) {
    // Create parent directory if it does not exist
    if err = os.MkdirAll(logPath, 0744); err != nil {
      fmt.Println("os.MkdirAll failed, err=", err)
      return
    }
  }

  if err != nil {
    fmt.Println("os.Stat failed, err=", err)
    return
  }

  rotate, err := rotatelogs.New(
    logPath+logName+".%Y%m%d",
    rotatelogs.WithLinkName(logPath+logName),
    rotatelogs.WithMaxAge(rotationTime), // 这里不写默认 24 hour
  )
  if err != nil {
    fmt.Println("rotatelogs.New failed, err=", err)
    return
  }

  writer := zapcore.AddSync(rotate)

  core := zapcore.NewCore(
    zapcore.NewConsoleEncoder(zap.NewProductionEncoderConfig()),
    writer,
    zap.InfoLevel,
  )
  Raw = zap.New(core)
  Sugar = Raw.Sugar()

  return
}

```

假设 `rotationTime` 为 `24hour` 即「天」，那么当你的程序在任意时间启动，都会在半夜 12 点，产生日志切割。

以上
