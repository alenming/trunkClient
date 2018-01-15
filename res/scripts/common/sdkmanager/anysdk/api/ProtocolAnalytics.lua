
--------------------------------
-- @module ProtocolAnalytics
-- @extend PluginProtocol

--------------------------------
-- Track an event begin.
-- @function [parent=#ProtocolAnalytics] logTimedEventBegin 
-- @param self
-- @param #char eventId, The identity of event
        
--------------------------------
-- log an error
-- @function [parent=#ProtocolAnalytics] logError 
-- @param self
-- @param #char errorId, The identity of error
-- @param #char message, Extern message for the error
        
--------------------------------
-- Whether to catch uncaught exceptions to server.
-- @function [parent=#ProtocolAnalytics] setCaptureUncaughtException 
-- @param self
-- @param #bool enabled
        
--------------------------------
-- Set the timeout for expiring a session.
-- @function [parent=#ProtocolAnalytics] setSessionContinueMillis 
-- @param self
-- @param #long millis, In milliseconds as the unit of time.
        
--------------------------------
-- Start a new session.
-- @function [parent=#ProtocolAnalytics] startSession 
-- @param self
        
--------------------------------
-- Stop a session.
-- @function [parent=#ProtocolAnalytics] stopSession 
-- @param self
        
--------------------------------
-- Track an event begin.
-- @function [parent=#ProtocolAnalytics] logTimedEventEnd 
-- @param self
-- @param #char char
        
--------------------------------
-- log an event.
-- @function [parent=#ProtocolAnalytics] logEvent 
-- @param self
-- @param #char char
-- @param #{key(str), value(str)}
        
return nil
