# Add workflow settings and aliases to `.gitconfig`

**Status:** proposed — needs go-ahead
**Priority:** 4 **Difficulty:** 1
**Created:** 2026-11-22 (William Emerison Six <billsix@gmail.com>)

## BLUF

Add eight groups of settings to `.gitconfig`. They suit a workflow of linear, curated history, squashing,
GPG signing and prose diffs:

- conflict display and remembered resolutions;
- better diffs;
- a verbose commit editor;
- sorting;
- signed tags;
- push conveniences;
- object checking on fetch;
- more log aliases.

Done means:
- they are in `.gitconfig`, merged into its existing sections (one `[tag]`, one `[push]`, one `[alias]`);
- `git config --list` parses the file;
- each setting works in a scratch repo (see Verification).

Two suggestions the maintainer did not choose (rebase autoSquash/updateRefs, and the large-repo speed
settings) are recorded at the end with what they would have done.

## Context

- The file is `.gitconfig` at this repo's root (github.com/billsix/dotfiles), installed as `~/.gitconfig`.
- Settings it already has, which the new ones fit beside:
  - `pull.ff = only`, `commit.gpgsign = true`, `rebase.autoStash`, `fetch.prune`, `push.default = simple`;
  - the `lg`, `squash` and `dw` aliases;
  - the `format` and `am` settings for emailed patches.
- The file mixes tab and space indentation. Indent new lines with a tab, as git writes them.
- **Minimum git versions:** `zdiff3` needs 2.35 and `push.autoSetupRemote` needs 2.37. The sandbox has
  2.56.1. Check `git --version` on each machine that uses these dotfiles (Fedora, macOS with Homebrew,
  Gentoo); an older git warns about or ignores an unknown value.

## The settings to add

### 1. Conflicts show the base; resolutions are remembered

```ini
[merge]
	conflictStyle = zdiff3
[rerere]
	enabled = true
```

- **`merge.conflictStyle = zdiff3`.** A conflict hunk normally shows only "ours" and "theirs". `zdiff3`
  adds a third section, `||||||| base`, with the text as it was before either side changed it. You can
  then see what each side *changed* rather than guessing from two results. The "z" means lines that both
  sides share at the edges are moved out of the conflict, so the hunk is as small as possible.
- **`rerere.enabled = true`** ("reuse recorded resolution"). When you resolve a conflict, git records the
  conflicted hunk and your fix in `.git/rr-cache`. The next time the same conflict appears, git applies
  your fix automatically. That happens when you rebase the same branch again, redo a squash, or re-merge
  after an abort.
  - The file is left unstaged, so you still review it and `git add` it.
  - `git rerere forget <path>` drops a recording that turned out wrong.

### 3. Better diffs, especially for moved code

```ini
[diff]
	algorithm = histogram
	colorMoved = default
	colorMovedWS = allow-indentation-change
```

- **`diff.algorithm = histogram`.** The default (Myers) diff finds a minimal edit, but it often matches
  lines that mean nothing on their own, such as blank lines and lone `}`. That splits one real change into
  several confusing hunks. Histogram prefers to anchor on rare, unique lines, so changes come out in the
  blocks a human would draw. It affects `diff`, `log -p`, `show`, and also merges.
- **`diff.colorMoved = default`.** Lines that were moved, deleted in one place and added unchanged in
  another, get their own colours instead of red and green. A refactor that relocates a function reads as
  a move, and the real edits stand out.
- **`diff.colorMovedWS = allow-indentation-change`.** A moved block still counts as moved when only its
  indentation changed, for example code moved into or out of a nested function or `if`.

### 4. The commit editor shows the diff

```ini
[commit]
	verbose = true
```

- **`commit.verbose = true`.** When `git commit` opens Emacs for the message, the staged diff appears
  below the message template, as if `git commit -v` were used. The diff is below the scissors line and is
  not part of the message.
- It is merged into the existing `[commit]` section beside `gpgsign = true`.

### 5. Version-aware tag order, recent-first branches, columns

```ini
[tag]
	sort = version:refname
[branch]
	sort = -committerdate
[column]
	ui = auto
```

- **`tag.sort = version:refname`.** `git tag` normally sorts names as strings, which puts `v0.0.10`
  before `v0.0.7`, so the newest release is not at the end. This sorts them as versions. It is the
  versions-are-not-strings rule from the runClaudeInContainer conventions, applied to git.
- **`branch.sort = -committerdate`.** `git branch` lists the most recently committed branch first, instead
  of alphabetically.
- **`column.ui = auto`.** On a terminal, `git branch`, `git tag` and `git status`'s untracked list are laid
  out in columns like `ls`. Piped output stays one item per line. This works with the existing
  `pager.branch = false`.

### 6. Tags are signed, like commits

```ini
[tag]
	gpgSign = true
```

- **`tag.gpgSign = true`.** `git tag <name>` makes a GPG-signed annotated tag, as `git tag -s` does, and
  opens the editor for the tag message.
  - Commits are already signed, but tags are what other people verify for a release, such as impo's `v*`
    tags that start its release workflow.
  - `git tag -v <name>` checks a signature.
- **Gotcha:** a quick lightweight tag now needs `git tag --no-sign <name>`.
- In the same sandbox batches that turn off `commit.gpgsign`, also turn this off, or a batch that tags
  will fail.
- It shares one `[tag]` section with `sort` from item 5.

### 7. Pushing without the setup steps

```ini
[push]
	autoSetupRemote = true
	followTags = true
```

- **`push.autoSetupRemote = true`.** The first `git push` of a new branch creates the branch on the remote
  and sets it as the upstream, so `git push -u origin <branch>` is no longer needed. It works with the
  existing `push.default = simple`.
- **`push.followTags = true`.** `git push` also pushes the *annotated* tags that point at the commits being
  pushed, so `git tag v0.0.1 && git push` publishes the tag too.
  - Lightweight tags and tags on other commits stay local.
  - With item 6 every new tag is annotated, so they all qualify.
- **Gotcha:** origin (the Pi box) and github are separate remotes, and each push sends the tags to only the
  remote it targets.

### 8. Fetched objects are checked

```ini
[transfer]
	fsckObjects = true
```

- **`transfer.fsckObjects = true`.** Every object received by `fetch`, `pull`, `clone` or a push you
  receive is checked for corruption and malformed data before git accepts it. Problems include broken
  trees, bad timestamps, and paths with `..` or `.git` that a crafted repository can use to attack a
  client. A failing fetch is refused, so bad objects never enter the repository.
- It does **not** judge whether a valid commit is trustworthy; signatures (`merge.verifySignatures`) do
  that.
- **Gotcha:** some old public repositories contain harmless malformed objects, such as zero-padded file
  modes from ancient tools, and a fetch from them fails. Allow a specific problem for that repository with
  `fetch.fsck.<msg-id> = ignore` in its `.git/config`. The error message names the `<msg-id>`.

### 10. More log aliases, in the style of `lg`

```ini
[alias]
	lga = lg --all
	lgs = log --graph --pretty=format:'%C(auto)%h %G? %d %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
	last = log -1 --stat
	unstage = restore --staged --
	fixup = "!f() { git commit --fixup=$1 && git rebase -i --autosquash $1~; }; f"
```

- **`lga`.** The `lg` graph for every branch and remote-tracking branch, not just the current one. Use it
  to see how branches diverge, or what a fetch brought in next to your work.
- **`lgs`.** A graph line with the signature status `%G?` after the hash:
  - `G` good, `U` good but untrusted key, `N` none, `B` bad;
  - `E` cannot check (the key is missing), `X` or `Y` expired signature or key, `R` revoked key.

  It shows unsigned or suspicious commits at a glance. It runs gpg once per commit, so it is slow on long
  histories; limit it, e.g. `git lgs -30` or `git lgs origin/master..`.
- **`last`.** The last commit with its list of changed files and line counts.
- **`unstage`.** `git unstage <path>` takes a file out of the index and leaves the working-tree change
  alone. It is the plain-English form of `git restore --staged`.
- **`fixup`.** `git fixup <sha>` commits the staged changes as a `fixup! <subject of sha>` commit and then
  starts an interactive rebase from just before `<sha>`, with the fixup already placed under its target.
  Save and quit Emacs to fold it in.
  - `--autosquash` is passed explicitly, so this works without the `rebase.autoSquash` setting that was
    not chosen.
  - It opens the rebase editor, so it is for a terminal session.
  - Don't use it on commits that are already pushed somewhere others pull from.
- Add these to the existing `[alias]` section beside `lg`, `squash` and `dw`, indented with tabs.

## Plan

1. Merge the blocks above into `.gitconfig`. Add new keys to existing sections (`[commit]`, `[push]`,
   `[alias]`) rather than repeating the section headers, and give `[tag]` both `sort` and `gpgSign`.
2. Check that it parses: `git config --file .gitconfig --list`.
3. Run the Verification steps in a scratch repo, with `GIT_CONFIG_GLOBAL=$PWD/.gitconfig` so the
   installed `~/.gitconfig` is not touched.
4. Stage `.gitconfig` and this task.

## Verification

In a scratch repo using the new file:

- `git config --get merge.conflictStyle` prints `zdiff3`. A conflicting merge shows a `|||||||` section.
- After resolving and aborting, the same merge again prints `Resolved '<file>' using previous resolution`
  (rerere).
- `git diff` on a moved function shows the move colours.
- `git commit` shows the diff in the editor.
- With tags `v0.0.7` and `v0.0.10`, `git tag` lists `v0.0.10` last.
- `git tag t1` asks for a message and `git tag -v t1` reports a good signature. This needs gpg in the
  environment; if it is missing, check `git config --get tag.gpgSign` only and say so.
- `git push` to a local bare repo sets the upstream and sends an annotated tag.
- `git lga`, `git lgs -5`, `git last`, `git unstage <f>` and `git fixup <sha>` (with `GIT_SEQUENCE_EDITOR=:`)
  each run.

## Suggested but not chosen

The maintainer chose 1, 3–8 and 10 on 2026-11-22. These two were left out; this is what each would have
done.

### 2. Rebase autoSquash and updateRefs (not chosen)

```ini
[rebase]
	autoSquash = true
	updateRefs = true
```

- **`rebase.autoSquash = true`** would make every `git rebase -i` place each `fixup!` / `squash!` /
  `amend!` commit under its target and mark it to fold in, without passing `--autosquash`.
  - The chosen `fixup` alias (item 10) passes `--autosquash` itself, so it does not depend on this.
  - Only a plain `git rebase -i` started by hand would have used it.
- **`rebase.updateRefs = true`** would let a rebase move any other branch pointing at a commit being
  rewritten. With stacked branches (feature-2 built on feature-1), rebasing feature-2 would bring
  feature-1 along, instead of leaving it on the old commits.

### 9. Large-repository speed settings (not chosen)

```ini
[feature]
	manyFiles = true
[fetch]
	writeCommitGraph = true
```

plus `git maintenance start` run once in each large repository.

- **`feature.manyFiles = true`** would turn on `index.version = 4` (a smaller index that stores paths with
  shared prefixes once) and `core.untrackedCache = true` (git remembers which directories have not
  changed, so `git status` skips rescanning them). That makes `status` and `add` noticeably faster in
  trees with tens of thousands of files, like impo's OpenStax content.
- **`fetch.writeCommitGraph = true`** would update the commit-graph file after each fetch. It is a
  precomputed index of commit parents and dates that makes `log --graph` (and so `lg`), `merge-base` and
  ahead/behind counts much faster in long histories.
- **`git maintenance start`** would register the repository for scheduled background upkeep through a
  systemd timer, launchd or cron:
  - an hourly prefetch of the remotes into a hidden ref namespace, so a real `fetch` has little left to
    do;
  - commit-graph updates;
  - repacking loose objects daily or weekly;
  - all without the long pauses of a foreground `gc`.
