#!/bin/sh

set -ex

cd $(dirname ${0})/../

rm -rf docs
mkdir docs

cp layout/*.png docs/
cp -R screens docs/
markdown_py layout/header.md > docs/index.html

for i in $(ls entries/*.md 2>/dev/null); do
    user=$(echo $(basename ${i}) | sed s/.md$//)

    markdown_py ${i} > docs/${user}.html
    cat layout/entry.md | sed 's/@@USER@@/'${user}'/g' | markdown_py -x md_video -c render/markdown-config.json >> docs/${user}.html

    markdown_py ${i} >> docs/index.html
    cat layout/entry-short.md | sed 's/@@USER@@/'${user}'/g' | markdown_py -x md_video -c render/markdown-config.json >> docs/index.html
done

echo "" >> docs/index.html
