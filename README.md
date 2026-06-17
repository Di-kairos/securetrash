**English** · [Русский](README.ru.md)

# SecureTrash

Honest secure file deletion for macOS — no SSD snake oil.

[![CI](https://github.com/Di-kairos/securetrash/actions/workflows/ci.yml/badge.svg)](https://github.com/Di-kairos/securetrash/actions/workflows/ci.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS%2010.15%2B-blue)
![shellcheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)

![SecureTrash demo](demo/demo.gif)

## The problem

When you delete a file and empty the Trash, macOS just marks the space as free.
The data itself stays on disk until something overwrites it. Free tools like
**Disk Drill** or **PhotoRec** happily recover these "deleted" files. The Trash
isn't deletion — it's "out of sight."

## ⚠️ The honest truth about SSDs

> On modern drives, the classic advice to "overwrite the file N times" (`rm -P`,
> the old `srm`, "Secure Empty Trash") does **not** guarantee that your data is
> gone.
>
> The SSD controller decides which physical cells to write to: **wear leveling**
> spreads writes across the drive, **copy-on-write** in APFS writes new versions
> elsewhere, and **TRIM** frees blocks in the background on its own schedule. A
> command to "overwrite this file" never reaches the cells where your bytes
> actually lived.
>
> That's exactly why Apple **removed** `srm` and "Secure Empty Trash" back in
> OS X 10.11 El Capitan — they created a false sense of security.
>
> Most "secure shredders" stay quiet about this and sell overwriting as a
> guarantee. **We don't.**

## What actually protects you

1. **FileVault** — full-disk encryption. The foundation for everything. If the
   drive is encrypted, "deleted" blocks are just ciphertext with no key. This is
   your primary, mandatory layer.
2. **Crypto-shred via `vault`** — keep secrets inside an encrypted container
   (AES-256) from the very start, then destroy the container along with its key.
   The data becomes unrecoverable no matter where its blocks physically sit on
   the SSD.

The vault is **preventive**: it only protects what you create or place inside the
container. It cannot retroactively erase plaintext that already lived on disk
unencrypted — that's what FileVault is for.

## Install

Homebrew:

```bash
brew install Di-kairos/tap/securetrash
```

Or a one-line install via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/Di-kairos/securetrash/main/install.sh | bash
```

## Quickstart

Drop-folder workflow — for everyday deletion:

```bash
securetrash setup          # creates ~/SecureTrash, the sectrash alias, checks FileVault
securetrash check          # honest audit: FileVault + drive type + verdict
# drag the files you want gone into ~/SecureTrash
securetrash empty          # empty the folder (overwrite on HDD; on SSD see below)
```

Encrypted container workflow — for secrets (a real guarantee on SSD):

```bash
securetrash vault create   # creates ~/SecureVault.sparsebundle (AES-256), prompts for a password
securetrash vault open      # mounts the container at /Volumes/SecretVault
# work with your secrets inside /Volumes/SecretVault
securetrash vault close     # unmount — the data is encrypted again
securetrash vault destroy   # destroy the container + key (crypto-shred, irreversible)
```

## Commands

| Command | What it does |
|---|---|
| `securetrash check` | Audits FileVault and drive type, gives an honest verdict on guarantees |
| `securetrash setup` | Creates `~/SecureTrash`, installs the `sectrash` alias, warns if FileVault is off |
| `securetrash empty` | Securely empties `~/SecureTrash` |
| `securetrash shred <path>...` | Securely deletes a file or folder |
| `securetrash vault create\|open\|close\|destroy` | Encrypted container (AES-256) for crypto-shred |
| `securetrash version` | Prints the version |

## How it works

The vault is built on **crypto-shred** — erasure by destroying the key.

The container (`sparsebundle`) is encrypted with AES-256 from the moment it's
created: everything you put inside is written to disk as ciphertext. An open
container mounts as a regular volume at `/Volumes/SecretVault`; a closed one is
just an unreadable encrypted image.

When you run `vault destroy`, the container itself is destroyed along with its
encryption key. Without the key, the blocks left behind on the SSD are
mathematical noise — recovery tools can read them all day long and find nothing
meaningful.

That's the advantage over overwriting: you **don't need** to reach specific
physical cells (which is impossible on SSDs thanks to wear leveling and TRIM).
Destroying one tiny key renders the entire body of data meaningless at once.

## FAQ

**Can a file be recovered after `shred`?**
On an HDD, `shred`/`empty` makes several overwrite passes — that's effective. On
an SSD, overwriting is **not a guarantee** (wear leveling, COW, TRIM). For
secrets, rely on FileVault + `vault` instead of `shred`.

**Why `vault` instead of overwriting?**
Overwriting tries to scrub specific cells, but on an SSD you have no physical
control over where the controller writes. Crypto-shred sidesteps the problem: the
data is encrypted from the start, and destroying the key makes it unreadable no
matter where the blocks live.

**Does this work without FileVault?**
You won't have the base layer of protection. Without FileVault, "deleted" blocks
on an SSD may be recoverable. Turn FileVault on: System Settings → Privacy &
Security → FileVault. `securetrash check` will verify it.

**Is `vault destroy` safe?**
The operation is **irreversible**: the container and key are deleted for good.
That's why the command asks for explicit confirmation (you have to type `yes`).
After it runs, the data cannot be recovered.

## Disclaimer

This software is provided "as is," without warranty of any kind (see [LICENSE](LICENSE)).
Security depends on your environment:

- Make sure FileVault is on: `fdesetup status` (should read `FileVault is On.`).
- The `vault` is a **preventive** measure: it protects data created inside it and
  does not retroactively erase anything that already sat on disk unencrypted.
- On SSD/APFS, overwriting individual files offers no erasure guarantee — that's a
  fundamental property of the technology, not a limitation of this tool.
