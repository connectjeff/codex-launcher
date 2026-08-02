# Codex Launcher

This folder contains a Dockable macOS launcher for Codex:

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

This configuration has been tested on the following system:

**Hardware**: Mac Studio M1 Ultra (128GB unified memory)
**Model**: Qwen3-Coder-Next
**Quantization**: MLX format on macOS (quantization controlled by system)

### Performance Benchmarks (Observed on 2026-08-02)

| Metric | Observed Range | Average |
|--------|----------------|---------|
| Avg Response Time | 3.10s-4.22s | 3.46s |
| Tokens/Second | 34.12-44.84 | 43.41 |

### Notes

These results were measured locally against LM Studio on this Mac Studio M1 Ultra using `qwen/qwen3-coder-next` and a 100-word essay prompt. Possible factors that can shift the numbers:

- **Quantization**: MLX format on macOS (quantization controlled by system)
- **GPU offload**: Enabled in LM Studio
- **Background processes**: System load during model inference

### Testing Command

Run this to reproduce the benchmark:
```bash
python3 -c "
import requests, time
url = 'http://127.0.0.1:1234/v1/chat/completions'
payload = {'model': 'qwen/qwen3-coder-next', 'messages': [{'role':'user','content':'Write a 100-word essay about machine learning'}], 'max_tokens': 256}
start = time.time(); r = requests.post(url, json=payload); data = r.json(); print(f\"{(time.time()-start):.2f}s, {data['usage']['completion_tokens']/(time.time()-start):.2f} tokens/s\")
"
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
