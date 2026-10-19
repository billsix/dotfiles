# Git notes — techniques worth keeping

A personal, growing cheatsheet of the less-obvious git moves. Not basics — the
things that are easy to forget the exact spelling of. Append freely; each entry is
*what it does* + *an example* + *when / gotcha*. Started 2026-10-12 (William
Emerison Six <billsix@gmail.com>).

Cross-references to this setup: `.gitconfig` already defines `git lg` (graph log),
`git dw` (word-diff), and `git squash <base> [msg]` (= `reset --soft <base> &&
commit`); `commit.gpgsign = true`, `rebase.autoStash = true`, `pull.ff = only`.

---

## Rewriting history

### `git rebase <base> --exec '<cmd>'` — run a command after every replayed commit
Rebases `<base>..HEAD` and runs `<cmd>` once **after each** commit is applied. If
`<cmd>` fails (nonzero exit) the rebase stops right there, so it doubles as a
"bisect-while-rebasing" — e.g. build/test each commit.

```sh
# Re-sign every commit since master (amend each in place, keep its message):
git rebase master --exec 'git commit --amend --no-edit -S'

# Prove every commit on this branch builds:
git rebase master --exec 'make test'
```

- `--no-edit` keeps the message; `-S` forces a GPG signature (needed because a plain
  amend does not re-sign). This is the fix for "the commits got made unsigned."
- Order doesn't matter: `git rebase --exec '<cmd>' <base>` is the same.
- With `rebase.autoStash = true` (already set) a dirty tree is stashed/popped
  around it automatically.

### `git commit --amend --no-edit -S` — re-sign / fixup the top commit only
Same as above but just for `HEAD`. Use when only the last commit needs signing or a
tiny staged fixup folded in without a new commit.

### Squash a range into one commit — two ways, both non-interactive
```sh
# (a) your alias — soft-reset to the base, then one commit:
git squash origin/master "epix figure migration"

# (b) explicit, when you want to rebuild on a scratch branch first:
git reset --soft origin/master && git commit -m "..."
```
`reset --soft` moves the branch pointer back but **keeps the index and working tree**,
so all the intervening changes are already staged as one — no diff is lost. Verify
with `git diff` against the pre-squash state (see "Prove a rewrite changed nothing").

**In a Git LFS repo, `--soft` is the squash that works** — not `--hard`, not an
interactive rebase. `--soft` does **no working-tree checkout**, so the LFS smudge
filter never runs and a not-yet-downloaded LFS object (a big `*.hdr`/`*.bin`) can't
abort the squash. `--hard` and rebase *do* check out the tree and will "crap out"
naming the LFS file if its object isn't cached or the remote is unreachable (see the
gotcha below). This is how the OpenGL port squash got unstuck (2026-10-19).

### `git cherry-pick -n <parent>..<end>` — replay a range of commits without committing
`-n`/`--no-commit` applies each commit's diff into the index but doesn't commit, so a
range collapses into one staged set you then commit once. The safe way to lift
"just this task's commits" onto another branch.

```sh
git checkout -b port-branch target-base
git cherry-pick -n goodwork~5..goodwork   # the 5 commits, staged, uncommitted
git commit -F /path/to/msg.txt
```

- `<parent>..<end>` is **exclusive** of `<parent>` — use `~1` of the first commit you
  want, not the first commit itself.
- `git cherry-pick` has **no `-q`** flag (unlike most porcelain) — it's chatty.

## Signing (GPG)

- `commit.gpgsign = true` signs normal commits automatically. An **amend** or a
  **rebase** does NOT re-sign unless you pass `-S` (hence the `--exec` recipe above).
- In a headless/no-TTY shell (a sandbox, CI) signing fails with no pinentry.
  `bin/gitGPGsign` (`export GPG_TTY=$(tty)`) points gpg at the terminal; source it
  before committing in a fresh shell. If there's genuinely no agent, the escape hatch
  is `git -c commit.gpgsign=false commit ...` (or `git commit --no-gpg-sign`) then
  re-sign later with the `--exec` rebase.
- **The exact symptom: a commit "craps out" with `gpg: signing failed: Timeout`**
  (right after `PINENTRY_LAUNCHED ... gnome3:curses`). Pinentry launches but there's
  no interactive TTY to type the passphrase into, so it times out and `git commit`
  dies with `fatal: failed to write commit object`. **This is what breaks a
  squash/rebase in a container:** with `git squash` / `reset --soft`, the
  `reset --soft` *succeeds* (branch pointer moved to the base, every change left
  staged as one commit) and only the *commit* fails — so the fix is just to redo the
  commit (do NOT re-reset), either after `source bin/gitGPGsign` or unsigned with
  `git commit --no-gpg-sign`, then optionally re-sign with the `--exec` rebase.
  Always `git branch backup-xyz` first; the half-done state is fully recoverable from
  it. (William Emerison Six <billsix@gmail.com>, 2026-10-19)
- Inside the Claude Code sandbox, the auto-approval classifier blocks `--no-gpg-sign`
  / `-c commit.gpgsign=false` as a security-weakening action, so the agent can't
  commit unsigned on its own — it has to ask you to authorize that specific commit (or
  you run it yourself in a terminal where pinentry works).
- Check what's signed: `git log --show-signature` (or `%G?` in a `--format`: `G`=good,
  `N`=none, `B`=bad).

## Applying / moving changes

### `git checkout <ref> -- <paths>` — pull specific files from another commit/branch
Restores just those paths from `<ref>` into the working tree + index, leaving
everything else alone. The surgical "revert only these files to how they were at
<sha>" — much safer than a whole-tree reset.

```sh
git checkout abc123 -- book/figures/epix/_scene2d.py   # one file, back to abc123
```
(Newer syntax: `git restore --source=abc123 --staged --worktree <paths>`.)

### `git merge --ff-only <branch>` — advance only if it's a clean fast-forward
Moves the current branch to `<branch>` iff no merge commit is needed; refuses (no-op)
otherwise. The honest "promote my finished branch onto master" that won't silently
create a merge.

### `git add --chmod=+x <paths>` — stage a file *and* set its executable bit
Records mode `100755` in the index even if the working-tree file is 644. Needed after
rewriting a committed script (a full-file rewrite drops `+x`), so the committed script
stays runnable.

## Inspecting / verifying

### Prove a rewrite changed nothing — `git diff` or `git range-diff`
After a squash/rebase, confirm you didn't lose or alter content:
```sh
git diff rebuilt-branch backup-branch        # empty tree-diff = identical end state
git range-diff origin/master..backup origin/master..rebuilt   # per-commit comparison
```
`range-diff` is the better tool when you *reordered/squashed* commits: it lines up the
old and new series and shows what moved, so "I squashed 6 into 3 and kept every line"
is checkable at a glance.

### Harvest a commit range for a write-up
```sh
git log --format='=== %h %s%n%b' <base>..HEAD      # subjects + bodies, to read
git log --stat --format='### %h %s' <base>..HEAD   # + files touched per commit
```
Used to reconstruct the decision history into a task doc before squashing it away.

### Misc
- `git branch -vv` — branches with their upstream + ahead/behind counts in one view.
- `git lg` (your alias) — the graph log; add a range or `--all`.
- `git dw` (your alias) — word-level diff, good for prose/doc changes.

---

## Gotchas learned the hard way

- **A multi-line `-m` fights the shell.** Under zsh especially, `git commit -m` with
  embedded newlines/quotes mis-parses. Write the message to a file and use
  `git commit -F msg.txt`.
- **`:Z` mount relabeling can "poison" a repo** shared between host and container
  (SELinux relabel breaks the other side's access). Don't bind-mount a git repo with
  `:Z` if the host also uses it.
- **Backup before a history rewrite.** `git branch backup-xyz` first; a rewrite is
  only safe because you can `git reset --hard backup-xyz`.
- **`git reset --hard` / `rebase` can "crap out" on a Git LFS file** (symptom: an error
  naming a tracked binary, e.g. `Binaries/doge2.hdr`). Those commands check out the
  working tree, which runs the LFS *smudge* filter: it swaps each 133-byte pointer for
  the real object, fetching from the LFS remote when it isn't cached — and that fails
  offline / with no reachable remote. Fixes: squash with `reset --soft` (no checkout →
  no smudge); or, when you genuinely need the checkout, skip the smudge with
  `GIT_LFS_SKIP_SMUDGE=1 git reset --hard ...` (leaves pointers in the worktree) and
  `git lfs pull` later. **The committed 133-byte pointer is the CORRECT LFS state, not
  a destroyed file** — the real bytes live in `.git/lfs/objects/`; confirm with
  `git lfs ls-files` (a `*` = object present) and `git lfs fsck`. `.gitattributes`
  says what's LFS (here `*.hdr`/`*.bin filter=lfs`). (William Emerison Six
  <billsix@gmail.com>, 2026-10-19)
