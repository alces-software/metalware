
# Overview

- Will have new `metal configure` command group for configuring values to be
  used within config files for a Metalware domain, a group of nodes, or an
  individual node:
  - `metal configure domain`
  - `metal configure group GROUP`
  - `metal configure node NODE`

- These commands may also perform other behaviour specific to the type of
  resource being configured.

- Note that these commands will be just one interface for configuring the
  'topology' of a cluster; it should be possible for alternative interfaces,
  such as a future web interface or manual editing, to modify the same files,
  and the loading of these files for use when templating will be independent of
  the `configure` commands.

- There will be a `configure.yaml` file in the repo root, specifying
  configuration questions to be used within these commands or alternative
  interfaces.

- The `configure` commands will save the entered answers to a file in
  `/var/lib/metalware/answers`, specific to the resource being configured.

- Repo configs will be able to use a new object in the magic `alces` namespace,
  `alces.answers.$question_identifier`, where `$question_identifier` is the
  identifier for a particular question specified in `configure.yaml`; when
  templating the corresponding question answer will then be used in these
  places.


# `configure.yaml` format

There will also be a `configure.yaml` in the repo root, which specifies
configuration questions for the different categories, with the following
suggested format:

```yaml
questions:
  example_question_identifier: &example_question_identifier
    question: 'What value should this take?' # Required.
    choices: # Optional; limit choices to one of these options.
      - 7
      - 11
    default: 11 # Optional; default value to use when no input entered, if any.
    type: 'integer' # Optional/default `'string'`. For validation and converting; see below for details.
    optional: true # Makes the question optional. Default if missing:`false`

  another_example: &another_example
    question: 'Enter anything?'

domain:
  # Both these questions will be asked for `metal configure domain`.
  example_question_identifier: *example_question_identifier
  another_example: *another_example

group:
  # Just ask this question for `metal configure group`.
  another_example: *another_example

node:
  # Similarly, just ask this for `metal configure node`. Note: the answer will
  # be saved under `different_name` in the resulting config this time however.
  different_name: *example_question_identifier
```

## Notes regarding above format

- By defining all the questions within a `questions` object we can then share
  questions between different categories without duplication using YAML's
  ability to refer to other parts of the document.

- Any name key can be used when specifying a question for a particular
  category. Often the same identifier will be used for the question definition
  and when specifying a question for a category, e.g. a `cluster_name` question
  may be defined in `questions` and then used as `cluster_name` under `domain`,
  however this will not necessarily always need to be the case.

## Notes on `type`

The `type` for a question will serve the dual purpose of validating input and
then converting this before saving.

For the minimal version of this feature possible type values will probably just
include `string`, `integer`, and `boolean`. These will be necessary as since we
are accepting user input we won't know what type we should save a given answer
as, and we will need non-string types when templating.

Later we can add types with more validation here, e.g. we can have an `ip` type
which will save the value as a string but validate that it is a valid IP first.
While these more complicated validations could be specified separately by
adding an optional regular expression field to question configs, I think
building these in to Metalware would be better since:

- there will only be a limited number of these more advanced types, and I don't
  think we need the flexibility of allowing more validations to be specified in
  the repo;

- having these built in to Metalware means we won't need to duplicate
  validations between repos or places within repos;

- we may later want to do non-regex validation, e.g. a `dns` type could
  validate that a particular IP entered gives the expected DNS response (though
  this particular example sounds like overkill).


# `metal configure` commands

The `metal configure` commands each take their specified questions and ask
them, save the results to a particular file within a new
`/var/lib/metalware/answers/` directory, and perform any other actions
appropriate to the resource being configured.

## `metal configure domain`

Asks the `domain` questions; the validated, converted answers will be saved to
`/var/lib/metalware/answers/domain.yaml` in the following format:

```yaml
answers:
  example_question_identifier: 7
  another_example: 'foo'
```

## `metal configure group $GROUP`

Asks for a genders line to be entered first, then similarly to `configure
domain` asks the `group` questions; the results will then be saved to
`/var/lib/metalware/answers/groups/$GROUP.yaml`

```yaml
genders: 'somenodes[01-03] somenodes,cluster,domain'
answers:
  another_example: 'foo'
```

Note that initially the genders line will just take a line of text, later we
can add more validation and potentially generate this based on e.g. entering a
number of nodes in the group and a group name.

Every time `metal configure group` is run we should regenerate
`/opt/metalware/etc/genders` by (for now at least) simply concatenating all the
group gender lines together; this way it should always be in sync with the
configured groups. Aside: it may be worth including a line in the generated
genders indicating this and that any changes to it directly may not persist.

## `metal configure node $NODE`

Similarly asks the questions configured for `node`, and saves these to
`/var/lib/metalware/answers/nodes/$NODE.yaml`. Note that unlike `configure
domain`, required before any nodes/group can be built, or `configure group`,
required before a particular group can be built, it will not be required to
`configure node` before building a particular node; `configure node` just
provides a way to further specialize a particular node's configuration.

## Re-running `configure` commands

If any `configure` command is re-run we will also want to pre-fill the answer
to each question with the saved answer.

When saving the answers after re-running `configure`, we will want to make sure
just the new answers are saved. For instance:

- `metal configure domain` run, an answer `'foo'` is given for the
  `some_question` question;

- the question `some_question` for `domain` is removed from
  `/var/lib/metalware/repo/configure.yaml`;

- `metal configure domain` is run again; `some_question` won't be asked and we
  should make sure the previous answer is not still included in the resulting
  `answers` file.


# `hosts` generation

With the addition of groups being defined separately from the genders file, it
should now be possible to have the whole `hosts` file generated in one pass
from a single template. To do this we will need a way when templating to get
all the defined groups, along with the nodes within each group and the config
for each node (to get each node's IP and hostname etc).

A possible way to do this would be to have an `alces.groups` method, which
takes a block with 2 arguments, `group_index` and `group`. `group_index` will
simply be a unique index for each configured group; `group` will have a `nodes`
method which takes a block with a `node` argument; `node` will provide access
to the loaded config for the given node, the same as would be available at the
top level if the templater was run with the `nodename` for this node and an
appropriate `index`.

This could then be used to generate a `hosts` file in some way, possibly like
this:

```erb
<%# Note: may not actually need to provide group_index here, just make it
available in configs. %>
<% alces.groups do |group_index, group| %>

  <% group.nodes do |node| %>

    <% node.networks.each do |name, network| %>
      <%# Note: `network.ip` could be either hard-coded or generated
      dynamically using `group_index` and `index` etc, will depend on config.
      %>
      <%= network.ip %> <%= network.hostname %> <%= network.short_hostname %>
    <% end %>

  <% end %>

<% end %>
```

The `alces.groups` parameter in this situation is going to load the config for
every possible node in every configured group for the Cluster. There is the
potential that this will be noticeably slow; if this is the case we may want to
have this only available in certain situations, for example when a
`load_groups`, or similar, argument is passed to the templater.

When this feature is implemented the `hosts` file will be able to be rendered
in full in a single pass; since the information used in the rendering can
change with any `configure` command it seems sensible to automatically
re-render the `hosts` file after every `configure` command, similarly to the
plan for `genders` after any `configure group` command. If we add this it will
largely make the `hosts` command obsolete, although we may want to retain it
for re-rendering after manually changing the template, or a config or answers
file.

We will also need to consider if we this how a `hosts` template other than the
default will be selected for automatic re-rendering, or alternatively if we
still need the ability to have multiple `hosts` templates within a single repo
now - it should now be possible to have the `hosts` template handle any
situations where we want to treat groups or nodes differently.


## Command ordering

With this new functionality certain commands will now require that other
commands have been run first:

- All `metal configure` commands will require the repo be set up (`repo use`
  has been run) before running.

- `metal build` will require that `metal configure domain` has been run first,
  i.e. that `/var/lib/metalware/answers/domain.yaml` has been generated, so any
  necessary answers have been configured before templating.

- Additionally, `metal build -g $GROUP` will require that `metal configure
  group $GROUP` has been run first, i.e. that
  `/var/lib/metalware/answers/groups/$GROUP.yaml` has been generated.

- Note that a node config is not required, so a
  `/var/lib/metalware/answers/nodes/$NODE.yaml` file is not required to build
  `$NODE`.

Note: functionality for handling commands depending on `repo` already exists in
`BaseCommand`; we will likely want to add to this, and possibly generalize
specifying a commands dependencies in some way.

Following discussion, a possible good abstraction for this would be to specify
a `DEPENDENCIES` constant in each command class. This could maybe be a map of
command names to file paths, specifying the command which needs to be run first
and the files which indicate this has occurred. `BaseCommand` could then use
this to check each dependency command has been run and display an appropriate
message if not.

## Templating

When loading `alces.answers` values from files in `/var/lib/metalware/answers/`
for use in templates, the same procedure will be followed as for loading the
repo configs, i.e.

- first `domain.yaml` will be loaded;

- if no `nodename` is passed, then nothing else will be loaded;

- if a `nodename` is passed, all/any gender groups will be found for the node,
  and any `groups/$GROUP.yaml` files will be loaded for these in order of
  precedence;

- any `nodes/$NODE.yaml` file for the specific node will be loaded.

When templating, attempting to use an `alces.answers` value which is not set in
the answers file should be a fatal error. All answers used in the repo
configs/templates should appear in the merged answers, as even if a particular
`configure.yaml` question is optional and nothing has been entered a value of
`nil` should still be saved, in which case `nil` will be used when templating -
however if the specified identifier is not present at all then this indicates
the repo has an inconsistent `answers` directory and `configure.yaml` file,
which should be addressed.


## Questions

- May want to change `all` to `cluster` everywhere? - following discussion we
  will change this to `domain` as this most accurately describes what Metalware
  sets up (a single Metalware installation could, with the right repo and
  config, be used to setup multiple Flight Compute clusters). Note: this
  document has been updated to reflect this.

- Change either `/var/lib/metalware/config` or `/var/lib/metalware/repo/config`
  to something else, as they are related but the naming may be confusing? Maybe
  also name `/var/lib/metalware/repo/configure.yaml` something else? -
  following discussion we will use `/var/lib/metalware/answers` to store the
  `configure.yaml` answers, and `alces.answers` to access these; this document
  has been updated to reflect this.
