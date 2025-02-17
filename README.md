# strife-patches

Repository for community-made changes to Strife.

## Strife Community Discord
Join our [Discord server](https://discord.gg/KuC7ufnRnU) to connect with the community.

## Brief Introduction to How the Game Executable Works
In the Strife installation folder, you can find the 'game' directory. Inside, there are two important files: _resources0.s2z_ and _resources2.s2z_. These are .zip archives with their extensions changed. 
- _resources0.s2z_ contains all the original game files (scripts, models, textures, sounds, etc.) that the executable loads initially.
- _resources2.s2z_ contains the changes we have made so far. Any files in _resources2.s2z_ with the same directories and names as those in _resources0.s2z_ will replace the original files.
- If there are other _resourcesXXX.s2z_ files, the game will process them in the same way.
- Finally, the game loads files from the "game" directory itself, so any changes to files in this directory will take effect in the client.

## Getting Started
- Extract the contents of _resources0.s2z_ into the "game" directory.
- Extract _resources2.s2z_ into the "game" directory, replacing any existing files.
- Any changes made to the extracted files will take effect in the client.

## How to Contribute
If you are ready to contribute, you can either pack the changed files into a new _resourcesXXX.s2z_ archive and share it with us on our [Discord server](https://discord.gg/KuC7ufnRnU), or (if you are familiar with how Git works) create a fork from the "dev" branch and submit a pull request to the "dev" branch.

If you choose to create a pull request and you make changes to files that were not added to repository yet (original file from resources0.s2z is used), please, add an original file in separate commit before applying changes. This serves two goals: it makes review easier for us and keeps history of changes.
