#!/usr/bin/env bash
# lib/config.sh — machine-specific configuration
# Override any value by exporting it before running init.sh

# Repository paths (override before running init.sh)
: "${MICHAEL_REPO:="/c/Dev/michael"}"
: "${CLOUD_NVIM_REPO:="/c/dev/cloud-nvim"}"

# External tooling (Grok MCP, opencode) — not read by init.sh lib scripts
: "${FORGEJO_MCP_PATH:="C:/dev/forgejo-mcp/forgejo-mcp-server.exe"}"
: "${FORGEJO_URL:="http://100.124.195.47:3000"}"

# Windows program roots (Unix-style paths for MSYS2)
: "${DOTNET_ROOT:="/c/Program Files/dotnet"}"
: "${AZURE_CLI_ROOT:="/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin"}"
: "${TAILSCALE_ROOT:="/c/Program Files/Tailscale"}"

# Zellij
ZELLIJ_MSI_URL='https://github.com/zellij-org/zellij/releases/download/v0.44.3/zellij-x86_64-pc-windows-msvc-installer.msi'
ZELLIJ_VERSION='0.44.3'
