--
-- 平台模型, 记录登录后的uid, openId, token
--

-- 记录登录验证信息，用于小重连
-- 公共小重连流程：
-- 0.断线时开启重连中提示
-- 1.连接成功 ——> 失败则继续提示重连中
-- 2.发送校验
-- 3.校验成功 ——> 失败应该弹出对话框，询问重试或退出登录
-- 4.发送重连 ——> 解除重连提示，继续游戏（raiseEvent，让PVP小重连刷新）

-- 关于PVP小重连
-- 在公共重连完成后（执行完第四步），通过监听raiseEvent执行
-- 1.先检测队列中是否有未执行的指令，如果有则直接完成重连步骤
-- 2.如果当前队列中的指令都执行完了，请求更新，在更新请求中携带当前GameTick + 最后一条执行的指令下标
-- 3.服务器接收到更新指令后，判断队列中如果在执行时间小于等于GameTick且大于前端发送的下标，发送反序列化包，否则结束小重连流程
-- 4.客户端收到服务端的反序列化包则执行反序列化，否则继续游戏

PlatformModel = {}

PlatformModel.loginType = "TestLogin" -- 另外还有"SDKLogin"
PlatformModel.userId = 0
PlatformModel.pfType = 0
PlatformModel.openId = ""
PlatformModel.token = ""
PlatformModel.host = "127.0.0.1"
PlatformModel.port = 0

