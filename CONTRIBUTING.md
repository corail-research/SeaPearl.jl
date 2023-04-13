# Contributing to SeaPearl

Please take a moment to review this document in order to make the contribution
process easy and effective for everyone involved.

Following these guidelines helps to communicate that you respect the time of
the developers managing and developing this open source project. In return,
they should reciprocate that respect in addressing your issue, assessing
changes, and helping you finalize your pull requests.

Contributions to SeaPearl are governed by our [Code of Conduct][1]. Come join us!

## Using the issue tracker

The [GitHub issue tracker][#gh_issues] is the preferred channel for
[bug reports](#bug-reports), [features requests](#feature-requests)
and [submitting pull requests](#pull-requests), but please **do not** 
derail or troll issues. Keep the discussion on topic and respect the 
opinions of others.

## Bug reports

A bug is a _demonstrable problem_ that is caused by the code in our
repositories.  Good bug reports are extremely helpful - thank you!

Guidelines for bug reports:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   latest `main` or `next` branch in the repository.

3. **Isolate the problem** &mdash; ideally create a reduced test case.

A good bug report shouldn't leave others needing to chase you up for more
information. Please try to be as detailed as possible in your report. What is
your environment? What steps will reproduce the issue? What OS experiences the
problem? What would you expect to be the outcome? All these details will help
people to fix any potential bugs. Our issue template will help you include all
of the relevant detail.

Example:

> Short and descriptive example bug report title
>
> A summary of the issue and the browser/OS environment in which it occurs. If
> suitable, include the steps required to reproduce the bug.
>
> 1. This is the first step
> 2. This is the second step
> 3. Further steps, etc.
>
> `<url>` - a link to the reduced test case
>
> Any other information you want to share that is relevant to the issue being
> reported. This might include the lines of code that you have identified as
> causing the bug, and potential solutions (and your opinions on their
> merits).

## Feature requests

Feature requests are welcome. But take a moment to find out whether your idea
fits with the scope and aims of the project. It's up to *you* to make a strong
case to convince the project's developers of the merits of this feature. Please
provide as much detail and context as possible.

## Pull requests

Good pull requests - patches, improvements, new features - are a fantastic
help. They should remain focused in scope and avoid containing unrelated
commits.

**Please ask first** before embarking on any significant pull request (e.g.
implementing features, refactoring code), otherwise you risk spending a lot of
time working on something that the project's developers might not want to merge
into the project. You can reach out to the project's maintainers to make sure.  
We're always open to suggestions and will get back to you as soon as we can!

### Commit message conventions

A well-crafted Git commit message is the best way to communicate context about a
change to other developers working on that project, and indeed, to your future self.

Commit messages can adequately communicate why a change was made, and understanding
that makes development and collaboration more efficient.

Here's a great template of a good commit message

```
Capitalized, short (50 chars or less) summary

More detailed explanatory text, if necessary.  Wrap it to about 72
characters or so.  In some contexts, the first line is treated as the
subject of an email and the rest of the text as the body.  The blank
line separating the summary from the body is critical (unless you omit
the body entirely); tools like rebase can get confused if you run the
two together.

Write your commit message in the imperative: "Fix bug" and not "Fixed bug"
or "Fixes bug."  This convention matches up with commit messages generated
by commands like git merge and git revert.

Further paragraphs come after blank lines.

- Bullet points are okay, too

- Typically a hyphen or asterisk is used for the bullet, followed by a
  single space, with blank lines in between, but conventions vary here

- Use a hanging indent
```

### For new Contributors

If you never created a pull request before, welcome :tada: :smile:
[Here is a great tutorial][2] on how to send one :)

1. [Fork][3] the project, clone your fork,
   and configure the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone https://github.com/<your-username>/<repo-name>
   # Navigate to the newly cloned directory
   cd <repo-name>
   # Assign the original repo to a remote called "upstream"
   git remote add upstream https://github.com/apache/<repo-name>
   ```

2. If you cloned a while ago, get the latest changes from upstream:

   ```bash
   git checkout main
   git pull upstream main
   ```

3. Create a new topic branch (off the main project development branch) to
   contain your feature, change, or fix:

   ```bash
   git checkout -b <topic-branch-name>
   ```

4. Make sure to update, or add to the tests when appropriate. Patches and
   features will not be accepted without tests. Look for a `Testing` section in
   the project’s README for more information.

5. If you added or changed a feature, make sure to document it accordingly in
   the [SeaPearl documentation][4] repository.

6. Push your topic branch up to your fork:

   ```bash
   git push origin <topic-branch-name>
   ```

8. [Open a Pull Request][7]
   with a clear title and description.
   
9. If you are struggling with something, there is a -small, but growing- [wiki](https://github.com/corail-research/SeaPearl.jl/wiki)

## Triagers

SeaPearl committers who have completed the GitHub account linking
process may triage issues. This helps to speed up releases and minimises both
user and developer pain in working through our backlog.

If you are not an official committer, please reach out to our project's maintainers
to learn how you can assist with triaging indirectly.

## Maintainers

If you have commit access, please follow this process for merging patches and cutting
new releases.

### Reviewing changes

1. Check that a change is within the scope and philosophy of the component.
2. Check that a change has any necessary tests.
3. Check that a change has any necessary documentation.
4. If there is anything you don’t like, leave a comment below the respective
   lines and submit a "Request changes" review. Repeat until everything has
   been addressed.
5. If you are not sure about something, mention specific people for help in a
   comment.
6. If there is only a tiny change left before you can merge it and you think
   it’s best to fix it yourself, you can directly commit to the author’s fork.
   Leave a comment about it so the author and others will know.
7. Once everything looks good, add an "Approve" review. Don’t forget to say
   something nice 👏🐶💖✨
8. If the commit messages follow [our conventions](#seapearl-commit-message-conventions)

   1. If the pull request fixes one or more open issues, please include the
      text "Fixes #[issue number]".
   2. Use the "Rebase and merge" button to merge the pull request.
   3. Done! You are awesome! Thanks so much for your help 🤗

9. If the commit messages _do not_ follow our conventions

   1. Use the "squash and merge" button to clean up the commits and merge at
      the same time: ✨🎩
   2. If the pull request fixes one or more open issues, please include the
      text "Fixes #[issue number]".

Sometimes there might be a good reason to merge changes locally. The process
looks like this:

### Reviewing and merging changes locally

```
git checkout main # or the main branch configured on github
git pull # get latest changes
git checkout feature-branch # replace name with your branch
git rebase main
git checkout main
git merge feature-branch # replace name with your branch
git push
```

When merging PRs from forked repositories, we recommend you install the
[hub][#gh_hub] command line tools.

This allows you to do:

```
hub checkout link-to-pull-request
```

meaning that you will automatically check out the branch for the pull request,
without needing any other steps like setting git upstreams! :sparkles:

## Thanks

Special thanks to [Hoodie][#gh_hoodie] for the great
CONTRIBUTING.md template.

A big thanks to [Robert Painsi][5] and [Bolaji Ayodeji][6] for
some commit message conventions.

[1]: https://github.com/corail-research/SeaPearl.jl/blob/master/CODE_OF_CONDUCT.md
[2]: https://egghead.io/series/how-to-contribute-to-an-open-source-project-on-github
[3]: https://help.github.com/fork-a-repo
[4]: https://corail-research.github.io/SeaPearl.jl/dev/
[5]: https://gist.github.com/robertpainsi/b632364184e70900af4ab688decf6f53
[6]: https://www.freecodecamp.org/news/writing-good-commit-messages-a-practical-guide
[7]: https://help.github.com/articles/using-pull-requests

[#gh_issues]: https://github.com/corail-research/SeaPearl.jl/issues
[#gh_hoodie]: https://github.com/hoodiehq/hoodie
[#gh_hub]: https://hub.github.com
