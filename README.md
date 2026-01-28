# Local Whisper Polish

> **Personal project** - A minimal MLX server menu bar app for grammar/text polishing with SuperWhisper on macOS.

## Install

### Option 1: Download Release

Download `WhisperPolish.app.zip` from [Releases](https://github.com/bxff/local-whisper-polish/releases).

**Note:** The app is unsigned. On first run, right-click and select "Open", or run:
```bash
xattr -cr /Applications/WhisperPolish.app
```

### Option 2: Build from Source

```bash
# Install mlx-lm first
pip install mlx-lm

# Build the app
cd WhisperPolishApp
./build.sh

# Install
cp -r WhisperPolish.app /Applications/
```

## Features

- Native macOS menu bar app
- Status indicator: Gray (stopped), Yellow (starting), Green (running)
- Model selection with presets + custom model support
- Live log viewer
- Remembers your model selection

## Requirements

- macOS 12+ with Apple Silicon
- Python 3.10+ with `mlx-lm`:
  ```bash
  pip install mlx-lm
  ```

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

## Available Models

| Model | RAM | Speed |
|-------|-----|-------|
| `mlx-community/Qwen3-4B-Instruct-2507-4bit` | ~2GB | Fast |
| `mlx-community/Qwen2.5-3B-Instruct-4bit` | ~1.5GB | Faster |
| `mlx-community/Qwen3-8B-Instruct-4bit` | ~4GB | Better |
| `mlx-community/gemma-3n-E4B-it-4bit` | ~3GB | Good |
