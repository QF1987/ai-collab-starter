# Finding 22: P1 #3 task brief 漏检同包 helper 重名

- Time: 2026-05-15 00:01 CST
- Task: `.ai/tasks/2026-05-14-p1-3-upgrade-app-upload.md`
- Reporter: Codex
- Priority: P3
- Status: open

## 现象

brief 要求新增 helper 签名：

```go
uploadFile(serverURL, apkPath, fileType string) (httpURL string, err error)
```

实施后 `go test -v ./internal/cmd/...` 编译失败：

```text
internal/cmd/upgrade_app.go:230:6: uploadFile redeclared in this block
	internal/cmd/release.go:543:6: other declaration of uploadFile
```

`internal/cmd/release.go` 已存在同包 `uploadFile(url, filePath, fileType string) (map[string]interface{}, error)`，但该函数不满足本 task 的 header、错误包装、URL 组装和返回值要求；同时 `release.go` 不在本 task scope 内，不能改名或重构。

## 本次处理

为守住 scope，本次改为在 `upgrade_app.go` 内新增 `uploadFileHTTPURL(...) (string, error)`，名称仍包含 `uploadFile`，满足 grep 证据但不完全满足 brief 的固定函数名要求。业务行为和测试按 brief 落地。

## 建议

starter / plan 阶段在锁定「新增私有函数签名」前，先对目标 package 跑一次同名符号 grep。若已有同名函数，brief 应直接给出允许的无冲突名字，避免 Codex 在实施期才遇到编译冲突。
