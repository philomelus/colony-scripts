--
-- warehouse_stock.lua - Maintain stock of items in colony warehouse.
-- Copyright (C) 2023  Russell E. Gibson
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
---------------------------------------------------------------------------
-- Lua script for use with CC: tweaked and Advanced Peripherals that will
-- help maintain stock within a colony warehouse.  It does so by watching
-- the warehouse, and making sure all desired items are within a minimum
-- and maximum range.  If there are more than maximum, it will remove the
-- items into digital storage until only maximum are left.  If there are
-- fewer than minimum, then it will get them from digital storage, asking
-- for crafting if needed and available, until minimum amount is stored
-- in warehouse.  Works for both Refined Storage and Applied Energistics 2.
--
-- Requirements:
-- 1.  Either a MEBridge or RSBridge connected to your computer.
-- 2.  Either the computer is placed against the warehouse control point,
--     or some kind of entangled block must be used to place the
--     warehouse next to the computer.
-- 3.  A monitor attached to the computer.  Most of the time, only a couple
--     of lines are shown on the monitor.  Once in awhile, especially for
--     larger or more advanced colonies there will be a long list.  The
--     script will only display what will fit on the monitor.
--
-- Finally, you will need to update some of the variables below.  Read the
-- description in the comments directly before the variable to see what
-- you need to do.
---------------------------------------------------------------------------

-- List of the items which should be stocked
-- Table of tables of items.  Each item to be stocked should be in this table,
-- inside a table containing  three items.  First item is minecraft name of
-- item, second item is the minimal numerical amount to keep stocked, and the
-- third is the maximum amount to keep stocked, like this:
--
-- { "minecraft:name_of_item", minimum amount, maximum amount }
--
-- NOTE that the name is the internal minecraft name of item, not the nice
--      name that is shown to users.  If you turn on advanced tooltips (via
--      F3+H), then you can see the item name in the popup window shown when
--      hovering over an item (when viewing inventory).
--
-- For example, to keep 1 to 2 stacks of bone meal in the warehouse:
--
-- { "minecraft:bone_meal", 64, 128 }

local stock_items = {
	{ "minecolonies:ancienttome", 32, 128 },
	{ "minecraft:azure_bluet", 16, 64 },
	{ "rootsclassic:blackcurrant", 16, 128 },
	{ "minecraft:blue_orchid", 16, 64 },
	{ "minecraft:bone", 16, 128 },
	{ "minecraft:bone_meal", 64, 128 },
	{ "minecraft:cactus", 16, 128 },
	{ "minecraft:carrot", 64, 128 },
	{ "minecraft:campfire", 16, 64 },
	{ "minecraft:cauldron", 4, 64 },
	{ "minecraft:clay", 1, 64 },
	{ "minecraft:coal", 16, 128 },
	{ "minecraft:cobbled_deepslate", 64, 256 },
	{ "minecraft:cobblestone", 256, 1024 },
	{ "minecolonies:compost", 64, 256 },
	{ "minecraft:copper_ingot", 32, 128 },
	{ "minecraft:cornflower", 16, 64 },
	{ "minecraft:dandelion", 16, 64 },
	{ "minecraft:dead_bush", 4, 64 },
	{ "minecraft:dirt", 32, 256 },
	{ "minecraft:egg", 16, 64 },
	{ "rootsclassic:elderberry", 16, 128 },
	{ "minecraft:flint", 32, 128 },
	{ "minecraft:glass", 16, 128 },
	{ "minecraft:glass_pane", 16, 128 },
	{ "minecraft:gold_ingot", 32, 128 },
	{ "minecraft:granite", 4, 128 },
	{ "minecraft:honeycomb", 16, 64 },
	{ "minecraft:iron_ingot", 32, 128 },
	{ "minecraft:ladder", 16, 64 },
	{ "minecraft:lapis_lazuli", 16, 128 },
	{ "minecraft:leather", 16, 128 },
	{ "minecraft:lily_pad", 4, 64 },
	{ "minecraft:milk_bucket", 4, 16 },
	{ "minecraft:netherrack", 16, 128 },
	{ "minecraft:nether_wart", 16, 128 },
	{ "minecraft:oak_log", 256, 512 },
	{ "minecraft:oak_sapling", 16, 128 },
	{ "minecraft:oak_wood", 16, 128 },
	{ "minecraft:potato", 64, 128 },
	{ "minecraft:prismarine_crystals", 4, 64 },
	{ "minecraft:prismarine_shard", 4, 64 },
	{ "minecraft:orange_tulip", 16, 64 },
	{ "minecraft:poppy", 16, 64 },
	{ "minecraft:beef", 128, 256 }, -- Raw Beef
	{ "minecraft:cod", 16, 128 }, -- Raw Cod
	{ "minecraft:mutton", 16, 128 }, -- Raw Mutton
	{ "minecraft:porkchop", 16, 128 }, -- Raw Porkchop
	{ "minecraft:rabbit", 16, 128 }, -- Raw Rabbit
	{ "minecraft:salmon", 16, 128 }, -- Raw Salmon
	{ "rootsclassic:redcurrant", 16, 128 },
	{ "minecraft:redstone", 32, 128 },
	{ "minecraft:soul_soil", 16, 64 },
	{ "minecraft:stick", 16, 128 },
	{ "minecraft:stone_bricks", 64, 256 },
	{ "minecraft:sugar_cane", 16, 128 },
	{ "minecraft:sunflower", 16, 64 },
	{ "utilitix:tiny_coal", 256, 512 },
	{ "minecraft:wheat", 128, 256 },
	{ "minecraft:wheat_seeds", 128, 256 },
	{ "rootsclassic:whitecurrant", 16, 128 },
	{ "minecraft:white_tulip", 16, 64 },
	{ "minecraft:white_wool", 16, 128 },
	{ "minecraft:yellow_banner", 1, 8 },
}

-- Scale of text on monitor.  0.5 allows two columns of equal width
-- in same space as normal scale (of 1.0).

local monitor_scale = 0.5

-- Amount of time, in seconds, between stock checks.

local period = 10

-- Find a uniquely identified computer peripheral.
--
-- id = Unique peripheral id on this computer
-- title = Name of item to display in error message
-- timeout = Maximum number of seconds to retry locating
--           periperal before failing.
--
-- On success, returns the peripheral table.
-- On failure, generates error and exits.

function findPeripheral(id, title, timeout)
	local p = nil
	local tries = 0
	local period = timeout / 5
	local r
	while tries < 6 do
		r, p = pcall(peripheral.find, id)
		if r then
			break
		end
		sleep(period)
		tries = tries + 1
	end
	if p == nil then
		error("Unable to locate " .. title .. ".", -1)
	end
	return p
end

-- This is the name of the warehouse inventory peripheral.  You can use the
-- name of the block, "inventory" if no ither inventory is available to
-- computer, or a direction (left/right/up/down/front/back)

-- NOTE:  entangled:tile takes a few seconds to become available after
--        initial load.

local warehouse = findPeripheral("entangled:tile", "warehouse", 30)

-- This is the name of the bridge peripheral.  For AE2 it should be "meBridge",
-- and for RS it should be "rsBridge".

local bridge = findPeripheral("meBridge", "bridge", 30)

-- Name (or side name if attached directly to computer) of monitor for status
-- display.  If you have a lot of items to stock, make it pretty large (I
-- normally use 6x4, so 24 total Advanced Monitors).

-- TODO:  Make this optional, as the display isn't _that_ useful

local mon = findPeripheral("monitor", "monitor", 30)

---------------------------------------------------------------------------
-- MODIFY NOTHING BELOW HERE (unless ...)
---------------------------------------------------------------------------

-- Used for printing debug messages.  Not always needed, but easier
-- than adding and removing the line regularly ...
local pp = require("cc.pretty").pretty_print

-- Constants

local S_LOW = 1					-- Not enough in stock
local S_HIGH = 2				-- Too much in stock
local S_GOOD = 3				-- At least minimum amount in stock
local S_NOCRAFT = 4				-- Not enough in stock, but not craftable
local S_UNKNOWN = 5				-- Unable to determine stock

-- Given item name and minimum amount to keep stocked, ensure
-- warehouse contains at least minimum amount of item.
-- Handles cases of item not in storage or not craftable.
--
-- itemName - Internal minecraft name (tag) for item
-- minCount - Minimum number of item to maintain
-- maxCount - Maximum number of item to maintain
-- line     - Line to show status of item on monitor
-- onLeft   - true to show in left column, otherwise right column

function checkItem(itemName, minCount, maxCount, line, onLeft)
	item = findItem(itemName)
	if item then
		-- Get info on the slots with item
		local items = {}
		local count = 0
		local title = nil
		for i, s in ipairs(item) do
			items[s] = warehouse.getItemDetail(s)
			if items[s] and title == nil then
				title = items[s].displayName
			end
		end
		
		-- Determine total count
		local count = 0
		for slot, detail in pairs(items) do
			count = count + detail.count
		end

		-- Too many?
		if count > maxCount then
			-- Move some to digital storage
			updateStatus(title, line, S_HIGH, onLeft)
			removeItems(itemName, count - maxCount)
		-- Not enough?
		elseif count < minCount then
			-- Get some from digital storage
			updateStatus(title, line, S_LOW, onLeft)
			local result, name = getItems(itemName, minCount - count)
			if type(result) == "number" then
				updateStatus(name, line, S_LOW, onLeft)
			elseif not result then
				print("Not craftable: " .. title)
				updateStatus(title, line, S_NOCRAFT, onLeft)
			end
		else
			-- Just right
			updateStatus(title, line, S_GOOD, onLeft)
		end
	else
		-- Couldn't find item, attempt to move some from storage
		local got, name = getItems(itemName, minCount)
		if type(got) == "number" then
			updateStatus(name, line, S_LOW, onLeft)
		else
			updateStatus(itemName, line, S_NOCRAFT, onLeft)
		end
	end
end

-- Check stock in all items in table.
--
-- items = Table of items as documented at near top of file
-- count = Number of items in table (passing it here saves a tiny
--         amount of cpu time versus getting the value every call)

function checkStock(items, count)
	local row
    for i = 1, count, 2 do
		row = math.floor(i / 2) + 1
		
		-- Update status of first item on left
        checkItem(items[i][1], items[i][2], items[i][3], row, true)

		-- If there is a second item
		if i < count then
			-- Update status of second item on right
			checkItem(items[i + 1][1], items[i + 1][2], items[i + 1][3], row, false)
		end
    end
end

-- Locate item in inventory warehouse
--
-- Returns table of all slot indexes if found, nil otherwise

function findItem(name)
	found = false
	slots = {}
	for slot, item in pairs(warehouse.list()) do
		if item.name == name then
			found = true
			table.insert(slots, slot)
		end
	end
	if found then
		return slots
	else
		return nil
	end
end

-- Get items from digital storage and place in warehouse.
--
-- Returns 2 items:
--   First is number of items moved, or false if there are not enough
--         items in storage to fill request and the item is not craftable.
--   If the first is a number, then second result is the display name
--         of the item.  If first result is false, then this is nil.

function getItems(item, count)
	-- Attempt to craft the item
	-- Returns true/false crafted, number crafted or nil,
	--         display name or nil
	local function docraft(name, count)
		-- Not in storage.  Is it in craftables?
		local craftables = bridge.listCraftableItems()
		local index, detail
		for index, detail in ipairs(craftables) do
			if detail.name == name then
				if bridge.craftItem({name=name, count=count}) then
					return true, amount, detail.displayName
				else
					return true, 0, detail.displayName
				end
			end
		end
		return false, nil, nil
	end
	
	local amount
	local result, detail = pcall(bridge.getItem, {name=item})
	if result then
		if detail then			-- can be nil on success if item doesn't exist
			if detail.amount >= count then
				result, amount = pcall(bridge.exportItemToPeripheral, {name=item, count=count},
									   peripheral.getName(warehouse))
				if result then
					return amount, detail.displayName
				else
					print("Item in storage, but move failed: " .. item
						  .. "\n    (" .. tostring(amount) .. ")")
					return false, nil
				end
			else
				-- Item exists, but there aren't enough to satisfy the request.
				-- Is it craftable?
				if detail.isCraftable then
					amount = count - detail.amount
					if bridge.craftItem({name=item, count=amount}) then
						return amount, detail.displayName
					else
						print("Not enough in storage, craft failed: " .. item)
						return false, nil
					end
				else
					print("Not in storage, not craftable: " .. item)
					return false, nil
				end
			end
		else
			-- Not in storage.  Is it in craftables?
			local count, title
			result, count, title = docraft(item, amount)
			if result then
				if count > 0 then
					-- Successfully crafting/ed
					return count, title
				else
					-- Not is storage and crafting failed
					print("Not in storage and craft failed: " .. item)
					return false, nil
				end
			else
				-- Not craftable.  Nothing to do.
				print("Not in storage, not craftable: " .. item)
				return false, nil
			end
		end
	else
		-- Item doesn't exist in storage or an error occured attempting
		-- to get the item (which is treated as non-existant item)
		-- Is it in the craftable list?
		local count, title
		result, count, title = docraft(item, amount)
		if result then
			if count > 0 then
				-- Successfully crafting/ed
				return count, title
			else
				-- Not is storage and crafting failed
				print("Not in storage and craft failed: " .. item)
				return false, nil
			end
		else
			-- Not craftable.  Nothing to do.
			print("Not in storage, not craftable: " .. item)
			return false, nil
		end
	end

	print("FAIL: " .. item .. " >" .. tostring(amount))
	return false, nil
end

-- Remove items from warehouse and place in digital storage
--
-- item  = Minecraft internal name for item
-- slots = Table of slot->details
-- count = Total number to remove from warehouse

function removeItems(item, count)
	return bridge.importItemFromPeripheral({name=item, count=count},
		peripheral.getName(warehouse))
end

-- Update display status for an item.
--
-- text = The name to show for item
-- line = Line number on monitor to display entry
-- status = Current state of the item (from constants above)
-- left = true to show in left column, otherwise in right column

function updateStatus(text, line, status, left)
	-- If line isn't on display, do nothing (allows showing as much as
	-- the display can handle)
	if line > screen_h then return end
	
	local widthCols = math.floor((screen_w - 1) / 2)
	local widthColsTitle = widthCols - 4
	local rightCol = widthCols + 2
	local shortText = text
	-- Truncate title if its too wide
	if string.len(shortText) > widthColsTitle then
		shortText = string.sub(text, 1, widthCols - 8) .. "..."
	end
	-- Extend title to full width so (potential) prior item name
	-- gets overwritten
	if string.len(shortText) < widthColsTitle then
		shortText = shortText .. string.rep(" ", widthColsTitle - string.len(shortText))
	end

	-- Move cursor for title
	if left then
		mon.setCursorPos(1, line)
	else
		mon.setCursorPos(rightCol, line)
	end

	-- Show title
	mon.setTextColor(colors.lightGray)
	mon.write(shortText)

	-- Move cursor for status
	if left then
		mon.setCursorPos(widthCols - 4, line)
	else
		mon.setCursorPos(screen_w - 4, line)
	end
	
	-- Determine text and color for status
	local statusText
	if status == S_GOOD then
		mon.setTextColor(colors.green)
		statusText = "OK "
	elseif status == S_HIGH then
		mon.setTextColor(colors.blue)
		statusText="Hi "
	elseif status == S_NOCRAFT then
		mon.setTextColor(colors.red)
		statusText="Low"
	elseif status == S_LOW then
		mon.setTextColor(colors.orange)
		statusText = "Low"
	else -- S_UNKNOWN
		mon.setTextColor(colors.yellow)
		statusText = "?!?"
	end

	-- Show status
	mon.write(statusText)
end

-- Put monitor in known state
mon.clear()
mon.setTextScale(monitor_scale)

-- Get these values one time only
screen_w, screen_h = mon.getSize()
local stockItemsCount = #stock_items

-- Loop forever
while true do
    print("\nUpdate starting at", textutils.formatTime(os.time(), false) .. " ...")
    checkStock(stock_items, stockItemsCount)
    print("Update complete at", textutils.formatTime(os.time(), false) .. ".")
    sleep(period)
end

