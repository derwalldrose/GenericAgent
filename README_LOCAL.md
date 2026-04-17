# GenericAgent 本地运行说明

这个项目现在支持用 `uv` 管理依赖，并用项目内脚本**统一管理 GA**。

这里的 **GA** 指下面三个服务的统一管理：

- Streamlit Web UI：`frontends/stapp.py`
- WeChat 前端：`frontends/wechatapp.py`
- Telegram 前端：`frontends/tgapp.py`

其中 Streamlit 通过 `streamlit run` 启动，监听：

- `0.0.0.0:18631`

三个服务互相独立；某一个挂了，不代表另外两个也挂。

---

## 1. 环境要求

推荐：

- Python `3.11` 或 `3.12`
- `uv` 已安装

检查：

```bash
python3 --version
uv --version
```

如果没装 `uv`，可先执行：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

安装后重新打开 shell，或手动把 `uv` 加入 PATH。

---

## 2. 首次同步依赖

在项目根目录执行：

```bash
uv sync
```

后续运行统一建议使用 `uv run ...`。

说明：

- 项目里原有 `.venv` 可以保留。
- `uv sync` 会优先复用/更新当前虚拟环境。
- 如果本机已有旧 `.venv` 且来源复杂，`uv sync` 仍可继续使用；若后续发现环境异常，可备份后删除 `.venv` 再重新 `uv sync`。

---

## 3. 配置 `mykey.py`

项目根目录应存在：

```bash
mykey.py
```

可参考：

```bash
mykey_template.py
```

至少需要这些字段（只写字段说明，不要把真实密钥提交到仓库）：

```python
# LLM 配置（示例字段）
oai_config = {
    'name': 'your-llm-name',
    'apikey': '你的 LLM API Key',
    'apibase': '你的接口地址',
    'model': '你的模型名',
}

# Telegram Bot token
tg_bot_token = '你的 Telegram Bot Token'

# 允许访问 bot 的 Telegram 用户 ID 列表
tg_allowed_users = [123456789]

# 可选：网络代理
proxy = 'http://127.0.0.1:2082'
```

注意：

- `tg_allowed_users` 不能为空，否则 TG 前端会直接退出。
- `mykey.py` 保持本地未跟踪，不要入库。
- 不要把真实 token / apikey / 任何 secret 写入文档或提交到 Git。

---

## 4. 以后重启 GA 具体怎么操作

### 最小命令

```bash
uv sync
bash scripts/start-bots.sh
bash scripts/stop-bots.sh
bash scripts/status-bots.sh
bash scripts/restart-bots.sh
```

### 推荐理解方式

- `start-bots.sh`：统一启动 GA 的三个服务
- `stop-bots.sh`：统一停止 GA 的三个服务
- `status-bots.sh`：统一查看 GA 的三个服务状态
- `restart-bots.sh`：统一重启 GA 的三个服务

### 标准操作

#### 启动 GA

```bash
bash scripts/start-bots.sh
```

脚本会统一处理：

- Streamlit：`frontends/stapp.py`（`0.0.0.0:18631`）
- WeChat：`frontends/wechatapp.py`
- Telegram：`frontends/tgapp.py`

脚本行为：

- 后台运行
- PID 写入 `temp/*.pid`
- 日志写入 `temp/*.out.log`
- 如果服务已经在运行，会自动识别并接管，不会重复拉起同一个服务
- Streamlit 的识别基于实际 `streamlit run ... frontends/stapp.py --server.port 18631 --server.address 0.0.0.0` 特征，而不是只看脚本文件名

#### 停止 GA

```bash
bash scripts/stop-bots.sh
```

脚本会尝试优雅停止；若等待超时，会执行强制停止。

#### 查看 GA 状态

```bash
bash scripts/status-bots.sh
```

输出会显示：

- 是否在运行
- PID
- 对应日志文件位置

#### 重启 GA

```bash
bash scripts/restart-bots.sh
```

它会依次执行：

1. `stop-bots.sh`
2. `start-bots.sh`
3. `status-bots.sh`

如果你只是想“把 GA 整体重启一遍”，直接执行这一条即可。

---

## 5. 日志位置

运行日志都在项目内 `temp/` 目录：

- Streamlit：`temp/streamlit.out.log`
- 微信：`temp/wechatapp.out.log`
- Telegram：`temp/tgapp.out.log`

快速查看：

```bash
tail -f temp/streamlit.out.log
tail -f temp/wechatapp.out.log
tail -f temp/tgapp.out.log
```

---

## 6. 单独手工启动（调试用）

如果你只想手工前台启动某一个前端：

```bash
uv run streamlit run frontends/stapp.py --server.port 18631 --server.address 0.0.0.0 --server.headless true
uv run python frontends/wechatapp.py
uv run python frontends/tgapp.py
```

---

## 7. 二维码 / Token 过期怎么办

### WeChat 二维码过期

微信前端首次登录或 token 失效时，会重新触发二维码登录流程。

处理方式：

1. 先停止旧进程：
   ```bash
   bash scripts/stop-bots.sh
   ```
2. 重新启动：
   ```bash
   bash scripts/start-bots.sh
   ```
3. 观察微信日志或终端输出，按提示重新扫码

补充说明：

- 微信登录状态通常保存在：`~/.wxbot/token.json`
- 如果缓存损坏或状态异常，可在确认后删除该文件，再重新启动登录

### Telegram token 失效

如果 TG bot 日志出现鉴权失败、无法轮询等问题：

1. 检查 `mykey.py` 里的 `tg_bot_token`
2. 确认 `tg_allowed_users` 是否正确
3. 保存后重启：
   ```bash
   bash scripts/stop-bots.sh
   bash scripts/start-bots.sh
   ```

---

## 8. Git SOP：如何拉取 origin，然后推送 target

这个仓库常见工作流是：

- `origin`：上游仓库
- `target`：你自己的目标仓库

### 8.1 查看 remotes

```bash
git remote -v
```

先确认当前仓库至少有：

- `origin`
- `target`

### 8.2 从 origin 拉最新，并更新本地 main

推荐操作：

```bash
git fetch origin
git checkout main
git rebase origin/main
```

如果你当前已经在 `main`，也可以直接：

```bash
git fetch origin
git rebase origin/main
```

这一步的目标是：

- 先拿到上游最新提交
- 再把你本地 `main` 基于 `origin/main` 线性更新

如果发生冲突，先解决冲突，再继续：

```bash
git add <已解决的文件>
git rebase --continue
```

### 8.3 把本地状态推到 `target/main`

普通情况下：

```bash
git push target main
```

### 8.4 什么时候普通 push，什么时候用 `--force-with-lease`

#### 可以普通 push 的情况

当你的本地 `main` 只是新增提交、没有改写提交历史时，用普通推送：

```bash
git push target main
```

典型场景：

- 你只是新提交了几个 commit
- 没有做 rebase / amend / reset / squash 等改写历史操作

#### 需要 `--force-with-lease` 的情况

如果你执行过这些会改写历史的操作：

- `git rebase ...`
- `git commit --amend`
- `git reset --hard/--soft ...`
- squash / 手动改写历史

那么推到 `target/main` 时，可能需要：

```bash
git push --force-with-lease target main
```

注意：

- **只在确实因为 rebase 或历史改写导致普通 push 被拒时使用**
- 不要直接用 `--force`
- 优先用更安全的 `--force-with-lease`

### 8.5 Secret 不入库提醒

提交前建议检查：

```bash
git status --short
```

务必确认：

- `mykey.py` 继续保持本地未跟踪
- 不要把 token / API key / cookie / 运行日志 / pid 文件提交进仓库
- `temp/` 下运行产物不应入库

---

## 9. 常用命令汇总

```bash
# 安装/同步依赖
uv sync

# 启动 GA（三个服务）
bash scripts/start-bots.sh

# 停止 GA（三个服务）
bash scripts/stop-bots.sh

# 查看状态
bash scripts/status-bots.sh

# 重启 GA（三个服务）
bash scripts/restart-bots.sh

# 看日志
tail -f temp/streamlit.out.log
tail -f temp/wechatapp.out.log
tail -f temp/tgapp.out.log

# 同步上游并推送到 target
git fetch origin
git rebase origin/main
git push target main
```
