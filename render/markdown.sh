#!/bin/sh

set -ex

if [ -z "$1" ]; then
    echo "Usage: $0 <http-root-url>"
    exit 1
fi

url=$1

cd $(dirname ${0})/../

rm -rf markdown
mkdir markdown

cat layout/header.md | sed 's#@@URL@@#'${url}'#g' > markdown/index.md

for i in $(ls entries/*.md 2>/dev/null); do
    user=$(echo $(basename ${i}) | sed s/.md$//)

    cat ${i} > markdown/${user}.md
    cat layout/entry.md | sed 's/@@USER@@/'${user}'/g;s#@@URL@@#'${url}'#g' >> markdown/${user}.md
done
