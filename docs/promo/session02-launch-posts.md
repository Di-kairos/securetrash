# Launch posts — securetrash v0.3.0

> Драфты для раскрутки. **Постит Mr. Di сам.** Не накручивать, не спамить, по одному
> сабреддиту за раз, отвечать в комментах. Ссылка везде: https://github.com/Di-kairos/securetrash

---

## 1. Show HN

**Title:**
```
Show HN: securetrash – an honest secure-delete CLI that admits rm -P can't shred SSDs
```

**URL:** `https://github.com/Di-kairos/securetrash`

**Body (first comment):**
```
I kept seeing "secure delete" tools promise to overwrite files so they're
unrecoverable. On modern SSDs that's a lie: wear leveling, copy-on-write and
TRIM mean the original bytes can survive in unmapped flash cells no matter how
many times you "overwrite" the logical file. `rm -P` gives you no guarantee.

securetrash is my attempt at a tool that doesn't pretend. Two ideas:

1. It tells you the truth in its own output — overwriting is best-effort, not
   a guarantee, and it says so.
2. The actual protection is crypto-shred: you keep secrets in an encrypted
   AES-256 vault (a macOS sparsebundle). When you destroy it, you destroy the
   key — the data becomes unrecoverable noise instantly, regardless of what the
   flash controller did with the bytes.

Commands: check, setup, empty, shred <path>, vault create|open|close|destroy.

It's pure Bash, zero runtime dependencies — I wanted a security tool you can
read top to bottom in one sitting. macOS is stable; there's a Windows
PowerShell port in beta (passes tests + CI, not yet validated on real
BitLocker hardware — testers welcome).

  brew install Di-kairos/tap/securetrash

Tests: bats 19/19 + Pester 35/35, shellcheck clean, CI on macOS + Windows.

Happy to hear where the threat model is wrong — that's the part I care most
about getting right.
```

---

## 2. r/privacy

**Title:**
```
I built a secure-delete CLI that refuses to lie about SSDs — real protection is crypto-shred, not overwriting
```

**Body:**
```
Most "secure erase" tools sell you on overwriting a file N times so it can't be
recovered. On an SSD that's largely theater: wear leveling and copy-on-write
mean the controller writes your "overwrite" to a *different* physical cell and
leaves the original sitting in flash until TRIM/garbage-collection maybe gets
to it. You have no control over when, or whether, that happens.

So I wrote securetrash around an honest threat model:

- Overwriting is presented as best-effort, never a guarantee. The tool says so
  in its own output instead of hiding it.
- The real mechanism is crypto-shred. You store sensitive files in an encrypted
  AES-256 container. Destroying the container destroys the key, and ciphertext
  without a key is just noise — unrecoverable immediately, no matter what the
  SSD did with the physical blocks.

It's a small, dependency-free Bash CLI (macOS stable, Windows port in beta),
MIT licensed, source readable end to end. Open about its limits in the README.

I'd genuinely like this group to poke holes in the threat model:
https://github.com/Di-kairos/securetrash
```

---

## 3. r/macapps

**Title:**
```
[OC] securetrash — tiny macOS CLI for honest secure deletion (FileVault + encrypted vault, brew install)
```

**Body:**
```
Made a small command-line tool for macOS secure deletion. The angle: it doesn't
pretend overwriting shreds files on an SSD (it can't reliably). Instead it leans
on what actually works on a Mac — FileVault plus an encrypted AES-256 vault
(sparsebundle) for crypto-shred. Destroy the vault, the key's gone, data's gone.

Commands: check, setup, empty, shred, vault create/open/close/destroy.

  brew install Di-kairos/tap/securetrash

Pure Bash, no dependencies, MIT. There's a Windows port too but it's still beta.
Feedback and "this is dumb because X" both welcome:
https://github.com/Di-kairos/securetrash
```

---

## 4. r/commandline

**Title:**
```
securetrash: a zero-dependency Bash secure-delete CLI you can actually read
```

**Body:**
```
Shipped a secure-delete tool written in pure Bash — zero runtime dependencies,
because I think a security tool should be readable top to bottom by eye rather
than trusted as a black box.

The interesting design constraint: it refuses to claim that overwriting shreds
files on SSDs (it doesn't, thanks to wear leveling / COW / TRIM). So instead of
a fake `rm -P` shredder, the core is crypto-shred via an encrypted AES-256
vault — destroy the container, destroy the key, done.

  check · setup · empty · shred <path> · vault create|open|close|destroy

Tested with bats (19/19) + shellcheck clean, CI on macOS. Windows PowerShell
port in beta with Pester. MIT.

https://github.com/Di-kairos/securetrash — critique on the Bash and the threat
model both welcome.
```

---

## Posting notes (для Mr. Di)

- **Не постить всё разом.** По одному за раз, день-два между, отвечать в комментах живьём.
- r/privacy и HN — самые строгие к самопиару: заходить честно («I built / I wrote»), не дропать ссылку и убегать.
- r/macapps любит тег `[OC]` для своих проектов.
- На HN лучшее окно — будни, утро PT. Title без хайпа, факт — иначе флаг.
- Везде главный нарратив: **разоблачение мифа**, не «ещё один шреддер».
