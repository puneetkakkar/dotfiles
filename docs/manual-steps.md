# Manual steps after `bootstrap.sh`

`bootstrap.sh` automates everything that's safe and idempotent. The steps
below cannot be automated either because they require secrets, interactive
prompts, or are tied to per-account state.

Order matters: do them top-to-bottom.

---

## 1. SSH key + GPG-via-SSH commit signing

Commits are signed with an SSH key. The key differs per machine (personal vs
work identity), so the tracked `.gitconfig` does not name one — it includes
`~/.gitconfig.local`, which you create on each machine.

```bash
# Pick the identity for THIS machine
KEY=~/.ssh/id_ed25519_personal          # personal machine
# KEY=~/.ssh/id_ed25519                 # work machine
EMAIL=pkakkar996@gmail.com              # or pkakkar@recovry.ai on work

# Generate the SSH key
ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY"

# Add to GitHub as an auth key, and again as a SIGNING key (they are separate)
gh ssh-key add "$KEY.pub" --title "$(hostname) auth"
gh ssh-key add "$KEY.pub" --title "$(hostname) signing" --type signing

# Point this machine's git at it (untracked, machine-local)
printf '[user]\n\tsigningkey = %s\n' "$KEY.pub" > ~/.gitconfig.local

# Allow local verification of your own signatures
echo "$EMAIL $(cat "$KEY.pub")" >> ~/.ssh/allowed_signers

# Load it into ssh-agent so signing doesn't hang waiting for the passphrase
ssh-add "$KEY"
```

Without `~/.gitconfig.local`, `commit.gpgsign = true` has no key and every
commit on that machine fails. To verify signatures made on your *other*
machine locally, append that machine's key line to `~/.ssh/allowed_signers`
too; otherwise its commits show as unverified locally (GitHub still verifies
them).

Test with: `git -C ~/recovry/repos/dotfiles log --show-signature -1`.

## 2. GitHub CLI auth

```bash
gh auth login
```

Choose GitHub.com, HTTPS, login via web browser. This populates `gh` creds
which `git push` then uses for HTTPS remotes.

## 3. Claude Code auth

Open a terminal, run `claude`, then inside the TUI:

```
/login
```

Follow the OAuth prompts in the browser.

## 4. Tmux plugins (resurrect + continuum)

Open tmux and press `prefix I` (capital I) to install plugins via TPM.
First run downloads `tmux-resurrect` and `tmux-continuum` into
`~/.tmux/plugins/`.

After installation, `~/.local/share/tmux/resurrect/` will start filling up
with auto-saved snapshots every 15 minutes.

## 5. Cloud / Kubernetes auths (when needed)

```bash
# AWS SSO
aws configure sso

# GCP
gcloud auth login

# Kubernetes context — depends on your cluster
# (kubectx / kubens are already installed via brew)
```

## 6. Optional — deploy preserved configs

`.vimrc` (Vundle-based) and `.config/nvim/` (Lua-based neovim) are stored
in this repo but **not** symlinked by default — they're preserved from
an earlier era of the setup, awaiting a polish pass.

When you're ready to use them, edit `bootstrap.sh` and uncomment the
`link_dotfile ".vimrc"` and `link_dotfile ".config/nvim"` lines (or
add them), then re-run `./bootstrap.sh` (idempotent — only changes the
two new symlinks).

For `.vimrc`: also install Vundle:
```bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
```

For `.config/nvim/`: just open `nvim`; lazy.nvim or whichever plugin
manager the config uses will install plugins on first launch.

## 7. Mac App Store apps (if any)

Anything tied to your Apple ID (Slack desktop, 1Password, etc.) needs
to be installed from the App Store — these aren't in the Brewfile.
