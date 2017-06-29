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
        local cur="$2" cmds input cur_ruby

        if [[ -z "$cur" ]]; then
            cur_ruby="__CUR_IS_EMPTY__"
        else
            cur_ruby=$cur
        fi

        cmds=$(
            cd /opt/metalware &&
            PATH="/opt/metalware/opt/ruby/bin:$PATH"
            bin/autocomplete $cur_ruby ${COMP_WORDS[*]}
        )

        COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    }
    complete -o default -F _metal metal me
fi
