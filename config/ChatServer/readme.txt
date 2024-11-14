The new system for managing features, regions, and hero availability from the Chat Server is finished now.  I'll give a brief description of how the commands work.  There's 7 root commands that all use the same syntax (List, Enable, Disable, Show, Hide, Revert, Default).  In general, disabled options are still visible and should be presenting using disabled buttons.  A hidden option is meant to remove the concept of that option entirely from the client's interface.

Here's some examples: (lines beginning with > are input)

List top level feature 'lobby'
>list lobby
lobby enabled:true visible:true

This listed all top level features
>list *
lobby enabled:true visible:true
matchmaking enabled:true visible:true

List all regions in matchmaking
>list matchmaking region *
matchmaking.pvp.USE enabled:false visible:false
matchmaking.pvp.USW enabled:false visible:false
matchmaking.pvp.US enabled:true visible:true
matchmaking.pvp.EU enabled:true visible:true
matchmaking.pvp.SEA enabled:true visible:true
matchmaking.pve.USE enabled:false visible:false
matchmaking.pve.USW enabled:false visible:false
matchmaking.pve.US enabled:true visible:true
matchmaking.pve.EU enabled:true visible:true
matchmaking.pve.SEA enabled:true visible:true

List the 'USE' lobby region
>list lobby region USE
lobby.USE enabled:true visible:true

When using the List command, pending edits will display in Red, values that are different than default and already submitted will display in Yellow.

Editing begins by using one of the Enable/Disable/Show/Hide commands. After an edit command is issued, it'll be added to the pending edit list.

>disable lobby region USE
Pending lobby.USE enabled true -> false

To view the pending edit list at any time, use the command PendingGameInfo.

>PendingGameInfo
Pending lobby.USE enabled true -> false

If you make a mistake and want to revert all pending changes before you end up submitting them, use the RevertGameInfo.  To revert individual changes, use the Revert root command.  To submit pending changes using the SubmitGameInfo command.  Doing so after running disable lobby region USE should look like this:

>SubmitGameInfo 
Submitting lobby.USE enabled true -> false

Submitting changes will automatically fix any incompatible options on any lobbies or parties, disbanding if necessary.

Restarting the Chat Server will always put it back to the default state defined in game.xml.  If you want to return to default state without restarting, use the DefaultGameInfo command followed by SubmitGameInfo.  To change individual settings back to default use the Default root command.

A cheat sheet for other possible commands:
>disable lobby - Globally disables lobby games
>disable matchmaking - Globally disables matchmaking
>disable matchmaking pve - Disables PvE matchmaking queue
>disable matchmaking pvp - Disables PvP matchmaking queue
>disable region SEA - disables SEA region in lobby and all matchmaking queues
>enable region * - enables all regions in lobby and all matchmaking queues
>disable hero Hero_Ace - disables Ace in lobby and all matchmaking queues
>disable matchmaking pvp hero Hero_Caprice - disables Caprice in the pvp matchmaking queue
>disable matchmaking hero Hero_Caprice - disables Caprice in the all matchmaking queues
>hide matchmaking - hides the concept of matchmaking altogether from clients

There will be other top level features in the future.