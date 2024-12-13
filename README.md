# greenix
A repository for greeneye utilities configuration, doubles as a flake input.

## Prerequisites
General requirements, some are optional but recommended.
> NOTE: for `nix` users see the [nix section](#nix)
- [coreutils](https://formulae.brew.sh/formula/coreutils)
    - If installing using brew on MacOS add the gnubin to PATH after installation
        ```bash
        # change to .bashrc if using bash
        echo 'export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"' >> ~/.zshrc
        ```
- [vault](https://developer.hashicorp.com/vault/install?product_intent=vault)
- [tailscale](https://tailscale.com/download)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

Optional:
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [fd](https://github.com/sharkdp/fd) - faster, parallelized find alternative
- [ripgrep](https://github.com/BurntSushi/ripgrep) - multithreaded grep

## Installation
Clone the repository:
```bash
git clone https://github.com/greeneyetechnology/greenix ~/greenix
```
Add the `bin` directory in the repo to your PATH:
```bash
# change to .bashrc if using bash
echo 'export PATH="$HOME/greenix/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Usage
gssh
```
$ gssh --help
Usage: gssh [OPTIONS] [PATTERN]

SSH into a Greeneye device using Tailscale.

Options:
  -h, --help                    Show this help message and exit
  --ignore-certificate          Skip certificate validation
  -i, --identity-path PATH      Path to SSH identity file (default: ~/.ssh/greeneye_id_ed25519)
  -u, --user USER               SSH user (default: yarok)
  -e, --ssh-extra-args ARGS     Additional SSH arguments (default: -Y -A)

Arguments:
  PATTERN                       Optional pattern to filter device selection

Examples:
  gssh                          # Select from all available devices
  gssh robot                    # Filter devices containing 'robot'
  gssh -u admin robot           # Connect as 'admin' user to device containing 'robot'
```

gkx
```
$ gkx --help
Usage: gkx [options] [pattern]

A tool to quickly switch between kubeconfig contexts using tailscale

Options:
  -h, --help    Show this help message and exit

Arguments:
  pattern       Optional pattern to filter available contexts
```

## Nix
This repository is designed to be used as a flake input:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    greenix.url = "github:greeneyetechnology/greenix";
    greenix.flake = false;
  };
  outputs = { nixpkgs, greenix, ... }: {
    homeConfigurations = {
      "username@hostname" = nixpkgs.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./greeneye.nix
        ];
        extraSpecialArgs = {
          inherit greenix;
        };
      };
    };
  };
}
```
And the `greeneye.nix` module for the requirements:
```nix
# greeneye.nix
{ pkgs, greenix, ... }:
{
  home.packages = with pkgs; [
    fd
    ripgrep
    tailscale
    azure-cli
    kubectl
    gawk
    fzf
    coreutils
    vault
  ];
  home.file = {
    ".local/bin/greeneye" = {
      source = "${greenix}";
      recursive = true;
    };
  };
  home.sessionPath = [
    "${greenix}/bin"
  ];
}
```
This will add the `bin` directory to your PATH, if it doesn't register the commands, log out and back in from your account.
