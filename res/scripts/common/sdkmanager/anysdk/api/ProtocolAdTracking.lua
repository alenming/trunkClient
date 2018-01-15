
--------------------------------
-- @module ProtocolAdTracking
-- @extend PluginProtocol

--------------------------------
-- Call this method if you want to track register events as happening during a section.
-- @function [parent=#ProtocolAdTracking] onRegister 
-- @param self
-- @param #char userId    user identifier
        
--------------------------------
-- Call this method if you want to track login events as happening during a section.
-- @function [parent=#ProtocolAdTracking] onLogin 
-- @param self
-- @param userInfo  The details of this parameters are already covered by document.
        
--------------------------------
-- Call this method if you want to track pay events as happening during a section.
-- @function [parent=#ProtocolAdTracking] onPay 
-- @param self
-- @param #{key(str), value(str)} productInfo  The details of this parameters are already covered by document.
        
--------------------------------
-- Call this method if you want to track custom events with parameters as happening during a section.
-- @function [parent=#ProtocolAdTracking] trackEvent 
-- @param self
-- @param #char char
-- @param #{key(str), value(str)} paramMap The details of this parameters are already covered by document.
        
return nil
