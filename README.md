# Local Whisper Polish

Minimal MLX server for grammar/text polishing with SuperWhisper on macOS.

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

First run downloads the model (~2GB). Server runs on `http://localhost:8080`.

## SuperWhisper Setup

1. Open SuperWhisper settings
2. Go to Advanced Settings sidebar → AI Models
3. Add custom model:
   - **Name**: `Local MLX`
   - **Model ID**: `mlx-community/Qwen3-4B-Instruct-2507-4bit`
   - **API URL**: `http://localhost:8080/v1`
   - **API Key**: `x`
4. Select "Local MLX" in your Mode settings (Message, Custom, etc.)

## Alternative Models

Edit `run.sh` to use different models:

| Model | RAM | Speed |
|-------|-----|-------|
| `mlx-community/Qwen3-4B-Instruct-4bit` | ~2GB | Fast |
| `mlx-community/Qwen2.5-3B-Instruct-4bit` | ~1.5GB | Faster |
| `mlx-community/Qwen3-8B-Instruct-4bit` | ~4GB | Better |

## Requirements

- macOS with Apple Silicon
- Python 3.10+
