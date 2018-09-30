# Archer

Opinionated set of scripts to install [Arch Linux](https://www.archlinux.org/).

The following creates a minimal installation, however you'll be prompted to
partition, format etc.

```console
# vim settings.sh
# make install
```

Additional steps can be automated, allowing for an unattended installation.

```console
# vim settings.sh

# # Queue scripts
# make platforms/x86_64-bios-single-partition
# make customizations/xfce
# make customizations/office

# # Install
# make install
```

These scripts are tailored to my 'standard' installation - you probably
don't want to run them as is.  With that said, they might serve as a good
starting point for your own systems.

## Table of Contents

* [Motivation](#motivation)
* [Usage](#usage)
* [Forking](#forking)
    * [Architecture](#architecture)
    * [I don't care how it works, what should I change?](#i-dont-care-how-it-works-what-should-i-change)

## Motivation

Arch Linux is pretty awesome, however getting started can be quite tedious.
By default, you're left with a very minimal environment, and customizing it
requires a fair bit of time spent looking at the
[wiki](https://wiki.archlinux.org/).  If you're in a rush, you might be
tempted to use some other, lesser distro.

Arch's installation process is lengthy because it aims to support a wide
variety of use cases.  In practice, however, I find that most of my systems
are quite similar.  These scripts aim to simplify the process.

Please note the goal of these scripts is not to create something robust or
beginner friendly, but to remove the tedium of 'standard' installations.
You're still expected to understand the installation process, and must be
able to resolve any errors that occur.

## Usage

1. Fill out settings.sh
2. Specify a target platform (optional)
    ```
    # make platforms/*
    ```
3. Specify any additional software (optional)
    ```
    # make customizations/*
    ```
4. Start the installation
    ```
    # make install
    ```
5. If an error occurs, manually correct and mark resolved
    ```
    # make continue install
    ```

A full list of supported 'platforms' and 'customizations' can be found in
their respective folders.

The scripts will 'show their work', and will halt on error.  Assuming
installation completes, a *lot* of text will be printed.  It probably isn't
necessary to read it.  Nonetheless, you may wish to record it, just in case
you need to reference it later.

```console
# script install.log
# make install
# exit
# mv install.log /mnt/
```

## Forking

### Architecture

#### install\_wrapper.sh

Used to run all installation scripts, it sources and validates
`settings.sh` and `working/chroot-settings.sh`.  Assuming no errors, it
then runs a script.  Intended to only be called by `make`.

#### settings.sh

Primarily used to set environment variables, though it can execute code.

#### /working/chroot-settings.sh

Contains the variables `chroot` and `chroot_user`.  Each serves as an alias
for some command that provides a bash shell.  They will likely use chroot
if the system is mounted, but could use SSH if running remotely (such as
for Arch Linux ARM).

The installation scripts (ab)use heredocs to pipe commands into the
'chroot'.  This kills syntax highlighting, but offers a simple way to
provide environment variables and command substitution to both chroot and
SSH.

#### /working/scripts/

Acts as a staging area for the scripts that will be executed by `make
install`.  The scripts should be prefixed with a number to enforce their
execution order.

#### /working/status/

Marks the progress of `make install`.  Once a script completes, a file with
an identical name will be created here by `make`.

#### /working/current\_target

Created by `make`, this file contains the name of the script currently
running.  Should the script fail, it's used by `make continue` to add an
entry to `/working/status/`.

#### /working/messages

The contents of this file are printed at the end of `make install`.
Scripts can add messages to remind the user to perform some action (such as
installing display drivers).

#### /customizations/

Each folder in this directory represents a group of scripts that can be
used to further automate an installation.  If selected, the folder's
contents are copied as-is into `/working/`.

#### /platforms/

This folder behaves identically to `/customizations/`; it was duplicated to
improve readability.  Each folder in this directory represents a common
system Arch might be installed on.  Currently only x86\_64 is supported,
but scripts for Arch Linux ARM will probably be included at some point.
These scripts should complete all actions outlined in
`/default/scripts/0x20-bootstrap.sh`.

#### /default/

Files in this folder will be copied by `make install` if they don't already
exist in `/working/`.  This way `make customizations/*` and `make
platforms/*` can override them assuming they were ran before `make
install`.

### I don't care how it works, what should I change?

#### /default/scripts/0x40-install.sh

1. Update the following sections:
    1. 'Set the Timezone'
    2. 'Setup Dotfiles'
    3. 'Setup neovim'
    4. 'Setup tmux'
    5. 'Setup tmuxinator'
2. Remove section 'Remap Caps Lock'
3. Section 'Setup SSH':
    1. Weaker crypto was disabled; undo this if you're planning to work
       with older SSH clients/servers
    2. **Remove my SSH key from ~/.ssh/authorized\_keys**

#### /customizations/xfce/scripts/0x60-xfce.sh

1. Note the name is somewhat misleading; Openbox and Compton are also
   installed.  They will replace xfwm if you use my dotfiles.
2. Remove section 'Remap Caps Lock'

#### /customizations/personal/scripts/0x80-personal.sh

1. Update to install whatever software you use on your workstations

