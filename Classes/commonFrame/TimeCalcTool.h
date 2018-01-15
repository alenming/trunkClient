#ifndef __TIMECALCTOOL_H__
#define __TIMECALCTOOL_H__

#include <time.h>

struct DayTime
{
	int hour;
	int minutes;
	int second;
};

struct MonthTime
{
	int month;
	int day;
	DayTime dayTime;
};

struct WeekTime
{
	int weekDay;
	DayTime dayTime;
};

struct YearTime
{
	int year;
	int month;
	int day;
	int hour;
	int minute;
	int second;
};

#define MINSECONDS 60
#define HOURSECONDS 3600
// 一天的秒数
#define DAYSECONDS  86400
#define WEEKSECONDS  604800

#define WEEKDAY 7

class CTimeCalcTool
{
public:
	//查询时间戳与现在时间是否跨过指定日时间
	static bool isDayTimeOver(time_t prev, DayTime &dayTime);
	//查询时间戳与现在时间是否跨过指定星期时间
	static bool isWeekTimeOver(time_t prev, WeekTime &weekTime);
	//查询时间戳与现在时间是否跨过指定月时间
	static bool isMonthTimeOver(time_t prev, MonthTime &month);
	//查询时间戳与现在时间是否大于second秒
	static bool isSecondOver(time_t prev, int second);
	//查询现在是否为指定的时间内
	static bool isDayTime(DayTime &beginTime, DayTime &endTime);
	//查询现在是否在指定日期内
	static bool isYearTime(YearTime &beginYearTime, YearTime &endYearTime);
	//查询是否到点, 并返回几次
	static int overDay(time_t prev, DayTime &dayTime);
	//查询是否到指定星期日期, 并返回几次
	static int overWeek(time_t prev, WeekTime &weekTime);
	//查询是否到指定秒数, 并返回几次
	static int overSecond(time_t prev, int second);

    // 根据指定时间获取当前是周几 返回值为1 - 7
    static int getWeekByTime(time_t now);

    // 根据上次恢复的时间戳、当前时间、时间间隔，计算中间经过了多少次间隔
    static int getTimesBySecond(time_t lastTime, time_t now, int interval);
    // 根据上次恢复的时间戳、当前时间、计算中间经过了多少天
    static int getTimesByDay(time_t lastTime, time_t now);
    // 根据上次恢复的时间戳、当前时间、计算中间经过了多少周
    static int getTimesByWeek(time_t lastTime, time_t now);

    // 根据当前时间和目标时间，计算剩余时间
    // 计算到指定时间点的剩余时间
    static int getSecondToNextSecond(time_t now, int target);
    // 计算到下一天指定时间的剩余时间
    static int getSecondToNextDay(time_t now, int hour, int min, int second);
    // 计算到下一周指定时间的剩余时间，day表示周几，值为 1 - 7
    static int getSecondToNextWeek(time_t now, int day, int hour, int min, int second);
    //返回某个时间戳到下个几时几分的时间戳
    static int getNextTimeStamp(time_t prev, int nextMin, int nextHour);
    //返回某个时间戳到周几几时几分的时间戳 wDay周1~7
    static int getWNextTimeStamp(time_t prev, int nextMin, int nextHour, int wDay);
};

#endif //__TIMECALCTOOL_H__
