# Release Artifacts

当前仓库不提交 IPA、App 包、证书和描述文件，避免公开本机签名凭据。

```bash
./scripts/package-release.sh
```

生成的文件位于 `build/release/`，该目录已被 `.gitignore` 排除。

公开发布 iOS 需要 Apple Developer Program、TestFlight 或 App Store；macOS 公共分发需要 Developer ID 签名和 Apple 公证。
