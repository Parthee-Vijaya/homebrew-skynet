# homebrew-skynet

Homebrew tap til [S.K.Y.N.E.T.](https://github.com/Parthee-Vijaya/skynet).

## Installation

```bash
brew install Parthee-Vijaya/skynet/skynet
```

Første gang `tap`'es repoet automatisk. Efterfølgende installationer kan blot
bruge `brew install skynet`.

## Opdatering

```bash
brew update && brew upgrade skynet
```

## Idempotent én-linjer (installerer eller opgraderer)

```bash
brew update && brew upgrade skynet 2>/dev/null || brew install Parthee-Vijaya/skynet/skynet
```

## Nyeste main-branch (HEAD)

```bash
brew install --HEAD Parthee-Vijaya/skynet/skynet
```

## Services

Daemon (port 6767) som login-service:

```bash
brew services start skynet
```

Portal (port 3100):

```bash
nohup skynet-portal > ~/Library/Logs/skynet-portal.log 2>&1 &
```

## Afinstallation

```bash
brew services stop skynet
brew uninstall skynet
brew untap Parthee-Vijaya/skynet
```

## Frigiv ny version (vedligeholder)

1. Tag en ny release i `Parthee-Vijaya/skynet`, fx `v0.2.0`.
2. Hent SHA256:
   ```bash
   curl -fsSL https://github.com/Parthee-Vijaya/skynet/archive/refs/tags/v0.2.0.tar.gz \
     | shasum -a 256
   ```
3. Opdater `url` og `sha256` i `Formula/skynet.rb`.
4. Commit + push.
