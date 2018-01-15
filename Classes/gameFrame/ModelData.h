#ifndef _SUM_MODEL_DATA_
#define _SUM_MODEL_DATA_

#include <map>
#include <set>
#include <vector>
#include <string>
#include "LoginProtocol.h"
#include "ConfStage.h"
#include "ConfGameSetting.h"

enum ETalentStatus
{
    ETS_LOCK,            // 未解锁
    ETS_UNLOCK,          // 解锁
    ETS_UNACTIVE,        // 未激活
    ETS_ACTIVE,           // 激活
    //ETS_EQUIPACTIVE,      // 装备激活(前端)
};

//章节状态
enum EChapterState
{
	ECS_LOCK,			//未解锁
	ECS_UNLOCK,			//已解锁
	ECS_FINISH,			//已完成
	ECS_REWARD,			//已领取
};

//关卡状态
enum ELevelState
{
	ESS_HIDE,			//未显示
	ESS_LOCK,			//未解锁
	ESS_UNLOCK,			//已解锁
	ESS_ONE,			//一星
	ESS_TWO,			//二星
	ESS_TRI,			//三星
};

// 装备部件类型
enum EquipPartType
{
    WEAPON = 1,					// 武器
    HEADWEAR,					// 头饰
    CLOTH,						// 衣服
    SHOES,						// 鞋子
    ACCESSORY,					// 饰品
    TREASURE,					// 宝具
};


/////////////////////////////////////////////////////////////////////////用户模型
class CUserModel
{
public:
	CUserModel();

public:

	bool init(void *data);

	void setUserID(int id){ m_nUserID = id; }
	int	getUserID(){ return m_nUserID; }

	void setHeadID(int id){ m_nHeadID = id; }
	int	getHeadID(){ return m_nHeadID; }

	void setGold(int num){ m_nGold = num; }
    void addGold(int num){ m_nGold += num; }
	int	getGold(){ return m_nGold; }

	void setLevel(int lv){ m_nLevel = lv; }
	int	getLevel(){ return m_nLevel; }

    void setUserExp(int exp) { m_nUserExp = exp; }
	int	getUserExp(){ return m_nUserExp; }

	void setDiamond(int num) { m_nDiamond = num; }
	int	getDiamond(){ return m_nDiamond; }

	void setTowerCoin(int coin) { m_nTowerCoin = coin; }
	int	getTowerCoin() { return m_nTowerCoin; }

	void setPVPCoin(int coin) { m_nPvpCoin = coin; }
	int	getPVPCoin() { return m_nPvpCoin; }

	void setUnionContrib(int contrib) { m_nUnionContrib = contrib; }	
	int	getUnionContrib() { return m_nUnionContrib; }

	void setFlashcard(int flashcard) { m_nFlashcard = flashcard; }
	int	getFlashcard(){ return m_nFlashcard; }

	void setFlashcard10(int flashcard10) { m_nFlashcard10 = flashcard10; }
	int	getFlashcard10(){ return m_nFlashcard10; }

	void setMaxEnergy(int max){ m_nMaxEnergy = max; }
	int	getMaxEnergy(){ return m_nMaxEnergy; }

    void setVipLv(int lv){ m_nVipLv = lv; }
	int getVipLv(){ return m_nVipLv; }

    void setVipPayment(int payment){ m_nPayment = payment; }
    void addVipPayment(int payment){ m_nPayment += payment; }
    int getVipPayment(){ return m_nPayment; }

    void setVipScore(int score){ m_nVipScore = score; }
    void addVipScore(int score){ m_nVipScore += score; }
    int getVipScore(){ return m_nVipScore; }

    void setMonthCardStamp(int time){ m_nMonthCardStamp = time; }
    int getMonthCardStamp(){ return m_nMonthCardStamp; }

    void setBuyGoldTimes(int times){ m_nBuyGoldTimes = times; }
	int getBuyGoldTimes(){ return m_nBuyGoldTimes; }

	const char* getUserName(){ return m_cUserName; }
    void setUserName(const char* name);
    void setChangeNameFree(){ m_nChangeNameFree = 1; }

	void setFreeHeroTimes(int times) { m_nFreeHeroTimes = times; }
	int	getFreeHeroTimes() { return m_nFreeHeroTimes; }
    
	int getChangeNameFree() { return m_nChangeNameFree; }
	    
    int getTotalSignDay(){ return m_nTotalSignDay; }
    void setTotalSignDay(int totalSignDay){ m_nTotalSignDay = totalSignDay; }
    
    int getMonthSignDay(){ return m_nMonthSignDay; }
    void setMonthSignDay(int monthSignDay){ m_nMonthSignDay = monthSignDay; }
    
    int getTotalSignFlag(){ return m_nTotalSignFlag; }
    void setTotalSignFlag(int totalSignFlag){ m_nTotalSignFlag = totalSignFlag; }

    // 重置数据
    void resetUserData();

protected:

	int			m_nUserID;					//用户ID
	int			m_nHeadID;					//头像ID
	int			m_nGold;					//金币
	int			m_nLevel;					//等级
    int         m_nUserExp;					//经验
	int			m_nDiamond;					//钻石
	int			m_nTowerCoin;				//塔币
	int			m_nPvpCoin;					//pvp币
	int			m_nUnionContrib;			//公会贡献
	int			m_nFlashcard;				//抽卡券
	int			m_nFlashcard10;				//十连抽卡券
	int			m_nMaxEnergy;				//最大体力
    int         m_nVipLv;					//VIP
    int         m_nPayment;              //已支付人民币
    int         m_nVipScore;                //vip积分
    int         m_nMonthCardStamp;          // 月卡过期时间戳
    int         m_nChangeNameFree;			//是否免费改名,0免费1不免费
    int         m_nBuyGoldTimes;			//购买金币次数
    int			m_nFreeHeroTimes;			//上次免费英雄时间
    int         m_nTotalSignDay;            //累计签到天数
    int         m_nMonthSignDay;            //当月累计签到天数
    int         m_nTotalSignFlag;           //累计签到次数

	char		m_cUserName[32];			//用户名
};

/////////////////////////////////////////////////////////////////////////背包模型
class CBagModel
{
public:
	CBagModel();

public:
	bool		init(void *data);
	//扩展背包修改容量上限
	bool		extra(int add);
	//添加物品:装备ID，配置ID；消耗品ID，数量
	bool		addItem(int id, int param);
	//删除物品
	bool		removeItem(int id);
    //删除物品
    bool		removeItems(int id, int count = 1);
	//判断是否有某物品
	bool		hasItem(int id);
    //获取背包存放的数量
    int         getItemCount() { return (int)m_mapBagItems.size(); }

public:
	//获取物品列表消耗品
	std::map<int, int>& getItems(){ return m_mapBagItems; }

	//获取当前容量
	int         getCurCapacity(){ return m_nCurCapacity; }
	void        setCurCapacity(int cur){ m_nCurCapacity = cur; }

protected:
	int			m_nCurCapacity;			//当前容量
	std::map<int, int>	m_mapBagItems;	//背包物品列表
};

/////////////////////////////////////////////////////////////////////////装备模型
class CEquipModel
{
public:
	//初始化
	bool init(void *data);
	//是否有装备
	bool haveEquip(int equipId);
	//添加装备
	bool addEquip(EquipItemInfo &EquipData);
	//移除装备
	void removeEquip(int equipId);
	//获得装备的配置id
	int getEquipConfId(int equipId);
    //获取装备属性
    bool getEquipInfo(int equipId, EquipItemInfo &info);
	//获得所有装备
	std::map<int, EquipItemInfo> &getEquips() { return m_mapEquips; }

protected:
	std::map<int,EquipItemInfo> m_mapEquips;		//装备列表
};

/////////////////////////////////////////////////////////////////////////召唤师列表模型
class CSummonersModel
{
public:
	//初始化数据
	bool		init(void *data);
	//增加召唤师
	bool		addSummoner(int id);
	//有召唤师么
	bool		hasSummoner(int id);
	//获取召唤师
	int			getSummonerCount();

public:
	//获取召唤师列表
	std::vector<int>&	getSummoners(){ return m_vecSummoners; }

protected:
	std::vector<int>	m_vecSummoners;		//召唤师列表
};

/////////////////////////////////////////////////////////////////////////英雄卡片模型
class CHeroCardModel
{
public:
    CHeroCardModel();
    bool init(void* data);

public:
    void setID(int id)      { m_nID = id;} 
    void setFrag(int frag)  { m_nFrag = frag; }
    void setLevel(int lv)   { m_nLv = lv; }
    void setStar(int star)  { m_nStar = star; }
    void setExp(int exp)    { m_nExp = exp; }

    // 添加, 删除, 替换 英雄装备 (eqDynID为0时表示该部位没有装备)
    void setEquip(EquipPartType eqPart, int eqDynID){
        if (eqPart > 0 && eqPart <= 6)
            m_equips[eqPart - 1] = eqDynID;
    }

    int getID()         { return m_nID; }
    int getFrag()       { return m_nFrag; }
    int getLevel()      { return m_nLv; }
    int getStar()       { return m_nStar; }
    int getExp()        { return m_nExp; }

    int getEquip(EquipPartType eqPart){
        if (eqPart > 0 && eqPart <= 6)
            return m_equips[eqPart - 1];
        return 0;
    }
    int* getEquips() { return m_equips; }

private:
    int m_nID;		               // 英雄ID
    int m_nFrag;                   // 英雄碎片
    int m_nLv;                     // 等级
    int m_nStar;                   // 星级
    int m_nExp;                    // 经验
    unsigned char m_talent[8];     // 天赋
    int m_equips[6];               // 6个装备
};

/////////////////////////////////////////////////////////////////////////英雄卡包模型
class CHeroCardBagModel
{
public:
public:
    bool init(void *data);
    bool addHeroCard(int id);
    bool hasHeroCard(int id);
    CHeroCardModel* getHeroCard(int id);
    std::map<int, CHeroCardModel*>& getHeroCards(){ return m_mapHeroCards; }
    int getHeroCardCount();
private:
    std::map<int, CHeroCardModel*>	m_mapHeroCards;		//英雄卡片
};


/////////////////////////////////////////////////////////////////////////关卡模型
class CStageModel
{
public:
	bool init(void *data);
	std::map<int, int>& getChapterStates(){ return m_mapChapterStates; }
    std::map<int, int>& getComonStageStates(){ return m_mapComonStageStates; }
    std::map<int, int>& getEliteStageStates(){ return m_mapEliteStageStates; }

public:
	int getCurrentComonStageID();							//获取当前普通关卡
	int getCurrentEliteStageID();						    //获取当前精英关卡
	int getChapterState(int ch);							//获取章节状态
    int getComonStageState(int lv);							//获取普通章节状态
    int getEliteStageState(int lv);							//获取精英关卡状态
	int getEliteChallengeCount(int lv);						//获取精英关卡已经挑战的次数
	int getEliteChallengeTimestamp(int lv);					//获取精英挑战时间戳
	int getEliteBuyCount(int lv);							//获取精关关卡购买次数
	int getEliteBuyTimestamp(int lv);						//获取精英购买时间戳

	void setCurrentComonStageID(int lv);					//设置当前普度关卡
	void setCurrentEliteStageID(int lv);					//设置当前精英关卡
	void setChapterState(int ch, int state);				//设置普通章节状态
	void setComonStageState(int lv, int state);				//设置普通章节状态
	void setEliteStageState(int lv, int state);				//设置精英关卡状态
	void setEliteChallengeCount(int lv, int count);			//设置精英关卡已经挑战的次数
	void setEliteChallengeTimestamp(int lv, int time);		//设置精英挑战时间戳
	void setEliteBuyCount(int lv, int count);				//设置精英关卡购买次数
	void setEliteBuyTimestamp(int lv, int time);			//设置精英购买时间戳

public:
	void resetEliteChallengeCount(int lv);					//重置精英关卡挑战次数
	void resetEliteBuyCount(int lv);						//重置精英关卡购买次数						

protected:
	int deltaDay(const TimeInfo& info);						//日间隔
	int deltaWeek(const TimeInfo& info);					//周间隔
	int getChapterIDByStageID(int id);						//获取当前章节ID

protected:
	int	m_nCurrentComonStageID;								//当前普通关卡
	int m_nCurrentEliteStageID;								//当前精英关卡
	std::map<int, int> m_mapChapterStates;					//普通章节状态
	std::map<int, int> m_mapComonStageStates;				//普通关卡状态
	std::map<int, int> m_mapEliteStageStates;				//精英关卡状态
	std::map<int, int> m_mapEliteStageChallengeCount;		//精英关卡已经挑战的次数
	std::map<int, int> m_mapEliteStageChallengeTimestamp;	//精英关卡挑战时间戳
	std::map<int, int> m_mapEliteStageBuyCount;				//精英关卡购买次数
	std::map<int, int> m_mapEliteStageBuyTimestamp;			//精英关卡购买时间戳
};

enum ETeamType
{
    ETT_PASE,        // 通关队伍
    ETT_SPORTE       // 竞技队伍
};

struct TeamInfo
{
    int teamType;                 // 队伍类型
    int summonerID;               // 召唤师ID
	int heroID[7];				  // 英雄id
};

/////////////////////////////////////////////////////////////////////////队伍模型
class CTeamModel
{
public:
    bool init(void *data);
    // 根据队伍类型获取队伍
    bool getTeamInfo(int teamType, int &summonerID, std::vector<int>& vecHero);
    // 根据队伍类型设置队伍信息
    void setTeamInfo(int teamType, int summonerID, const std::vector<int>& vecHero);
    // 从所有队伍中去掉某个英雄
    void removeHeroFromAllTeam(int heroID);
    // 英雄是否存在队伍中(任意队伍)
    bool hasHeroAllTeam(int heroID);

private:
    std::map<int, int>              m_mapTeamSummoner;  // teamType, summoner
    std::map<int, std::vector<int>> m_mapTeamHero;      // teamType, herolist
};

// 任务状态(状态类任务,由前端计算)
enum ETaskStatus
{
	 ETASK_UNATIVE = -1,          // 未激活(等级未到)
	 ETASK_ACTIVE,                // 激活状态
	 ETASK_FINISH,                // 完成(可领取)
	 ETASK_GET,                   // 已经领取
};

struct EquipInfo
{
	 int equipID;            // 装备唯一ID
	 int equipConfID;        // 装备配置ID
};

struct ItemInfo
{
	 int itemID;             // 配置表ID
	 int itemCount;          // 道具数量
};

class CTaskModel
{
public:
	bool init(void* data);
	bool addTask(const TaskInfo& taskInfo);
	bool delTask(const int& taskId);
	bool setTask(const TaskInfo& taskInfo);
	inline const std::map<int, TaskInfo>& getTasksData() { return m_mapTasksInfo; }
private:
	std::map<int, TaskInfo> m_mapTasksInfo;
};

enum EAchieveStatus
{
	 EACHIEVE_STATUS_UNACTIVE = -1,// 未激活
	 EACHIEVE_STATUS_ACTIVE,       // 激活
	 EACHIEVE_STATUS_FINISH,       // 完成
	 EACHIEVE_STATUS_GET,          // 领取
};

class CAchieveModel
{
public:
	 bool init(void* data);
	 bool addAchieve(const AchieveInfo& achieveInfo);
	 bool delAchieve(const int& achieveID);
	 // 设置成就
	 bool setAchieve(const AchieveInfo& achieveInfo);
	 inline const std::map<int, AchieveInfo>& getAchievesData() { return m_mapAchievesInfo; }
private:
	std::map<int, AchieveInfo> m_mapAchievesInfo;
};

class CGuideModel
{
public:
	 bool init(void* data);

public: 
	void del(int id);
	void add(int id);
	std::set<int>& getActives(){ return m_setActives; }

private:
	 std::set<int> m_setActives;
};

class CUnionModel
{
public:
    CUnionModel();
    bool init(void* data);

    bool getHasUnion(){ return m_bHasUnion; }
    void setHasUnion(bool hasUnion){
        m_bHasUnion = hasUnion;
        if (hasUnion)
        {
            m_nApplyCount = 0;
            m_nApplyStamp = 0;
            m_vecApplyInfo.clear();
        }
        else
        {
            m_bHasAudit = false;
            m_nUnionID = 0;
            m_nTodayLiveness = 0;
            m_nTotalContribution = 0;
            m_cPos = 0;
            memset(m_cUnionName, 0, sizeof(m_cUnionName));
            memset(m_cUnionNotice, 0, sizeof(m_cUnionNotice));
        }
    }

    bool getHasAudit(){ return m_bHasAudit; }
    int getUnionID(){ return m_nUnionID; }
    int getTodayLiveness(){ return m_nTodayLiveness; }
    int getTotalContribution(){ return m_nTotalContribution; }
    char    getPos(){ return m_cPos; }
    const char* getUnionName(){ return m_cUnionName; }
    const char* getUnionNotice(){ return m_cUnionNotice; }

    void setHasAudit(bool hasAudit){ m_bHasAudit = hasAudit; }
    void setUnionID(int id){ m_nUnionID = id; }
    void setTodayLiveness(int value){ m_nTodayLiveness = value; }
    void setTotalContribution(int value){ m_nTotalContribution = value; }
    void setPos(int pos){ m_cPos = pos; }
    void setUnionName(const char* name)
    {
        if (strlen(name) < sizeof(m_cUnionName))
        {
            memset(m_cUnionName, 0, sizeof(m_cUnionName));
            memcpy(m_cUnionName, name, strlen(name));
        }
    }
    void setUnionNotice(const char* notic)
    {
        if (strlen(notic) < sizeof(m_cUnionName))
        {
            memset(m_cUnionNotice, 0, sizeof(m_cUnionNotice));
            memcpy(m_cUnionNotice, notic, strlen(notic));
        }
    }

    int getApplyCount(){ return m_nApplyCount; }
    int getApplyStamp(){ return m_nApplyStamp; }
    const std::vector<ApplyInfo> getApplyInfo(){ return m_vecApplyInfo; }

    void setApplyCount(int count){ m_nApplyCount = count; }
    void setApplyStamp(int stamp){ m_nApplyStamp = stamp; }
    void addApplyInfo(ApplyInfo& info){ m_vecApplyInfo.push_back(info); }
    bool delApplyInfo(int unionID);

private:
    bool        m_bHasUnion;        // 是否有公会
    // 有公会的数据
    bool        m_bHasAudit;        // 是否有审核信息
    int			m_nUnionID;		    // 工会id
    int         m_nTodayLiveness;    // 今日活跃度
    int         m_nTotalContribution;  // 累计贡献
    char        m_cPos;             // 职位
    char		m_cUnionName[20];   // 公会名
    char        m_cUnionNotice[128];// 公会公告
    // 没有公会的数据
    int         m_nApplyCount;       // 已申请的次数
    int         m_nApplyStamp;       // 可申请时间戳
    std::vector<ApplyInfo> m_vecApplyInfo;  //申请的公会信息

};

/////////////////////////////////////////////////////////////////////////活动副本模型
class CActivityInstanceModel
{
public:
	 bool init(void *data);
	 std::map<int, InstanceInfo>& getActivityInstance(){ return m_mapInstance; }

private:
	 std::map<int, InstanceInfo> m_mapInstance;
};

/////////////////////////////////////////////////////////////////////////邮件模型
enum EMailType
{
	MAIL_TYPE_NORMAL,           // 普通邮件(活动、背包不足)
    MAIL_TYPE_UNIONTIPS,        // 公会提醒邮件
    MAIL_TYPE_WEB,              // GM邮件(手动填写标题、内容等)
};

// 公会邮件TIPS
enum EMailTipsType
{
    MAIL_TIPS_NON,                     // 
    MAIL_TIPS_NOPASS,                  // 公会申请不通过
    MAIL_TIPS_KICK,                    // 公会踢出
    MAIL_TIPS_APPOINT,                 // 任命
    MAIL_TIPS_RELIEVE,                 // 撤职
    MAIL_TIPS_PASS,                    // 公会申请通过
};

#pragma pack(1)
struct DropItemInfo
{
    int id;					//物品id
    int num;				//物品个数
    int crit;				//暴击次数
};

struct NoramlMailInfo
{
    int nMailID;						// 邮件ID
    int mailConfID;                     // 邮件配置ID
    int sendTimeStamp;                  // 发送时间戳
    char szTitle[32];					// 邮件标题
};

struct MailTips
{
    int tipsType;                        // 提示类型EMailTipsType
    int extend;                          // 扩展字段
	char unionName[32];                  // 公会名称
};
#pragma pack()

struct MailInfo
{
    bool isGetContent;                  // 是否获取内容
    int mailID;                         // 邮件ID
    int mailType;					    // 邮件类型 EMailType
    int mailConfID;                     // 游戏配置ID
    int sendTimeStamp;                  // 发送时间戳
    std::string title;                  // 标题
    std::string sender;					// 来自
    std::string content;			    // 内容
    std::vector<DropItemInfo>	items;	// 道具
};

class CMailModel
{
public:
    CMailModel();
    ~CMailModel();

	 bool init(void *data);
	 bool addMail(const MailInfo& info);
     bool setMail(const MailInfo& info);
	 bool removeMail(int mailKey);
	 const MailInfo* getMail(int mailKey);
	 const std::map<int, MailInfo>& getMails(){ return m_mapMailInfo; }

	 void addUnionMail(const MailTips tips){ m_unionMailTip = tips; }
     void delUnionMail(){ memset(&m_unionMailTip, 0, sizeof(MailTips)); }
	 const MailTips& getUnionMail(){ return m_unionMailTip; }

     int getMailCount(){ return m_mapMailInfo.size(); }
private:
	 // 添加普通邮件的时候, map的key是邮件 -100 - ID, 防止和web邮件重叠
	 int getMailKey(int mailID, int mailType);
private:
	 std::map<int, MailInfo> m_mapMailInfo;
	 // 公会邮件提示, 当type为MAIL_TIPS_NON时没有提示
	 MailTips				 m_unionMailTip;		
};

/////////////////////////////////////////////////////////////////////////金币试炼模型
struct GoldTestInfo
{
	 int count;		//挑战次数
	 int stamp;		//时间戳
	 int damage;	//总伤害
	 int state;		//宝箱状态
};

class CGoldTestModel
{
public:
	 bool init(void* data);
	 int getCount(){ return m_sInfo.count; }
	 int getStamp(){ return m_sInfo.stamp; }
	 int getDamage(){ return m_sInfo.damage; }
	 int getState(int i);

	 void addCount(int count){ m_sInfo.count += count; }
	 void setStamp(int stamp){ m_sInfo.stamp = stamp; }
	 void addDamage(int damage){ m_sInfo.damage += damage; }
	 void setState(int i);  //操作为领取宝箱
	 void setFlag(int flag){ m_sInfo.state = flag; }
    void resetGoldTest(int stamp);
private:
	 GoldTestInfo m_sInfo;
};

/////////////////////////////////////////////////////////////////////////英雄试炼模型
struct HeroTestInfo
{
	 int stamp;
	 int count;
};

class CHeroTestModel
{
public:
	 bool init(void* data);
	 int getCount(int i);
	 void setCount(int i, int count);
    void addCount(int i, int count);
	 int getStamp(){ return m_nStamp; }
	 void setStamp(int stamp ){ m_nStamp = stamp; }
    void resetHeroTest(int stamp);
private:
	 int m_nStamp;
	 std::map<int, int> m_mapCount;
};

/////////////////////////////////////////////////////////////////////////爬塔试炼模型
struct TowerTestInfo
{
	 int stamp;		//时间戳
	 int floor;     //当前楼层
	 int event;     //当前事件
	 int param;     //当前事件参数
	 int score;		//积分
	 int count;		//Buff个数
	 int crystal;	//水晶
	 int star;		//星星
};

class CTowerTestModel
{
public:
	 bool init(void* data);
	 int getFloor(){ return m_nFloor; }
	 void setFloor(int f){ m_nFloor = f; }
	 void addBuff(int id);
private:
	 int m_nFloor;		//当前楼层
};

/////////////////////////////////////////////////////////////////////////公会个人任务模型
struct PersonalTaskInfo
{
	 int id;		// 任务ID
	 int stage;		// 任务当前执行到的关卡
	 int status;	// 任务状态
	 int enemyLv;   // 敌人等级
};

class CPersonalTaskModel
{
public:
	 CPersonalTaskModel();
	 int getResetTime(){ return m_nResetTime; }
	 void setResetTime(int time) { m_nResetTime = time; }
	 bool addTask(PersonalTaskInfo info);
	 std::map<int, PersonalTaskInfo> getTasks(){ return m_mapTaskInfo; }
	 bool setTask(PersonalTaskInfo info);
	 void clearPersonaTasks(){ m_mapTaskInfo.clear(); m_nResetTime = 0; }
private:
	 // 重置时间
	 int m_nResetTime;
	 // 个人任务
	 std::map<int, PersonalTaskInfo> m_mapTaskInfo;
};

/////////////////////////////////////////////////////////////////////////公会团队任务模型
struct TeamTaskInfo 
{
	 int curTaskID;			// 当前任务ID
	 int endTime;           // 结束时间戳
	 int stage;             // 第几个关卡
	 int bossHp;            // 剩余血量
	 int rewardBox;			// 奖励节点领取情况 
	 int challengeCDTime;	// 挑战冷却时间
	 int challengeTimes;	// 挑战次数
	 int nextTargetTime;    // 下个任务目标刷出时间
};

struct TeamHurtInfo
{
	 int userID;                 // 玩家ID
	 char userName[16];          // 玩家名称
	 int job;					 // 职位
	 int headID;                 // 头像
	 int hurt;                   // 伤害值
};

struct NextTeamTaskInfo
{
	 int taskID;                 // 任务ID
	 int status;                 // 状态 1为被设置下次任务目标
};

class CTeamTaskModel
{
public:
	 CTeamTaskModel();
	 TeamTaskInfo getTeamTask(){ return m_teamTaskInfo; }
	 void setTeamTask(TeamTaskInfo info){ m_teamTaskInfo = info; }
	 std::vector<int> getNextTeamTasks(){ return m_vecNextTask; }
	 void setNextTeamTask(std::vector<int> nextTask){ m_vecNextTask = nextTask; }
	 void setNextTeamTaskID(int taskID){ m_nNextTaskID = taskID; }
	 int getNextTeamTaskID(){ return m_nNextTaskID; }
	 std::map<int, TeamHurtInfo> getHurtsInfo() { return m_mapHurtsInfo; }
	 bool setHurtInfo(TeamHurtInfo info);
	 bool addHurtInfo(TeamHurtInfo info);
	 void clearTask();
private:
	 // 下次目标任务ID
	 int m_nNextTaskID;
	 // 当前任务信息
	 TeamTaskInfo m_teamTaskInfo;
	 // 下次任务ID
	 std::vector<int> m_vecNextTask;
	 // BOSS伤害信息
	 std::map<int, TeamHurtInfo>	m_mapHurtsInfo;
};

/////////////////////////////////////////////////////////////////////////PVP模型
enum MatchType
{
    MATCH_FAIRPVP,			//公平竞技
    MATCH_CPN,				//锦标赛
};

enum EPvpRoomType
{
    PVPROOMTYPE_NONE,
    PVPROOMTYPE_PVP,				//pvp房间		
    PVPROOMTYPE_ROBOT,				//机器人房间
    PVPROOMTYPE_CHAMPIONSHIP,		//锦标赛房间
};

struct PvpInfo // pvp信息
{
	int BattleId;		   // battleId
    int ResetStamp;        // 刷新时间戳
    int DayBattleCount;    // 日挑战次数
    int DayContinusWin;    // 日连胜次数
    int DayWin;            // 日胜利次数
    int HistoryRank;       // 历史最高排名
    int HistoryScore;      // 历史最高积分
    int RewardFlag;        // 竞技任务领取状态
    int Rank;              // 当前排位
    int Score;             // 当前积分
    int ContinusWinTimes;  // 连续胜场
    int DayMaxContinusWinTimes; // 日最高胜场
    int HistoryContinusWinTimes; // 历史最高连胜

    int CpnRank;					 //锦标赛排名
    int CpnWeekResetStamp;           //锦标赛周重置时间
    int CpnGradingNum;               //锦标赛定级赛场数
    int CpnGradingDval;              //锦标赛定级赛分差
    int CpnIntegral;                 //锦标赛竞技积分
    int CpnContinusWinTimes;         //锦标赛段位连续胜场
    int CpnHistoryHigestRank;        //锦标赛历史最高排名
    int CpnHistoryHigestIntegral;    //锦标赛历史最高积分
    int CpnHistoryContinusWinTimes;  //锦标赛历史最高连胜场数

    int LastChestTime;               //最后一个宝箱时间
    int ChestStatus;                 //宝箱状态 1可领取
    int DayBuyChestTimes;            //日购买次数
    int ChestInsurance;              //保底次数

    PvpInfo operator=(const LoginPvpModelInfo &info)
    {
        BattleId = info.battleId;
        ResetStamp = info.dayResetStamp;
        Score = info.integral;
        Rank = info.rank;
        ContinusWinTimes = info.continusWinTimes;
        DayWin = info.dayWinTimes;
        DayContinusWin = info.dayContinusWinTimes;
        DayMaxContinusWinTimes = info.dayMaxContinusWinTimes;
        DayBattleCount = info.dayBattleTimes;
        HistoryRank = info.historyHighestRank;
        HistoryScore = info.historyHighestIntegral;
        RewardFlag = info.rewardFlag;
        HistoryContinusWinTimes = info.historyContinusWinTimes;

//         CpnRank = info.cpnRank;
//         CpnWeekResetStamp = info.cpnWeekResetStamp;
//         CpnGradingNum = info.cpnGradingNum;
//         CpnGradingDval = info.cpnGradingDval;
//         CpnIntegral = info.cpnIntegral;
//         CpnContinusWinTimes = info.cpnContinusWinTimes;
//         CpnHistoryHigestRank = info.cpnHistoryHigestRank;
//         CpnHistoryHigestIntegral = info.cpnHistoryHigestIntegral;
//         CpnHistoryContinusWinTimes = info.cpnHistoryContinusWinTimes;

        LastChestTime = info.lastChestGenStamp;
        ChestStatus = info.chestStatus;
        DayBuyChestTimes = info.dayBuyChestTimes;
        ChestInsurance = info.chestInsurance;

        return *this;
    }
};

class CPvpModel
{
public:
    CPvpModel();
    ~CPvpModel();

public:
    // 初始化
    bool init(void* data);
    // 重置状态
    void resetPvp();
    // 获取Pvp信息
    PvpInfo& getPvpInfo() { return m_PvpInfo; }
	// 是否重连
	bool isReconnect();
	// 设置是否重连
	void setReconnect(bool isReconn);
	// 设置battleid
	void setBattleId(int battleId);
    // 设置排名
    void setRank(int type, int rank);
	// 获得pvp排名
	int getRank() { return m_PvpInfo.Rank; }
    // 设置积分
    void setScore(int type, int score);
    // 获取积分
    int getScore(int type);
    // 设置历史最高排名
    void setHistoryRank(int type, int rank);
	// 获得历史最高排名
    int getHistoryRank(int type);
    // 设置历史最高积分
    void setHistoryScore(int type, int score);
	// 获得历史最高积分
    int getHistoryScore(int type);
    // 获取任务奖励状态
    int getPvpTaskStatus(int type);
    // 设置任务奖励状态1
    void setPvpTaskStatus(int type);
	// 根据胜利失败计算日胜场等任务
	void setDayTask(int result);
	// 重置 0=日战斗场次 1=日累计胜场次 2=日连胜场次
	void resetPvpTaskWithType(int taskType);
    // 设置pvp连续胜场
    void setContinueWinTimes(bool win);
    // 获取pvp历史最高连胜
    int getHistoryContinueWinTimes() { return m_PvpInfo.HistoryContinusWinTimes; }
    // 锦标赛赛季重置
    void resetChampionArena();
    // 设置房间类型
    void setRoomType(int type){ m_nRoomType = type; };
    // 获取房间类型
    int getRoomType(){ return m_nRoomType; };
    // 定级赛次数+1
    void addGradingNum(){ m_PvpInfo.CpnGradingNum += 1; }
    // 设置最后宝箱时间
    void setLastChestTime(int time){ m_PvpInfo.LastChestTime = time; }
    // 设置宝箱状态
    void setChestStatus(int status){ m_PvpInfo.ChestStatus = status; }
    // 设置日购买宝箱次数
    void setDayBuyChestTimes(int times){ m_PvpInfo.DayBuyChestTimes = times; }
    // 获取最后宝箱时间
    int getLastChestTime(){ return m_PvpInfo.LastChestTime; }

private:

	bool m_bIsReconnect;
    int m_nRoomType;
    PvpInfo m_PvpInfo;
};


/////////////////////////////////////////////////////////////////////////商店模型
// 商品结构
#pragma pack(1)
struct ShopGoodsData
{
    int nIndex;					// 商品索引
    int nGoodsShopID;			// 商品ID
    int nGoodsID;				// 道具ID
    int nGoodsNum;				// 道具个数
    int nCoinType;				// 货币类型
    int nCoinNum;				// 价格
    int nSale;					// 折扣值
};
#pragma pack()

//商店结构
struct ShopData
{
    int	nShopType;				//商店类型
    int nCount;					//商店总物品数
    int nCurCount;				//当前物品数
    int nFreshedCount;		    //已经刷新的次数
    int nNextFreshTime;			//下次刷新时间戳
    std::vector<ShopGoodsData> m_vecGoodsData;  //商品结构列表
};

// 商店模型
class CShopModel
{
public:
    CShopModel();
    ~CShopModel();

public:
    /**
     * @brief  初始化
     * @param  data    商店数据
     */
    bool init(void* data);

    /**
     * @brief  获取商店个数
     * @return 商店个数
     */
    inline int getShopCount(){ return m_nShopCount; }

    /**
     * @brief  获取商店模型数据
     * @param  shopType    商店类型
     * @return 返回商店模型数据
     */
    ShopData* getShopModelData(int shopType);

    /**
     * @brief  设置商店模型数据
     * @param  shopType    商店类型
     */
    void setShopModelData(const ShopData& data);

    /**
     * @brief   判断是否为首次充值
     * @param   pID     商品索引
     */
    bool isFirstCharge(int pID);

    /**
    * @brief   设置首次充值状态
    * @param   pID     商品索引
    */
    void setFirstChargeState(int pID);

private:
    int m_nShopCount;                       // 商店个数
    std::map<int, ShopData> m_mapShopInfo;  // 商店列表
    std::map<int, int>      m_mapDiamondShopData;
};


/////////////////////////////////////////////////////////////////////////运营活动模型
// 商店活动
struct SOperateActiveShop
{
    int nShopNum;				//礼包个数
    std::vector<SLoginActiveShopData> m_vecActiveShopData;
};

// 任务活动
struct SOperateActiveTask
{
    int nActiveTaskNum;				//活动任务数
    std::vector<SLoginActiveTaskData> m_vecActiveTaskData;
};

//运营活动模型
class COperateActiveModel
{
public:
    COperateActiveModel();
    ~COperateActiveModel();

    enum ActiveType
    {
        TYPE_NONE,
        TYPE_SHOP,
        TYPE_DROP,
        TYPE_TASK,
    };

    /**
     * @brief  初始化
     * @param  data    运营活动数据
     */
    bool init(void* data);

    /**
    * @brief  获取活动个数
    * @return 活动个数
    */
    inline int getActiveCount(){ return m_nActiveCount; }

    inline void delActiveCount(){ --m_nActiveCount; }

    /**
     * @brief   获取活动基础信息
     */
    std::map<int, SLoginActiveData> getActiveData(){ return m_mapActiveData; }

    /**
     * @brief   获取商店活动数据
     * @param   activeID    活动ID
     * @return  商店活动数据
     */
    SOperateActiveShop* getActiveShopData(int activeID);

    /**
     * @brief    设置已经购买次数
     * @param    activeID   活动ID
     * @param    giftID     礼包ID
     * @param    buyTimes   已经购买次数
     */
    void setActiveShopBuyTimes(int activeID, int giftID, int buyTimes);

    /**
     * @brief   获取任务活动数据
     * @param   activeID    活动ID
     * @return  任务活动数据
     */
    SOperateActiveTask* getActiveTaskData(int activeID);

    /**
    * @brief    设置任务完成进度
    * @param    activeID   活动ID
    * @param    taskID     任务ID
    * @param    value      任务完成进度
    */
    void setActiveTaskProgress(int activeID, int taskID, int value);

    /**
    * @brief    设置任务状态
    * @param    activeID   活动ID
    * @param    taskID     任务ID
    * @param    value      任务完成进度
    */
    void setActiveTaskFinishFlag(int activeID, int taskID, int flag);

    /*
     * @brief   移除已经结束的活动
     */
    void removeActiveData(int activeID, int activeType);

private:
    int m_nActiveCount;
    std::map<int, SLoginActiveData> m_mapActiveData;   // 运营活动基础信息, 以活动id为索引
    std::map<int, SOperateActiveShop> m_mapActiveShop;   // 商店活动数据
    std::map<int, SOperateActiveTask> m_mapActiveTask;   // 商店活动数据
};

// 头像数据
class CHeadModel
{
public:
    CHeadModel();
    ~CHeadModel();

    /**
    * @brief  初始化
    * @param  data   已解锁头像列表
    */
    bool init(void* data);

    /*
     * @brief   获取已解锁头像 
     * @return  已解锁头像列表
     */
    //std::vector<int> getHeadList(){ return m_vecHeadID; }
    std::vector<int> getUnlockedHeads(){ return m_vecUnlockedHead; }

    /*
     * @brief   判断头像是否已解锁
     * @param   头像ID
     * @return  是否已解锁
     */
    bool isUnlocked(int headID);

    /*
     * @brief   添加头像
     * @param   头像ID
     * @return  成功返回true, 否则返回false
     */
    bool addHead(int headID);

private:
    int m_nNum;
    std::vector<int> m_vecUnlockedHead;
};

#endif