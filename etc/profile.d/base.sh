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
    (cd /opt/metalware && PATH="/opt/metalware/opt/ruby/bin:$PATH" bin/metal "$@")
    # unset alces_COLOUR
}

if [ "$ZSH_VERSION" ]; then
    export metal
else
    export -f metal
fi
alias met=metal

if [ "$BASH_VERSION" ]; then
    _metal() {
        local cur="$2" prev="$3" cmds opts

        path=$( IFS=$'/'; echo "${COMP_WORDS[*]}" | sed "s/^metal\/\|$cur$//g" 2>/dev/null)
        cur_dir="/opt/metalware/src/commands/$path"

        if [ -d "$cur_dir" ]; then
            cmds=$(ls $cur_dir | sed s/\.rb//g)
        fi

        # Additional bash commands, ideally these will be migrated to ruby
        if [ "$path" == "" ]; then
            cmds="$cmds power console"
        fi

        COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    }
    complete -o default -F _metal metal me
fi
