# Change Log

All notable changes to this project will be documented in this file.  This
project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0]

### Changed

- Removed scripts, boot and kickstart duplication
- New render command that can render any template
- Commands only look in repo folder for templates
- Removed support for multiple repos. Only a single repo can be used at a time.
- Hunter no longer updates dhcp. It only caches detected mac addresses
- Build command replaces the old boot command
- CLI now uses the Alces version of the Commander Gem
- All CLI information is stored in a config
- Tests have been mirgrated to use rspec
- The Iterator has been replaced with a Nodes class

### Added

- Added the Node class which contains all the functions specific to a node. Example: combining the template parameter hash and pulling the gender groups it belongs to
- Added the magic namespace to the template parameters used by erb
- Added dhcp command which updates dhcp sever using the hunter cache
- Replaced the all gender group with domain

## [1.2.0]

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
