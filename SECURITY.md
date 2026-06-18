# Security Policy

securetrash is a security tool, so its own correctness matters. If you find a
vulnerability, please report it responsibly.

## Reporting a vulnerability

**Do not open a public issue for an exploitable vulnerability.**

Use GitHub's private vulnerability reporting:

1. Go to the repository's **Security** tab → **Report a vulnerability**
   (<https://github.com/Di-kairos/securetrash/security/advisories/new>).
2. Describe the issue, affected versions, and a reproduction if possible.

You'll get a response as soon as reasonably possible. Once a fix is ready, the
advisory is published and you'll be credited unless you prefer to stay anonymous.

## Scope

In scope:

- Anything that causes securetrash to **claim a guarantee it does not provide**
  (the project's whole point is honesty about secure deletion).
- Vault handling: password exposure, weak container creation, unsafe destroy.
- Path handling in `shred` / `empty` that could delete unintended files.
- Privilege or injection issues in the shell / PowerShell code.

Out of scope:

- The documented limitations of overwriting on SSDs (that's the honest premise,
  not a bug — see the README and `docs/blog/`).
- Leaks from an **open** vault via Spotlight / swap / Time Machine / cloud sync
  that are already documented as limitations (improvements welcome as features).

## Supported versions

The latest released version receives security fixes. securetrash is pre-1.0;
older tags are not maintained.
