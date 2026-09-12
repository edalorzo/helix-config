# Helix configuration

My personal configuration for the [Helix](https://helix-editor.com) editor on macOS.
It lives in `~/.config/helix` and consists of:

| File | Purpose |
|---|---|
| `config.toml` | Editor settings: theme, relative line numbers, cursor shapes, indent guides, LSP display options, status line, auto-save on focus loss. |
| `languages.toml` | Per-language setup: language servers, formatters, debug adapters, and their settings. Everything below refers to this file. |
| `runtime/queries/` | Extra tree-sitter queries that Helix does not ship (currently Clojure textobjects). |

The rest of this document is a setup guide for a fresh machine: which programs each
language needs, how to install them, and what the configuration does with them.
Tools are installed with [MacPorts](https://www.macports.org) whenever a port exists.

## Setting up a new machine

1. Install Helix and clone this repository into place:

   ```sh
   sudo port install helix
   git clone git@github.com:edalorzo/helix-config.git ~/.config/helix
   ```

2. Install the tools for the languages you care about (sections below).

3. Check that Helix finds everything:

   ```sh
   hx --health                # overview of every language
   hx --health typescript     # one language: servers, formatter, debugger, grammars
   ```

   A red `✘` next to a program means it is not on `PATH`. Helix resolves commands through
   the `PATH` of the shell that starts it, so tools installed by MacPorts (`/opt/local/bin`)
   and npm globals must be visible there.

### PATH assumptions

Some tools are duplicated between package managers. The configuration assumes this order
of directories on `PATH`, first wins:

1. `~/.nvm/versions/node/<version>/bin` — npm global installs (Node managed by nvm)
2. `~/.local/bin` — hand-placed wrappers (only the ESLint workaround below)
3. `/opt/local/bin` — MacPorts
4. `/usr/bin` — Apple Command Line Tools

## Markdown

No external programs. The configuration enables soft wrapping at 80 columns.

## Go

**Install**

```sh
sudo port install go gopls
# Optional second diagnostics source:
sudo port install golangci-lint
go install github.com/nametake/golangci-lint-langserver@latest   # puts the binary in ~/go/bin
```

**Configuration**

- `gopls` is the language server for `.go` files and `go.mod`; both format on save.
- gopls is configured for gofumpt formatting, staticcheck, extra analyses (unused
  parameters and writes, nilness, shadowing), semantic tokens, placeholders in
  completions, code lenses (tidy, test, vulncheck, ...) and a chosen set of inlay hints.
- Diagnostics are shown down to hint severity.
- `golangci-lint-langserver` is defined but not attached to the language; add it to the
  Go `language-servers` list to enable it.

## Web: JavaScript, TypeScript, React, HTML, CSS, JSON, GraphQL

**Install**

Node and npm are managed with [nvm](https://github.com/nvm-sh/nvm); the language servers
are npm packages without MacPorts ports (MacPorts does have `typescript-language-server`
and `vscode-langservers-extracted`, but not the rest, so npm is used for all of them to
keep one Node runtime).

```sh
npm install -g typescript@6 typescript-language-server vscode-langservers-extracted \
  graphql-language-service-cli prettier @tailwindcss/language-server \
  @olrtg/emmet-language-server
```

Two things to know:

- **TypeScript must stay at major version 6.** TypeScript 7 is the native Go port and no
  longer ships `tsserver.js`, which `typescript-language-server` requires. Projects with
  their own `typescript` in `node_modules` are used in preference to the global one.
- **ESLint needs an older server.** `vscode-langservers-extracted` 4.9 and later ship an
  ESLint server that only supports LSP pull diagnostics, which Helix 25.07 does not
  implement, so it silently reports nothing. The last push-based release is installed in
  an isolated prefix and exposed under a distinct name:

  ```sh
  npm install --prefix ~/.local/lib/vscode-eslint-language-server-4.8 vscode-langservers-extracted@4.8.0
  ln -s ~/.local/lib/vscode-eslint-language-server-4.8/node_modules/.bin/vscode-eslint-language-server \
        ~/.local/bin/vscode-eslint-language-server-4.8
  ```

  When Helix gains pull diagnostics, switch the command back to
  `vscode-eslint-language-server` and delete that prefix.

**Configuration**

- `typescript-language-server` serves JS, JSX, TS and TSX with auto-import completions,
  function-call completion snippets, and inlay hints in "literals" mode (parameter names
  only for literal arguments). Toggle hints with `:toggle lsp.display-inlay-hints`.
- ESLint runs as a second server on JS/TS files using the project's own ESLint and its
  config; flat config (`eslint.config.*`) is auto-detected. Projects without ESLint get
  nothing. Fix-it and disable-rule code actions are enabled.
- `vscode-html-language-server` and `vscode-css-language-server` provide completion and
  validation. Unknown at-rules are ignored in CSS so Tailwind directives do not warn.
- `vscode-json-language-server` validates and completes JSON against SchemaStore schemas
  for `package.json`, `tsconfig.json`, Prettier, ESLint, Babel, Lerna, Turbo, Vercel,
  VS Code settings and web manifests. `tsconfig.json` is treated as JSON with comments.
- `graphql-lsp` serves `.graphql` files; it needs a `graphql.config.*` or `.graphqlrc*`
  in the project to know the schema.
- Tailwind and Emmet servers are attached to the web languages. Tailwind stays inert
  until a Tailwind config exists in the workspace.
- **Prettier formats every web language on save**, invoked as
  `prettier --stdin-filepath <file>` so it picks the parser and honours the project's
  `.prettierrc` and `.prettierignore`. It takes precedence over LSP formatting.

A Node debug adapter (`js-debug-dap`) was configured and verified but is currently kept
out of the repository (git stash "Javascript Debugger").

## Clojure

**Install**

```sh
sudo port install clojure leiningen clojure-lsp
```

Java comes from [SDKMAN](https://sdkman.io). Note that the MacPorts `clojure-lsp` port lags
upstream (2023.02.27 as of September 2026); it works fine with this configuration. If a
newer release is ever needed, the native `macos-amd64` zip from the
[clojure-lsp releases](https://github.com/clojure-lsp/clojure-lsp/releases) can be dropped
into a `PATH` directory instead.

**Configuration**

- `clojure-lsp` handles completion, navigation, hover, refactorings, semantic tokens, and
  diagnostics from both clj-kondo (bundled) and clojure-lsp's own analysis. The whole
  project is linted at startup.
- Format on save uses clojure-lsp's built-in cljfmt, which honours a project's
  `.cljfmt.edn`. No separate formatter is configured.
- `.edn` files share the language definition. `bb.edn` is a recognised project root.
- `runtime/queries/clojure/textobjects.scm` adds textobjects Helix lacks: `]f` / `[f`
  jump between `defn`-style forms, `maf` selects a whole form, `mif` selects its parameters
  and body, `mac` / `mic` work on comments.
- Per-project server settings: `.lsp/config.edn`. User-wide: `~/.config/clojure-lsp/config.edn`.
  Reference: <https://clojure-lsp.io/settings/>.
- There is no REPL integration in Helix; run `clj` or `lein repl` in a split terminal.

## C, C++ and CMake

**Install**

The Apple Command Line Tools provide clang, `clangd`, `clang-format` and `lldb-dap` at one
matching LLVM version, and the configuration uses them directly:

```sh
xcode-select --install          # if the Command Line Tools are missing
sudo port install cmake ninja neocmakelsp
```

`clang-format` and `lldb-dap` are not on `PATH`, so they are reached through `xcrun`,
which resolves the active Xcode or Command Line Tools toolchain.

MacPorts alternative: `sudo port install clang-21` gives `clangd-mp-21`,
`clang-format-mp-21` and `clang-tidy-mp-21`; swap the commands in `languages.toml` to use
them. `sudo port select --set clang mp-clang-21` provides unversioned names but also makes
`clang`/`clang++` on `PATH` point at MacPorts instead of Apple's compiler. MacPorts has no
current lldb port, so `lldb-dap` stays with the Command Line Tools.

**Configuration**

- `clangd` runs with background indexing, clang-tidy (configured via `.clang-tidy`
  files), include-what-you-use header insertion, and detailed completion with argument
  placeholders.
- Projects should provide a `compile_commands.json` at the root. With CMake:

  ```sh
  cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug
  ln -sf build/compile_commands.json .
  ```

  Files not covered by one (single-file exercises) fall back to
  `-std=c++23 -Wall -Wextra -Wpedantic`.
- `clang-format` formats on save and reads the nearest `.clang-format` walking up from the
  file; without one it uses LLVM style. Put a `~/.clang-format` in place for a personal
  default. Indentation is 4 spaces for C and C++.
- `lldb-dap` debug templates: launch a binary, launch with arguments, attach to a
  process id. `<space>g b` toggles a breakpoint, `<space>g l` launches.
- `neocmakelsp` serves `CMakeLists.txt` with completion, hover documentation, syntax
  diagnostics and format on save (indentation only).

## Python

**Install**

```sh
sudo port install python313 pyright ruff py313-debugpy
sudo port select --set python python313
```

MacPorts selects `python` and `python3` separately. This configuration launches the
debugger with `python`, so only that selection is required; `python3` may still point at
Apple's Python 3.9 without affecting Helix.

**Configuration**

- `pyright` provides type checking (standard mode), completion with auto-imports,
  navigation, hover and rename. Projects override settings with `pyrightconfig.json` or
  `[tool.pyright]` in `pyproject.toml`. Reference:
  <https://microsoft.github.io/pyright/#/settings>.
- `ruff server` provides linting with fix-it code actions and import organising. It is
  restricted to diagnostics, code actions and formatting so pyright owns hover, completion
  and go-to-definition. Project rules come from `[tool.ruff]` in `pyproject.toml` or
  `ruff.toml`; the defaults apply otherwise.
- **`ruff format` formats on save**, invoked with the file name so project settings apply.
- `debugpy` is the debug adapter, started as `python -m debugpy.adapter`. Templates:
  launch the current file, launch a module (default `pytest`), attach to a process started
  with `python -m debugpy --listen host:port`. When a project uses a virtualenv, debugpy
  must be importable by that interpreter (`pip install debugpy` into the venv).

## Verifying an installation

`hx --health <language>` shows whether each configured program was found. To see what a
server actually reports, start Helix with logging and open a file:

```sh
hx -vv path/to/file
tail -f ~/.cache/helix/helix.log
```

Errors from formatters and language servers appear in the log and in the editor via
`:log-open`.
