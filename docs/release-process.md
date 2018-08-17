
# Release process

1. Update CHANGELOG on `develop` to briefly document all user-facing changes
   since the last pre-release/release candidate (for a new pre-release/release
   candidate), or since the last major release (for a new major release, by
   merging all entries for its pre-releases/release candidates under a new
   heading).

   When updating the CHANGELOG include a reference to the pull request which
   fixed each issue or completed each change.

2. Merge everything which should be released into `master`, and push this.

3. Appropriately tag this release on GitHub, in the format
   `year.release.patch[-prerelease_marker]` (e.g. `2018.1.0-rc1`).

4. Create a release for the tag at https://github.com/alces-software/metalware/releases

5. Announce the release at https://alces.slack.com/messages/C5FL99R89/,
   mentioning what's new in this release (the entries added to the CHANGELOG
   above), or at least where to find this if many things have been added.
