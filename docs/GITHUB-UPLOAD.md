# 上传到 GitHub

## GitHub Desktop

1. 安装并登录 GitHub Desktop。
2. 选择 `File → Add Local Repository`。
3. 选择本目录 `CS-Self-Study-Companion`。
4. 点击 `Publish repository`。
5. 如需保护个人信息，选择 Private。
6. 以后修改后填写 Commit message，点击 Commit，再点击 Push origin。

## 命令行

在 GitHub 创建空仓库，不要初始化 README、License 或 `.gitignore`：

```bash
git remote add origin https://github.com/<用户名>/<仓库名>.git
git push -u origin main
```

以后更新：

```bash
git add -A
git commit -m "说明本次更新"
git push
```

上传前运行 `git status` 和 `./scripts/run-tests.sh`。不要提交证书、描述文件、签名 IPA、学习数据、DerivedData 或设备 UDID 日志。
