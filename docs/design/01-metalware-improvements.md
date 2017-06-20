
This document describes the planned/suggested improvements to the Metalware CLI
for building clusters, with the aims of making it simpler, more flexible, and
more consistent, both for internal use and as a base for use by higher-level
tools. Once we have this improved Metalware CLI we plan to use it as the base
for developing one or more 'wizard-like' CLI or GUI tools, which will be
provided to customers for building bare metal and/or Flight clusters with
reasonably standard configurations.

This base Metalware tool is mostly intended for us/Steve to use, therefore it
is not worth attempting to bring absolutely everything needed to build any
cluster into one tool which will never need to be left. This tool needs to be
very flexible to handle building clusters with any odd requirements, and this
will always require a certain amount of manual tweaking - from our perspective
Metalware is a way to save time and avoid mistakes while doing this, while
retaining flexibility.

Note that this document only concerns the tools directly related to building
clusters, which are currently as follows:

- `repo`
- `hosts`
- `hunter`
- `scripts`
- `kickstart`
- `boot`

Metalware also currently also contains the following other tools:

- `console`
- `each`
- `ipmi`
- `power`
- `status`

These are utilities for working with bare metal clusters; these are not
discussed here however they will probably be folded into the updated CLI at
some point, possibly with some tweaks to their current form.


# New CLI library

It makes sense to use a new CLI library for Metalware when making these
changes, rather than the custom Alces tools we use at the moment. Benefits of
doing this:

- make things more consistent between different commands

- simpler to add subcommands (which we may want to do in some cases to make the
  interface a bit easier to use)

- easier to use, and more flexible for the various common things we want to do

[Commander](https://github.com/commander-rb/commander) seems the obvious choice
for this since it seems like the Ruby CLI library which provides the most, and
we also use it already for other tools (e.g. Gridware).


# Multiple clusters

For now we are not doing any special handling for building multiple clusters
with Metalware. If you want to do this you can always manually reset or adjust
things as needed to stop things intended for different clusters interfering, as
well as namespace things intended for different clusters as needed (e.g. name
nodes like `cluster1.node01` etc).


# Repo adjustments

Metalware will now only have a single repo active at a time. Repos will contain
a bit less than they do currently, but further files will be able to be used
from arbitrary other locations (see
[below](#metalware-config-files-parameter)).

There will be no default repo; when using Metalware on a new machine you must
initially specify a repo to be used.

Adjusted repo layout:

- There will be directories for each of the special templates, each of these
  will contain a `default` file which is used as the default template for that
  template type, as well as any other additional templates. These directories
  are:

  - `pxelinux` (formerly `boot`)
  - `hosts`
  - `dhcp` (formerly `hunter`)
  - `kickstart`

- There is also a `files` directory for holding arbitrary templates, which is
  pretty much what the `scripts` directory is currently but more generally
  named to reflect the fact that these templates can be anything (scripts,
  config files, snippets of larger files etc).


# Metalware config `files` parameter

Within Metalware config files a user will be able to specify a `files`
parameter. Although we will leave the `files` parameter untouched when passing
this to the templater, we will pick up this information and use it in a special
way.

The `files` parameter in a config file takes the following format:


```yaml
- files: 
  namespace1:
    - file1
    - /path/to/some/file/file2
  namespace2:
    - file1
    - http://example.com/path/to/file
```

Each `files` parameter contains some arbitrary namespaces; these can be
anything. Within each of these will be a list of files. These files can be
specified as any of:

- a file within the files directory of the Metalware repo

- an absolute path to a file on the deployment server

- the URL to get the file from; we don't care what this is, it can be a file in
  another Git repo, a file on S3 etc.

When running the [new `metal build` command](#build-command), for
each node to be built we will load all the applicable `files` from
its applicable configs.  This will then be merged into an overall
files object for that node. For each file specified we then:

- obtain the file from the specified location

- render this file for the node in the usual way

- then when rendering the main files for this node (the `pxelinux` config,
  `kickstart` file etc.) information about the rendered files will be made
  available within the templates (see [below](#templating-adjustments))


# Templating adjustments

## Magic namespace

In addition to the current magic parameters provided in templates by the
Metalware templater (and with the exception of some of these which are no
longer needed or provided in a different way), we also want to provide access
to the following magic parameters within templates:

- URLs on the Metalware deployment server that the `hosts` file, `genders`
  file, and potentially other similar system files can be obtained from

- a URL on the deployment server that is used to inform Metalware that the node
  being templated has finished building (this will be for the `kscomplete.php`
  script, or equivalent new version of this)

- the information gathered by `hunter` (see [splitting `hunter`
  section](#splitting-hunter))

- when running the `build` command, information on the rendered files for that
  node

To avoid a profusion of magic parameters available within templates leading to
confusion, we have decided to namespace all magic parameters to be made
available within templates within an `alces` object. This will be the only
variable which it will be an error to set in config files. All information in
this namespace will be generated based on the current node, information on the
deployment server, user input etc. 

A possible layout for this namespace is as follows:

- `variables` = values which vary based on the current node
  - `nodename`
  - `index`
  - `build_complete_url`

- `constants` = values based on details of the deployment server, which will
  not vary by current node
  - `hostip`
  - `hosts_url`
  - `genders_url`

- `hunter` = array of nodename/MAC address pairs, as found by the adjusted
  hunter command

- `files` = only available when running the `build` command; contains an array
  of objects for each of the rendered files for the current node, as discussed
  above. Each entry in this array will have the following format:

  - `raw` = the raw value entered in the config to specify this file, i.e. a
    file path within the repo, an absolute path on the deployment server, or a
    URL

  - either:
    - `error` = info on the error if we couldn't find the file, specific to the
      type of file to be found; when this occurs we will by default also output
      the error as a warning to inform the user

    - the following values with info about the file:
      - `name` = the rendered file name
      - `url` = a URL to obtain the rendered file from the deployment server

Alternatively, maybe we don't need the distinction between `variables` and
`constants`? We could just have all these values in the main `alces` namespace.

Note some current magic parameters are not present in the above, this is
because we have decided they are no longer needed with the Metalware
refactoring; these are:

- for `boot`:

  - `kickstart` - `boot` is being merged into the new `build` command (see
    [here](#build-command)), which always renders kickstart files.

  - `permanent` - the distinction between permanent and temporary booting is
    leftover from when the Metalware templating didn't exist; we no longer need
    this and can just adjust templates as needed.

  - `kernelappendoptions` - leftover from before the full templating was
    implemented, there is no longer a need for special handling of this, we can
    just set this in config files as needed.

- for `hunter`:
  - `fixedaddr` and `hwaddr` no longer need special handling, due to the
    `hunter` split (see [splitting `hunter` section](#splitting-hunter)) all
    values found by hunter will be available when rendering all templates

Note also that this means there are no longer differing magic values between
the different commands which render templates, simplifying these (aside from
the new `files` parameter, which although it could always be generated and
provided it only makes sense/is simpler to provide for just the `build`
command).


## Adjusting templating options

Currently it is possible to specify JSON overrides when templating using the
`--json` parameter for various commands.

Compared to specifying values within the config file hierarchy this has the
disadvantage of making it harder to reproduce building nodes. For example, if
one user builds a cluster using some JSON overrides, and then later another
user wants to modify some templated files for some nodes of this cluster, even
if the latter user changes the templates and configs, without knowing the exact
JSON overrides used earlier they may get a different result.

Given this disadvantage and the lack of an advantage to using this parameter
(any such changes can always be made in a config file) we will be removing this
parameter, which should make building nodes generally more likely to be
reproducible.

Additionally we want to remove the `--template-options` parameter provided for
various Metalware commands; the information given by this parameter would be
better suited to being in documentation.


## Warning about unset values

We also want to make a warning be output when templating files if an attempt is
made to use an unset value in the ERB; this will only be a warning by default
as sometimes it is desirable to have parameters be optionally set, or insert
nothing when they are unset.


## Providing access to raw templater

To support arbitrary access to templating in any way while building a cluster,
we will now also have a command providing direct access to the templater. This
new `render` command will simply take a (absolute, or relative to the working
directory) path and optionally a node name, load the config in the usual way
for this node, and output the rendered template to stdout. The output can then
be piped or redirected as needed.


# Splitting `hunter`

Currently the `hunter` command performs two related, intertwined functions:

- watching for nodes coming up on the network and displaying their MAC
  addresses

- writing a dhcp config file given the found MAC addresses and chosen node
  names as these come up

To increase the flexibility of Metalware and make it simpler to recover from
mistakes using `hunter` we have decided to split this command in two based on
these functions:

- a cut-down `hunter` command:
  - looks for MAC addresses as the current `hunter` does, and accepts node
    names to associate with these when found
  - performs no validation that the given node name is defined in the `hosts`
    file or is not duplicated in `dhcp.hosts`; does not restart `dhcpd`
  - writes output to new cache file in `/var/lib/metalware/cache/hunter.yaml`;
    the data from this file will then be made available in any future
    templating within the `alces.hunter` object (described above)

- a new `dhcp` command:
  - a simple wrapper command around running new `render` command with a `dhcp`
    config template and outputting this to `/etc/dhcp/dhcp.hosts`, along with
    some associated validation and restarting of `dhcpd`. The best way to
    validate this may be to make a backup before making the changes, restart
    `dhcpd`, and if this fails rollback the config and output the error;
    alternatively there may be some other way to validate `dhcp` configs.
  - this command will happen to use information found by `hunter` command,
    however it will not have any special info available to it compared to in
    other templates, and can also use any other template data if needed; other
    commands run after `hunter` can also use the `alces.hunter` info if needed

Note that this change means within Metalware repos the `dhcp` template will now
be for the entire `dhcp.hosts` file, rather than just for individual nodes
within this.

# Splitting `hosts`

Similarly to `hunter`, we would like to split `hosts` in to two commands as
well:

- a stage to build up a config file in `/var/lib/metalware/cache` specifying
  the association of node names with IPs on various networks, or possibly to
  just associate indices with nodes on particular networks (which can then be
  used to generate IPs)

- another similar wrapper around `render` for rendering `hosts`, which will
  entirely rerender the `hosts` file based on the built up config (as well as
  any other template parameters needed)

Given these commands we could incrementally build up the `hosts` config and
rerender the file as needed, without risking duplicate or obsolete entries.

However given that the current way of rendering `hosts` is mostly sufficient,
and that this split would be more work than the `hunter` split (as we will need
to handle multiple IPs and names for nodes), we will keep the current
functionality for the moment. We may investigate this split further at some
point but it is not key for the initial improvements.


# `build` command

We plan to combine the `scripts`, `kickstart`, and `boot` commands into a new
`build` command. These commands currently serve one purpose, of rendering the
scripts needed when building a node, so it makes sense to combine them; this
also means the rendered scripts will always be consistent and will be the
scripts last used when building that node.

This command will function as follows:

- given a node name or group, for each specified node:

  - the config files are loaded in the standard way, including the
    `alces.files` object as described above

  - each specified file is obtained and rendered for the current node; the
    result of this is saved in the `files` object, as also described above

  - the `kickstart` and `pxelinux` files are rendered for the current node.
    Note that:
    - The `pxelinux` files will be rendered the same as for `boot` currently,
      to `/var/lib/tftpboot/pxelinux.cfg/`; the `kickstart` files will now
      always be rendered to `/var/lib/metalware/rendered` (we now only need the
      'permanent' boot behaviour)
    - As with the other special templates, the `kickstart/default` and
      `pxelinux/default` templates will be used by default in this command;
      `--kickstart` and `--pxelinux` options will be available to override this
      if necessary.

  - the 'boot' process will execute and watch for built nodes, similarly to the
    current `boot` behaviour; this will always function with the current
    'permanent' boot behaviour

  - if the 'boot' process is interrupted, before exiting options will be given
    to either act as if all nodes reported as built, and rewrite the configs
    appropriately, or to just exit without cleanup. The former will be the
    default behaviour, as this is usually what we want to happen if e.g. a
    build is started and a while later we realize some needed file is missing.
 

# Summary

## Adjusted commands layout

Following from the various points above, the new suggested new layout of
Metalware build commands will be as follows:

- `repo`

    - `use REPO_URL` = performs the current behaviour of `repo --clone` for the
      given repo, installing it as Metalware's (only) repo. Options:
      - `--force`/`-f` = to force the use of a new repo even if local changes
        have been made

    - `update` = performs the current behaviour of `repo --update`, except
      always for the single repo. Options:
      - `--force`/`-f` = to force the update even if local changes have been
        made

- `render TEMPLATE_PATH [NODE_NAME]` = load config and render given ERB
  template for given node (if given) to stdout. Notes:
  - for one-off templating it may still be useful to provide a JSON overrides
    option for just this command - thoughts?

- `hosts` = perform the current behaviour of `hosts --add` (for the moment at
  least, until we investigate changing the way rendering `hosts` works, as
  described above). Options:
  - one of the following is required to specify the nodes to add:
    - `--node`/`-n`
    - `--group`/`-g`
  - `--template`/`-t` = specify template in `/var/lib/metalware/rendered/hosts`
    to use (instead of `default`)
  - `--dry-run`/`-x`

- `hunter` = look for nodes on the network and then associate names with each
  found MAC address; results are saved to
  `/var/lib/metalware/cache/hunter.yaml`. Options:
    - `--interface`/`-i`
    - `--prefix`/`-p` = same as current `--identifier`, but more descriptive
      name for purpose
    - `--length`/`-l`
    - `--start`/`-s`

- `dhcp` = simple wrapper around `render` for `dhcp` templates and outputting
  result to `/etc/dhcp/dhcp.hosts`; validates the resulting config file and
  restarts `dhcpd`
  - `--template`/`-t` = specify template in `/var/lib/metalware/rendered/dhcp`
    to use (instead of `default`)

- `build` = combination of rendering needed files for each specified node
  (specified `files`, `kickstart`, and `pxelinux` config) and then waiting for
  `boot` process to complete
  - one of the following is required to specify the nodes to build:
    - `--node`/`-n`
    - `--group`/`-g`
  - `--kickstart`/`-t` = specify Kickstart template in
    `/var/lib/metalware/rendered/kickstart` to use (instead of `default`)
  - `--pxelinux`/`-p` = specify Pxelinux template in
    `/var/lib/metalware/rendered/pxelinux` to use (instead of `default`)

Note that:
  - various options are no longer needed in the new CLI
  - of those options mentioned above, these should function in the same way as
    the existing option unless stated otherwise
  - the node name or group options, where present, are just called `--node` or
    `--group`
  - only `hosts` and `build` still need to be passed either a `node` or `group`
    option, no other commands need to operate on the level of individual nodes.
    If/when `hosts` is changed to function more like the split `hunter` then it
    will also not need to operate at this level (as the config will be built up
    distinct from the rendering, and the rendering will use the full config)


### Shared options

Additionally, all commands will have the following options available:

- `--help`/`-h`

- `--verbose`/`-v`

- `--quiet`/`-q` = in several places in this document warnings are mentioned; this
  will suppress these and other errors from being output (not essential for MVP
  Metalware improvements)

- `--strict`/`-s` = converts these warnings in to errors, and causes commands
  to fail fast when these are encountered (also not essential for MVP)


## Metalware directories

Where possible we want to confine Metalware's data to `/var/lib/metalware/`;
this directory will have the following layout:

- `repo` = the current Metalware `repo`

- `rendered` = the location for all rendered files aside from those which need
  to be output to `/var/lib/tftpboot/pxelinux.cfg/` or `/etc/`

- `cache` = the location for any `config`-type files generated using Metalware,
  which will be made available when templating; currently will just contain
  `hunter.yaml` but more files may later be written here

- `system` = links to system files which will be made available by the
  Metalware deployment server; currently will just contain `hosts` and
  `genders`

- `exec` = scripts on the deployment server which will be made available to be
  triggered by requests from nodes; currently will just contain the
  `kscomplete.php` script for reporting nodes are built.

  Aside: it may be worth removing this PHP script at some point and replacing
  it with using `alces-flight-trigger` for this purpose. This would mean we no
  longer need to have Apache for this purpose, proxied to by Nginx. I made an
  initial look at doing this in
  https://github.com/alces-software/imageware/commit/ada3e817f7f369c8db4ee2a52419dcc12228c74d
  but have left it for now as the current way works OK. If we were to do this
  we could probably make the `alces-flight-trigger` credentials available as a
  magic parameter when templating; nodes would then need to use these when
  reporting that they have built.

Given this directory structure, the `rendered`, `system`, and `exec`
directories will currently be made available on the deployment server to nodes.
These will normally be accessed using parameters from the `alces` namespace
when templating files for nodes.
