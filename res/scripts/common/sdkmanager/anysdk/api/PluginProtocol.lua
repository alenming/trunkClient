
--------------------------------
-- @module PluginProtocol

--------------------------------
-- get plugin name
-- @function [parent=#PluginProtocol] getPluginName 
-- @param self
-- @return char#char ret (return value: string)
        
--------------------------------
-- get the version of plugin
-- @function [parent=#PluginProtocol] getPluginVersion 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- set plugin name
-- @function [parent=#PluginProtocol] setPluginName 
-- @param self
-- @param #char name, the name of plugin
        
--------------------------------
-- get the version of sdk
-- @function [parent=#PluginProtocol] getSDKVersion 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- switch debug plug-in on/off
-- @function [parent=#PluginProtocol] setDebugMode 
-- @param self
-- @param #bool bDebug, the value of on/off
-- @deprecated

--------------------------------
-- Check function the plugin support or not
-- @function [parent=#PluginProtocol] isFunctionSupported
-- @param self
-- @param #string name, the name of plugin
-- @return bool#bool ret (return value: bool)

--------------------------------
-- methods for reflections
-- @function [parent=#PluginProtocol] callFuncWithParam 
-- @methods for reflections
-- @param self
-- @param #string funcName, function name
-- @param #anysdk.PluginParam param,....; or [anysdk.PluginParam]. (some PluginParams)

--------------------------------
-- methods for reflections
-- @function [parent=#PluginProtocol] callStringFuncWithParam 
-- @methods for reflections
-- @param self
-- @param #string funcName, function name
-- @param #anysdk.PluginParam param,....; or [anysdk.PluginParam]. (some PluginParams)

--------------------------------
-- methods for reflections
-- @function [parent=#PluginProtocol] callIntFuncWithParam 
-- @methods for reflections
-- @param self
-- @param #string funcName, function name
-- @param #anysdk.PluginParam param,....; or [anysdk.PluginParam]. (some PluginParams)

--------------------------------
-- methods for reflections
-- @function [parent=#PluginProtocol] callBoolFuncWithParam 
-- @methods for reflections
-- @param self
-- @param #string funcName, function name
-- @param #anysdk.PluginParam param,....; or [anysdk.PluginParam]. (some PluginParams)

--------------------------------
-- methods for reflections
-- @function [parent=#PluginProtocol] callFloatFuncWithParam 
-- @methods for reflections
-- @param self
-- @param #string funcName, function name
-- @param #anysdk.PluginParam param,....; or [anysdk.PluginParam]. (some PluginParams)
        
return nil
