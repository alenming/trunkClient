
--------------------------------
-- @module ProtocolCrash
-- @extend PluginProtocol

--------------------------------
-- set user identifier
-- @function [parent=#ProtocolCrash] setUserIdentifier 
-- @param self
-- @param #char userInfo, The identity of user
        
--------------------------------
-- The uploader captured in exception information
-- @function [parent=#ProtocolCrash] reportException 
-- @param self
-- @param #char errorId, The identity of error
-- @param #char message, Extern message for the error
        
--------------------------------
--  customize logging
-- @function [parent=#ProtocolCrash] leaveBreadcrumb 
-- @param self
-- @param #char char breadcrumb
        
return nil
