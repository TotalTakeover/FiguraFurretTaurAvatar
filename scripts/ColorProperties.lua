-- Avatar color
avatar:color(vectors.hexToRGB("A77962"))

-- Glowing outline
renderer:outlineColor(vectors.hexToRGB("A77962"))

-- Host only instructions
if not host:isHost() then return end

-- Table setup
local c = {}

-- Action variables
c.hover     = vectors.hexToRGB("D2AF9D")
c.active    = vectors.hexToRGB("775043")
c.primary   = "#775043"
c.secondary = "#D2AF9D"

-- Return variables
return c