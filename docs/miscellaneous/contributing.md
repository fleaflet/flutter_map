---
id: contributing
sidebar_position: 1
---

# Contributing

`flutter_map` is only as big and useful as it is because of contributors. You can see a [list of current contributors here](https://github.com/fleaflet/flutter_map/graphs/contributors), and there are currently [![GitHub PRs](https://img.shields.io/github/issues-pr/fleaflet/flutter_map.svg?label=Pull%20Requests)](https://GitHub.com/fleaflet/flutter_map/pulls/), each potentially from a new contributor.

Therefore, your contribution would be greatly appreciated, so we've written a guide to help you contribute successfully:

## Rough Guide

**Do you think your contribution is essential to `flutter_map`/useful to all users?**

If not, then creating a plugin might be a good idea. To do this, see the Plugins section in these docs: there is advice, starting templates and a few rules to bear in mind. Plugins are preferred when possible as they keep the base library lightweight and easy to understand.

If you think it might be, continue onwards.

**Is the contribution to fix a bug? Do you feel comfortable coding it yourself?**

If it is, and you are comfortable fixing it yourself, feel free to create an issue stating the bug, mentioning that you're working on fixing it. Then cleanly fork the main repository, and fix the bug. Make sure you only fix/add/remove what's necessary, as this helps to avoid breaking changes. If there is a quick and dirty fix, try not to use it unless the bug is a big one and might take time to fix otherwise.

If it isn't, open a discussion or an issue stating your request. It might be that other people have already found a way to do it. If people like the idea, and you are comfortable doing it yourself, cleanly fork the main repository. Instead of then working on the `main` branch, work in a new branch: this helps to avoid merge conflicts until the end of development. You may choose to then open a DRAFT pull request to signify that you are working on it. Make sure you only fix/add/remove what's necessary, as this helps to keep track of changes.

If you don't feel comfortable coding changes yourself, start a discussion or an issue.

**I've finished coding it. What's next?**

Make sure you thoroughly test your changes, and consider writing automated tests.

Then consider whether you need to write documentation. If you do, make sure you follow a similar format to all the other pages in these docs, and use correct spelling and grammar (consider getting a spell checker for Markdown). Then remember to change the documentation version at 'introduction/go'. Change the title of the grey box, the text version, and the link (to the newest migration page), but leave the dynamic badge and other text untouched. If no new documentation is needed, don't touch the grey box.

After that, check if you need to add a migration guide. This is only applicable if the change was a breaking change.

One last thing! Consider if you need to write examples for your changes. If it's a bug fix, you probably won't need to, unless an example also needs to be fixed. But if it's a feature addition, it needs an example, or at least the updating of an existing example. Make sure you test the example as well!

**Can I publish it yet?**

Yes! Open a PR (or take the existing PR out of draft stage), and link the issue that you opened.

Hopefully a maintainer will merge your changes quickly. Note that not every new merge will result in a new pub.dev release, so you may have to switch to using the [GitHub installation method](/introduction/go#from-githubcom) for your new features.

We appreciate your changes!
