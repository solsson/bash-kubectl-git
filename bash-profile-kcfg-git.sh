#### Customize prompt, with git and kubectl ####

host_or_nothing() {
  AT="";
  [[ "$HOSTNAME" =~ "MacBook" ]] || AT="$HOSTNAME"
  echo "$AT"
}

# https://coderwall.com/p/fasnya/add-git-branch-name-to-bash-prompt
parse_git_branch() {
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ ! -z "$branch" ] && echo " (${branch:0:10})"
}

#export PS1="\u@\$(host_or_nothing)\[\033[34m\]\$(basename \"\$KUBECONFIG\")\[\033[00m\] \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "

# https://stackoverflow.com/questions/3497885/code-challenge-bash-prompt-path-shortener
_dir_chomp () {
    local IFS=/ c=1 n d
    local p=(${1/#$HOME/\~}) r=${p[*]}
    local s=${#r}
    while ((s>$2&&c<${#p[*]}-1))
    do
        d=${p[c]}
        n=1;[[ $d = .* ]]&&n=2
        ((s-=${#d}-n))
        p[c++]=${d:0:n}
    done
    echo "${p[*]}"
}
export PS1="\[\033[32m\]\$(_dir_chomp \$(pwd) 10)\[\033[33m\]\$(parse_git_branch)\[\033[00m\] \[\033[34m\]\$(basename \"\$KUBECONFIG\")\[\033[00m\] $ "

#### End prompt customization ####

# https://github.com/solsson/kubectx/pull/1
# Assumption: default config (~/.kube/config) is never a production cluster -- you must explicitly select those per shell
#chmod a-w ~/.kube/config

# TODO how do we get bash completion to work for kubectl aliases?
alias k="kubectl"

kcfg_block() {
  KCFG="${1}"
  echo "Block $KCFG"
}

kcfg_unblock() {
  KCFG="${1}"
  echo "Unblock $KCFG"
}

kcfg() {
  KCFG="${1}"
  [ "$KCFG" == "block" ] && kcfg_block "${2}" && return
  [ "$KCFG" == "unblock" ] && kcfg_unblock "${2}" && return
  # keep config names short and you won't need tab completion :)
  [ ! -f "$KCFG" ] && [ -f "$HOME/.kube/$KCFG" ] && KCFG="$HOME/.kube/$KCFG"
  export KUBECONFIG="$KCFG"
  namespaces=$(kubectl --request-timeout 3 get namespace -o jsonpath="{.items[*].metadata.name}")
  [ $? -eq 0 ] && {
    echo -n "Aliases for $(basename $KUBECONFIG):"
    for namespace in $namespaces
    do
      # https://github.com/kubernetes/kubernetes/pull/23262
      alias k-$namespace="kubectl --namespace $namespace"
      echo -n ", k-$namespace"
    done
    echo ""
  }
  unset namespace
}
