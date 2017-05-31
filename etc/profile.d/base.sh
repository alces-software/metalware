################################################################################
##
## Alces Metalware - Shell configuration
## Copyright (c) 2008-2015 Alces Software Ltd
##
################################################################################
metal() {
    # XXX Disabled for now as does not do anything for new Metalware.
    # if [[ -t 1 && "$TERM" != linux ]]; then
    #     export alces_COLOUR=1
    # else
    #     export alces_COLOUR=0
    # fi
    (cd /opt/metalware && bin/metal "$@")
    # unset alces_COLOUR
}

if [ "$ZSH_VERSION" ]; then
  export metal
else
  export -f metal
fi
alias met=metal

# XXX Disabled as completion not done yet for new Metalware.
# if [ "$BASH_VERSION" ]; then
#     _metal() {
#         local cur="$2" prev="$3" cmds opts

#         COMPREPLY=()

#         cmds=$(ls /opt/metalware/lib/actions)

#         COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
#     }

#     complete -o default -F _metal metal me
# fi
