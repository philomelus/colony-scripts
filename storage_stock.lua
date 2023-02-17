-- storage_stock.lua - Maintain stock of items in digital storage.
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
-- Lua script for use with CC: tweaked that will keep a minimum stock of
-- any item contained within a list.  Works for both Refined Storage and
-- Applied Energistics 2.
--
-- Requirements:
-- 1.  Either a MEBridge or RSBridge connected to your computer.
-- 2.  A ColonyIntegrator connected to your computer.
-- 3.  Since the Colony Integrator must be within a colony for it to work,
--     either place the computer and all periperals within a colony or use
--     your choice of entagled blocks to accomplish the same.
-- 4.  A monitor attached to the computer.  Most of the time, only a couple
--     of lines are shown on the monitor.  Once in awhile, especially for
--     larger colonies (or more advanced ...) there will be a long list.
--     The script will only display what will fit on the monitor.
--
-- Finally, you will need to update some of the variables below.  Read the
-- description in the comments directly before the variable to see what
-- what you need to do.
--

---------------------------------------------------------------------------
-- List of the items which should be stocked
-- Table of tables of items.  Each item to be stocked should be in this table,
-- inside a table containing  two items.  First item is minecraft name of item,
-- and second item is the minimal numerical amount to keep stocked, like this:
--
-- { "minecraft:name_of_item", amount }
--
-- NOTE that the name is the internal minecraft name of item, not the nice
--      name that is shown to users.  If you turn on advanced tooltips (via
--      F3+H), then you can see the item name in the popup window shown when
--      hovering over an item (when viewing inventory).

local items_to_stock = {
	{"minecraft:anvil", 2},
	{"minecraft:black_bed", 2},
    {"minecraft:black_concrete", 4},
    {"minecraft:black_concrete_powder", 4},
    {"minecraft:black_dye", 4},
    {"minecraft:black_stained_glass", 16},
    {"minecraft:black_stained_glass_pane", 16},
    {"minecraft:black_terracotta", 16},
    {"minecraft:blue_concrete", 4},
    {"minecraft:blue_concrete_powder", 4},
    {"minecraft:blue_dye", 4},
    {"minecraft:blue_stained_glass", 16},
    {"minecraft:blue_stained_glass_pane", 16},
    {"minecraft:blue_terracotta", 16},
    {"minecraft:brown_concrete", 4},
    {"minecraft:brown_concrete_powder", 4},
    {"minecraft:brown_dye", 4},
    {"minecraft:brown_stained_glass", 16},
    {"minecraft:brown_stained_glass_pane", 16},
    {"minecraft:brown_terracotta", 16},
	{"minecraft:chiseled_stone_bricks", 8},
    {"minecraft:cyan_concrete", 4},
    {"minecraft:cyan_concrete_powder", 4},
    {"minecraft:cyan_dye", 4},
    {"minecraft:cyan_stained_glass", 16},
    {"minecraft:cyan_stained_glass_pane", 16},
    {"minecraft:cyan_terracotta", 16},
	{"minecraft:flower_pot", 10},
	{"minecraft:gray_bed", 2},
    {"minecraft:gray_concrete", 4},
    {"minecraft:gray_concrete_powder", 4},
    {"minecraft:gray_dye", 4},
    {"minecraft:gray_stained_glass", 16},
    {"minecraft:gray_stained_glass_pane", 16},
    {"minecraft:gray_terracotta", 16},
    {"minecraft:green_concrete", 4},
    {"minecraft:green_concrete_powder", 4},
    {"minecraft:green_dye", 4},
    {"minecraft:green_stained_glass", 16},
    {"minecraft:green_stained_glass_pane", 16},
    {"minecraft:green_terracotta", 16},
	{"minecraft:ladder", 16},
    {"minecraft:light_blue_concrete", 4},
    {"minecraft:light_blue_concrete_powder", 4},
    {"minecraft:light_blue_dye", 4},
    {"minecraft:light_blue_stained_glass", 16},
    {"minecraft:light_blue_stained_glass_pane", 16},
	{"minecraft:light_blue_terracotta", 16},
	{"minecraft:light_gray_bed", 2},
    {"minecraft:light_gray_concrete", 4},
    {"minecraft:light_gray_concrete_powder", 4},
    {"minecraft:light_gray_dye", 4},
    {"minecraft:light_gray_stained_glass", 16},
    {"minecraft:light_gray_stained_glass_pane", 16},
	{"minecraft:light_gray_terracotta", 16},
    {"minecraft:lime_concrete", 4},
    {"minecraft:lime_concrete_powder", 4},
    {"minecraft:lime_dye", 4},
    {"minecraft:lime_stained_glass", 16},
    {"minecraft:lime_stained_glass_pane", 16},
    {"minecraft:lime_terracotta", 16},
    {"minecraft:magenta_concrete", 4},
    {"minecraft:magenta_concrete_powder", 4},
    {"minecraft:magenta_dye", 4},
    {"minecraft:magenta_stained_glass", 16},
    {"minecraft:magenta_stained_glass_pane", 16},
    {"minecraft:magenta_terracotta", 16},
	{"minecraft:oak_button", 5},
	{"minecraft:oak_fence", 64},
	{"minecraft:oak_fence_gate", 4},
	{"minecraft:oak_slab", 15},
	{"minecraft:oak_trapdoor", 10},
	{"minecraft:orange_bed", 2},
    {"minecraft:orange_concrete", 4},
    {"minecraft:orange_concrete_powder", 4},
    {"minecraft:orange_dye", 4},
	{"minecraft:orange_glazed_terracotta", 4},
    {"minecraft:orange_stained_glass", 16},
    {"minecraft:orange_stained_glass_pane", 16},
    {"minecraft:orange_terracotta", 16},
    {"minecraft:pink_concrete", 4},
    {"minecraft:pink_concrete_powder", 4},
    {"minecraft:pink_dye", 4},
    {"minecraft:pink_stained_glass", 16},
    {"minecraft:pink_stained_glass_pane", 16},
    {"minecraft:pink_terracotta", 16},
    {"minecraft:purple_concrete", 4},
    {"minecraft:purple_concrete_powder", 4},
    {"minecraft:purple_dye", 4},
    {"minecraft:purple_stained_glass", 16},
    {"minecraft:purple_stained_glass_pane", 16},
    {"minecraft:purple_terracotta", 16},
	{"minecraft:red_bed", 2},
    {"minecraft:red_concrete", 4},
    {"minecraft:red_concrete_powder", 4},
    {"minecraft:red_dye", 4},
    {"minecraft:red_stained_glass", 16},
    {"minecraft:red_stained_glass_pane", 16},
    {"minecraft:red_terracotta", 16},
	{"minecraft:smoker", 2},
	{"minecraft:smooth_stone", 16},
	{"minecraft:smooth_stone_slab", 6},
	{"minecraft:stone_brick_wall", 12},
	{"minecraft:stone_brick_slab", 12},
	{"minecraft:stone_bricks", 64},
	{"minecraft:white_bed", 2},
    {"minecraft:white_concrete", 4},
    {"minecraft:white_dye", 4},
    {"minecraft:white_concrete_powder", 4},
    {"minecraft:white_stained_glass", 16},
    {"minecraft:white_stained_glass_pane", 16},
    {"minecraft:white_terracotta", 16},
    {"minecraft:yellow_concrete", 4},
    {"minecraft:yellow_concrete_powder", 4},
    {"minecraft:yellow_dye", 4},
    {"minecraft:yellow_stained_glass", 16},
    {"minecraft:yellow_stained_glass_pane", 16},
    {"minecraft:yellow_terracotta", 16},
}

-- Scale of text on monitor.  0.5 allows two columns of equal width
-- in same space as normal scale (of 1.0).

local monitor_scale = 0.5

-- Amount of time, in seconds, between stock checks.

local period = 5

-- This is the name of the bridge peripheral.  For AE2 it should be "meBridge",
-- and for RS it should be "rsBridge".

local bridge = peripheral.find("meBridge") or error("Unable to locate bridge.", -1)

-- Name (or side name if attached directly to computer) of monitor for status display.
-- If you have a lot of items to stock, make it pretty large (I normally use 6x4, so
-- 24 total Advanced Monitors).

local mon = peripheral.find("monitor") or error("Unable to locate monitor.", -2)

---------------------------------------------------------------------------
-- MODIFY NOTHING BELOW HERE
---------------------------------------------------------------------------

-- Constants

local S_LOW = 1					-- Not enough in stock
local S_UNKNOWN = 2				-- Unable to determine stock
local S_GOOD = 3				-- At least minimum amount in stock

-- Title at top of display (no need to change).

local label = "Stock"

-- Given item name and minimum amount to keep stocked, ensure
-- storage contains at least minimum amount of item.
-- Handles cases of item not in storage or not craftable.
--
-- itemName - Internal minecraft name (tag) for item
-- minCount - Minimum number of item to maintain
-- line     - Line to show status of item on monitor
-- onLeft   - true to show in left column, otherwise right column

function checkItem(itemName, minCount, line, onLeft)
	-- Get item info from storage
	local item = bridge.getItem({name=itemName})
	-- If item existed in storage
	if item then
		-- Number of items in the system lower than the minimum amount?
		if item.amount < minCount then
			-- Not enough.  Is item craftable?
			if item.isCraftable then
                -- Only request crafting if its not already crafting
                if not bridge.isItemCrafting({name = itemName}) then
                    bridge.craftItem({name = itemName, count = (minCount - item.amount)})
                end
				
				-- Update display
				updateState(item.displayName, line, S_LOW, onLeft)
				return
			end
		else
			-- Enough stocked
			updateState(item.displayName, line, S_GOOD, onLeft)
			return
		end
		
		-- Stock is low and its not craftable
		updateState(item.displayName, line, S_UNKNOWN, onLeft)
		return
	else
		-- Item not in storage, is it craftable but zero quantity?
		local craft_items = bridge.listCraftableItems()
		for ci = 1, #craft_items do
			if craft_items[ci].name == itemName then
				bridge.craftItem({name = itemName, count = minCount})
				updateState(craft_items[ci].displayName, line, S_LOW, onLeft)
				return
			end
		end
		
		-- Item not in storage, so can't stock it.  Don't have item info
		-- so ugly internal minecraft name is shown instead of normal name.
		updateState(itemName, line, S_UNKNOWN, onLeft)
    end
end

-- Check stock in all items in table.
--
-- items = Table of items as documented at top of file
-- count = Number of items in table (passing it here saves a tiny
--         amount of cpu time versus getting the value every call)

function checkStock(items, count)
	-- First row on monitor to show items status'.  First row contains
	-- centered title (useless???).
    local row = 2

	-- For every two items in table
    for i = 1, count, 2 do
		-- Update status of first item on left
        checkItem(items[i][1], items[i][2], row, true)

		-- If there is a second item
		if i < count then
			-- Update status of second item on right
			checkItem(items[i + 1][1], items[i + 1][2], row, false)
		end

		-- Next line on monitor
		row = row + 1
    end
end

-- Update display status for an item.
--
-- text = The nice display name to show for item
-- line = Line number on monitor to display entry
-- status = Current state of the item (from constants above)
-- left = true to show in left column, otherwise in right column

function updateState(text, line, status, left)
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
	elseif status == S_LOW then
		mon.setTextColor(colors.red)
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
mon.setTextColor(colors.white)

-- Display title, centered
screen_w, screen_h = mon.getSize()
local left = math.floor((screen_w - string.len(label)) / 2)
mon.setCursorPos(left, 1)
mon.write(label)

-- Get this count one time only (it cannot change while running!)
local itemsToStockCount = #items_to_stock

-- Loop forever
while true do
    checkStock(items_to_stock, itemsToStockCount)
    sleep(period)
end
