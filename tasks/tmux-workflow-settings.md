# Add Emacs- and container-friendly settings to `.tmux.conf`

**Status:** in progress: item 11 done 2026-11-22; items 1–10 wait until it is committed
**Priority:** 4 **Difficulty:** 1
**Created:** 2026-11-22 (William Emerison Six <billsix@gmail.com>)

## BLUF

Add eleven settings to `.tmux.conf`, **item 11 first, on its own** (the maintainer's order, 2026-11-22: do
item 11, stage it, and after that is committed do items 1–10). Item 11 shows the full program title, such
as emerge's `(2 of 15) category/package` progress, in the status bar. Two of the others fix things the
current config means to do but doesn't:
- the pane-border label is never shown;
- Emacs can't be sent `C-t`.

The other eight fit how the config is used:
- tmux runs `emacs -nw`;
- it is mounted into the project containers;
- the terminals are Alacritty and iTerm2.

Done means the settings are in `.tmux.conf`, a fresh tmux server loads it with no errors, and each setting
behaves as described in Verification.

## Context

- The file is `.tmux.conf` at this repo's root (github.com/billsix/dotfiles), installed as `~/.tmux.conf`.
- The project Makefiles mount it into their containers (`-v ~/.tmux.conf:/root/.tmux.conf`). So it also
  runs inside containers, sometimes under a tmux on the host that uses the same prefix.
- **What it has now:**
  - `mouse on`;
  - prefix `C-t`, which keeps `C-b` (backward-char) for Emacs;
  - a blue status bar with `{user@host}` on the left;
  - `default-terminal "xterm-256color"`;
  - 1-based windows and panes, and `renumber-windows on`;
  - `history-limit 4000`;
  - a `pane-border-format`;
  - windows shown as only their number.
- The terminals: `configs/.config/alacritty/alacritty.toml`, and iTerm2's `configs/iterm2/Default.json`.
- **tmux versions differ by machine:** the sandbox has 3.8; macOS gets its tmux from Homebrew; Fedora and
  Gentoo use their packaged versions. The defaults quoted below were read from tmux 3.8 with
  `tmux -L probe -f /dev/null start-server \; show -sg escape-time` (and similar).

## The settings to add

### 1. Send the prefix through to Emacs or a nested tmux

```
bind C-t send-prefix
```

- With the prefix on `C-t`, Emacs never receives `C-t` (transpose-chars): tmux takes it first.
- This binding makes `C-t C-t` send one `C-t` to the program in the pane. When that program is a tmux
  inside a container (under a tmux on the host with the same prefix), `C-t C-t` is how you reach the inner
  one. For example, `C-t C-t c` opens a window in the inner tmux.

### 2. Show the pane-border labels

```
set -g pane-border-status top
```

- The config already sets `pane-border-format "#P: #{pane_current_command}"`. tmux draws that format only
  when `pane-border-status` is `top` or `bottom`, and it defaults to `off`, so today the label never
  appears.
- With this, every pane has a title line naming its number and its running command, e.g. `2: emacs`.
- The line takes one row per pane. A window with a single pane shows it too.
- **Decision:** the label keeps the command name `#{pane_current_command}`, not the program's title.
- **Alternative, not chosen:** `pane-border-format "#P: #{pane_title}"` would show each pane's own title
  (e.g. emerge's progress) along the top of that pane. With several panes, each shows its own, whereas the
  status bar (item 11) shows only the active pane's. Not chosen because shells, Emacs and ssh also set
  titles, often long ones, so every border would carry noise. The command name is short and always
  meaningful. Switch to it if you often watch titles in inactive panes, or combine both:
  `"#P: #{pane_current_command} #{pane_title}"`.

### 3. Pin a short escape-time so Meta keys are not delayed in Emacs

```
set -sg escape-time 10
```

- When tmux receives Esc, it waits `escape-time` milliseconds to see whether it starts a longer sequence.
  Terminals send Meta (Alt) as Esc followed by the key, so a long wait makes `M-x`, `M-f` and friends in
  `emacs -nw` feel sticky, and can split them into a bare Esc and a letter.
- tmux 3.8 already defaults to 10 ms. Older releases defaulted to 500 ms, so setting it explicitly keeps
  every machine the same, including a Mac or Gentoo box running an older tmux.

### 4. The right terminal type and 24-bit colour

```
set -g default-terminal "tmux-256color"
set -as terminal-features ",alacritty*:RGB,xterm-256color:RGB"
```

- **`default-terminal`** sets `TERM` inside tmux.
  - `tmux-256color` describes tmux itself: italics, the "standout" and dim attributes, and some key
    sequences. `xterm-256color` describes a different terminal, so programs sometimes draw italics as
    reverse video or misread keys. tmux 3.8's own default is `tmux-256color`; the current line overrides
    it.
  - **Gotcha:** the machine needs a `tmux-256color` terminfo entry, which the sandbox has. macOS's system
    ncurses is old and may not include it. If `infocmp tmux-256color` fails there, install the entry
    (Homebrew's `ncurses`, or `tic` from the ncurses source) or keep `xterm-256color` on that machine.
- **`terminal-features ... RGB`** tells tmux that the outer terminal (Alacritty, or iTerm2, which reports
  `xterm-256color`) supports 24-bit colour, so tmux passes it through.
  - Without it, tmux maps every colour to the nearest of 256, and Emacs themes such as `material` look
    washed out or banded.
  - In Emacs, `M-x list-colors-display` shows the full range when it works.

### 5. Much more scrollback

```
set -g history-limit 50000
```

- Each pane keeps this many lines of scrollback for copy mode and mouse-wheel scrolling. tmux's default
  is 2000 and the config has 4000, which is roughly one podman build or one `make test` run.
- 50,000 lines costs a few megabytes per pane at most, and only for panes that fill it.
- It applies to panes created after the setting is loaded.

### 6. Let programs inside tmux set the system clipboard

```
set -g set-clipboard on
```

- tmux can set the terminal's clipboard with the OSC 52 escape sequence. That works over ssh and inside
  containers, where there is no X or Wayland clipboard to talk to.
- tmux 3.8's default, `external`, already sends a **copy-mode** selection to the terminal clipboard.
- `on` adds one thing: **programs running inside tmux** can set it too. Examples are Emacs with an OSC 52
  package (`clipetty`), a shell `printf '\e]52;c;…\a'`, or a remote tool. tmux both stores the text as a
  buffer and forwards it to the terminal.
- **Gotcha:** the terminal must allow OSC 52. Alacritty allows copying by default. In iTerm2, enable
  Settings → General → Selection → "Applications in terminal may access clipboard".
- **Security:** any program in a pane can then overwrite the clipboard (not read it).

### 7. New panes and windows open in the current directory

```
bind '"' split-window -v -c "#{pane_current_path}"
bind %   split-window -h -c "#{pane_current_path}"
bind c   new-window      -c "#{pane_current_path}"
```

- By default a new pane or window starts in the directory the session was created in.
- These rebind the standard split keys (`"` stacks panes vertically, `%` side by side) and new-window to
  start in the directory of the pane you are in. Splitting while in `hanoi/python/src/hanoigame` gives a
  shell already there.
- The keys stay the same; only the starting directory changes.

### 8. Reload the config with one key

```
bind r source-file ~/.tmux.conf \; display-message "~/.tmux.conf reloaded"
```

- `C-t r` re-reads the config in the running server and confirms in the status line, so a change can be
  tried without killing every session.
- Most settings take effect at once. A few apply only to new panes or windows: `history-limit`, and a
  `default-terminal` change.
- Removing a line does not undo its effect until the server restarts, because sourcing only applies what
  the file says.

### 9. Pass focus events to Emacs

```
set -g focus-events on
```

- tmux tells the program in a pane when the pane gains or loses focus, with the escape sequences terminals
  use for window focus. The default is `off`.
- Emacs (29 and later, in a terminal) runs its focus hooks. Those check visited files for changes made
  outside Emacs, such as a `git checkout`, a build, or an agent editing files, and reload or warn on
  return. Packages that save on focus loss or dim unfocused windows also use them.

### 10. The terminal window title shows where you are

```
set -g set-titles on
set -g set-titles-string "#{user}@#H: #{pane_current_command}"
```

- tmux sets the outer terminal's window title, as seen in the Alacritty title bar, iTerm2's tab and window
  title, and the desktop window switcher. It shows the user@host from the status bar plus the running
  command, e.g. `root@3f2a9c1e: emacs`.
- In a container the host is the container ID, so you can tell from the switcher which window is in which
  container and what it is running.
- The default is `off`, which leaves whatever title the terminal or shell set.

### 11. Show the full pane title in the status bar (do this first)

```
set -g status-right "#{pane_current_command}: #{pane_title}  %H:%M %d-%b-%y"
set -g status-right-length 200
set -g status-left-length 40
```

- **The problem.** Programs set the terminal title with an escape sequence, and tmux stores it as the pane
  title (`#{pane_title}`). Gentoo's `emerge` does this through Portage's `xterm-titles` feature, on by
  default, with titles like `emerge: (2 of 15) dev-libs/foo-1.2 Compile`. The config never sets
  `status-right`, so tmux's default is used. On tmux 3.8 that default is
  `"#{=21:pane_title}" %H:%M %d-%b-%y`, with `status-right-length 40`:
  - the title is cut to 21 characters, which is why only "emerge (2 of " shows;
  - the whole right side is capped at 40 characters.

  The bar has plenty of free space, because the window list is only numbers, but none of it is used.
- **`status-right`** shows the active pane's running command, then the whole title, then the time and
  date.
  - The command name (`#{pane_current_command}`) is read from the process, so it is always there.
  - The title is there only when a program sets one. After item 11 first went in with the title alone,
    `glxgears` showed nothing about itself: it opens an X window and never sends a title. The command name
    was added for that case (William Emerison Six <billsix@gmail.com>, 2026-11-22).
  - During an emerge, "emerge" appears twice (`emerge: emerge: (2 of 15) …`), the cost of always showing
    the command. The default's quotes and its
  `window_bigger` offset prefix are dropped. The prefix only shows when the window is larger than the
  client, which a single-client setup never has.
- **`status-right-length 200`** raises the cap, so the title can use the free width.
  - tmux still shortens the right side if the bar runs out of room.
  - The status bar shows the **active** pane's title only.
  - Programs that don't set a title show the default, which is the hostname.
- **`status-left-length 40`.** The left side has the same problem: `status-left-length` defaults to 10, so
  `{user@host}` is cut whenever it is longer than 10 characters. `{bill@gentoo}` is 13, and a container's
  hostname is its 12-character ID. 40 fits both.
- **Alternatives considered:**
  - **Dropping the date:** `status-right "#{pane_title}  %H:%M"` leaves about 10 more columns for the
    title. The date was kept, as the default has it.
  - **A truncation limit instead of no limit:** e.g. `#{=80:pane_title}`, to keep a runaway title from
    pushing the clock off. Not chosen: `status-right-length` already bounds the right side, and tmux
    trims it to fit.
  - **The pane border instead of the status bar:** see item 2's alternative.
- **Done 2026-11-22.**
  - The three lines are in `.tmux.conf` after `status-left`.
  - On a scratch tmux 3.8 server (`-L check`): the file loaded with no errors, and the three options read
    back as set.
  - With the command name added, `#{T:status-right}` expanded to:
    - `zsh: 74345296a9e1  …` at an idle prompt (the title defaults to the hostname);
    - `sleep: 74345296a9e1  …` while a program that sets no title ran;
    - `sleep: emerge: (2 of 15) dev-libs/foo-1.2 Compile  …` after that pane set an emerge-style title.
  - A real `emerge` on a display is still for the maintainer to watch.
- **Verify:**
  - In a scratch server, `printf '\033]2;emerge: (2 of 15) dev-libs/foo-1.2 Compile\033\\'` in a pane sets
    the title.
  - `tmux -L check display -p '#{pane_title}'` shows it in full.
  - `tmux -L check show -g status-right-length` reports 200.
  - On a real display, `emerge` shows its whole progress line in the status bar.

## Plan

0. **Item 11 alone first:** add its three lines, verify, and stage. The maintainer commits that, then
   steps 1–4 do items 1–10.
1. Add the lines for items 1–10 to `.tmux.conf`:
   - replace `default-terminal "xterm-256color"` with item 4's two lines;
   - replace `history-limit 4000` with item 5's line;
   - group the key bindings (1, 7, 8) after the prefix line.
2. Load it in a scratch server: `tmux -L check -f .tmux.conf new-session -d \; show -g pane-border-status`.
   Any error in the file is printed.
3. Run the Verification steps. Use `-L check` throughout, so a tmux you have running is not touched.
4. Stage `.tmux.conf` and this task.

## Verification

In the sandbox (tmux 3.8), on a scratch server (`-L check`):

- The file loads with no errors. `show -g` reports:
  - `pane-border-status top`, `history-limit 50000`, `focus-events on`, `set-titles on`;
  - `set-clipboard on`, `escape-time 10`;
  - `default-terminal tmux-256color`.
- `list-keys` shows the four bindings: `C-t` send-prefix, `"`, `%` and `c` with `-c`, and `r`
  source-file.
- In a nested setup (tmux inside tmux, both with this file), `send-keys C-t C-t c` creates a window in the
  inner server.
- A split from a pane in a subdirectory starts in that directory: compare `display -p '#{pane_current_path}'`
  in the old and new panes.
- For the maintainer on a real display:
  - item 4: true colour in Emacs (`M-x list-colors-display`);
  - item 6: OSC 52 copies arriving in the desktop clipboard;
  - item 10: the window title.

  These need a real terminal; the sandbox has none.
