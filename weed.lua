-- main `S` code in init.lua
local S
S = farming.S

initial_timeout = 12
repeat_timeout	= 4
pesticide_timeout_extra = 30

minetest.register_node("farming:weed", {
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

minetest.register_craftitem("farming:pesticide", {
	description: "Weed Repellent",
	inventory_image = "farming_pesticide.png",
	on_use = function(itemstack, user, pointed)
        if pointed == nil or pointed.type ~= "node" then
        	return nil
        end

		-- make sure we're looking at tilled soil, or weed above tilled soil
        local pos = pointed.under
		local node = minetest.get_node(pos)

		if node.name == "farming:weed" then
			pos.y = pos.y - 1
			node = minetest.get_node(pos)
		end

		if node.name ~= "farming:soil_wet" and node.name ~= "farming:soil" then
			return nil
		end

		-- get weed and try to break it
		-- (abort if we can't, even if the rest works;
		-- because a pesticide that makes ground less weedy
		-- and still can't kill existing weed doesn't make sense)
		pos.y = pos.y + 1
		local weedcheck = minetest.get_node(pos)

		if weedcheck.name == "farming:weed" then
			if not minetest.dig_node(pos) then
				return nil
			end
		end

		-- set the timeout of tiled soil to the max (initial_timeout + 1) if
		-- smaller, and add pesticide_timeout_extra

		pos.y = pos.y - 1
		
		local meta = minetest.get_meta(pos)
		local timeout = meta:get_int("farming_plus:weed:timeout")

		if timeout < initial_timeout + 1 then
			timeout = initial_timeout + 1
		end

		timeout = timeout + pesticide_timeout_extra

		meta:set_int("farming_plus:weed:timeout", timeout)

		-- take 1 item from stack and return
		itemstack.take_item()
		return itemstack
    end,
})

minetest.register_craft(recipe = {
	"output": "farming:pesticide 24",
	"recipe": {
		{"", 				"basic_materials:plastic_sheet",    ""},
		{"default:paper", 	"flowers:mushroom_red",				"default:paper"},
		{"default:paper", 	"flowers:mushroom_red",				"default:paper"}
	},
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
			status = "Grassiness: 100%"

		else
			status = "Grassiness: "..(1 + initial_timeout - timeout) * 100 / initial_timeout.."%"

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
