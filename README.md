<h1>CS:GO Glow Menu</h1>

A menu which players can enable Glow to themselves.
The colors that appear on the menu can be changed in a config file;
The glow can be restricted to a certain flag, also has different styles;

<h2>ConVars</h2>:

<ul>
<li><b>sm_glowcolor_style</b> (<b>1</b> by Default) - It changes the Glow Style to the players (Min 0, Max 3). WARNING: If you set the style to 0, <b>all players can see the glow through Walls</b>;</li>
<li><b>sm_glowcolor_default</b> (<b>255 255 255</b> by Default) - Default Glow Color to players which haven't choosed the color from the menu. Empty will disable it;</li>
<li><b>sm_glowcolor_flag</b> (<b>Empty</b> by Default) - Restrict the Glow to players with a certain flag.</li>
</ul>


Installation:
<ol>
<li>Drag the file named <i>colors.cfg</i> to <b>addons/sourcemod/configs/glow_colors</b>.</li>
<li>Drag the file named <i>csgo_glow_menu.smx</i> to <b>addons/sourcemod/plugins</b>.</li>
<li>Drag the file named <i>csgo_glowcolor_menu.phrases.txt</i> to <b>addons/sourcemod/translations</b>.</li>
<li>Load the plugin or just wait for the next map.</li>
<li>Change the ConVars as you wish in the file <i>csgo_glowcolor_menu.cfg</i> located in <b>cfg/sourcemod</b></li>
</ol>

Requeriments:
<ul>
<li>(To Show the Glow to everyone): Set your server with the <b>sv_force_transmit_players</b> ConVar to <b>1</b></li>
<li>(To Compile): ColorVariables - https://github.com/PremyslTalich/ColorVariables</li>
</ul>

I hope you enjoyed!

My Steam Profile if you have any questions -> http://steamcommunity.com/id/HallucinogenicTroll/

My Website -> http://htconfigs.me/

Alliedmodders Thread, related with this plugin -> https://forums.alliedmods.net/showthread.php?t=295236
