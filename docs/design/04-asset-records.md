# Overview

- Provide an easy way to add asset records for different physical components
  and to assign them to nodes.
- Should be based of `YAML` that is directly loaded into the namespace
  (through some mechanism) and allow them to be templated against.
- Some ability to add new asset records based of a pre-existing "templates"
  of different asset types (from repo content)
- The ability to edit/ delete pre-existing records
- Asset records will need to be assigned to nodes (and reference each other
  at some future date)
- Some basic "validation" of the files

# New Commands:

There will be three basic commands:
- `metal asset add TYPE NAME`
- `metal asset edit NAME`
- `metal asset delete NAME`

# Adding a new asset record

To make a new asset record, first a blank "template" needs to be loaded from
repo. Note that these "templates" are not ERB. Instead they are the "YAML"
that will provide the basis for the asset record. An no point will the
entire "template" be rendered using ERB (however the individual tags might?).

The template will then be opened using the system editor (see issues). Before
being saved to the final location in `/var/lib/metalware/assets`. See
`Editing` for more details on this process.

In short, the validation will occur when the file is saved. Currently the
template file must be valid `YAML`. Blank fields will therefore need to be
represented with `nill`.

As this is a new record, the `type` is required for the command. This tells
`metalware` which "template" should be used. The templates should be stored
under `repo/assets`. The `name` is to be used for saving the asset. So a
typical command would look like:
`metal asset add rack rack1`

# Editing an existing record
As the asset already has a name, the command will look like:
`metal asset edit rack1`.
The type is not required as the asset can be retrieved with the name itself.

This will be similar to adding a new record except the old record is used
instead of the template. Otherwise the following process is the same for both.

The edit process should not be destructive until after the updated file has
been validated. This means the files can not be edited in place. Instead the
existing record should be moved to a temporary file which is then edited.

Once the user has finished editing the file and saves it, `metalware` should
detect the editor has closed and continue on with the process. This should 
be the case when using `POpen.capture3`, however it might need to poll the
editor `PID` until it is closed.

At this stage, only basic validation of the file is required. The file is
valid if it can be reloaded as a hash using `Data.load`. If the file is not
valid, then the process should end with an error and point the user to the
bad file's temp location. NOTE: Ruby does automatically delete temporary
files, so special handling maybe required to prevent this. Validation can
also occur on open.

At this stage re-editing a previously bad file does not need to be supported.
This can be added in the future.

At the end, the temporary file is moved to its final location.

# Accessing Asset Records and Naming

The asset records will be loaded into the namespace under `alces.assets`.
They will be accessible by name as both: `alces.assets.<name>` and
`alces.assets.find_by_name(name)`. The `MetalArray` could be used for this
however ideally the files would be lazy loaded when they are first used.

# Associating Asset to Nodes and Deleting Assets

A manifest (stored in `/v/l/m/cache`) will assign assets to nodes. An `asset` method on the `NodeNamespace` will poll the manifest for the
corresponding asset (`node.asset`). An empty hash should be returned if
it is missing.

The use of a manifest will assist with deleting records as it can also be
updated at the same time. This prevents nodes from referencing non-existent
records.

Instead of reloading the file for the node, `node.asset` should use
`alces.assets.find_by_name` so they can share the cached files.

A flag should be included as part of the `add` and `edit` commands to assign
a record to a node. Most likely `-n` and `--node` would be appropriate.
Metalware will then update the manifest to assign the link.
NOTE: Should a single record, be able to link to multiple nodes?

# Issues

- EDITOR: Make sure that the system editor is used at all times. Note that
  both `$VISUAL` and `$EDITOR` will have to be considered. `vi` is probably
  an appropriate fallback option.
- SAVE LOCATION: Even though multiple different types of asset records will
  be used, all the `YAML` will be saved within the same `assets` directory
  (instead of subdirectories). This is because all assets need a unique name
  so they can be listed under `alces`. Using the name as the `filename` will
  ensure uniqueness and make accessing the file easier.
- HASH OR ROS: Through out this document the term 'hash' has been used
  loosely. When referring to the object loaded into the namespace, it needs
  to be at least a `RecursiveOpenStruct`. However if the tags also need to be
  rendered, than the `MetalRecursiveOpenStruct` needs to be used instead.
  In all other situations, use what ever is easiest to implement (which maybe
  a hash).

# Tasks

1. Develop a utility that opens files in the correct editor and waits for
   them to be closed.
1. Develop a class that wraps the editor utility but also handles the moving
   of temporary files from a `source` to `target` location. It should
   implement the process described under the Edit section.
1. Define the appropriate methods on `FilePath` so they are reusable
1. Use the above points to implement the basic functionality of the `add` and
   `edit` commands
1. Implement the ability to assign assets to nodes using the manifest
1. Implement the deletion of asset records.

