# ffmpeg-decklink

A nix flake to easily build ffmpeg with decklink support on Linux or MacOS.

Tested on x86\_64-linux and aarch64-darwin (Apple Silicon)

## Setup

1. [Install Nix](https://nixos.org/download/) (the package manager, not the OS)
2. Enable nix-command and flakes by running
   ```
   mkdir -p ~/.config/nix/ && \
   echo 'experimental-features = nix-command flakes' >>~/.config/nix/nix.conf
   ```
3. Run one of the `nix run`/`nix shell` commands below to start the compilation

## Usage

You can run ffmpeg with the following command:
```sh
NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:half-duplex/ffmpeg-decklink -- --help
```

Or enter a shell where `ffmpeg` refers to this version:
```sh
NIXPKGS_ALLOW_UNFREE=1 nix shell --impure github:half-duplex/ffmpeg-decklink
ffmpeg --help
```

## Updating

### Flake

Add `--refresh` after `--impure` in any of the above commands to grab the
latest changes to this repo.

### ffmpeg

1. Download or clone this repo
2. If needed, choose which [branch](https://wiki.nixos.org/wiki/Channel_branches)
   you prefer and update flake.nix
3. Run `nix flake update`
4. Run one of the above `nix run` or `nix shell` commands again to start the
   rebuild, replacing `github:…` with the `path/to/the/flake/`

### DeckLink SDK

ffmpeg 7.1 doesn't seem to support SDK 14.4, but if support for >12.9 is added:
1. Update the `version` and `downloadId` variables, and set `outputHash = "";`
2. Try to build the flake (any `nix run/shell/build`)
3. Put the hash in the error message into `outputHash`
4. Try to build again


## Notes

- `--impure` is required to allow `NIXPKGS_ALLOW_UNFREE=1` to affect the build.
- There are probably a lot of sub-optimal things here, I'm not great at nix. Comments/PRs welcome.
