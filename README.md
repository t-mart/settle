Tim Martin's Dotfiles
=====================

This project is a combination of:
* An installation procedure for placing [configuration files](http://en.wikipedia.org/wiki/Configuration_file) and running scripts.
* My actual configuration files and scripts to set up a system the way I like it. The most prominent configs are for vim and zsh (via [oh-my-zsh](../robbyrussell/oh-my-zsh)).

This project was forked from [ryanb's version](../ryanb/dotfiles), but little has survived.

Prerequisites
------------

To run the installation procedure you need:
* ruby
* rake

And optionally, my configurations are for this software:
* vim
* zsh
* GDM
* nethack

This project have been tested with Ubuntu 12.04, but I'd imagine it'd work on
any \*nix system.


Usage Notes
-----------

When you run `rake`, the process is as follows:

1. Run a pre-installation script called `PRE_INSTALL.sh`.
2. Link the configuration files in this directory to your $HOME as dotfiles.
3. Initialize and pull down submodules to the commit specified in `.gitmodules`.
   This is super useful if you want to retain the repo-ness of another project
   within this one.
4. Run the post-install script called `POST_INSTALL.sh`.

The pre/post install scripts are just shell scripts. If they don't exist, that's
okay.

To link a configuration file to your $HOME, it must not be hidden here (e.g.
`some_config`, NOT `.some_config`). The '.' will be prepended automatically.
This applies to folders too. Of course, this file and the pre/post install
scripts will not be linked.

Running `rake submodule:latest` will pull the latest commits of your submodules
repos. This goes further than the default rake task, which just gets the
submodules up to the commit when you `git submodule add ...`-ed them.  This may
cause compatibility issues if your set up relies on submodule features only
present in a certain commit.

Enjoy and don't hesitate to contact me, fork, or pull request.

-Tim
