local component = require("component")
local sides = require("sides")

local SIDE_NAMES = {}
for name, value in pairs(sides) do
  if type(value) == "number" then
    SIDE_NAMES[value] = name
  end
end

local function tryCallSide(target, methodName, side)
  local method = target[methodName]
  if type(method) ~= "function" then
    return nil
  end

  local ok, result = pcall(method, target, side)
  if ok then
    return result
  end

  ok, result = pcall(method, target)
  if ok then
    return result
  end

  return nil
end

local function buildBatteryLine(adapter, side, blockName)
  local stored = tryCallSide(adapter, "getEnergyStored", side)
  local capacity = tryCallSide(adapter, "getMaxEnergyStored", side)
  local euIn = tryCallSide(adapter, "getInputRate", side)
  local euOut = tryCallSide(adapter, "getOutputRate", side)

  return string.format(
    "GTNH батарея (%s): %s/%s EU, ввод %s EU/t, вывод %s EU/t",
    blockName,
    stored or "?",
    capacity or "?",
    euIn or "?",
    euOut or "?"
  )
end

local function buildReactorLine(adapter, side, blockName)
  local heat = tryCallSide(adapter, "getHeat", side)
  local maxHeat = tryCallSide(adapter, "getMaxHeat", side)
  local output = tryCallSide(adapter, "getOutput", side) or tryCallSide(adapter, "getReactorOutput", side)

  return string.format(
    "NC2 реактор (%s): тепло %s/%s, выход %s EU/t",
    blockName,
    heat or "?",
    maxHeat or "?",
    output or "?"
  )
end

local function describeAdapter(adapter)
  local lines = {}

  for side = 0, 5 do
    local blockName = tryCallSide(adapter, "getBlockName", side)
    if blockName then
      local label = SIDE_NAMES[side] or tostring(side)
      local descriptor

      if blockName:lower():find("battery", 1, true) or blockName:lower():find("buffer", 1, true) then
        descriptor = buildBatteryLine(adapter, side, blockName)
      elseif blockName:lower():find("reactor", 1, true) or blockName:lower():find("nuclear", 1, true) then
        descriptor = buildReactorLine(adapter, side, blockName)
      else
        local meta = tryCallSide(adapter, "getMetadata", side)
        descriptor = string.format("Неизвестный блок (%s), метаданные %s", blockName, meta or "?")
      end

      table.insert(lines, string.format("[%s] %s", label, descriptor))
    end
  end

  if #lines == 0 then
    return "Нет подключённых блоков"
  end

  return table.concat(lines, "\n")
end

for address in component.list("adapter") do
  local adapter = component.proxy(address)
  print(("Адаптер %s:\n%s"):format(address, describeAdapter(adapter)))
end