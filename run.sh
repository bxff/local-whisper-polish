#!/bin/bash
# Start MLX server with Qwen3-4B for SuperWhisper grammar polish
# Usage: ./run.sh

pip install -q mlx-lm 2>/dev/null
exec mlx_lm.server --model mlx-community/Qwen3-4B-Instruct-2507-4bit --port 8080
