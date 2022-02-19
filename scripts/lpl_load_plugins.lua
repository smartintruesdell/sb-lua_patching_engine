--[[
  This script allows for easy managent of Plugins for existing script modules.

  Instead of making direct edits to the vanilla scripts, we use this script once
  in each of those scripts to load plugins dynamically.
]]
require "/scripts/lpl_dependencies.lua"
require "/scripts/lpl_plugin_util.lua"

PluginLoader = {}
PluginLoader.debug = false

local function debug(message, ...)
  if PluginLoader.debug then
    sb.logInfo(
      string.format(
        "PluginLoader: "..message,
        ...
      )
    )
  end
end

---@param config_path string
---@return boolean, table
function PluginLoader.load(config_path)
  local loaded_plugins = {}
  assert(
    root ~= nil,
    "Run `load_plugins` in module new or init. Cannot run in the global context"
  )
  debug("Loading plugins from %s", config_path)
  local config_data = root.assetJson(config_path)
  debug("Resolving plugin dependencies")
  local plugins_to_load = PluginDependencies.resolve(config_data.plugins)
  for _, plugin in ipairs(plugins_to_load) do
    if not loaded_plugins[plugin.name] then
      debug("Loading plugin '%s' from %s", plugin.name, plugin.path)
      require(plugin.path)
      loaded_plugins[plugin.name] = true
    end
  end
end


function PluginLoader.add_plugin_loader(module_name, path, fn)
  return function(...)
    -- Load the plugins
    PluginLoader.load(path)

    -- Call pre-fn hooks
    local pargs = table.pack(Plugins.call_before_initialize_hooks(module_name, ...))

    -- call the original function
    local results = table.pack(fn(table.unpack(pargs)))

    -- call post-fn hooks
    return Plugins.call_after_initialize_hooks(module_name, table.unpack(results))
  end
end
