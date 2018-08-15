<h1>CS:GO Glow Menu</h1>

A menu which players can enable Glow to themselves.
The colors that appear on the menu can be changed in a config file;
The glow can be restricted to a certain flag, also has different styles;

<h2>ConVars:</h2>

- <b>sm_glowmenu_style</b> (<b>1</b> by Default) - It changes the Glow Style to the players (Min 0, Max 3). WARNING: If you set the style to 0, <b>all players can see the glow through Walls</b>;
- <b>sm_glowmenu_prefix</b> (<b>[Glow Menu]</b> by Default) - Chat's Prefix;
- <b>sm_glowmenu_flag</b> (<b>Empty</b> by Default) - Restrict the Glow to players with a certain flag.

<h2>MySQL</h2>
<p>Add this to your databases.cfg in <i>addons/sourcemod/configs</i> and change it as you need.

```
"glow_menu"
{
  "driver"    "mysql"
  "host"      "YOUR_HOST_ADDRESS"
  "database"  "YOUR_DATABASE_NAME"
  "user"      "DATABASE_USERNAME"
  "pass"      "USERNAME_PASSWORD"
}
```

<h2>Installation:</h2>

1. Setup your MySQL database first (read above)
2. Drag the file named <i>glow_menu.ini</i> to <b>addons/sourcemod/configs</b>.
3. Drag the file named <i>glow_menu.smx</i> to <b>addons/sourcemod/plugins</b>.
4. Drag the file named <i>glow_menu.phrases.txt</i> to <b>addons/sourcemod/translations</b>.
5. Restart the server.
6. Change the ConVars as you wish in the file <i>glow_menu.cfg</i> located in <b>cfg/sourcemod</b>

<h2>Requirements:</h2>

- [Sourcemod](https://www.sourcemod.net/);
- [ColorVariables](https://forums.alliedmods.net/showthread.php?t=267743) (To Compile);
- <b>sv_force_transmit_players</b> ConVar to <b>1</b>(To show the Glow to everyone); 
=======
<ol>
<li>Drag the file named <i>colors.cfg</i> to <b>addons/sourcemod/configs/glow_colors</b>.</li>
<li>Drag the file named <i>csgo_glow_menu.smx</i> to <b>addons/sourcemod/plugins</b>.</li>
<li>Drag the file named <i>csgo_glowcolor_menu.phrases.txt</i> to <b>addons/sourcemod/translations</b>.</li>
<li>Drag the file named <i>csgo_glowcolor_menu.cfg</i> to <b>cfg/sourcemod</b>.</li>
<li>Load the plugin or just wait for the next map.</li>
<li>Change the ConVars as you wish in the file <i>csgo_glowcolor_menu.cfg</i> located in <b>cfg/sourcemod</b></li>
</ol>

<h2>Requirements:</h2>
<ul>
<li>(To Show the Glow to everyone): Set your server with the <b>sv_force_transmit_players</b> ConVar to <b>1</b></li>
<li>(To Compile): ColorVariables - https://github.com/PremyslTalich/ColorVariables</li>
</ul>

<h2>FAQ:</h2>

<p><b> Q: This plugin would lag my servers massively? </b></p>
R: That depends where your server is hosted from, or if it has many users with glow enabled.
With <b>Version 2.0</b>, all the new users are set without glow, by default, so they need to change with the <b>sm_glow</b> command.
Another option is to set <b>sm_glowmenu_flag</b> to any flag, just to restrict the maximum numbers possible.

<h2>Style's Screenshots (More to be added):</h2>

![Alt text](https://steamuserimages-a.akamaihd.net/ugc/307738934717361893/057A983F0BF99D22CDD1F231A8A775B612A2D0FA/?raw=true "Screenshot 1")
![Alt text](https://steamuserimages-a.akamaihd.net/ugc/307738934717359810/AAFDFAD4B2E4E308F2CBDCEB77A5B60A7C322365/?raw=true "Screenshot 2")
![Alt text](https://steamuserimages-a.akamaihd.net/ugc/307738934717359336/D8438AF5A080FB28B167DE6391A2F91547241FE1/?raw=true "Screenshot 3")

I hope you enjoyed!

My Steam Profile if you have any questions -> http://steamcommunity.com/id/HallucinogenicTroll/

My Website -> http://hallucinogenictrollconfigs.com

