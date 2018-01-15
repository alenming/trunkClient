
--------------------------------
-- @module ProtocolPush
-- @extend PluginProtocol

--------------------------------
-- start/register  Push services
-- @function [parent=#ProtocolPush] startPush 
-- @param self
        
--------------------------------
-- close Push services
-- @function [parent=#ProtocolPush] closePush 
-- @param self
        
--------------------------------
-- del alias
-- @function [parent=#ProtocolPush] delAlias 
-- @param self
-- @param #string alias, alias
        
--------------------------------
-- get pListener The callback object for Push result
-- @function [parent=#ProtocolPush] getActionListener 
-- @param self
-- @return PushActionListener#PushActionListener ret (return value: anysdk.PushActionListener)
        
--------------------------------
-- set alias
-- @function [parent=#ProtocolPush] setAlias 
-- @param self
-- @param #string alias, alias
        
--------------------------------
-- set the result listener
-- @function [parent=#ProtocolPush] setActionListener 
-- @param self
-- @param #function function of listener callback

--------------------------------
-- remove the result listener
-- @function [parent=#ProtocolREC] removeListener 
-- @param self
        
--------------------------------
-- set tag
-- @function [parent=#ProtocolPush] setTags 
-- @param self
-- @param #table {tag1(str),tag2(str),..}
        
--------------------------------
-- get tag
-- @function [parent=#ProtocolPush] delTags 
-- @param self
-- @param #table {tag1(str),tag2(str),..}
        
return nil
