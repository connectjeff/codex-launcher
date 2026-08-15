# Codex Launcher

This repository contains native launchers for Codex on macOS and Windows 11.

| Version | Entry point | Desktop integration | Profile manager |
|---|---|---|---|
| macOS | `Codex Launcher.app` | Dock/Finder application | `scripts/config-manager.sh` |
| Windows 11 | `windows/codex-launcher.cmd` | Start menu/taskbar shortcut | `scripts/config-manager.cmd` |

## Windows 11

Run `windows\codex-launcher.cmd` or right-click `windows\Codex-Launcher.ps1` and choose **Run with PowerShell**. The launcher offers the normal Codex profile and an isolated LM Studio profile under `%USERPROFILE%\codex-config\codex-home-lmstudio`.

To install an always-current Start menu shortcut backed by a symbolic link to this repository, run `windows\Install-CodexLauncher.ps1 -PinToTaskbar`. Windows 11 may require you to right-click the resulting Start menu entry and select **Pin to taskbar** if its protected taskbar API declines automatic pinning.

The Windows icon is generated from the macOS iconset by `windows\Build-WindowsIcon.ps1`, so both launchers use the same artwork.

The default LM Studio endpoint is `http://127.0.0.1:1234/v1`. This works with LM Studio running on Windows and with remote models exposed locally through LM Link. For a direct connection to another computer, override it without editing the script by setting `LMSTUDIO_BASE_URL`, or pass `-Endpoint` to the PowerShell entry point. The remote LM Studio server must listen on the LAN and permit inbound TCP port 1234.

The Windows launcher queries `/v1/models`, excludes embedding and reranking models, prompts for a model, verifies a chat completion, writes the isolated Codex `config.toml`, removes common cloud API-token variables for the child process, and launches Codex. It does not alter the normal `%USERPROFILE%\.codex` profile.

Windows configuration management is available through `scripts\config-manager.cmd` with `list`, `create`, `switch`, `export`, `import`, `show`, and `edit` commands.

## macOS

The existing macOS launcher remains unchanged:

- `Codex Launcher.app` prompts for a runtime configuration.
- `Codex Launcher.app/Contents/Resources/CodexLauncher.icns` provides the Dock/Finder icon.
- `Default Codex config` launches Codex with `CODEX_HOME=$HOME/.codex`.
- `Local LM Studio only` launches the ChatGPT/Codex desktop app with `CODEX_HOME=$HOME/codex-config/codex-home-lmstudio`.

The LM Studio mode uses a custom OpenAI-compatible provider named `lmstudio-local` pointed at `http://127.0.0.1:1234/v1`. It does not use Codex's `--oss` mode, so it will not try to download `openai/gpt-oss-*` models. It does not copy `~/.codex/auth.json` or your normal Codex state. It also unsets common OpenAI/Codex API-token environment variables before starting Codex and refuses to launch unless LM Studio is reachable.

When you select "Local LM Studio only", the launcher will:
1. Query LM Studio for available chat models (embedding models are excluded)
2. Present a model picker dialog so you can choose which model to use
3. Verify the selected model responds correctly before launching
4. Update `codex-home-lmstudio/config.toml` with your selection

To use it from the Dock, drag `Codex Launcher.app` to the Dock.

If your LM Studio server uses a different port, edit `LMSTUDIO_URL` in `Codex Launcher.app/Contents/MacOS/codex-launcher`, and update `model_providers.lmstudio-local.base_url` in `codex-home-lmstudio/config.toml`.

The icon source is `assets/codex-launcher-icon.svg`.

## Installation

1. Drag `Codex Launcher.app` to your Applications folder (optional)
2. Copy the launcher app to your Dock for easy access
3. First launch: Select "Local LM Studio only" to configure for LM Studio
4. Ensure LM Studio is running with the local server enabled on port 1234

## Configuration Manager

A command-line tool is available for managing configurations and profiles:

```bash
# List all saved profiles
./scripts/config-manager.sh list

# Create a new profile from current config
./scripts/config-manager.sh create my-profile

# Switch between profiles
./scripts/config-manager.sh switch my-profile

# Export current configuration
./scripts/config-manager.sh export ~/Desktop/codex-backup.tar.gz

# Import configuration from backup
./scripts/config-manager.sh import ~/Desktop/codex-backup.tar.gz

# Show current configuration
./scripts/config-manager.sh show

# Edit configuration in your editor
./scripts/config-manager.sh edit
```

## GitHub CLI

Codex sessions launched from either the default config or the LM Studio config get `gh` on `PATH` through stable wrappers:

- `$HOME/.codex/bin/gh`
- `codex-home-lmstudio/bin/gh`
- `bin/gh`

All wrappers delegate to `/opt/homebrew/bin/gh`.

## Local LM Studio Performance

### macOS: Mac Studio M1 Ultra

This configuration has been tested on the following system:

**Hardware**: Mac Studio M1 Ultra (128GB unified memory)
**Model**: Qwen3-Coder-Next
**Quantization**: MLX format on macOS (quantization controlled by system)

#### Performance Benchmarks (Observed on 2026-08-02)

| Metric | Observed Range | Average |
|--------|----------------|---------|
| Avg Response Time | 3.10s-4.22s | 3.46s |
| Tokens/Second | 34.12-44.84 | 43.41 |

#### Notes

These results were measured locally against LM Studio on this Mac Studio M1 Ultra using `qwen/qwen3-coder-next` and a 100-word essay prompt. Possible factors that can shift the numbers:

- **Quantization**: MLX format on macOS (quantization controlled by system)
- **GPU offload**: Enabled in LM Studio
- **Background processes**: System load during model inference

#### Testing Command

Run this to reproduce the benchmark:
```bash
python3 -c "
import requests, time
url = 'http://127.0.0.1:1234/v1/chat/completions'
payload = {'model': 'qwen/qwen3-coder-next', 'messages': [{'role':'user','content':'Write a 100-word essay about machine learning'}], 'max_tokens': 256}
start = time.time(); r = requests.post(url, json=payload); data = r.json(); print(f\"{(time.time()-start):.2f}s, {data['usage']['completion_tokens']/(time.time()-start):.2f} tokens/s\")
"
```

### Windows 11: Intel NUC 12 with RTX 4070 SUPER

- **Hardware**: Intel NUC 12, NVIDIA GeForce RTX 4070 SUPER, 64GB system memory
- **Model**: Qwen3-Coder-Next
- **Quantization**: GGUF Q4_K_M
- **LM Studio runtime**: CUDA 12 `llama.cpp`, 8 model layers offloaded to the GPU, 32,768-token loaded context

#### Performance Benchmarks (Observed on 2026-08-15)

| Metric | Observed Range | Average |
|--------|----------------|---------|
| Response Time | 12.66s-14.74s | 13.58s |
| Tokens/Second | 11.33-13.01 | 11.97 |

These results are from five measured requests after one warm-up request. LM Link was disabled, and the benchmark used the Windows-local `Qwen3-Coder-Next-Q4_K_M.gguf` model through `http://127.0.0.1:1234/v1/chat/completions`. Each request used the same 100-word machine-learning essay prompt and 256-token limit as the Mac Studio benchmark. The five measured responses generated 811 completion tokens in total.

#### Testing Command

```powershell
$url = 'http://127.0.0.1:1234/v1/chat/completions'
$payload = @{
    model = 'qwen/qwen3-coder-next'
    messages = @(@{ role = 'user'; content = 'Write a 100-word essay about machine learning' })
    max_tokens = 256
} | ConvertTo-Json -Depth 5

$start = Get-Date
$response = Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body $payload
$elapsed = ((Get-Date) - $start).TotalSeconds
"{0:N2}s, {1:N2} tokens/s" -f $elapsed, ($response.usage.completion_tokens / $elapsed)
```

## Changelog

### v1.0.0 (Current)
- Added retry logic for LM Studio connection failures
- Improved error messages with alert dialogs
- Added logging levels (debug, info, warn, error)
- Enhanced model picker with default model selection
- Added version tracking in app bundle
- Configuration manager for profiles and export/import
- Disk space warnings before launching
- Better error handling throughout

## TODO

See [`TODO.md`](./TODO.md) for planned features and improvements.

## License

MIT
