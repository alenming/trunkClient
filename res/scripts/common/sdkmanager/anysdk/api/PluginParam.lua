
--------------------------------
-- @module PluginParam

--------------------------------
-- the default constructor of PluginParam
-- @function [parent=#PluginParam] PluginParam 
-- @param self
-- @param null, or #string str, or #number num, or #bool b, or #table {key(str)=value(str), ..}
        
--------------------------------
-- get the ParamType of value
-- @function [parent=#PluginParam] getCurrentType 
-- @param self
-- @return number#number ret (return value: number)
        
--------------------------------
-- get the int value
-- @function [parent=#PluginParam] getIntValue 
-- @param self
-- @return number#number ret (return value: number)
        
--------------------------------
-- get the float value
-- @function [parent=#PluginParam] getFloatValue 
-- @param self
-- @return number#number ret (return value: number)
        
--------------------------------
-- get the boolean value
-- @function [parent=#PluginParam] getBoolValue
-- @param self
-- @return boolean#boolean ret (return value: boolean)

--------------------------------
-- get the char value
-- @function [parent=#PluginParam] getStringValue 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- get the map of  value
-- @function [parent=#PluginParam] getMapValue 
-- @param self
-- @return table#table ret (return value: table{key(str)=value(anysdk.PluginParam), ..})
        
--------------------------------
-- get the StringMap value
-- @function [parent=#PluginParam] getStrMapValue 
-- @param self
-- @return table#table ret (return value: table{key(str)=value(str), ..})
        
return nil
