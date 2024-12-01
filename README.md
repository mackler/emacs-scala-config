# Emacs Configuration for Scala I.D.E.

Inspired by Robert Krahn’s [Emacs configuration for Rust](https://github.com/rksm/emacs-rust-config),
the example configuration given in
[the official Metals Emacs instructions](https://scalameta.org/metals/docs/editors/emacs/#installation), and the [java_emacs](https://github.com/neppramod/java_emacs) configuration of [Pramod Nepal](https://github.com/neppramod).

Includes configuration settings according to my personal preferences, such as:

- Displaying line numbers
- Disabling tabs in favor of spaces
- Auto-reloading buffers when files are changed outside Emacs
- Running `scalafmt` automatically when saving a buffer
- And more

See the referenced sources for more usage details.

## Uses Helm

This setup uses Helm, so if you're not used to it you will be surprised when searching for a file to open works differently than you expect.  In particular `M-x` is bound to `helm-M-x` and `C-x b` is bound to `helm-buffers-list`.

Use `C-c h` to see more helm commands.

[Read more about it here.](https://emacs-helm.github.io/helm/)

`C-x c` shows some Helm options.

## Useful key combinations:

### Language Server Protocol

Control the LSP server with `C-c l` (lowercase L for LSP).  It brings up a menu that shows the keys for the options. For workspaces type `w`, and from there you can start, restart, and shutdown the LSP server.

Or, instead of typing `w` for workspaces, use `g` as in "goto" for finding declarations, definitions, implementations, references and more, depending on what's under the text cursor.

Some popular options have even shorter shortcuts.  For example
`C-c l G g` will peek at the definition of the identifier at the text cursor but so will `M-.`

Ctrl-Clicking on a symbol (left mouse button) goes to the definition of the symbol under the text cursor (not what's under the mouse pointer).

#### LSP Sessions

Currently, when you quit emacs, all LSP workspaces will be closed.  This means you will have to import them again the next time you open the project.

I automated this removal because of issues with LSP paying attention to sessions I wasn't working on, and showing me errors I wasn't interested in.  You can clear all the projects from LSP manually with: `M-x lsp-workspace-remove-all-folders` but I was doing that so often I just made it automatic.  If removing workspaces automatically this way causes problems then I might revert to the default of workspaces persisting until you remove them even after emacs exits.

You can see all the current sessions with:

```elisp
(lsp-session-folders (lsp-session))
```
To remove just one project, use: `(lsp-workspace-folders-remove session-folder)`

## Projectile

Projectile enables searching throughout the project in various ways.  To get to the options type `C-c p` which shows the further options.  For example, type `f` to search for a file.

## Debugging

Type `F-5` to start the debugger.

Type `M-9` to see project errors in a separate buffer.

By default, the following windows auto show on debugging when in dap-ui-auto-configure-mode:

* sessions
* locals
* breakpoints
* expressions
* controls
* tooltip

For more configuration details, see the [DAP Mode documentation](https://emacs-lsp.github.io/dap-mode/page/configuration/).

## Project Explorer

Opten the file explorer with `M-x treemacs`.  Treemacs has a separate idea of the project root than LSP, so you must load it separately into the file explorer.

Within the Treemacs buffer `C-c C-p` shows options for adding and removing projects from the file explorer: `a` to add, `d` to delete, and so on.

Treemacs shows other tree representations of your projects.  For example:

* `M-x lsp-open-treemacs-symbols` displays symbols information
* `M-x lsp-treemacs-references` shows references for the symbol at cursor
* `M-x lsp-treemacs-implementations`  show the implementations for the symbol at cursor

## Running Emacs

Here is an example command script to start Emacs in Scala-IDE mode:

```bash
#!/usr/bin/env sh
emacs --no-init-file --load /usr/local/repos/emacs-scala-config/init.el $@ &
```

## Conclusion and Summary

Use at your own risk and pleasure.