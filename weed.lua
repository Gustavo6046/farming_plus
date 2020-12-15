-- main `S` code in init.lua
local S
S = farming.S

initial_timeout = 12
repeat_timeout	= 4

minetest.register_node(":farming:weed", {
	description = S("Weed"),
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	drawtype = "plantlike",
	tiles = {"farming_weed.png"},
	inventory_image = "farming_weed.png",
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.5+4/16, 0.5}
		},
	},
	groups = {snappy=3, flammable=2,plant=1},
	sounds = default.node_sound_leaves_defaults()
})

minetest.register_abm({
	nodenames = {"farming:soil_wet", "farming:soil"},
	interval = 5.0,
	chance = 10,
	action = function(pos, node)
		if minetest.find_node_near(pos, 4, {"farming:scarecrow", "farming:scarecrow_light"}) ~= nil then
			return
		end
		
		local meta = minetest.get_meta(pos)
		local timeout = meta:get_int("farming_plus:weed:timeout")
		local tilled_soil = minetest.get_node(pos)

		pos.y = pos.y + 1
		local air_above = minetest.get_node(pos)
		
		if timeout == 0 then
			timeout = initial_timeout + 1
			
		elseif timeout > 1 then
			timeout = timeout - 1
			
		else
			if air_above.name == "air" then
				node.name = "farming:weed"
				minetest.set_node(pos, node)
			end

			if timeout < repeat_timeout + 1 then
				timeout = repeat_timeout + 1
			end
		end
		
		meta:set_int("farming_plus:weed:timeout", timeout)
		meta:mark_as_private("farming_plus:weed:timeout")

		local status

		if node.name == "farming:weed" then
			status = "Grassiness: "..(1 + initial_timeout - timeout) * 100 / initial_timeout.."%"

		else
			status = "Grassiness: 100%"

		end
		
		meta:set_string("infotext", status)

		pos.y = pos.y - 1
		-- minetest.log("info", "("..pos.x..pos.y..pos.z..") "..status)
	end
})

-- ========= FUEL =========
minetest.register_craft({
	type = "fuel",
	recipe = "farming:weed",
	burntime = 1
})
