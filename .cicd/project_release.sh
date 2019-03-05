#!/usr/bin/env /bin/bash

set -euo pipefail


projectrelease_help() {
    echo "
Usage:
    $(basename $0) --project <PROJECT> --version <VERSION>

    --project <PROJECT>     update files of PROJECT, one of:
$(
for p in ${PROJECTS_SUPPORTED[@]}; do
    echo -e '                              - '$p;
done
)

    --version <VERSION>     generate Homebrew files for specified VERSION in
                            SemVer2 format, equal to appropriate GitHub tag

Description:
    This script generates Homebrew files for the new version of the specified
    project.

"
}


projectrelease_raise() {
    echo -e "\\nERROR: $*\\n" >&2
    exit 1
}


projectrelease_parse_args() {
    while (( $# > 0 )); do
        arg="$1"
        shift
        case "$arg" in
            (--project)
                [[ -n "${1:-}" ]] || projectrelease_raise \
                    "project name must be present next to --project option."
                [[ " ${PROJECTS_SUPPORTED[@]} " =~ " $1 " ]] || \
                    projectrelease_raise "unsupported project '$1'."
                project="$1"
                shift
                ;;
            (--version)
                [[ -n "${1:-}" ]] || projectrelease_raise \
                    "version must be present next to --version option."
                [[ "$1" =~ ^([0-9]+\.){2}[0-9]+$ ]] || \
                    projectrelease_raise \
                        "incorrect version format '$1'. SemVer2 expected."
                version="$1"
                shift
                ;;
            (help|--help|-?|--?)
                projectrelease_help
                exit 0
                ;;
            (*)
                projectrelease_help
                exit 1
                ;;
        esac
    done
    if [[ -z ${project:-} ]] || [[ -z ${version:-} ]]; then
        projectrelease_help
        exit 1
    fi
}


projectrelease_init() {
    PROJECTS_SUPPORTED=( libthemis )
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
}


projectrelease_main() {
    if [[ "$project" == 'libthemis' ]]; then
        project_github='themis'
    else
        project_github="$project"
    fi

    TMP_DIR="$(mktemp -d)"

    wget "https://github.com/cossacklabs/${project_github}/archive/${version}.tar.gz" \
        -O "${TMP_DIR}/${project_github}.tar.gz"
    sha256=$(sha256sum "${TMP_DIR}/${project_github}.tar.gz" | awk '{print $1'})

    cp -f "${BASE_DIR}/Formula.templates/${project}.rb" "${TMP_DIR}/"

    sed -i "s/<%CL_THEMIS_VERSION%>/$version/g" "${TMP_DIR}/${project}.rb"
    sed -i "s/<%CL_THEMIS_GITHUB_TARGZ_SHA256%>/$sha256/g" "${TMP_DIR}/${project}.rb"

    cp -f "${TMP_DIR}/${project}.rb" "${BASE_DIR}/../Formula/${project}.rb"

    rm -rf "$TMP_DIR"

    cd "${BASE_DIR}/../"

    if ! git diff --exit-code; then
        git config user.name 'Cossack Labs CICD'
        git config user.email 'cicd@cossacklabs.com'

        git add -A
        git commit -m "[CICD] Release $project $version"
        git push
    else
        echo 'Nothing to commit - no changes.'
    fi

    cd "$BASE_DIR"
}


projectrelease_run() {
    projectrelease_init
    projectrelease_parse_args "$@"
    projectrelease_main
}


projectrelease_run "$@"
