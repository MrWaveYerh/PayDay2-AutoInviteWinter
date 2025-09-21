function GroupAIManager:auto_spawn_phalanx(target_pos)
	if not Network:is_server() then
		--managers.chat:send_message(ChatManager.GAME, "System", "Not server, cannot spawn Winters")
		return false
	end

	local GAIS = managers.groupai:state()
	local assault_data = GAIS and GAIS._task_data.assault
	local _phase
	if assault_data and assault_data.phase then
		_phase = assault_data.phase
	else
                --调试消息，是否生成队长
		--managers.chat:send_message(ChatManager.GAME, "System", "No assault data, cannot spawn Winters")
		return false
	end

	--调试消息，检测是否在可生成队长的阶段
        --if not (_phase == "build" or _phase == "sustain") then
		--managers.chat:send_message(ChatManager.GAME, "System", "Not in build/sustain phase, cannot spawn Winters. Current phase: " .. tostring(_phase))
		--return false
	--end

	local spawned = managers.groupai:state()._phalanx_spawn_group
	if spawned then
		--managers.chat:send_message(ChatManager.GAME, "System", "Winters already spawned")
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
InviteWinters._initial_delay = 240  -- 4 minute 
InviteWinters._interval = 240       -- 4 minute

function InviteWinters:get_random_player()
	-- 获取所有存活玩家（参考您提供的代码）
	local alive_player_positions = {}
	
	-- 检查所有可能的玩家槽位（1-4）
	for i = 1, 4 do
		local peer = managers.network and managers.network:session() and managers.network:session():peer(i)
		local unit = peer and peer:unit() or nil
		if unit and alive(unit) then
			table.insert(alive_player_positions, {
				id = i,
				pos = unit:position(),
				peer = peer
			})
		end
	end
	
	-- 如果没有存活玩家，使用默认位置
	if #alive_player_positions == 0 then
		local safe_pos = Vector3(0, 0, 0)
		if managers.player:player_unit() then
			safe_pos = managers.player:player_unit():position()
		end
		return safe_pos, "Host", nil
	end
	
	-- 随机选择一个玩家
	local selected_index = math.random(#alive_player_positions)
	local selected_player = alive_player_positions[selected_index]
	return selected_player.pos, selected_player.peer:name(), selected_player.peer
end

function InviteWinters:try_spawn_winters()
	if not Network:is_server() then
		return
	end
	
	-- 计时器初始化
	local timer_manager = TimerManager:game()
	if not timer_manager then
		return
	end
	
	local current_time = timer_manager:time()
	
	-- 检查是否到达生成时间
	if not current_time or current_time < self._next_spawn_time then
		return
	end
	
	-- 发送调试消息
	--managers.chat:send_message(ChatManager.GAME, "System", "Attempting to spawn Winters...")
	
	-- 获取玩家
	local target_pos, player_name, player_peer = self:get_random_player()
	--managers.chat:send_message(ChatManager.GAME, "System", "Target player: " .. player_name)
	
	-- 生成冬日队长
	local success = GroupAIManager:auto_spawn_phalanx(target_pos)
	
	if success then
		-- 发送锁定消息
		local display_name = player_peer and player_peer:name() or player_name
		local message = string.format("%s's position has been locked by Captain Winters!", display_name)
		managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "System", message)
		
		-- 设置下一次生成时间
		self._next_spawn_time = current_time + self._interval
	else
		-- 如果生成失败，1秒后重试
		self._next_spawn_time = current_time + 1
		--managers.chat:send_message(ChatManager.GAME, "System", "Failed to spawn Winters, retrying in 1 second")
	end
end

-- 初始化定时器
Hooks:Add("GameSetupUpdate", "InviteWinters_GameSetupUpdate", function(t, dt)
	-- 初始化
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
	
	-- 初始化第一次生成时间
	if InviteWinters._next_spawn_time == 0 then
		InviteWinters._next_spawn_time = current_time + InviteWinters._initial_delay
		managers.chat:send_message(ChatManager.GAME, "System", "The First Caption will spawn within " .. InviteWinters._initial_delay .. " seconds")
	end
	
	InviteWinters:try_spawn_winters()
end)