# frontend-migrate-agent

一个用于把前端仓库代码迁入后端仓库子目录的命令行工具。

它封装了下面这类 Git subtree 流程：

```bash
git remote add <temp-remote> <frontend-repo-url>
git fetch <temp-remote>
git subtree add --prefix=<target-dir> <temp-remote>/<frontend-branch>
git remote remove <temp-remote>
git push origin <current-backend-branch>
```

## 安装

### 方式一：一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/fishman132yangbo/frontend-migrate-agent/main/install.sh | bash
```

默认安装到 `~/.local/bin/frontend-migrate`。如果 `~/.local/bin` 不在 `PATH` 中，请把下面这行加入你的 shell 配置文件：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 方式二：从源码安装

```bash
git clone https://github.com/fishman132yangbo/frontend-migrate-agent.git
cd frontend-migrate-agent
bash install.sh
```

## 使用

先进入后端工程的本地 Git 仓库目录：

```bash
cd /path/to/backend-repo
```

执行迁移：

```bash
frontend-migrate <前端仓库url> <前端分支名>
```

示例：

```bash
frontend-migrate https://github.com/example/frontend.git v4.15.2
```

默认会把前端代码迁入后端仓库的 `frontend-contractweb/` 目录，并推送后端当前所在分支：

```bash
git push origin <当前后端分支>
```

## 参数

### `--prefix <目录名>`

指定前端代码迁入到后端仓库里的目录。

默认值：

```text
frontend-contractweb
```

示例：

```bash
frontend-migrate https://github.com/example/frontend.git main --prefix frontend-operation
```

### `--squash`

把前端仓库的提交历史压缩成一次提交。

不加 `--squash`：保留前端仓库完整提交历史。

加 `--squash`：后端仓库只生成一次迁入提交，历史更简洁。

示例：

```bash
frontend-migrate https://github.com/example/frontend.git main --squash
```

### `--dry-run`

预演模式，只打印将要执行的命令，不修改仓库。

正式迁移前可以先检查当前后端分支、前端分支、迁入目录是否正确：

```bash
frontend-migrate https://github.com/example/frontend.git main --dry-run
```

## 安全检查

工具会在执行前做这些检查：

- 当前目录必须是 Git 仓库。
- 当前仓库不能处于 detached HEAD 状态。
- 当前工作区必须干净。
- 目标迁入目录不能已经存在。

## 测试

```bash
bash tests/test_frontend_migrate.sh
```

测试会创建本地临时前端仓库和后端仓库，验证真实的 `git subtree add` 和 `git push origin <当前分支>` 流程。

## License

MIT
