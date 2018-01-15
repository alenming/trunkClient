
function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")
end

package.path = package.path .. ";src/"
cc.FileUtils:getInstance():setPopupNotify(false)
print("conect server")
connectToServer("127.0.0.1", 5555, 0, 0)
--require("app.UIDemoApp").new():run()
