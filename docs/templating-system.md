
# Metalware templating system

Various Metalware commands render templates as all or part of their
functionality. To do this Metalware provides a flexible templating system,
which broadly functions as follows:

- Config files in the repo `config` directory are loaded. If a template is not
  being rendered for a particular node then only the `domain.yaml` config is
  loaded; otherwise configs will be loaded in the following precedence order
  for the node:

  - `domain.yaml` is always the lowest precedence config;

  - the corresponding configs for each of the node's specified gender groups
    are loaded, if any, from right (low precedence) to left (high precedence);

  - `${NODE_NAME}.yaml` is loaded for the current node's `$NODE_NAME`, this is
    the highest precedence config.

- Any such config files which are not present are simply skipped.

- The available loaded configs are then deep merged together in their
  precedence order, i.e. YAML objects will be deep merged together in
  precedence order, while all other YAML values will be overwritten to the
  highest precedence present config value.

- The resulting object will then be made available when rendering templates;
  additionally an [`alces` namespace](#alces-namespace) will also be merged in
  to this object, which provides access to various other properties of the
  environment.

- The template to be rendered is then rendered to the appropriate file, which
  can be a real file or stdout depending on the command. Templates are written
  in ERB; the variables available within the ERB tags are the properties of the
  final config object. For nicer templates, nested config object values are
  made accessible using `.` notation as well as Ruby hash access notation
  (`[]`); i.e. `<%= networks.pri.hostname %>` can be written instead of `<%=
  networks['pri']['hostname'] %>`. Additionally, an `each` function is made
  available on these objects at any level within the config to iterate through
  the config values available at that level, for example see
  [here](https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/files/core/networking.sh#L9)
  for a usage of this.


## `alces` namespace

The `alces` namespace is available within templates along with the repo config,
and provides access to various properties of the environment, previously
discovered and generated values, and values generated based on the repo config.
Values available within this namespace are:

<table>

<tr>
<th>Value</th>
<th>Description</th>
<th>Example usage</th>
</tr>


<tr>
<td><code>index</code></td>
<td>

The index of the current node within its primary group. The primary group for a
node is the first group associated with that node in the genders file, i.e. the
first group to appear in the output of `nodeattr -l $NODE_NAME`. The
<code>index</code> is guaranteed to be consistent between invocations of
different commands which template for the same node, so long as the genders
file remains consistent.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/config/domain.yaml#L3'>
metalware-default
</a>
</td>
</tr>

<tr>
<td><code>group_index</code></td>
<td>

The unique index of the current node's primary group. This is guaranteed to
remain consistent for a particular primary group; it may change for a node if
that node's primary group is changed.

</td>

<td>
<pre lang="yaml">

ip: "10.10.<%= alces.group_index %>.<%= alces.index %>"

</pre>
</td>
</tr>


<tr>
<td><code>nodename</code></td>
<td>

The name of the current node being templated.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/config/domain.yaml#L26'>
metalware-default
</a>
</td>
</tr>


<tr>
<td><code>firstboot</code></td>
<td>

`true` or `false` depending on if this is the initial boot or not of this node;
only available when rendering PXELINUX templates as part of the `metal build`
command.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/pxelinux/default#L6'>
metalware-default
</a>
</td>
</tr>


<tr>
<td><code>files</code></td>
<td>

A hash/object with details of the specified build files for the node. See <a
href='design/01-metalware-improvements.md#metalware-config-files-parameter#'>here</a>
for details of how this is formed, and <a
href='design/01-metalware-improvements.md#magic-namespace'>here</a> for the
structure of this object. Only available when rendering templates in `metal
build`.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/master/files/main.sh#L21'>
metalware-default
</a>
</td>
</tr>


<tr>
<td><code>genders</code></td>
<td>

An object with properties for every defined gender group, each of which has a
value which is an array of the node names in that group.

</td>

<td>
<pre lang='sh'>

<% alces.genders.nodes.each do |node| %>
ping "<%= node %>"
<% end%>

</pre>
</td>
</tr>


<tr>
<td><code>hunter</code></td>
<td>

A hash/object with properties for accessing MAC addresses found using the
`metal hunter` command, where the properties are node hostnames and the values
are the corresponding MAC address found for the node.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/dhcp/default#L2'>
metalware-default
</a>

</td>
</tr>


<tr>
<td><code>hosts_url</code></td>
<td>

A URL from which the Metalware deployment server `/etc/hosts` file can be
retrieved via a HTTP GET request.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/files/core/base.sh#L6'>
metalware-default
</a>

</td>
</tr>


<tr>
<td><code>genders_url</code></td>
<td>

A URL from which the Metalware deployment server `genders` file
(`/var/lib/metalware/rendered/system/genders`) can be retrieved via a HTTP GET
request.

</td>

<td>
<pre lang='sh'>

curl "<%= alces.genders_url %>" > /etc/genders

</pre>
</td>
</tr>


<tr>
<td><code>kickstart_url</code></td>
<td>

A URL from which the Kickstart file for the current node can be retrieved via a
HTTP GET request.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/pxelinux/default#L10'>
metalware-default
</a>

</td>
</tr>


<tr>
<td><code>build_complete_url</code></td>
<td>

A URL which notifies the `metal build` command's watching process that a node
is built, when a HTTP GET request is made to it (which is not a semantic usage
of GET, but is kept for now for legacy purposes).

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/kickstart/default#L93'>
metalware-default
</a>

</td>
</tr>


<tr>
<td><code>hostip</code></td>
<td>

The IP of the Metalware deployment server on the deployment network. The IP on
the specified private/primary network is used if the deployment server is a
Controller appliance; otherwise <code>hostname -i</code> is used to determine
the IP, which may or may not be on the desired network.

</td>

<td>
<a
href='https://github.com/alces-software/metalware-default/blob/226cf530d4ce6bdc09a6c65ba3f4bfc553032752/config/domain.yaml#L17'>
metalware-default
</a>

</td>
</tr>

</table>
