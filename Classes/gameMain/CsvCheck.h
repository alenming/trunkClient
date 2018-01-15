//*************************************************
// Copyright (c) 2016,…Ó€⁄. All rights reserved.
// File name: CsvCheck.h
// Author: Mr. Alen
// Version: 1.0 
// Date: 2016/12/01
// Description: 
// Others:
// History:
//*************************************************

#ifdef WIN32

#ifndef __CSVCHECK_H__
#define __CSVCHECK_H__
#include <vector>
#include <map>
#include <set>
#include "ConfManager.h"

#define  CheckCsvTest

class CConfStatusPath : public CConfBase
{
public:
	virtual bool LoadCSV(const std::string& str);
	std::map<int, std::vector<int> >& geMapData()
	{
		return m_mapAnimation;
	}
private:
	std::map<int, std::vector<int> > m_mapAnimation;
};

class CsvCheck
{
public:
	CsvCheck();
	~CsvCheck();

	static CsvCheck* getInstance();
	static void destory();

	bool checkCsv();

	bool checkCsvHead();

	bool checkAnimationCsv();
	bool checkBuffCsv();
	bool checkBulletCsv();
	bool checkCountCsv();
	bool checkSearchCsv();
	bool checkSkillCsv();
	bool checkAIAndStatusCsv();
	bool checkBossCsv();
	bool checkCallCsv();
	bool checkMonsterCsv();
	bool checkHeroCsv();
	bool checkSoldierCsv();
	bool checkStageCsv();
	void printResult();
	bool checkResPreload();
	bool checkResCsv();
	void comput();
	bool checkStatusPath();
private:
	static CsvCheck *m_pInstance;
	std::map<std::string, std::map<std::string, int>> m_checkResult;
	CConfStatusPath* m_status;
	//std::map<std::string, std::map<int, int>> m_rongYu;
	std::map<std::string, std::set<int> > m_XXXX;
	std::map<std::string, std::vector<int>> endResult;
};


#endif    //__CSVCHECK_H__
#endif //WIN32