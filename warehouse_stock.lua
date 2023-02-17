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
	{ "rootsclassic:blackcurrant", 16, 128 },
	{ "minecraft:bone", 16, 128 },
	{ "minecraft:bone_meal", 64, 128 },
	{ "minecraft:cauldron", 4, 64 },
	{ "minecraft:clay", 1, 64 },
	{ "minecraft:copper_ingot", 32, 128 },
	{ "rootsclassic:elderberry", 16, 128 },
	{ "minecraft:gold_ingot", 32, 128 },
	{ "minecraft:iron_ingot", 32, 128 },
	{ "minecraft:lapis_lazuli", 16, 128 },
	{ "minecraft:leather", 16, 128 },
	{ "minecraft:oak_log", 256, 512 },
	{ "minecraft:potato", 64, 128 },
	{ "minecraft:prismarine_crystals", 4, 64 },
	{ "minecraft:prismarine_shard", 4, 64 },
	{ "minecraft:beef", 16, 128 }, -- Raw Beef
	{ "minecraft:cod", 16, 128 }, -- Raw Cod
	{ "minecraft:mutton", 16, 128 }, -- Raw Mutton
	{ "rootsclassic:redcurrant", 16, 128 },
	{ "minecraft:salmon", 16, 128 }, -- Raw Salmon
	{ "minecraft:sugar_cane", 16, 128 },
	{ "minecraft:wheat", 128, 256 },
	{ "minecraft:wheat_seeds", 128, 256 },
	{ "rootsclassic:whitecurrant", 16, 128 },
	{ "minecraft:white_wool", 16, 128 },
}

-- Scale of text on monitor.  0.5 allows two columns of equal width
-- in same space as normal scale (of 1.0).

local monitor_scale = 0.5

-- Amount of time, in seconds, between stock checks.

local period = 5

-- This is the name of the warehouse inventory peripheral.  You can use the
-- name of the block, "inventory" if no ither inventory is available to
-- computer, or a direction (left/right/up/down/front/back)

local warehouse = peripheral.find("entangled:tile") or error("Unable to locate warehouse.", -1)

-- This is the name of the bridge peripheral.  For AE2 it should be "meBridge",
-- and for RS it should be "rsBridge".

local bridge = peripheral.find("meBridge") or error("Unable to locate bridge.", -2)

-- Name (or side name if attached directly to computer) of monitor for status display.
-- If you have a lot of items to stock, make it pretty large (I normally use 6x4, so
-- 24 total Advanced Monitors).

local mon = peripheral.find("monitor") or error("Unable to locate monitor.", -3)

---------------------------------------------------------------------------
-- MODIFY NOTHING BELOW HERE
---------------------------------------------------------------------------

local pp = require("cc.pretty").pretty_print

-- Constants

local S_LOW = 1					-- Not enough in stock
local S_HIGH = 2				-- Too much in stock
local S_GOOD = 3				-- At least minimum amount in stock
local S_NOCRAFT = 4				-- Not enough in stock, but not craftable
local S_UNKNOWN = 5				-- Unable to determine stock

-- Locate item in inventory warehouse
-- Returns slot index if found, nil otherwise

function find_item(name)
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
	item = find_item(itemName)
	if item then
		-- Get info on the slots with item
		local items = {}
		local count = 0
		local title = nil
		for i, s in ipairs(item) do
			items[s] = warehouse.getItemDetail(s)
			if title == nil then
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
			removeItems(itemName, items, count - maxCount)
		-- Not enough?
		elseif count < minCount then
			-- Get some from digital storage
			updateStatus(title, line, S_LOW, onLeft)
			if not getItems(itemName, items, minCount - count) then
				updateStatus(title, line, S_NOCRAFT, onLeft)
			end
		else
			-- Just right
			updateStatus(title, line, S_GOOD, onLeft)
		end
	else
		updateStatus(itemName, line, S_UNKNOWN, onLeft)
	end
end

-- Check stock in all items in table.
--
-- items = Table of items as documented at top of file
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

-- Get items from digital storage and place in warehouse
-- Returns false if not enough items in storage to fill
-- request and the item is not craftable

-- TODO:  Craft the item if needed

function getItems(item, slots, count)
	local amount = bridge.exportItemToPeripheral({name=item, count=count},
		peripheral.getName(warehouse))
	return amount >= count
end

-- Remove items from warehouse and place in digital storage
--
-- item  = Minecraft internal name for item
-- slots = Table of slot->details
-- count = Total number to remove from warehouse

function removeItems(item, slots, count)
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
    checkStock(stock_items, stockItemsCount)
    sleep(period)
end

