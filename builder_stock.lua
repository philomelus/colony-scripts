--
-- Script attempts to automatically fill colony requests from a
-- digital storage bridge (Applied Energistics 2 and Refined
-- Storage are supported).
--

pp = require("cc.pretty").pretty_print

-- Digital storage bridge
bridge = peripheral.find("meBridge") or print("Unable to find bridge.", 0)

-- Colony integrator
mc = peripheral.find("colonyIntegrator") or error("Unable to find colony integrator.", 0)

-- Monitor
dsp = peripheral.find("monitor") or error("Unable to find monitor.", 0)

