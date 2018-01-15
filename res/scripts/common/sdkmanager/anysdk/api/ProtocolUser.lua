
--------------------------------
-- @module ProtocolUser
-- @extend PluginProtocol

--------------------------------
-- Check whether the user logined or not
-- @function [parent=#ProtocolUser] isLogined 
-- @param self
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- Get user ID
-- @function [parent=#ProtocolUser] getUserID 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- remove the result listener
-- @function [parent=#ProtocolREC] removeListener 
-- @param self
        
--------------------------------
-- User login
-- @overload self, info         
-- @overload self        
-- @function [parent=#ProtocolUser] login
-- @param self
-- @param #{key(str), value(str)} info

--------------------------------
-- Get plugin ID
-- @function [parent=#ProtocolUser] getPluginId 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- set the result listener
-- @function [parent=#ProtocolUser] setActionListener 
-- @param self
-- @param #function function of listener callback
        
return nil
