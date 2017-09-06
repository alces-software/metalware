# Intro

A significant amount of work has now been down on the MagicNamespace however it
now has numerous purposes and inconsistent behaviour. The current behaviour of
the MagicNamespace can be summarised as follows:

1. Access domain level information (`hosts_url`, `genders_url`, `hostip` etc)
1. Access node (that is in scope) specific information
   (`nodename`, `kickstart_url`, `index` and `group_index`)
1. A hacked version of the node level answers that prevents bugs
1. Access to Group level information through another Namespace

When accessing group level information (through `alces.groups.each`), a group
level namespace is returned for the group that is in scope. The following
methods are available to it:

1. Access to the group name
1. Access to the group level answers
1. Loop through configs for the nodes in the group

On top of all this, a config is loaded into ERB's binding which can also return
values. Currently their are two options for what this config is. Normally it is
the config for the Node that is in scope (such as a kickstart file). In this
case, the MagicNamespace has a node in scope as well and `alces.nodename` and
alces.index will return correctly.

However if a domain level config is being rendered, then the config in the ERB's
binding is only `configs/domain.yaml`.

# Issues

The main issue is complexity and maintainability. Currently the design is ad
hoc which makes it next to impossible to replicated the behaviour in order to
make a change. The following is the issues within the current design.

The most obvious bug is fairly cosmetic at this point. Their are a lot of nil
warning's being issued because value's haven't been set in the config. However
this is more indicative of the larger problem, 'which config?'

Currently we can always access Node level configs, ironically through the
GroupNamespace. However we can never access group level configs (this may not be
required) and we can only access domain level config parameters if they just so
happen to be in scope.

However the bigger issue is each config can reference answers and vice versa.
Now answers can be accessed at the node level with `alces.answers` but the
behaviour will be different depending if a node is in scope. Group level answers
can be accessed through the group level namespace.

The config loaded into the ERB binding will be which ever happens to
be in scope (aka domain or node level). This means a node level config (accessed
throught the GroupNamespace) can reference a group level answer which references
the "config". This config could either be for the domain or a random node
depending whatever is in scope.

This complexity is partly way we need to allow `alces.<nodename | index>`
to fail silently (e.g. return empty string or 0) as they are incorrectly being
accessed through the various level configs.

# Proposed Change Overview

The MagicNamespace is doing too much and thus has an undefined purpose. Also as
answers reference the "config" they need to a rationalisation which config
should that be. The ultimate goal is to get Metalware to render each template in
well defined and consistent manner.

The way this could be achieved is to adjust the MagicNamespace to become an API
within the binding. This means all parameters will be accessed through a `alces`
API with an explicit path.

Their are two main parts this document will look at:
1. Adjust the MagicNamespace to become (/create) an API
1. Simplify the referencing to config/ answers within the API.

## Creating the API

The first stage is creating the API based on the existing MagicNamespace. For
the purpose of this document, the term API and Namespace can be used reasonable
interchangeable. However Namespace refers more specifically to a component of
the API. This will require splitting the MagicNamespace up according to role.

As all parameters will be accessed through the API, the config hashes will no
longer be loaded into the ERB binding. Instead the config's will have explicitly
defined paths within the API.

The three broad sections of the API are as follows:

1. AlcesNamespace: API Entry Point + domain level parameters
1. GroupNamespace: Contains the group level parameters
1. NodeNamespace: Contains the node level parameters

### AlcesNamespace
This will be the entry point to all parameter calls through the API. The other
sections of the API can be accessed through the `alces` call. This is to
distinguish between API calls and local variables defined within ERB. The
`alces` command will also contain the domain level information for the cluster.

The AlcesNamespace will be very similar to the MagicNamespace except all the
node specific methods will be removed. This means `index`, `nodename` and
`kickstart_url` will all be removed (and be moved to `NodeNamespace`). It will
still contain the domain level methods (`hosts_url`, `hostip`, etc).

The major additions/ changes will be the following methods:
- `alces.config`: The config for the domain (aka just domain.yaml)
- `alces.node`: The NodeNamespace for the node in scope OR nil if not set
- `alces.group`: Same as alces.node but for a GroupNamespace [OPTIONAL]
- `alces.nodes`: An array of NodeNamespace's for each node in the cluster
- `alces.groups`: Same as alces.nodes but GroupNamespace's of primary groups

These commands will allow the user to access domain level information from
anywhere in the template or config without worrying what is meant by alces. Also
for a particular templating run (e.g. rendering a single template and require
config/ answers), their will only be one alces object, insuring consistency.

Now this Namespace will be initialized with a NodeNamespace if a node is within
scope (e.g. rendering a kickstart file). Now as their is only ever one
AlcesNamespace, then their can only ever be one node in scope. Other nodes can
still be accessed using the `nodes` method but these nodes will not be in scope.

Similarly, if the Node is out of scope, then it will always be out of scope.
This fixes one issue with the previous `alces.nodename` warning when rendering
a template.

### NodeNamespace

Within the API, whenever a node level parameter is requested, it will be
accessed through the NodeNamespace. The NodeNamespace can be accessed in a few
different ways but typically through:

1. The in scope node (if applicable): `alces.node`
1. An iterator: `alces.nodes.each { |node_namespace| ... }`

The NodeNamespace will have a node level information such as: name (previously
nodename) and index. It will also access the node level config through `.config`
method similar to AlcesNamespace.

It will not contain group_index however as this is not node level information
(do not speak to strangers children). Instead it will contain a reference to the
GroupNamespace through a `.group` method.

### GroupNamespace

Similar to the NodeNamespace. A decision has not been made if their will be a
group in scope. So the `alces.group` method may not be included into the API.
However the GroupNamespace can be accessed through:

1. An iterator: `alces.groups.each { group_namespace }`
1. A node: `alces.node.group`

It will have similar methods to NodeNamespace where `name` will return the group
name and `index` will return the group index. It will also have a `nodes` method
which will return an array of NodeNamespace's within the primary group.

## Iterator Scope

This change still contains an issue with the scope of config parameters when
using a iterator. It occurs because the config parameters may contain ERB, but
if they are pulled from an iterator then they are not in the same scope.

Example:
`alces.nodes.each { |node| node.config.value }: <%= alces.node.config.other %>`

`node.config.value` is referring to a value for a node in a collection of nodes
that is being iterated through, however `alces.node.config.other` is statically
defined for the in-scope node. This means referencing of config parameters
within an iterator does not work.

A possible fix to this is to revisit what is meant by the `in-scope node`. When
running an iterator, one would expect that when within the block the node in
scope would be the current node in the iterator. After all, that is the purpose
of the iterator.

So instead of yielding the NodeNamespace to the block, `alces.node` could be
switched instead. Something along these lines:

```ruby
def each
    node_array.each do |node_namespace|
        AlcesNamespace.in_scope_node_stack.push(node_namespace)
        yield
        AlcesNamespace.in_scope_node_stack.pop
    end
end
```

Then the iterator is used by going:
`alces.nodes.each { alces.node.config.value }`

This means their shouldn't be an issue if `config.value` returns an ERB tag
referencing the in-scope node as the iterator has changed. A
similar process will need to be completed for the `GroupNamespace`.

ONE BIG BUT!!

This may not work at all. I am not sure how ERB replaces iterated values. My
guess is it uses blocks like regular ruby. If this is the case, the above
solution should work. However if ERB first expands the each block and then does
the ERB substitutions in a second pass, then the `in-scope node` will not be
set currently and the solution will fail. Will need to research this.

### Alternative

Instead of switching what is meant by `node` as this could be confusing, the
idea of a `scope` namespace could be introduced. It would be accessed through
`alces.scope` and would initially always be set to `nil`. It would be
implemented along these lines:

```ruby
def render_config_value(value)
    AlcesNamespace.scope_stack.push(self) # NOTE: this is the inbuilt ruby self
    render(config.value, AlcesNamespace)  # aka the current scope
    AlcesNamespace.scope_stack.pop
end
```

This `scope` namespace is not designed to be used in the templates, hence why
it should be set to nil initially. However when rendering a `config` value,
`alces.scope` would be set to the namespace that the config belongs to. So
`alces.node.config.value` could reference `alces.scope.config.other` and be
sure that it is accessing it's own config.

This makes config fall through behave nicer as a default set in `domain.yaml`
does not need to reference `alces.node`. This means that if `alces.config.value`
returns `alces.scope.config.other` it will look for `alces.config.other`.

Assuming that the `node` doesn't override `value` in it's own config,
`alces.node.config.value` will also return `alces.scope.config.other`. This will
then be equivalent to `alces.node.config.other`.

## Simplifying the use config and answers

Previously the config was rendered in full before substitution into the
template. If the config used an answer, then the answer was substituted into
the config pre-rendering. Through this process of recursive substitution all
the ERB tags where removed.

However at this point this process this occurs in is not well understood making
the code difficult to maintain. Also now multiple config and answer files are
being loaded into API, it is not practical to render them all up front.

Instead, each value returned from a config or answer should be rendered on an
as-needed basis. The [previous attempt to make this
change](https://github.com/alces-software/metalware/pull/166) failed as it
needed to match the old usage and context, however this change should be much
simpler when made along with the other changes described in this document as we
will then have explicit static paths defined for all templating parameters.

A `RenderParameter` object should handle the access to both the config and
answers. Once a value has been rendered it can be cached as it was created with
explicit paths that should not return a different result if reran. The API MUST
BE stateless in that regard. Initially however, caching is not required as it
is only a performance update as opposed to core functionality.

Also when rendering config and answers, it must be rendered against the same
API object. This insures the config parameters are rendered in the exact same
way as the template and can take advantage of the cached rendered parameters.

How answers are accessed might also be needlessly complex. The concept of an
answer is separate to the concept of a config. This makes the two referencing
each other tricky as they are not rendered currently in the same way.

Their are a few fixes on how this can be overcame:

### Render them in the same way under separate keys

The config can still be stored as `alces.config` (or `alces.node.config` etc)
however also have a `alces.answers` which operates in the same manner. This
allows config parameters to explicitly reference answers and mimics current
usage. However they will be handled separately by the internals of the API. This
design pattern does lead configs referencing answer referencing configs. It also
requires duplication within API and adds complexity.

### Load the answers inside of the config

Instead of treating answers and configs as separate concepts, we can treat
answers as just another type of config (as they kinda are). In this case, the
answers will be loaded under an `answer` key in the config. This means they can
still be explicitly referenced as `alces.config.answer` however internally they
are the same thing. This doesn't removed the circular referencing between the
config and answers, but renders it a moot point.

### Merge the answer over the config

This change would make config's and answer's two sides of the same coin. Instead
of treating the answers as a separate concept, they will be merged directly over
config value. Their is some distinct advantages to doing this. The first is the
user doesn't need to remember if value is stored as `alces.config` or
`alces.answer` and risk getting it wrong, their is only one value.

This would also make setting defaults for answers more logical as they do not
need to be set in `configure.yaml`. Instead the default to the answer is saved
in the config. That way if the answer is not set, it reverts to the config
values as that is the default.

It will still be possible to explicitly reference an answer over a config values
by using separate keys. Doing so would require smart repo design instead of
relying on Metalware to do it for you. The advantage being Metalware is now
operating in a more consistent manner.

It would require the following considerations:

1. Allow hierarchical answers (which order should they be asked in?)
1. Look into conditional questions (their is already a use for this)
1. Relook at how fall through works (do domain answer override group configs)?

# Implementation Considerations

The following items are not critical to the design but should be reviewed before
starting as they may impact how it is implemented.

## API entry point and domain

It might be a good idea to separate out the API entry point and the domain.
Currently they are the same thing, but it could be clear to use
`alces.domain.config` and have a DomainNamespace. This will make `alces` solely
responsible for controlling the API calls.

## The binding wrapper

As ERB uses a binding to determine the scope, a wrapper object is going to be
required. This is because the `alces` tag doesn't exist within the
`AlcesNamespace`, it is the namespace. This means the binding needs to be
external and control access to the namespace.

Currently nil detection isn't working amazingly well, but this is more a symptom
of poor overall design. The API should hopefully resolve this and thus nil
detection should remain in the wrapper.

As all calls go through the AlcesNamespace, they also go through the wrapper.
This means the NodeNamespace does not need it's own wrapper. Instead, when the
wrapper makes the API call, it wraps the return value in a wrapper. As the
method calls on the binding vary, the Blank module should be used.

The wrapper can also keep track of the call stack. This call stack will be used
to print the nil warning if something goes wrong. NOTE: the API should be
stateless and thus the returned object should not use the call stack. The
returned object should be ready to directly accept the next method call.

The following values should not be wrapped: true, false and nil. It also needs
to be able to coerce values to be the wrapped object. Refer to the
`dev/binding` branch for an example wrapper that means most of the
requirements. Note that the binding is NOT stateless and is based on the config
being loaded into the binding (which is now obsolete).

## Remove the concept of a no-node Node

Previously a Node object had to be able to accept a nil as the node name. This
does not make sense as it is essentially a "no-node" Node. This being replaced
by `alces.node` ever being in or out of scope and thus resolves the issue. The
Node object may continually be use internally by Metalware, but should be
refactored.

## Long method calls + Syntax Sugar

The biggest advantage of the API is also the largest draw back, it is explicit.
This means calls like `alces.node.config.network.pri.interface` become standard.
This significantly reduces the usability of the API. Their are two possible
solutions which can be used together:

### Default API short cuts

As all parameter calls now need to start with alces, it is easy define when a
user may want to make a short cut API call; it won't start with alces. For
example, when rendering a kickstart file, `network.pri.interface` can be
automatically prefixed with `alces.node.config`.

This will need to vary depending on template type (e.g. genders would need to be
`alces.config` as the node is out of scope). These short cuts could be hard
coded into Metalware or exist in the repo under varies forms. Possible include
a `.templater` file which lists them.

### Default alias

It might be a good idea to include default alias into the templater. For example
`alces.groups.each` could be shortened to `agroup.each` or `beta.each. These
aliases would need to be customisable and thus need to exist in the repo.

## Pedantry Changes
Small changes we may want to make along the way. Does not influence the overall
design.

1. Future of additional parameters in the namespaces. Now that we are "plugins"
(e.g. named), these methods need to provide additional info to the Namespaces
(typically what will be the AlcesNamespace). Do we want to build this into the
namespace itself or pass it in on an as need basis. The same applies for
FirstBoot

1. Rationalise/ standardise the used of the term "group". The accepted usage now
is a group refers to a primary group that has been configured. Where genders
refer to all "groups of nodes" that appear in the genders file. The genders may
or may not be a primary group.

1. Everything is singular, remove the "s". With the exception of things that are
clearly a collection (e.g. `alces.nodes`) it should be singular. This will make
using the API easier as you do not need to remember if it is `alces.answer` or
`alces.answers`.

1. Do we still need to IterableRecusiveOpenStruct
