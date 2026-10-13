# Contributing

We're always happy to receive improvements and fixes, so please submit them whenever you can! A few key points are listed below.

> Many feature additions are more suitable for plugins, instead of being added to the core. This is aimed to reduce the future maintenance burden/cost on the maintainers.  
If we deny your PR for this reason, please do consider publishing a plugin, and we'll be happy to add it to the [Plugins List](https://docs.fleaflet.dev/plugins/list)! See [Making A Plugin](https://docs.fleaflet.dev/plugins/making-a-plugin) for more information.

* **If your PR will add a major or breaking change, please discuss it with us first, via the Issue Tracker.**  
We don't want to waste your time if we think it's more appropriate for a plugin, and it helps to make a clear plan before starting work.
Additionally, if your PR makes breaking changes, or depends on another breaking commit, we may have some additional guidance.

* **Create a draft PR as soon as work starts, and take it out of draft status when ready for review.**  
Keep everyone in the loop, so no-one tries working on the same thing as you.

* **Don't change the package version, GitHub workflows, lints, or any other meta files without clarification.**  
We rely on a standardized process and procedure to ensure top-quality releases.

* **Use a clear (preferably [Conventional](https://www.conventionalcommits.org/)) PR title.**  
This makes it easier for us to group commits for release and write correct CHANGELOGs.

## AI

Please remember, **the maintainers do not usually use AI to assist in maintaining this library**. Every issue opened,
or pull request created is treated equally and investigated/tested manually, without the use of AI.

Therefore, it is very easy to make such a large workload it is impossible for the maintainer's limited time and
resources to keep up. This easily causes burnout.

We understand new contributors are eager to help and learn, but please remember this is a real software product used
and maintained by real people, not AI.

* **Creating a bug report with AI?**  
Make sure it includes everything that's expected, and that the example code is executable. Make sure that it isn't
hallucinating: test all of the assertions it makes yourself. If your report suggests you have evidence that we
haven't seen and isn't sensitive, we will ask to see it. Make sure the bug is not already fixed. If we suspect there
is no human oversight, it will be rejected.

* **Opening a pull request with AI?**  
If it's fixing a bug that the AI also spotted: make sure yourself it actually is a bug and that your code actually
fixes it. Make sure it is clear that you used AI, even if it is usually inferrable from the code. If the code is of
insufficient quality, or goes against good practises, or does not follow the planned/discussed resolution options in
an issue report without good reason, it will be rejected. If we suspect there is no human oversight, it will be
rejected.

**Humans must take all responsibility for the output of their AI model.**

We do not have a specific policy against or for the use of AI. This does not necessarily reflect the views of
individual maintainers, but tries to keep things as simple as possible. We want new contributors! But we would also
like new contributors to have a good idea of what they are actually doing.
