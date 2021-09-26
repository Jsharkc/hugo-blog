#!/bin/sh

if [ ! -d "../jsharkc.github.io" ]
then
    echo "jsharkc.github.io not exist. clone jsharkc.github.io.git"
    cd .. && git clone https://github.com/Jsharkc/jsharkc.github.io.git
    cd -
fi

echo "Generating site"
hugo -b https://jsharkc.github.io/

echo "Copy static file to jsharkc.github.io"
cp -r ./public/* ../jsharkc.github.io

echo "Updating jsharkc.github.io"
cd ../jsharkc.github.io && git add --all && git commit -m "Publishing to gh-pages (publish.sh)"

echo "Push to github"
git push origin 
