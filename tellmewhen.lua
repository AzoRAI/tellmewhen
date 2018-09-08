--[[
Copyright (c) 2018, Joshua Tyree
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

_addon.name = 'tellmewhen'
_addon.author = 'Shozokui'
_addon.version = '1.0.0'
_addon.commands = {"tmw", "tellmewhen"}
_addon.language = 'english'


-- <editor-fold> Requires/Includes
require('chat')
require('lists')
require('logger')
require('sets')
require('tables')
require('strings')
require('pack')
files = require('files')
packets = require('packets')
config = require('config')
texts = require('texts')
res = require('resources')
inspect = require('inspect')
-- </editor-fold> Requires/Includes

-- <editor-fold> Defaults, Configuration

-- Notification Schema
-- {
--    "actor": "<name>", -- optional
--    "ability": <id>,
--    "only_target": <true/false> -- Notify only when targeting something
--    "only_engaged": <true/false> -- Notify only when engaged
--    "reponse": "<sound/chat/log/command>" -- Can use pipes to do multiple
--    "chat_mode": "party/tell/linkshell"
--    "chat_target": "<player name>" -- Only used if using chat_mode "tell"
--    "format": "%actor used %ability!"
--    "sound": "<path>"
--    "log_color": 67
--    "command": "addon command" -- The console command to run, merge params include:
--    -- actor (full name), actor_id, ability (full name), ability_id, target (full name), target_id
-- }+

player = windower.ffxi.get_player()
defaults = {}
defaults.notifications = {}
settings = config.load(defaults)

-- </editor-fold> Defaults, Configuration


PAIN_SYNC_ABILITY_ID = 4096
windower.register_event('addon command', function(command, ...)
  command = command and command:lower() or 'status'
  local args = T{...}
  -- status_msg("Addon commands not supported at this time")

  if command == 'status' then
    windower.add_to_chat(57, inspect(settings.notifications))
  elseif command == 'reload' then
    config.reload(settings)
    status_msg("Settings reloaded.")
  elseif command == 'clear' then
    settings.notifications = {}
    config.save(settings)
    status_msg("Notifications cleared.")
  end
end)


-- <editor-fold> Helper Functions
function status_msg(msg)
  windower.add_to_chat(50, "TellMeWhen: "..msg)
end

function is_player_engaged()
  local p = windower.ffxi.get_player()
  return p["status"] == 1
end

function is_actor_target(actor)
  local target = windower.ffxi.get_mob_by_target('t')
  return actor == target["id"]
end

function find_ability(id)
  return res.monster_abilities[id]
end

function find_target(actor)
  return windower.ffxi.get_mob_by_id(actor)
end

function find_notifications_for(ability)
  local notifications = {}

  for i,notification in pairs(settings.notifications) do
    -- windower.add_to_chat(50, notification["ability"].." <> "..ability)
    if tostring(notification["ability"]) == tostring(ability) then
      table.insert(notifications, notification)
    end
  end

  return notifications
end
-- </editor-fold>


-- <editor-fold> Incoming Chunk Logic
windower.register_event('incoming chunk', function(id, _, data)
  if id == 0x028 then -- Received
    -- Action Packet::
    --  Category 7 - NPC WS Start
    --  Category 11 - NPC TP Finish
    --  Actor - Who's casting
    --  Target 1 Action 1 Param - What ability is being cast (Monster Abilities.lua)
    local packet = packets.parse('incoming', data)
    local actor = packet["Actor"]
    local category = packet["Category"]


    if category == 7 then
      local ability = packet["Target 1 Action 1 Param"]
      local notes = find_notifications_for(ability)
      -- windower.add_to_chat(50, inspect(notes))

      for i,note in ipairs(notes) do
        local target_req_met = true
        local engaged_req_met = true

        if note["only_target"] and is_actor_target(actor) == false then
          target_req_met = false
        end

        if note["only_engaged"] and is_player_engaged() == false then
          engaged_req_met = false
        end

        if target_req_met and engaged_req_met then
          notify(note, packet)
        end
      end
    end
  end
end)


local DEFAULT_FORMAT = "%actor% used %ability%"
function notify(note, packet)
  -- Category 7 - NPC WS Start
  -- Category 11 - NPC TP Finish
  -- Actor - Who's casting
  -- Target 1 Action 1 Param - What ability is being cast (Monster Abilities.lua)
  -- local actor = packet['Actor']
  -- local category = packet['Category']
  -- local ability = packet["Target 1 Action 1 Param"]
  -- local monster_ability = find_ability(ability)
  -- windower.add_to_chat(57, inspect(packet))


  local response = note["response"]
  if response == nil or response == "" then -- Can't repsond if no response type
    return
  end

  local color  = note["log_color"] or 57
  local format = note["format"] or DEFAULT_FORMAT
  local mob = find_target(packet["Actor"])
  local target = find_target(packet["Target 1 ID"])
  local ability = packet["Target 1 Action 1 Param"]
  local monster_ability = find_ability(ability)



  local message = string.gsub(format, "%actor", mob["name"])
  message = string.gsub(message, "%ability", monster_ability["en"])


  local response_types = string.split(response, "|")
  -- windower.add_to_chat(57, "DEBUG: Response Types: "..inspect(response_types))
  for i,rt in ipairs(response_types) do
    if rt == "chat" then
      notify_chat(note, message)
    elseif rt == "sound" then
      notify_sound(note, packet)
    elseif rt == "command" then
      local cmd = note["command"] or ""
      cmd = string.gsub(cmd, "%actor", mob["name"])
      cmd = string.gsub(cmd, "%actor_id", mob["id"])
      cmd = string.gsub(cmd, "%target_id", packet["Target 1 ID"])
      cmd = string.gsub(cmd, "%target", target["name"])
      cmd = string.gsub(cmd, "%ability_id", ability)
      cmd = string.gsub(cmd, "%ability", monster_ability["en"])
      windower.send_command(cmd)
    else
      windower.add_to_chat(color, message)
    end
  end
end

function notify_chat(note, message)
  local chat_mode = note["chat_mode"] or "party"
  local cmd = "input /"..chat_mode.." "

  -- windower.add_to_chat(57, "DEBUG: Chat Mode ("..chat_mode..")")
  if chat_mode == "tell" then
    if note["chat_target"] == nil or note["chat_target"] == "" then
      return
    end
    cmd = cmd..note["chat_target"].." "
  end
  cmd = cmd..message
  windower.add_to_chat(57, "DEBUG: Command ("..cmd..")")
  windower.send_command(cmd)
end

function notify_sound(note, packet)
  local sound = note["sound"] or windower.addon_path.."alert.wav"
  windower.play_sound(sound)
end
-- </editor-fold>

status_msg("Loaded!")
