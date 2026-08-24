# .bashrc
export HTTPS_PROXY=http://127.0.0.1:25563

# playwright-cli
export PATH="$HOME/AppData/Local/Zed/node/node-v24.11.0-win-x64:$PATH"
export PLAYWRIGHT_MCP_PROXY_SERVER="http://127.0.0.1:25563"

alias curl='echo "NEVER CURL!" >&2; false'
alias ls='echo "NEVER LS!" >&2; false'
alias find='fd'
alias grep='rg'
