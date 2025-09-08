function GroupAIManager:auto_spawn_phalanx(target_pos)
	if not Network:is_server() then
		return false
	end

	local GAIS = managers.groupai:state()
	local assault_data = GAIS and GAIS._task_data.assault
	local _phase
	if assault_data and assault_data.phase then
		_phase = assault_data.phase
	else
		return false
	end

	if not (_phase == "build" or _phase == "sustain") then
		return false
	end

	local spawned = managers.groupai:state()._phalanx_spawn_group
	if spawned then
		return false
	end

	managers.groupai:state()._phalanx_center_pos = nil
	managers.groupai:state()._phalanx_center_pos = target_pos

	managers.groupai:state():_spawn_phalanx_manual()

	return managers.groupai:state()._phalanx_group_has_spawned
end

-- Time
if not _G.InviteWinters then
	_G.InviteWinters = {}
end

InviteWinters._mod_path = ModPath
InviteWinters._next_spawn_time = 0
InviteWinters._last_message = ""
InviteWinters._initial_delay = 240  -- 4 minute(第一次刷新时间)
InviteWinters._interval = 240       -- 4 minute(第一次刷新之后的间隔时间)

function InviteWinters:get_random_player()
	-- 获取玩家
	local all_players = {}
	
	-- 添加玩家
	local host_peer = managers.network:session():local_peer()
	if host_peer and host_peer:unit() and alive(host_peer:unit()) then
		table.insert(all_players, {
			position = host_peer:unit():position(),
			name = host_peer:name(),
			peer = host_peer
		})
	end
	
	-- 添加玩家
	local peers = managers.network:session():peers() or {}
	for _, peer in ipairs(peers) do
		if peer and peer ~= host_peer and peer:unit() and alive(peer:unit()) then
			table.insert(all_players, {
				position = peer:unit():position(),
				name = peer:name(),
				peer = peer
			})
		end
	end
	

	if #all_players == 0 then
		local safe_pos = Vector3(0, 0, 0)
		if managers.player:player_unit() then
			safe_pos = managers.player:player_unit():position()
		end
		return safe_pos, "Host"
	end
	

	local selected_index = math.random(#all_players)
	local selected_player = all_players[selected_index]
	return selected_player.position, selected_player.name, selected_player.peer
end

function InviteWinters:try_spawn_winters()
	if not Network:is_server() then
		return
	end
	

	local timer_manager = TimerManager:game()
	if not timer_manager then
		return
	end
	
	local current_time = timer_manager:time()
	

	if not current_time or current_time < self._next_spawn_time then
		return
	end
	

	local target_pos, player_name, player_peer = self:get_random_player()
	

	local success = GroupAIManager:auto_spawn_phalanx(target_pos)
	
	if success then
		local display_name = player_peer and player_peer:name() or player_name
		local message = string.format("%s's position has been locked by Captain Winters!", display_name)
		managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "System", message)
		
		self._next_spawn_time = current_time + self._interval
	else

		self._next_spawn_time = current_time + 1
	end
end


Hooks:Add("GameSetupUpdate", "InviteWinters_GameSetupUpdate", function(t, dt)
	if not Network:is_server() or 
	   not managers.groupai or 
	   not managers.groupai:state() or 
	   not TimerManager:game() then
		return
	end
	
	local timer_manager = TimerManager:game()
	if not timer_manager then
		return
	end
	
	local current_time = timer_manager:time()
	if not current_time then
		return
	end
	

	if InviteWinters._next_spawn_time == 0 then
		InviteWinters._next_spawn_time = current_time + InviteWinters._initial_delay
	end
	
	InviteWinters:try_spawn_winters()
end)