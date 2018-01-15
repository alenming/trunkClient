
--------------------------------
-- @module ProtocolIAP
-- @extend PluginProtocol

--------------------------------
-- get plugin id
-- @function [parent=#ProtocolIAP] getPluginId 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- get order id
-- @function [parent=#ProtocolIAP] getOrderId 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- change the state of paying
-- @function [parent=#ProtocolIAP] resetPayState 
-- @param self
        
--------------------------------
-- pay for product
-- @function [parent=#ProtocolIAP] payForProduct 
-- @param #table info, The info of product, must contains key:
-- @param productName         The name of product
-- @param productPrice        The price of product(must can be parse to float)
-- @param productDesc         The description of product
        
--------------------------------
-- set the result listener
-- @function [parent=#ProtocolIAP] setResultListener 
-- @param self
-- @param #function function of listener callback

--------------------------------
-- remove the result listener
-- @function [parent=#ProtocolREC] removeListener 
-- @param self
        
return nil
