
--------------------------------
-- @module ProtocolSocial
-- @extend PluginProtocol

--------------------------------
-- show the id of Leaderboard page
-- @function [parent=#ProtocolSocial] showLeaderboard 
-- @param self
-- @param #string leaderboardID
        
--------------------------------
-- user signOut
-- @function [parent=#ProtocolSocial] signOut 
-- @param self
        
--------------------------------
-- show the page of achievements
-- @function [parent=#ProtocolSocial] showAchievements 
-- @param self
        
--------------------------------
-- user signIn
-- @function [parent=#ProtocolSocial] signIn 
-- @param self
        
--------------------------------
-- submit the score
-- @function [parent=#ProtocolSocial] submitScore 
-- @param self
-- @param #string leaderboardID
-- @param #long score, the score
        
--------------------------------
-- remove the result listener
-- @function [parent=#ProtocolREC] removeListener 
-- @param self
        
--------------------------------
-- set the result listener
-- @function [parent=#ProtocolSocial] setListener 
-- @param self
-- @param #function function of listener callback
        
--------------------------------
-- methods of achievement feature
-- @function [parent=#ProtocolSocial] unlockAchievement 
-- @param self
-- @param #table {key(str)=value(str), ..}
        
return nil
