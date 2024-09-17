# strife-patches
Repository for community changes made Strife.

## Strife community Discord:
Join our [Discord server](https://discord.gg/KuC7ufnRnU) to connect with community.

## Short introduction to how game executable works:
In Strife installation folder you can find 'game' directory. There you can find files _resources0.s2z_ and _resources2.s2z_. Those are .zip archives with extension changed. 
- _resources0.s2z_ contains all files original games uses (scripts, models, textures, sounds, etc.). Executable file loads them initially.
- _resources2.s2z_ contains changes we made so far. All files from it with same directories and names as files from _resources0.s2z_ replace original files.
- If there were other _resourcesXXX.s2z_ files, game would process them in the same way as well.
- And finally game loads files from the "game" directory itself, which means that changes to files in game directory will take effect in client itself.

## First steps to begin are:
- Extract contents of resources0.s2z into "game" directory;
- Extract resources2.s2z into "game" directory with replace;
- Changes made to extracted files will take effect in client.

## To contribute:
If you are ready to contribute, you can either pack changed files into new resourcesXXX.s2z archive and share it with us on [Discord server](https://discord.gg/KuC7ufnRnU) or (if you are familiar and experienced with how git works) create a fork from "dev" branch and create pull request to "dev" branch.
