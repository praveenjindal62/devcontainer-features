#!/bin/bash
set -e

SED=$(which gsed || which sed)

SCRIPT_DIR=$(dirname "$0")
PIP_REQUIREMENTS=$(cat /requirements.txt)

verify_binary() {
    if which $1 > /dev/null 2>&1; then
        echo "$1 exists at path $(which $1 |  head -n 1)"
        return 0
    else
        return 1
    fi
}

install_pyenv() {
    verify_binary curl
    curl https://pyenv.run | bash
    if [ -n $PYENV_ROOT ]; 
    then
        PYENV_PATH=$PYENV_ROOT
    else
        PYENV_PATH=$HOME/.pyenv
    fi
    echo "PATH=\"${PATH}:${PYENV_PATH}\"" > /etc/environment
    . /etc/environment
    verify_binary pyenv
    pyenv --version
}

main() {
    # Install pyenv
    if ! verify_binary pyenv; then
        install_pyenv
    fi

    # Coerce space separated string to array
    if [[ ${#PYTHON_VERSIONS[@]} -eq 1 ]]; then
        PYTHON_VERSIONS=($PYTHON_VERSIONS)
    fi

    if [[ -z "${PYTHON_VERSIONS[@]}" ]]; then
        echo "No python versions specified. Make sure PYTHON_VERSIONS is set." 1>&2
        exit 1
    fi

    # Find all latest pyenv supported versions for requested python versions
    PYENV_VERSIONS=()
    for v in "${PYTHON_VERSIONS[@]}"; do
        LATEST=$(get_latest_patch_version "$v")
        if [[ -z "$LATEST" ]]; then
            echo "Latest version could not be found for ${v}." 1>&2
            exit 1
        fi
        PYENV_VERSIONS+=($LATEST)
    done

    # Install each specific version
    for v in "${PYENV_VERSIONS[@]}"; do
        pyenv install "$v" &
    done
    wait

    # Install dependencies for each version
    for v in "${PYENV_VERSIONS[@]}"; do
        PYENV_VERSION=$v pyenv exec pip install --upgrade $PIP_REQUIREMENTS
    done

    # Set all installed versions as globally accessible
    pyenv global ${PYENV_VERSIONS[@]}
}

get_latest_patch_version() {
    pyenv install --list |  # Get all python versions
        $SED 's/^ *//g' |  # Remove leading whitespace
        grep -E "^$1" |  # Find specified version by matching start of line
        grep -v -- "-c-jit-latest" |  # Filter out pypy JIT versions
        $SED -E '/(-[a-zA-Z]+$)|(a[0-9]+)|(b[0-9]+)|(rc[0-9]+)/!{s/$/_/}' |  # Append trailing _ to any non development versions to place them lower when sorted
        sort -V |  # Sort using version sorting
        $SED 's/_$//' |  # Remove any added trailing underscores to correct version names
        tail -1  # Grab last result as latest version
}


main