# Change Log

All notable changes to this project will be documented in this file.

## Unreleased

## [2018.3.1] - 2018-08-16

- Allow `--answers` option for `metal configure local` command (https://github.com/alces-software/metalware/pull/447)

## [2018.3.0] - 2018-08-15

- Moved asset types to be stored in Metalware itself rather than the repo being
  used (https://github.com/alces-software/metalware/pull/394).
- Store assets by type (https://github.com/alces-software/metalware/pull/393).
- Provide access to assets by type in namespace
  (https://github.com/alces-software/metalware/pull/401).
- Added `layout add` and `layout edit` to create and edit asset layouts
  (https://github.com/alces-software/metalware/pull/400,
  https://github.com/alces-software/metalware/pull/406)
- Added method to nodes in namespace to check if node is the local node
  (https://github.com/alces-software/metalware/pull/409).
- Added ability to save or edit sub-assets when creating an asset
  (https://github.com/alces-software/metalware/pull/414).
- Added ability to create an asset from a layout as well as a type
  (https://github.com/alces-software/metalware/pull/415).
- Added more data to asset types
  (https://github.com/alces-software/metalware/pull/420).
- Switched `named` and `hosts` files to be rendered as Metalware-managed files
  (https://github.com/alces-software/metalware/pull/418).
- Fixed messages not being printed until build script finished in local build
  (https://github.com/alces-software/metalware/pull/419).
- Added `eval` command for programmatic access to Metalware namespace
  (https://github.com/alces-software/metalware/pull/435).
- Fixed non-Kickstart build methods often not being detected
  (https://github.com/alces-software/metalware/pull/440).

## [2018.2.0] - 2018-04-25

- Fixed default values not being displayed when configuring when question
  `type` is `integer` (https://github.com/alces-software/metalware/pull/357).
- Added `asset` commands for managing asset files with the following
  subcommands:
  - `asset add` which creates a new asset from an asset type template in repo
    (https://github.com/alces-software/metalware/pull/364).
  - `asset edit` which opens existing assets in the system editor
    (https://github.com/alces-software/metalware/pull/365).
  - `asset link/unlink` which manage the relationships between assets and nodes
    (https://github.com/alces-software/metalware/pull/373).
  - `asset delete` which deletes an asset and unassigns it from the nodes.
- Made assets configured using the above available within Metalware namespace
  (https://github.com/alces-software/metalware/pull/362).

## [2018.1.0] - 2018-03-27

- Added support for conditional Metalware configuration questions.
- Added `orchestrate` commands for orchestration of VMs via Libvirt in
  Metalware.
- Added support for running `ipmi` (or at least VM equivalent to this) and
  `power` commands on VMs.
- Improved error-handling in existing `ipmi`, `power`, and `console` commands.
- Added `plugin` commands for Metalware plugin management.
- Added support for configuration of Metalware plugins.
- Added merging of plugin configs for node, and retrieving/rendering of plugin
  files, by similar processes as currently used for repo configs and files for
  node.
- Added access to plugin namespaces for enabled plugins when templating for
  nodes.
- Improved commands which take `-g`/`--group` option so they can operate on any
  gender specified in the genders file, and changed the long form of this
  option to `--gender` to reflect this change
  (https://github.com/alces-software/metalware/pull/306).
- Fixed `view-answers` commands to work with latest `configure.yaml` format
  (https://github.com/alces-software/metalware/pull/311).
- Suppressed output suggesting there might be a problem with Metalware when
  displaying known user input errors
  (https://github.com/alces-software/metalware/pull/314).
- Added `overview` command to give overview of state of whole domain and
  configured groups (https://github.com/alces-software/metalware/issues/284).
  Note: this requires a new `overview.yaml` file to be present in the repo.
- Condensed build event output to single line for clarity
  (https://github.com/alces-software/metalware/issues/287).
- Fixed issue where `view-answers` did not work for orphan nodes
  (https://github.com/alces-software/metalware/issues/312).
- Fixed issue with non-group genders not working with `ipmi`-based commands
  (https://github.com/alces-software/metalware/issues/323).
- Fixed issue where `console` used incorrect hostname in `ipmitool` command run
  (https://github.com/alces-software/metalware/issues/326).
- Fixed issue where boolean questions would accept invalid answers the initial
  time a particular `configure` command was run
  (https://github.com/alces-software/metalware/issues/329).
- Fixed various issues when `configure`ing where answers incorrectly
  would/would not be saved depending on the current higher level answers and
  defaults (https://github.com/alces-software/metalware/issues/330).
- Fixed inconsistent and undocumented overriding of defaults at different
  levels (https://github.com/alces-software/metalware/pull/335).
- Fixed `power` and `ipmi` commands run on groups to not fail, and just report
  the error, if any individual `ipmitool` command(s) run for individual nodes
  fail (https://github.com/alces-software/metalware/issues/337).
- Fixed issue where orphan nodes would be saved in the group cache even if the
  `configure` command to add them is cancelled before completion
  (https://github.com/alces-software/metalware/issues/341).
- Fixed issue with defaults not being set for non-domain level questions
  (https://github.com/alces-software/metalware/issues/345).
- Support various options to `ipmi` command that were accepted in previous
  versions of Metalware (`--command`/`-c`/`-k`)
  (https://github.com/alces-software/metalware/issues/348).
- Various other small bug fixes and tweaks.

## [2017.2.1] - 2018-01-05

- Fix the infinite recursion bug when rendering the pxelinux file for
  multiple nodes in the build command.

## [2017.2.0] - 2017-12-19

- Added `metal template` command which renders the templates and build files
  for a node or group. All files are rendered to the staging directory and not
  their final location.
- Added `metal sync` command which moves staged files in place and restarts
  associated services.
- Remove rendering of templates/ files as part of `metal build`. This has been
  replaced by `metal template` followed by `metal sync`. Also removed the
  obsolete edit start and continue flags.
- Removed the `metal dhcp` command as it has been replaced by `metal template`
  followed by `metal sync`.
- Added staging to rendering of genders file in `metal configure`. The genders
  file needs to be synced (using `metal sync`) before it can be used by `metal
  template`.
- Fixed the bugs that slowed down metalware. A shared cache is now used to
  render all metalware templates/ files.
- Updated to the new `Namespace` structure. See documentation for further
  details.

## [2017.1.1] - 2017-11-14

- Have build `files` replace rather than be merged in to `files` set at a
  higher config level.

## [2017.1.0] - 2017-09-26

- Added `metal configure` commands, to answer questions for various objects
  managed by Metalware and save the answers for use in later templating.
- Added support for having Metalware use `named` instead of `hosts` file for
  managing host name resolution.
- Added full rendering of various domain templates when `metal configure`
  commands are run, including `genders` file and `hosts`/`named` template.
- Removed `metal hosts` command, as made obsolete by above change.
- Changed node indexes to be consistent across different commands effecting a
  node.
- Made various commands be dependent on other files existing and being valid,
  and hence other commands having been run first.
- Added various `alces` namespace parameters including `group_index`, `groups`,
  and `answers`.
- Added `metal hunter` `--ignore-duplicate-macs` option to ignore already found
  MAC addresses.
- Added `metal view-config` command to view the complete current Metalware
  config.
- Added `metal view-answers` commands to view the configured answers applicable
  to different Metalware objects.
- Added `metal remove group` command to remove a configured group.
- Added alternative `basic`, `self`, and `uefi-kickstart` node build methods to
  the default `kickstart` method.
- Added support for splitting `build` command to only perform actions before or
  after editing, to allow editing templates in between.
- Made full paths be displayed in warnings for missing template parameters.
- Implemented prototype Metalware GUI; not yet publicly exposed.
- Numerous other bug fixes and minor tweaks.
- Switched to new year-based versioning system.

## [2.0.0] - 2017-08-07

- Rewrote and restructured much of Metalware to be more consistent and
  flexible.
- Only using a single Metalware repo at a time is now supported, and the `repo`
  command has been simplified to reflect this; note that the previous
  flexibility is retained more simply via the `build` `files` feature.
- The `hunter` command has been adapted into two commands: `hunter` for hunting
  for nodes and caching the detected MAC addresses, and `dhcp` for fully
  rendering the `dhcpd.hosts` template using these.
- The `build` command now replaces and encompasses the behaviour of the
  previous `scripts`, `kickstart`, and `boot` commands.
- Arbitrary files from the repo, the Metalware deployment server, or any URL,
  can also be retrieved and rendered for nodes by `build`, covering previous
  use cases for `scripts` and multiple repos more simply.
- A new `render` command provides direct access to the Metalware templater, to
  render arbitrary templates for any (or no) node.
- When rendering templates, all parameters which do not directly come from the
  repo config are now namespaced under an `alces` namespace; new parameters
  have also been added to this namespace (see [here](docs/templating-system.md)
  for details).
- Warnings are now displayed on stderr for certain potentially bad events;
  these can be suppressed or converted to errors with the `--quiet` or
  `--strict` global options.
- The universal config, which is always loaded when rendering templates, has
  been renamed from `all.yaml` to `domain.yaml`.
- See [the initial design document](docs/design/01-metalware-improvements.md)
  for full details of the planned changes for this release; note that some
  additional changes have occurred since this.

## [1.2.0] - 2017-05-23

### Changed

- Refactored Metalware content to separate Metalware content repos
- Improved determination of `hostip` when templating

### Added

- Created repo system for Metalware content and new `metal repo` command to
  manage these
- Added `metal status` tool to display the `ping` and `power` state of the
  nodes

## [1.1.0] - 2017-03-20

### Changed
- Defined hierarchy for template inputs

### Added
- Template engine (ERB) supports config files
- Support for script file manipulation using ERB templates
- Support permanent templating/ boot
- Logging file manipulations and error events

## [1.0.0] - 2017-02-28

### Changed
- Removed cobbler integration in 'metal hunter'

### Added
- Support for host file manipulation based on ERB templates
- Support for kickstart file manipulation
- Support for PXE boot file manipulation
- Built in genders based node iteration
- Basic installation master and client deployment scripts
