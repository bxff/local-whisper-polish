# Local Whisper Polish

> **Personal project** - A minimal MLX server menu bar app for grammar/text polishing with SuperWhisper on macOS.

## Prerequisites

```bash
# Install mlx-lm (requires Python 3.10+)
pip install mlx-lm
```

## Install WhisperPolish

### Option 1: Download Release

Download `WhisperPolish.app.zip` from [Releases](https://github.com/bxff/local-whisper-polish/releases).

Unzip and move to Applications:
```bash
unzip WhisperPolish.app.zip -d /Applications/
```

**Note:** The app is unsigned. On first run, right-click and select "Open", or run:
```bash
xattr -cr /Applications/WhisperPolish.app
```

### Option 2: Build from Source

```bash
git clone https://github.com/bxff/local-whisper-polish.git
cd local-whisper-polish/WhisperPolishApp
./build.sh
cp -r WhisperPolish.app /Applications/
```

## Usage

1. Launch WhisperPolish from Applications
2. A menu bar icon appears (gray = stopped, yellow = starting, green = running)
3. First launch downloads the model (~2GB) - check "View Logs" for progress
4. Once green, the server is ready at `http://localhost:8080`

## SuperWhisper Setup

1. Open SuperWhisper settings
2. Go to Advanced Settings sidebar -> AI Models
3. Add custom model:
   - **Provider**: `Custom`
   - **Name**: `Localhost`
   - **Model ID**: `mlx-community/Qwen3-4B-Instruct-2507-4bit`
   - **API URL**: `http://localhost:8080/v1`
   - **API Key**: `x`
4. Select "Localhost" in your Mode settings (Message, Custom, etc.)

## Features

- Native macOS menu bar app
- Status indicator: Gray (stopped), Yellow (starting), Green (running)
- Model selection with presets + custom model support
- Live log viewer
- Remembers your model selection

## Available Models

Select from the menu or enter any `mlx-community` model ID:

| Model | RAM | Notes |
|-------|-----|-------|
| `mlx-community/Qwen3-4B-Instruct-2507-4bit` | ~2GB | Default |
| `mlx-community/Qwen2.5-3B-Instruct-4bit` | ~1.5GB | Lighter |
| `mlx-community/Qwen3-8B-Instruct-4bit` | ~4GB | Higher quality |
| `mlx-community/gemma-3n-E4B-it-4bit` | ~3GB | Alternative |

Browse more: https://huggingface.co/mlx-community

## Requirements

- macOS 12+ with Apple Silicon (M1/M2/M3/M4)
- Python 3.10+

## Troubleshooting

**App shows yellow but never turns green:**
- Check "View Logs" for errors
- Ensure `mlx-lm` is installed: `pip install mlx-lm`

**Model download stuck:**
- Check internet connection
- First download can take several minutes
