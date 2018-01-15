#include "TimeCalcTool.h"
#include <string.h>

bool CTimeCalcTool::isDayTimeOver(time_t prev, DayTime &daytime)
{
	time_t now = time(NULL);
	tm *pPrevTm = localtime(&prev);
	tm *pNowTm = localtime(&now);
	int daySecond = 24 * 60 * 60;
	
	if (now - prev >= daySecond)
	{
		//如果大于1天, 返回true
		return true;
	}
	else
	{
		if (pPrevTm->tm_mday != pNowTm->tm_mday)
		{
			//不同一天的, now跨过指定时间即可
			bool ret1 = pNowTm->tm_hour > daytime.hour;
			bool ret2 = pNowTm->tm_hour == daytime.hour && pNowTm->tm_min > daytime.minutes;
			bool ret3 = pNowTm->tm_hour == daytime.hour && pNowTm->tm_min == daytime.minutes && pNowTm->tm_sec >= daytime.second;

			return ret1 || ret2 || ret3;
		}
		else
		{
			//同一天的, prev在指定时间之前
			bool ret1 = pPrevTm->tm_hour < daytime.hour;
			bool ret2 = pPrevTm->tm_hour == daytime.hour && pPrevTm->tm_min < daytime.minutes;
			bool ret3 = pPrevTm->tm_hour == daytime.hour && pPrevTm->tm_min == daytime.minutes && pPrevTm->tm_sec < daytime.second;
			//now在指定时间之后
			bool ret4 = pNowTm->tm_hour > daytime.hour;
			bool ret5 = pNowTm->tm_hour == daytime.hour && pNowTm->tm_min > daytime.minutes;
			bool ret6 = pNowTm->tm_hour == daytime.hour && pNowTm->tm_min == daytime.minutes && pNowTm->tm_sec >= daytime.second;

			return (ret1 || ret2 || ret3) && (ret4 || ret5 || ret6);
		}
	}
	return false;
}

bool CTimeCalcTool::isWeekTimeOver(time_t prev, WeekTime &weekTime)
{
	time_t now = time(NULL);
	tm *pPrevTm = localtime(&prev);
	tm *pNowTm = localtime(&now);
	int weekSecond = 7 * 24 * 60 * 60;

	if (now - prev >= weekSecond)
	{
		//超过一个星期天
		return true;
	}
	else
	{ 
		//prev在指定星期天之前
		bool ret1 = pPrevTm->tm_wday < weekTime.weekDay;
		bool ret2 = pPrevTm->tm_wday == weekTime.weekDay
			&& pPrevTm->tm_hour < weekTime.dayTime.hour;
		bool ret3 = pPrevTm->tm_wday == weekTime.weekDay && pPrevTm->tm_hour == weekTime.dayTime.hour
			&& pPrevTm->tm_min < weekTime.dayTime.minutes;
		bool ret4 = pPrevTm->tm_wday == weekTime.weekDay && pPrevTm->tm_hour == weekTime.dayTime.hour
			&& pPrevTm->tm_min == weekTime.dayTime.minutes && pPrevTm->tm_sec < weekTime.dayTime.second;
		//now在指定星期天之后
		bool ret5 = pNowTm->tm_wday > weekTime.weekDay;
		bool ret6 = pNowTm->tm_wday == weekTime.weekDay
			&& pNowTm->tm_hour > weekTime.dayTime.hour;
		bool ret7 = pNowTm->tm_wday == weekTime.weekDay && pNowTm->tm_hour == weekTime.dayTime.hour
			&& pNowTm->tm_min > weekTime.dayTime.minutes;
		bool ret8 = pNowTm->tm_wday == weekTime.weekDay && pNowTm->tm_hour == weekTime.dayTime.hour
			&& pNowTm->tm_min == weekTime.dayTime.minutes && pNowTm->tm_sec >= weekTime.dayTime.second;

		return (ret1 || ret2 || ret3 || ret4) && (ret5 || ret6 || ret7 || ret8);
	}
	return false;
}

bool CTimeCalcTool::isMonthTimeOver(time_t prev, MonthTime &month)
{
	time_t now = time(NULL);
	return true;
}

bool CTimeCalcTool::isSecondOver(time_t prev, int second)
{
	time_t now = time(NULL);
	return now - prev >= second;
}

bool CTimeCalcTool::isDayTime(DayTime &beginTime, DayTime &endTime)
{
	time_t now = time(NULL);
	tm *pNowTm = localtime(&now);

	bool ret1 = pNowTm->tm_hour > beginTime.hour;
	bool ret2 = pNowTm->tm_hour == beginTime.hour && pNowTm->tm_min > beginTime.minutes;
	bool ret3 = pNowTm->tm_hour == beginTime.hour && pNowTm->tm_min == beginTime.minutes && pNowTm->tm_sec >= beginTime.second;

	bool ret4 = pNowTm->tm_hour < endTime.hour;
	bool ret5 = pNowTm->tm_hour == endTime.hour && pNowTm->tm_min < endTime.minutes;
	bool ret6 = pNowTm->tm_hour == endTime.hour && pNowTm->tm_min == endTime.minutes && pNowTm->tm_sec <= endTime.second;

	return (ret1 || ret2 || ret3) && (ret4 || ret5 || ret6);
}

bool CTimeCalcTool::isYearTime(YearTime &beginYearTime, YearTime &endYearTime)
{
	tm beginTm;
	tm endTm;
	memset(&beginTm, 0, sizeof(beginTm));
	memset(&endTm, 0, sizeof(endTm));

	time_t now = time(NULL);
	time_t beginTime;
	time_t endTime;

	beginTm.tm_year = beginYearTime.year;
	beginTm.tm_mon = beginYearTime.month;
	beginTm.tm_mday = beginYearTime.day;
	beginTm.tm_hour = beginYearTime.hour;
	beginTm.tm_min = beginYearTime.minute;
	beginTm.tm_sec = beginYearTime.second;
	
	endTm.tm_year = endYearTime.year;
	endTm.tm_mon = endYearTime.month;
	endTm.tm_mday = endYearTime.day;
	endTm.tm_hour = endYearTime.hour;
	endTm.tm_min = endYearTime.minute;
	endTm.tm_sec = endYearTime.second;

	beginTime = mktime(&beginTm);
	endTime = mktime(&beginTm);

	return beginTime <= now && endTime >= now;
}

int CTimeCalcTool::overDay(time_t prev, DayTime &dayTime)
{
	time_t now = time(NULL);
	tm *pPrevTm = localtime(&prev);
	tm *pNowTm = localtime(&now);
	int times = 0;
	int d = now - prev;
	int ds = 24 * 60 * 60;
	// 先算到指定时间需要的秒数
	int seconds = 0;
	if (pPrevTm->tm_hour <= dayTime.hour)
	{
		seconds = (dayTime.hour - pPrevTm->tm_hour) * 60 * 60;
	}
	else
	{
		seconds = ((24 - pPrevTm->tm_hour) + dayTime.hour) * 60 * 60;
	}

	seconds = (seconds + dayTime.minutes * 60 + dayTime.second) - (pPrevTm->tm_min * 60 + pPrevTm->tm_sec);
	if (d >= seconds)
	{
		times += 1;
		// 剩下的满1天+1
		d -= seconds;
		times += static_cast<int>(d / ds);
		return times;
	}
	return 0;
}

int CTimeCalcTool::overWeek(time_t prev, WeekTime &weekTime)
{
	time_t now = time(NULL);
	tm *pPrevTm = localtime(&prev);
	tm *pNowTm = localtime(&now);
	int times = 0;
	int d = now - prev;
	int ds = 24 * 60 * 60;
	int ws = 7 * ds;

	int seconds = 0;
	if (pPrevTm->tm_wday <= weekTime.weekDay)
	{
		seconds = (weekTime.weekDay - pPrevTm->tm_wday) * ds;
	}
	else
	{
		seconds = ((7 - pPrevTm->tm_wday) + weekTime.weekDay) * ds;
	}

	seconds = (seconds + weekTime.dayTime.hour * 60 * 60 + weekTime.dayTime.minutes * 60 + weekTime.dayTime.second)
		- (pPrevTm->tm_hour * 60 * 60 + pPrevTm->tm_min * 60 + pPrevTm->tm_sec);

	if (d >= seconds)
	{
		times += 1;
		d -= seconds;
		times += static_cast<int>(d / ws);
		return times;
	}
	return 0;
}

int CTimeCalcTool::overSecond(time_t prev, int second)
{
	time_t now = time(NULL);
	int d = now - prev;
	return static_cast<int>(d/second);
}

int CTimeCalcTool::getWeekByTime(time_t now)
{
    tm* date = localtime(&now);
    return date->tm_wday + 1;
}

int CTimeCalcTool::getTimesBySecond(time_t lastTime, time_t now, int interval)
{
    return (now - lastTime) / interval;
}

int CTimeCalcTool::getTimesByDay(time_t lastTime, time_t now)
{
    return (now - lastTime) / DAYSECONDS;
}

int CTimeCalcTool::getTimesByWeek(time_t lastTime, time_t now)
{
    return (now - lastTime) / WEEKSECONDS;
}

int CTimeCalcTool::getSecondToNextSecond(time_t lastTime, int target)
{
    return target - lastTime;
}

int CTimeCalcTool::getSecondToNextDay(time_t now, int hour, int min, int second)
{
    tm* date = localtime(&now);
    int hourOffset = hour - date->tm_hour;
    int minOffset = min - date->tm_min;
    int secondOffset = second - date->tm_sec;

    // 当前到指定时刻的偏移时间（有可能为负数）
    int secondToTime = hourOffset * HOURSECONDS + minOffset * MINSECONDS + second;
    // 如果今天未到指定的时刻，返回今日剩余秒数
    if (secondToTime > 0)
    {
        return secondToTime;
    }
    else
    {
        // 否则返回到明日指定时刻的剩余秒数
        return DAYSECONDS + secondToTime;
    }
}

int CTimeCalcTool::getSecondToNextWeek(time_t now, int day, int hour, int min, int second)
{
    tm* date = localtime(&now);
    int dayOffset = day - (date->tm_wday + 1);
    int hourOffset = hour - date->tm_hour;
    int minOffset = min - date->tm_min;
    int secondOffset = second - date->tm_sec;
    // 当前到指定时刻的偏移时间（有可能为负数）
    int secondToTime = dayOffset * DAYSECONDS + hourOffset * HOURSECONDS + minOffset * MINSECONDS + second;
    // 如果未到本周指定的时刻，返回本周剩余秒数
    if (secondToTime > 0)
    {
        return secondToTime;
    }
    else
    {
        // 否则返回到下周指定时刻的剩余秒数
        return WEEKSECONDS + secondToTime;
    }
}

int CTimeCalcTool::getNextTimeStamp(time_t prev, int nextMin, int nextHour)
{
    tm *pPrevTm = localtime(&prev);
    int n = (nextHour - pPrevTm->tm_hour) * HOURSECONDS + (nextMin - pPrevTm->tm_min) * MINSECONDS - pPrevTm->tm_sec;
    if (n <= 0)
    {
        n += DAYSECONDS + int(prev);
    }
    else
    {
        n += int(prev);
    }

    return n;
}

int CTimeCalcTool::getWNextTimeStamp(time_t prev, int nextMin, int nextHour, int wDay)
{
    wDay %= WEEKDAY; // 注：周7为0
    tm *pPrevTm = localtime(&prev);

    int w = wDay - pPrevTm->tm_wday;
    if (w < 0)
    {
        w += WEEKDAY;
    }

    int n = (nextHour - pPrevTm->tm_hour) * HOURSECONDS + (nextMin - pPrevTm->tm_min) * MINSECONDS - pPrevTm->tm_sec;
    return w * DAYSECONDS + n + (int)prev;
}