# Deploying playwright-cli

## Install the CLI

```bash
npm install -g @playwright/cli@latest
```

The global binary lands at the npm prefix, e.g. `$HOME/AppData/Local/Zed/node/node-v24.11.0-win-x64/playwright-cli.cmd` (Zed's bundled Node, your path may differ).

## Install browsers

```bash
playwright-cli install
```

This downloads FFmpeg and Winldd, and detects an existing system Chrome. Skip if you only need the system browser.

To add Playwright's own Chromium/Firefox/WebKit:

```bash
playwright-cli install-browser chromium
playwright-cli install-browser firefox
playwright-cli install-browser webkit
```

## Proxy (if behind one)

Set the env var before running any commands:

```bash
export PLAYWRIGHT_MCP_PROXY_SERVER="http://127.0.0.1:<port>"
```

Without this, Chromium ignores bash's env `HTTP_PROXY` / `HTTPS_PROXY` and may connections time out.

## Verify

```bash
playwright-cli --version    # e.g. 0.1.15
playwright-cli open https://example.com
```
