
--------------------------------
-- @module ProtocolShare
-- @extend PluginProtocol

--------------------------------
-- share information
-- @function [parent=#ProtocolShare] share 
-- @param self
-- @param #table info{key(str)=value(str), ..}
-- @param The info of share, contains key:
-- @param SharedText                	The text need to share-- @param 
-- @param SharedImagePath				The full path of image file need to share (optinal)
        
--------------------------------
-- set the result listener
-- @function [parent=#ProtocolShare] setResultListener 
-- @param self
-- @param #function function of listener callback
        
--------------------------------
-- remove the result listener
-- @function [parent=#ProtocolREC] removeListener 
-- @param self
return nil
