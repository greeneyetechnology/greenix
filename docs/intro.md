# Introduction to Nix
- The What
- The Why
- The How

> I am assuming a feature called `flakes` is enabled, even though it is still in experimental phase.

---

# What is Nix?
Nix in its essense, is an idea. The idea to declatarativley and reliably reproduce systems.

---

# But really... what is it?
Its complicated...

---

# Nix is, but it isnt

- Nix is the Package Manager.
- Nix is the Language.
- Nix is the Operating System.

however...

- The Nix Package manager isn't the Language
- The Nix Language isn't the Operating system
- The Nix Operating System is not the Package Manager


---

# Nix The Package Manager
The nix Package Manager is not that different...

$ sudo apt install vim

$ nix profile install nixpkgs#vim

If you really wanted to, you could use nix almost the same as any other package manager.

> Keep in mind this is what's called the "imperative" way of using nix,
> which in the nix community is considered bad practice.

---

# Nix The Package Manager
The nix Package Manager is **somewhat** different...

$ **sudo** apt install vim

$ nix **profile** install **nixpkgs**#vim

The sudo, the profile and the nixpkgs

> Nix have a daemon running in the background which means you don't have to escalate privileges.

> You can install a package to different profiles
> A profile can be your user profile, my user's profile or any idea of what a profile is.
> You can quickly switch between profiles too.

> nixpkgs, is us saying explicitly, where this package is coming from.

---

# What can Nix do?

> $ vim
> vim: command not found

> $ nix shell nixpkgs#vim
> $

> $ vim --version
> VIM - Vi IMproved 9.0 (...)

Nix lets us create **Ephemeral** shells.

We can also achieve this with

`nix run nixpkgs#vim -- --version`

This will load the package, run the command and throw it away.

---

# Cool but... nixpkgs?

nixpkgs is a repository, the largest repositry of nix packages and nixos modules, hosted on GitHub.

> The way nixpkgs works, is it holds `closure` for each package,
> you can imagine closure as the entire dependency graph that is needed to build a single piece of software.
> That entire closure, is what nixpkgs modules are.
> You could override that graph, like change the compiler, from llvm to gcc
> but that would change this nixpkgs module completley, and see it as a whole new vim package.

Nixpkgs is the repositry with the most amount of fresh packages in the world! with more than 120,000 unqiue packages and growing!

So everytime you pull a package from nixpkgs, you compile it from source?

> Not really, the way the Nix maintainers setup nixpkgs,
> is they have a cache server, so if atleast 1 person (or automated bot) built a package,
> it will be cached in the server, so unless you use nixpkgs unstable or applied your own patches to a package,
> most packages should be cached already.

---

# Development

Lets say you want to contribute to nixpkgs, or any repository (even self hosted) that holds nix modules

> $ nix develop nixpkgs#vim

> $ unpackPhase && cd source

> $ vim
> vim: command not found

> $ make && make test

> $ vim --version
> VIM - Vi IMproved 9.0 (...)

You can basically enter a development environment tailored for the package you want. then make changes, and compile from source using the same tools used to compile the original package!

You can commit this back to upstream (make a PR!) and when you are done, throw away this whole environment.

---

# Storage is full!

Because of the way nix works, you might end up with a lot of unused garbage. similar to how docker handles this, you can call a sort of garbage collector to clean up every package / module that is not referenced by your profile!

> $ nix store gc
> 203 store paths deleted, 723.85 MiB freed

This way you can keep your system clean, only holding onto the packages you actually currently using.

---

# Step further

So the nix package manager gives you not only the ability to get software, but takes it a step further and lets you
- Install software
- Test software out without comitting
- Develop for software

---

# Nix the Programming Language

Nix is also a full, functional programming language

```nix
fun = { pkgs.myList }:
pkgs.lib.reverseList myList

fun { pkgs = pkgs
      myList = [ 1 2 3 ]; }
```

> [ 3 2 1 ]

---

# Language made for packaging?

Every single nix package, is basically a function that takes parameters.

```nix
{ lib, fetchFromGitHub }: # lib and fetchFromGitHub functions are coming from nixpkgs
rec { # recursive set (lets us reference values within the same set)
  version = "9.0.0601";

  src = fetchFromGitHub { # where to get the package from fetchFromGitHub is a nice utility function from nixpkgs
    owner = "vim";
    repo = "vim";
    rev = "v${version}";
    hash = "sha256-...="; # have to define a hash, there are ways to build without but it will be impure!
  };
};
```

> The hash of a nix package is the input attributes and the build steps that we take.
> If we change anything in the inputs or the build steps, the entire hash changes.
> This means we can (almost) always backtrack how a package was built.

In a few lines of code, we defined how we build something and where it can get it from.

The reasons this is extremeley valuable, compared to `apt` for example, when you install something, you just pull binary blobs someone uploaded, with nix you still pull binary blobs (most of the time) but you can always go check how it was built and even verify yourself by checking that after you built it you get the same output (hash).

---

# Nix the Operating System

The Operating System is nothing more than a package in nixkgs!

What is Linux? We take source code, we apply some build steps to it and we get a binary that we happen to run.

However, it goes a step further and it gives us a nice interface to also configure that operating system!

---

# NixOS configuration

Instead of just building linux, and then imperativley applying changes like `sudo adduser yarok` we can define these changes using Nix!

```nix
users.users.yarok = {
  isNormalUser = true;
  home = "/home/yarok";
  description = "Development user";
  extraGroups = [ "wheel" "networkmanager" ];
  openssh.authorizedKeys.keys = [ "..." ];
};
```

Now when we call `nixos-rebuild switch` it will build this configuration and apply it. The nice thing about NixOS is that every change to your configuration generates a new hash for your config, so you have a history from your first build, that you can always switch back to.

---

# NixOS configuration

This interface that NixOS gives us is not just limited creating users and all your system administration stuff, it let's you do pretty much everything you can do on a linux system, like configuring services:

```nix
services.prometheus.exporters.node = {
  enable = true;
  port = 9100;
  enabledCollectors = [ "logind" "systemd" ];
  disabledCollectors = [ "textfile" ];
  openFirewall = true;
}; 
```

---

# But we have Ansible...

Yes, this seems very much like what we already do with tools like Ansible.

But remember, the way Nix works is inherently different.
- Ansible requires an existing infrastructure to function.
- Nix basically just compiles software.

> Nix is looking at software packaging as programming
> with traditional packages, you write some code, compile it and gets an output you can run
> nix follows the same route, you write your configurtation as code, build it and get an output you can run.
