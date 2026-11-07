# Updating from upstream (ublue-os/image-template)

This repo tracks [ublue-os/image-template](https://github.com/ublue-os/image-template)
via a two-branch model:

- `template` — mirrors upstream exactly. Never edit directly.
- `live` — your customizations, rebased on top of `template`. This is what CI builds from.

## Check for upstream changes

```bash
git fetch upstream
git log template..upstream/main --oneline
```

If this is empty, you're already up to date — stop here.

## Review what changed (optional but recommended)

```bash
git diff template upstream/main -- .github/workflows/build.yml
git diff template upstream/main -- Justfile
```

Swap the path to inspect any other file you care about before pulling it in.

## Pull the update in

```bash
# fast-forward template to match upstream
git checkout template
git merge --ff-only upstream/main
git push origin template

# rebase your customizations on top
git checkout live
git rebase template
```

Resolve any conflicts (`git status` shows affected files), then:

```bash
git add <resolved files>
git rebase --continue
```

## Push the result

```bash
git push --force-with-lease origin live
```

`--force-with-lease` is expected here — you're rewriting `live`'s history via rebase.
It's safe because it refuses to push if someone else changed `live` since your last fetch.

## After pushing

- Confirm the build workflow runs successfully on `live` (Actions tab)
- Spot-check `IMAGE_NAME` / `IMAGE_REGISTRY` env handling wasn't touched by the rebase
- If `cosign.pub` or signing steps changed upstream, verify signing still works before
  rebasing any real machines onto the new image
