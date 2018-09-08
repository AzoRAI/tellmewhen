## Windower Addon - TellMeWhen

TellMeWhen is an addon that allows you to respond to TP moves in your vicinity.

Addon is config-only, there are no in-game commands currently.

Planned Features:
* Filter by actor who started action
* Filter by zone
* Filter by action type (TP Move Start, TP Move End, Spell Cast Start, Spell Cast End)
* Render graphics on-screen for notifications

##### Notification Schema and Data Requirements

```lua
{
  "actor": "<name>", -- optional
  "ability": <id:int>,
  "only_target": <true/false> (bool) -- Notify only when targeting something
  "only_engaged": <true/false> (bool) -- Notify only when engaged
  "reponse": "sound|chat|log|command" -- Can use pipes to do multiple
  "chat_mode": "party/tell/linkshell" -- Can ONLY USE ONE
  "chat_target": "<player name>" -- Only used if using chat_mode "tell"
  "format": "actor used ability!" -- Available merge values: actor, ability
  "sound": "<path>" -- Path should be full path to file
  "log_color": 50
  "command": "input /say actor used ability!" -- The console command to run, merge params include: actor (full name), actor_id, ability (full name), ability_id, target (full name), target_id
}
```

##### Settings File

```xml
<?xml version="1.1" ?>
<settings>
    <global>
        <notifications>
            <1>
                <ability>300</ability>
                <chat_mode>tell</chat_mode> <!-- Send a tell to Shozokui -->
                <chat_target>Shozokui</chat_target>
                <command>input /cure target</command> <!-- When activated, use cure or whomever was targeted, requires shortcuts -->
                <format>actor used ability!</format>
                <log_color>50</log_color>
                <only_engaged>true</only_engaged>
                <only_target>true</only_target>
                <response>log|chat|sound|command</response>
            </1>
            <2>
                <ability>301</ability>
                <chat_mode>tell</chat_mode>
                <chat_target>Shozokui</chat_target>
                <command>input /cure target</command>
                <format>actor used ability!</format>
                <log_color>50</log_color>
                <only_engaged>true</only_engaged>
                <only_target>true</only_target>
                <response>log|chat|sound|command</response>
            </2>
        </notifications>
    </global>
</settings>

```
