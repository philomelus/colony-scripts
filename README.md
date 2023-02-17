# colony-scripts
Various scripts for MineColonies control/usage/convenience.

# request_stock.lua

Originally based on Scott Adkins RSWarehouse.lua script.  It has change significantly, but maintains the same purpose:  Automatically stock requested items - from builders or workers - via items in digital storage.  Both Refined Storage and Applied Energistics 2 are supported.

# storage_stock.lua

Uses a list of items to automatically keep at a minimum level within a digital storage system.  Both Refined Storage and Applied Energistics 2 are supported.

# warehouse_stock.lua

Keeps stock of items within a colony warehouse at a specific level.  This means it will REMOVE items from the warehouse if there are more than a specified limit, and place them within the digitial storage, OR restock the item from digital - crafting if needed and available -  storage if there are more than a specified minimum amount.
