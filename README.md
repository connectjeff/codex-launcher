# Codex Launcher

Codex Launcher is a desktop launcher for macOS and Windows 11 that starts Codex with either the standard Codex configuration or an isolated LM Studio configuration. The LM Studio workflow discovers available chat models, validates the selected model, updates the profile, and then starts Codex.

## Features

- Native launchers for macOS and Windows 11
- Standard Codex and isolated LM Studio profiles
- Automatic model discovery through the LM Studio OpenAI-compatible API
- Filtering of embedding and reranking models from the chat-model picker
- Completion test before Codex starts
- Just-in-time model loading through LM Studio
- Support for Windows-local models, remote LAN servers, and LM Link
- Profile creation, switching, import, and export tools
- Shared launcher artwork across both platforms
- Persistent logging and visible launch errors

## Installation

### Requirements

- The Codex desktop app
- LM Studio when using the LM Studio profile
- An LM Studio chat model available through `/v1/models`
- macOS 12 or later, or Windows 11 with PowerShell 5.1 or later

Download the appropriate archive from the [latest GitHub release](https://github.com/connectjeff/codex-launcher/releases/latest).

### macOS

1. Download and extract `Codex-Launcher-macos-<version>.zip`.
2. Move `Codex Launcher.app` into `/Applications`.
3. Drag the application from Applications to the Dock.
4. Start LM Studio and enable its local server if you plan to use the LM Studio profile.
5. Open Codex Launcher and select either **Default Codex config** or **Local LM Studio only**.

If macOS blocks the first launch because the app is unsigned, Control-click the application, choose **Open**, and confirm the prompt.

### Windows 11

1. Download and extract `Codex-Launcher-windows-<version>.zip` into a permanent folder.
2. Open PowerShell in the extracted folder.
3. Run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\Install-CodexLauncher.ps1 -PinToTaskbar
   ```

4. Open **Codex Launcher** from the Start menu.
5. If Windows does not pin it automatically, right-click the Start menu entry and select **Pin to taskbar**.
6. Start LM Studio before selecting **Local LM Studio only**.

The Windows installer creates a directory junction from `%LOCALAPPDATA%\Programs\Codex Launcher` to the extracted folder. Keep that folder in place after installation so the shortcut remains valid. Running the installer again updates the junction and shortcut.

### LM Studio endpoint

The default endpoint is:

```text
http://127.0.0.1:1234/v1
```

This endpoint works with models hosted directly on the same computer and models exposed through LM Link. For a direct LAN connection, the remote LM Studio server must listen on the network and allow inbound TCP port 1234.

On Windows, override the endpoint with the `LMSTUDIO_BASE_URL` environment variable or the PowerShell launcher's `-Endpoint` parameter. On macOS, update `LMSTUDIO_URL` in the launcher script and the provider `base_url` in the LM Studio profile.

## Benchmarks

Both benchmarks used `qwen/qwen3-coder-next`, the prompt `Write a 100-word essay about machine learning`, and a 256-token output limit through LM Studio's `/v1/chat/completions` endpoint.

| Platform | Model format | Response time | Average response time | Throughput | Average throughput |
|---|---|---:|---:|---:|---:|
| Mac Studio M1 Ultra, 128GB | MLX | 3.10–4.22s | 3.46s | 34.12–44.84 tokens/s | 43.41 tokens/s |
| Intel NUC 12, RTX 4070 SUPER, 64GB | GGUF Q4_K_M | 12.66–14.74s | 13.58s | 11.33–13.01 tokens/s | 11.97 tokens/s |

### Mac Studio

The Mac Studio measurements were recorded on 2026-08-02 with GPU offload enabled. MLX quantization was controlled by LM Studio and the macOS runtime.

### Windows 11

The Windows measurements were recorded on 2026-08-15 from five measured requests after one warm-up request. LM Link was disabled to ensure the model ran on the NUC. LM Studio used its CUDA 12 `llama.cpp` backend, GGUF Q4_K_M quantization, eight GPU-offloaded layers, and a 32,768-token loaded context. The five measured responses generated 811 completion tokens.

### Reproduce the benchmark

macOS:

```bash
python3 -c "
import requests, time
url = 'http://127.0.0.1:1234/v1/chat/completions'
payload = {'model': 'qwen/qwen3-coder-next', 'messages': [{'role':'user','content':'Write a 100-word essay about machine learning'}], 'max_tokens': 256}
start = time.time(); response = requests.post(url, json=payload); data = response.json()
elapsed = time.time() - start
print(f'{elapsed:.2f}s, {data[\"usage\"][\"completion_tokens\"] / elapsed:.2f} tokens/s')
"
```

Windows:

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

Results vary with model quantization, GPU offload, context size, background load, and whether LM Link routes the request to another device.

## Technical details

### Platform components

| Platform | Launcher | Desktop integration | Profile manager |
|---|---|---|---|
| macOS | `Codex Launcher.app` | Dock/Finder application | `scripts/config-manager.sh` |
| Windows 11 | `windows/Codex-Launcher.ps1` and `windows/codex-launcher.cmd` | Start menu/taskbar shortcut | `scripts/config-manager.ps1` and `scripts/config-manager.cmd` |

### Profile isolation

The standard profile uses the normal Codex home directory:

- macOS: `~/.codex`
- Windows: `%USERPROFILE%\.codex`

The LM Studio profile uses a separate Codex home:

- macOS: `~/codex-config/codex-home-lmstudio`
- Windows: `%USERPROFILE%\codex-config\codex-home-lmstudio`

The isolated profile does not copy the normal Codex authentication state. Before starting the LM Studio session, the launcher removes common OpenAI and Codex API-token environment variables from the child process.

The generated provider configuration uses an OpenAI-compatible provider:

```toml
model = "qwen/qwen3-coder-next"
model_provider = "lmstudio-local"

[model_providers.lmstudio-local]
name = "LM Studio"
base_url = "http://127.0.0.1:1234/v1"
wire_api = "chat"
requires_openai_auth = false
```

### Launch sequence

When the LM Studio profile is selected, the launcher:

1. Queries `/v1/models`.
2. Removes embedding and reranking models from the picker.
3. Prompts for a chat model.
4. Sends a minimal request to `/v1/chat/completions`.
5. Writes the model and provider to the isolated `config.toml`.
6. Starts Codex with the isolated `CODEX_HOME`.

On Windows, the launcher resolves the installed `OpenAI.Codex` AppX package and starts its registered `ChatGPT.exe`. If Codex is already running, the launcher asks permission to restart it so the selected environment takes effect. Logs are written to `%USERPROFILE%\codex-config\codex-launcher.log`.

On macOS, the application bundle launches the Codex executable embedded in the installed desktop app and uses native AppleScript dialogs for profile and model selection.

### Profile management

The profile managers support:

```text
list
create <name>
switch <name>
export [file]
import <file>
show
edit
```

Use `scripts/config-manager.sh` on macOS or `scripts\config-manager.cmd` on Windows.

### Repository layout

```text
Codex Launcher.app/        macOS application bundle
windows/                   Windows launcher, installer, icon, and example configuration
scripts/                   macOS and Windows profile managers
assets/                    Shared source artwork
```

## License

MIT
