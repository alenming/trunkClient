
--------------------------------
-- @module ProtocolREC
-- @extend PluginProtocol

--------------------------------
-- Start to record video
-- @function [parent=#ProtocolREC] startRecording 
-- @param self
        
--------------------------------
-- Stop to record video
-- @function [parent=#ProtocolREC] stopRecording 
-- @param self
--------------------------------

-- share video
-- @function [parent=#ProtocolREC] share 
-- @param self
-- @param #table info{key(str)=value(str), ..}
-- @param The info of share, contains key:
-- @param Video_Title                	The title need to share-- @param 
        
--------------------------------
-- set the result listener
-- @function [parent=#ProtocolREC] setResultListener 
-- @param self
-- @param #function function of listener callback

--------------------------------
-- remove the result listener
-- @function [parent=#ProtocolREC] removeListener 
-- @param self
        
return nil
