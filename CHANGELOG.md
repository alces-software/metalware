# Change Log

All notable changes to this project will be documented in this file.  This
project adheres to [Semantic Versioning](http://semver.org/).

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
