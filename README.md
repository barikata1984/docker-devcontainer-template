# Devcontainer Base Template (uid1000 variant)

NVIDIA CUDA + Ubuntu 24.04 ベースの VS Code devcontainer テンプレート。
GPU 開発環境を新規プロジェクトごとに素早く立ち上げるためのベース設定。

> **このブランチ (`uid1000`) について**
> コンテナ内ユーザーを **UID=1000 / GID=1000 / 名前 `uid1000`** に固定したバリアント。
> ホスト側の `id -u` / `id -g` / `$USER` を build arg に注入する仕組みを廃止し、
> どのマシンでビルドしても同一イメージが得られる。
> ホストが UID=1000 の場合はバインドマウントされたファイルの所有権も一致する。
> ホストが UID=1000 でない場合は `/workspace` 上のファイル所有権が `uid1000` 側からは
> 別 UID として見える点に注意 (read のみなら問題なし、書き戻しは要 `chown` か別バリアント)。

## ディレクトリ構成

```
template/
├── .devcontainer/
│   └── devcontainer.json       # VS Code 拡張・Python・シェル設定
├── docker/
│   ├── Dockerfile              # nvidia/cuda + Ubuntu 24.04, Python venv, 非 root ユーザー
│   ├── docker-compose.yaml     # GPU・ボリューム・ipc: host
│   ├── entrypoint.sh           # zsh 初期化 + gosu による非 root 切替
│   ├── requirements.txt        # 共通 dev ツール (ruff, pytest, debugpy 等)
│   └── .env.example            # マシン固有の設定テンプレート
├── .dockerignore               # ホワイトリスト方式のビルドコンテキスト制御
├── .gitignore                  # docker/.env 等を除外
└── README.md
```

## 使い方

### 1. テンプレートをコピー

```bash
cp -r template/ my-new-project/
cd my-new-project/
```

### 2. プロジェクト名を書き換える

各ファイル内の `TODO` コメントを検索し、プロジェクトに合わせて変更する。

| ファイル | 変更箇所 |
|---------|---------|
| `docker/docker-compose.yaml` | `name`, サービス名 (`dev`), `image` |
| `.devcontainer/devcontainer.json` | `name`, `service` |

### 3. 環境変数を設定

このブランチではコンテナ内ユーザーは **UID=1000 / GID=1000 / 名前 `uid1000` に固定**されているため、UID/GID をホストから注入する手順は不要。`docker/init-env.sh` は互換のために残してあるが no-op。

CUDA バージョンや DISPLAY を上書きしたい場合のみ、`docker/.env.example` をコピーして `docker/.env` を作成する:

```bash
cp docker/.env.example docker/.env   # 必要なら CUDA_VERSION や DISPLAY を編集
```

`docker/.env` は git 管理外。

### 4. プロジェクト固有の依存を追加

`docker/requirements.txt` にプロジェクトで使うパッケージを追記する。

### 5. コンテナを起動

**VS Code (devcontainer)**:

コマンドパレット → `Dev Containers: Reopen in Container`

**CLI (standalone)**:

```bash
cd docker
docker compose build
docker compose up -d
docker compose exec dev zsh
```

## 含まれる設定

### ベースイメージ

`nvidia/cuda:${CUDA_VERSION}-devel-ubuntu24.04` — CUDA バージョンは `.env` の `CUDA_VERSION` で切替可能。

### GPU サポート

デフォルトで NVIDIA GPU 全台を割当。`ipc: host` により PyTorch DataLoader / NCCL の共有メモリも有効。

### 非 root ユーザー

UID=1000 / GID=1000 / 名前 `uid1000` で固定。`gosu` でランタイム切替。
ホストが UID=1000 ならバインドマウントしたファイルの所有権も自動で一致する。

### ボリュームマウント

コンテナ側の `~` は `/home/uid1000` を指す。

| ホスト | コンテナ | 用途 |
|-------|---------|------|
| プロジェクトルート | `/workspace` | ワークスペース |
| `~/.ssh` | `/home/uid1000/.ssh` (ro) | SSH 鍵 |
| `~/.gitconfig` | `/home/uid1000/.gitconfig` (ro) | Git 設定 |
| `~/.netrc` | `/home/uid1000/.netrc` (ro) | wandb 等の認証 |
| `/tmp/.X11-unix` | `/tmp/.X11-unix` | GUI 転送 |
| named volume | `/home/uid1000/.cache/pip` | pip キャッシュ永続化 |

### VS Code 拡張 (14個)

Claude Code, Python, Pylance, Ruff, Jupyter, Docker, GitLens, Git Graph, Debugpy, YAML, TOML, Markdown, Error Lens, Todo Tree, Spell Checker, Path Intellisense

### entrypoint.sh の動作

1. 初回起動時に zsh の設定ファイルを生成
2. `~/.cache`, `~/.local`, `~/.config`, `~/.claude` を作成
3. `pyproject.toml` があればプロジェクトを editable install
4. `gosu` で非 root ユーザーに切替してコマンドを実行

## カスタマイズ例

### GPU 不要の場合

`docker-compose.yaml` の `deploy` セクションと GPU 関連の `environment` を削除し、ベースイメージを `ubuntu:24.04` に変更する。

### 追加サービスが必要な場合

`docker-compose.yaml` に `services` を追加する (例: DB, Redis, Ollama 等)。
