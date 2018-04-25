# Overview

The `metal asset` command now provides a mechanism for adding new
asset records, however this is still a time consuming process. Each
asset needs to be added manually, including filling out its details.

The issue with `metal asset` is that it can only add basic asset
`types`. To fix this issue, a new asset `layout` concept is to be
introduced.

An asset `layout` will act as an intermediary between `types` and
actual assets. A `layout` is a partially filled asset which is to be
generated from a `type`. An `asset` can then be made from the `layout`.

The other key feature of a `layout` is its ability to automatically
trigger the creation of sub assets (discussed below).


# Command Changes:

A new command to create `layouts` will be required:
- `metal asset layout-add TYPE NAME`

Also the existing `add` and `edit` commands need to be updated with
a `-l` flag.

Thus, `metal asset edit -l NAME`, will be used to edit an existing
layout instead of an asset.

Also, `metal asset add -l LAYOUT NAME`, will switch the `TYPE` input
to be a `LAYOUT` input. This way the `asset add` command can create a
new asset from both a `type` or `layout`.

NOTE: The `-l` may not be needed for the `add` command if `types` and
`layouts` have unique names. The implementation of this has not been
finalised.

# Refactoring of Assets Types

Before `layouts` are implemented, the current handling of asset `types`
needs to be updated. The asset `type` is a key property and will need
to be loaded into the `asset` metadata along with its name.

However before this can be done, the `type` needs to be encoded with
the asset name. The most direct way to implement this is to use asset
type subdirectories to store the assets. This is a break from the
initial implementation which only had a simple flat directory 
structure.

## Key Issues:

0. Consider moving asset `types` from `metalware-default` into
   `metalware`?
1. Each asset needs to be stored in a subdirectory corresponding to
   its asset `type`,
   * When should the subdirectories be made?
2. Each asset needs its `type` loaded into the metadata,
3. Each asset needs to be accessible by name ONLY. The type should not
   be required.
   * This will require each `name` to be unique
4. Assets can not share a name with an existing asset `type` OR the
   plural of an `type`.
   * This is to prevent potential future conflicts
5. The assets need to be iterable by `type`
   * The plural of each `type` should be defined as a method on
   `AssetArray`. These method should return a new `AssetArray` like
   object (without the type methods). The sub array object should
   share the original asset loaders. This way the asset files are
   still only loaded once.

# Implementation of layouts:

## Creating an layout

Creating an asset `layout` is the same in many ways to the creation of
an `asset`. It still is created from a `type` and goes through the
editor like an `asset`. It should also be stored in subdirectories
by type BUT the layout name should also be unique.

The asset `layouts` will however be stored in a different base
directory, `/v/l/m/asset-layouts`. Also the asset layouts will not be
loaded into the namespace.

## Editing of a layout

Editing of an existing asset `layout` will be the same as an existing
`asset`. To implement this, a [`-l`, `--layout`] flag will be added to
the `metal asset edit` command. Otherwise it is exactly the same.

## Creating an Asset from a Layout

The primary purpose of the `layouts` is the ability to rapidly generate
assets from them. The [`-l`, `--layout`] flag needs to be added to the
`metal asset add` command. This will tell the command to add a new
asset from the `layout`. As each `layout` has a type, this will be the
type of the asset. This may not be required if `types` and `layouts`
have unique names.

### Generation of Sub Assets

The `^name` notation in the `layouts` is going to be slightly different
then `assets`. In the assets, `^name` denotes a link to another 
asset. In the layouts, the notation going to be:
`type_or_layout_name^base_asset_name`.

Once the asset (from a layout) has been edited, the `yaml` is parsed
for the above notation. This notation tells metalware to create an 
asset of type: `type_or_layout_name`. Asset layouts and types have
unique names, it is possible to tell which one should be used.

Then the `base_asset_name` tells metalware how to construct the
translated asset name. As layouts are going to be used multiple 
times, they can not all use the same name. Thus the syntax for the
sub asset name will be: `#{parent_asset_name}_#{base_asset_name}`.

The penultimate step of creating an asset form the layout is to
replace `type_or_layout_name^base_asset_name` with
`^#{parent_asset_name}_#{base_asset_name}` and thus automatically
creates the link between the asset and sub assets.

The final step is then to prompt the user if they want to create each
sub asset, if so the process is repeated.

### Key questions:

1. Should the sub-assets be made in depth first or breadth first order
2. When a sub asset is created, should the `^parent_asset` link be
   automatically generated?
   * This could be done using the parents asset type as the key
3. How are sub-assets handled if they already exists? Should it just
   be an edit? How does point 2 affect this?
4. In a layout, should there be special handling of `^asset_name`
   notation? There has been discussion of using the hash key that
   contains it as the `type` for the auto generation of sub assets.
   This, however, removes the ability to statically reference an
   asset from a `layout`.


## Side Issue - Temp Filename

When the editor is open, it is hard to know which asset is currently
be edited because of the use of a temporary file.

The temp file should still be used, however its name should be updated
to include the final save name NOT the asset type. Also the random bit
of the name should be at the end. Thus the temp file path should be:
`/tmp/asset_name.yaml.XXXXXXXX`
