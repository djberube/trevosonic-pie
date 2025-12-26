# Contributing

Hello! If you are interested in contributing to Trevosonic Pie in some way, fantastic. Everyone is welcome to help!

Are you wondering about the different ways you might be able to contribute? See [TYPES-OF-CONTRIBUTIONS.md](TYPES-OF-CONTRIBUTIONS.md).

For upstream Sonic Pi features, see [the Sonic Pi features project board](https://github.com/orgs/sonic-pi-net/projects/1).

## Understanding the Trevosonic Pie source code
There are several ways that you can learn more about the technical design of the source code.
- You can read brief outlines of the source code structure on the upstream [Sonic Pi wiki](https://github.com/sonic-pi-net/sonic-pi/wiki). _**Note: these reflect the upstream project and may not include Trevosonic Pie-specific changes.**_
- You can study the source code itself at the official [Trevosonic Pie GitHub repository](https://github.com/davidjberube/trevosonic-pie)
- For upstream Sonic Pi documentation, see the [upstream repository](https://github.com/sonic-pi-net/sonic-pi)
- You can ask questions at any of the places we gather as a [community](COMMUNITY.md)

## Project and development process guidelines
There are several guidelines that we value when planning the format of new work. We encourage community contributors to keep these in mind also when thinking about contributing to Sonic Pi. They are:

- We prefer to limit the number of different technologies/frameworks/languages used in the project where practical
- We prefer friendly, conversational style for documentation over formal language
- In line with the core aims of the project, we want Sonic Pi features to be simple enough for a 10 year old child to understand and use
- We prefer proposed contributions, as well as the technical choices made when building them, to have clear benefits that outweigh any downsides
- We prefer not to introduce potential instability or uncertainty into the code that is used in the app's build process unless there is a really good reason to do so
- Trevosonic Pie maintains compatibility with Sonic Pi while adding pattern-based features. Contributions should align with this vision.

Also, regarding the Sonic Pi development process:
- We don't set development deadlines
- All work in progress we merge into the `dev` branch. We merge code into the `stable` branch for stable releases.
- We want code intended to be merged into the `dev` or `stable` branches to be passing all tests where possible
- We prefer an issue ticket to be raised as soon as possible when a new bug is discovered (ideally within 48 hours)
- When someone intends to start work on an issue or new feature:
  - They check first that no-one else intends to (or has already done) work on it, via the [Issues page](https://github.com/davidjberube/trevosonic-pie/issues)
  - If the issue or feature is freely available for work, the person who intends to start work on it mentions this publicly somewhere (for issues, leaving a message on the ticket requesting to be assigned to it, and for new features, mentioning it in any of the places we gather as a [community](COMMUNITY.md))

## Ideal process for contributing with code
1. Familiarise yourself with the part(s) of the code that you wish to contribute towards if necessary. We're always happy to answer questions about the Sonic Pi code!
2. For complex or large code changes, it's worth initially discussing the potential solutions with the core team and other Sonic Pi contributors - either by opening an issue and labelling it as a feature request, or again by chatting with us at any of the places we gather as a [community](COMMUNITY.md).
3. Fork a copy of the Trevosonic Pie repository to your personal GitHub account.
4. Clone your fork to your local machine.
5. Make changes to your local clone of Trevosonic Pie.
6. Commit your changes and push them to your fork on GitHub.
7. Open a Pull Request to the official Trevosonic Pie repository.
8. If changes are requested either by bots attached to the Sonic Pi repository, or the core team, make the desired changes and push again to your fork on GitHub.
9. Once your code has passed review, it will be merged.

(If you need any further help with any of the above steps for preparing a Pull Request for us on GitHub, it's worth searching the [GitHub documentation](https://docs.github.com/) first, but feel free to ask us for help if you're still stuck after that).

**Note**: if it is decided that a contribution will _not_ be included at the time, this does _not_ mean that the effort is not valued! if such a situation occurs, the core team will endeavour to provide an explanation.
