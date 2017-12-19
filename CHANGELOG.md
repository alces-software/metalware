# Change Log

All notable changes to this project will be documented in this file.

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
