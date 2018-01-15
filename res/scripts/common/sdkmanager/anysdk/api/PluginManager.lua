
--------------------------------
-- @module PluginManager

--------------------------------
-- unload the plugin by name and type
-- @function [parent=#PluginManager] unloadPlugin 
-- @param self
-- @param #char name, the name of plugin
-- @param #int type, the type of plugin
        
--------------------------------
-- load the plugin by name and type
-- @function [parent=#PluginManager] loadPlugin 
-- @param self
-- @param #char name, the name of plugin
-- @param #int type, the type of plugin
-- @return PluginProtocol#PluginProtocol ret (return value: anysdk.PluginProtocol)
        
--------------------------------
-- Destory the instance of PluginManager
-- @function [parent=#PluginManager] endManager 
-- @param self
        
--------------------------------
-- Get singleton of PluginManager
-- @function [parent=#PluginManager] getInstance 
-- @param self
-- @return PluginManager#PluginManager ret (return value: anysdk.PluginManager)
        
return nil
