function GroupAIStateBesiege:_spawn_phalanx_manual()

	self._phalanx_group_has_spawned = false

	if not self._phalanx_center_pos then
		return
	end

	local phalanx_center_pos = self._phalanx_center_pos
	local phalanx_center_nav_seg = managers.navigation:get_nav_seg_from_pos(phalanx_center_pos)
	local phalanx_area = self:get_area_from_nav_seg_id(phalanx_center_nav_seg)
	local phalanx_group = {
		tac_shield_wall_ranged = {
			1,
			1,
			1
		}
	}

	if not phalanx_area then
		return
	end

	local spawn_group, spawn_group_type = self:_find_spawn_group_near_area(phalanx_area, phalanx_group, nil, nil, nil)

	if not spawn_group then
		return
	end

	spawn_group_type = 'Phalanx'

	if spawn_group.spawn_pts[1] and spawn_group.spawn_pts[1].pos then
		local spawn_pos = spawn_group.spawn_pts[1].pos
		local spawn_nav_seg = managers.navigation:get_nav_seg_from_pos(spawn_pos)
		local spawn_area = self:get_area_from_nav_seg_id(spawn_nav_seg)

		if spawn_group then
			local grp_objective = {
				type = "defend_area",
				area = spawn_area,
				nav_seg = spawn_nav_seg
			}

			print("Phalanx spawn started!")
			managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "player", managers.localization:text("announce_spawn"))

			self._phalanx_spawn_group = self:_spawn_in_group(spawn_group, spawn_group_type, grp_objective, nil)

			self:set_assault_endless(true)
			managers.game_play_central:announcer_say("cpa_a02_01")
			managers.network:session():send_to_peers_synched("group_ai_event", self:get_sync_event_id("phalanx_spawned"), 0)

			self._phalanx_group_has_spawned = true
		end
	end
end

