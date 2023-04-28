#!/bin/bash

self=$( realpath $0 )
dir=$( dirname $self )

function echoerr { echo "$@" 1>&2; }

function on_main {
    git merge-base --is-ancestor HEAD $parent
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function get_user {
    json=$( curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/user )
    echo $( echo $json | jq '.login' )
}

function have_comment {
    all_comments=$( curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$repo/pulls/$pr_number/comments )

    user=$( get_user )

    sm_comment=$( echo $all_comments | jq "$( printf '[.[] | select(.path=="%s" and .user.login=="%s")] | length' $sm_path $user )" )

    if [ "$sm_comment" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

function post_comment {
    comment="$( printf "Check that your submodule is up-to-date.<br /><br />By the way, did you know that %s" "$( $dir/random-dolphin-fact )" )"

    json=$( printf '{"body":"%s","commit_id":"%s","path":"%s","line":1}' "$comment" "$parent_commit" "$sm_path" )

    echoerr "Posting comment"

    curl -s -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $token" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$repo/pulls/$pr_number/comments \
        -d "$json"
}

function child {
    if on_main ; then
        echoerr "Is already on main"
    else
        echoerr "Is not on main"
        if have_comment ; then
            echoerr "Already has comment"
        else
            echoerr "Does not have comment"
            post_comment
        fi
    fi
}

usage="Usage: $0 token parent_branch commit_id repo pr_number"

if [ $# -lt 1 ]; then
    echo "$usage"
    exit 3
fi

if [ $1 == "--child" ]; then
    child
    exit $?
fi

if [ $# -lt 5 ]; then
    echo "$usage"
    exit 2
fi

git config --global --add safe.directory '*'

export token="$1"
export parent="$2"
export parent_commit="$3"
export repo="$4"
export pr_number="$5"

git submodule foreach "$self --child"
