# The OpenTTD 1.11 Title Screen Competition

This repository automates part of the Title Screen Competitions.

It renders, based on the savegames, some animated GIFs, some mp4s, and PNGs.
It combines these to generate some HTML files for people to quickly and easily see how an entry looks in different resolutions.

## To add an entry

Simply add an entry to the `entries` folder.
The savegame should be called `USERNAME.sav` and a markdown file `USERNAME.md` should be next to it, with some fluff the user wrote about the savegame.
When you push this to GitHub, a GitHub Action will automatically do the rest.

## To update an entry

Simply update the savegame in the `entries` folder, including the hidden `.done` file.
After pushing this to Github, a GitHub Action will automatically do the rest.

## Where is the rendered Markdown?

This can be found in the `markdown` folder.
This is automatically updated on every change.
