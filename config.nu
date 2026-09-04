# config.nu
#
# Installed by:
# version = "0.115.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

$env.config.show_banner = false

# source ($nu.data-dir | path join "completions" "cargo" "cargo-completions.nu")
# source ($nu.data-dir | path join "completions" "gh" "gh-completions.nu")
# source ($nu.data-dir | path join "completions" "git" "git-completions.nu")
# source ($nu.data-dir | path join "completions" "tree-sitter" "tree-sitter-completions.nu")
# source ($nu.data-dir | path join "completions" "winget" "winget-completions.nu")

$env.HTTP_PROXY = "http://127.0.0.1:25563"
$env.HTTPS_PROXY = "http://127.0.0.1:25563"
$env.ALL_PROXY = "http://127.0.0.1:25563"
$env.http_proxy = $env.HTTP_PROXY
$env.https_proxy = $env.HTTPS_PROXY
$env.all_proxy = $env.ALL_PROXY

# `def --wrapped awk [...args: string] {}`, from git bash, ready to use
def --wrapped awk [...args: string] {
    ^r#'C:\Program Files\git\usr\bin\awk.exe'# ...$args
}

# `def --wrapped sed [...args: string] {}`, from git bash, ready to use
def --wrapped sed [...args: string] {
    ^r#'C:\Program Files\git\usr\bin\sed.exe'# ...$args
}

# def clipEx [cmd: closure] {
#     let result = try {
#         do $cmd
#     } catch {|err|
#         $err
#     }

#     let prompt = ($env.PROMPT_COMMAND | do $in | str trim)
#     let command = ($cmd | to nuon --serialize | str trim | str replace --regex '^"\{(.*)\}"$' '$1')
#     let output = ($result | to text | ansi strip | str trim)

# $"($prompt)
# > ($command) | clip
# ($output)
# " | clip
# }

# `which-noise-filtered `: filtered `which` for terminal session-start context.
# Hides noisy vendor tool suites (Windows Kits\Debuggers, Windows Performance
# Toolkit -- ~43 entries) and stray WindowsApps consumer-app shims, but keeps
# cdb/windbg (used for full memory dump analysis) and winget.
def which-noise-filtered [] {
    let keep = [cdb.exe, windbg.exe]
    let drop = [MediaPlayer.exe, microsoftstore.exe, SnippingTool.exe]
    which
    | where type not-in [built-in keyword]
    | where path !~ 'C:\\WINDOWS'
    | where {|r| ($r.command in $keep) or ($r.path !~ 'Windows Kits') }
    | where command not-in $drop
}
