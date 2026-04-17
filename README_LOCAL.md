# GenericAgent 本地运行说明

这个项目现在支持用 `uv` 管理依赖，并用项目内脚本常驻启动两个前端：

- `frontends/wechatapp.py`
- `frontends/tgapp.py`

它们是**两个独立进程**，互不影响；某一个挂了，不代表另一个也挂。

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

后续运行统一建议使用：

```bash
uv run python ...
```

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
- 不要把真实 token / apikey 写入文档或提交到 Git。

---

## 4. 常驻启动 / 重启 / 停止 / 状态

### 启动两个前端

```bash
bash scripts/start-bots.sh
```

脚本行为：

- 使用 `uv run python ...` 启动
- 后台运行
- PID 写入 `temp/*.pid`
- 日志写入 `temp/*.out.log`
- 已在运行时不会重复启动同一个 bot

### 重启两个前端

```bash
bash scripts/restart-bots.sh
```

脚本会：

- 先调用 `stop-bots.sh`
- 再调用 `start-bots.sh`
- 最后显示当前状态

### 停止两个前端

```bash
bash scripts/stop-bots.sh
```

脚本会：

- 按 pid 文件优先发送 `SIGTERM`
- 等待一段时间
- 若仍未退出，再执行强制停止

### 查看状态

```bash
bash scripts/status-bots.sh
```

输出会显示：

- 是否在运行
- PID
- 对应日志文件位置

---

## 5. 日志位置

运行日志都在项目内 `temp/` 目录：

- 微信：`temp/wechatapp.out.log`
- Telegram：`temp/tgapp.out.log`

快速查看：

```bash
tail -f temp/wechatapp.out.log
tail -f temp/tgapp.out.log
```

---

## 6. 单独手工启动（调试用）

如果你只想手工前台启动某一个前端：

```bash
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

## 8. 常用命令汇总

```bash
# 安装/同步依赖
uv sync

# 启动
bash scripts/start-bots.sh

# 重启
bash scripts/restart-bots.sh

# 停止
bash scripts/stop-bots.sh

# 查看状态
bash scripts/status-bots.sh

# 看日志
tail -f temp/wechatapp.out.log
tail -f temp/tgapp.out.log
```
