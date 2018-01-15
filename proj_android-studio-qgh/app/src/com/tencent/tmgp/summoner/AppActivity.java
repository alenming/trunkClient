/****************************************************************************
Copyright (c) 2015 Chukong Technologies Inc.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package com.tencent.tmgp.summoner;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.GregorianCalendar;

public class AppActivity extends Cocos2dxActivity {
    private static final long SEC_OF_DAY = 24*60*60;
	static
    {
		//用于程序开始运行时导入fmod.jar
		System.loadLibrary("fmod"); 
        System.loadLibrary("fmodstudio"); 
    }

    private static AppActivity sAppActivity;

    public static void openURL(String url) {
        Intent i = new Intent(Intent.ACTION_VIEW);
        i.setData(Uri.parse(url));
        sAppActivity.startActivity(i);
    }

    public static void runOnGLThread(final int luaFunc) {
        sAppActivity.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Cocos2dxLuaJavaBridge.callLuaFunctionWithString(luaFunc, "");
                Cocos2dxLuaJavaBridge.releaseLuaFunction(luaFunc);
            }
        });
    }

    public static void startPushService(int id, String triggerTime, String content, int isRepeating, int repeatInterval) {
        try {
            long trigTimeLongFormat = Long.parseLong(triggerTime);

            System.out.println("AppActivity.startPushService: " + System.currentTimeMillis() / 1000);
            System.out.println("AppActivity.startPushService: " + id + ", " + triggerTime + ", " + content);
            SimpleDateFormat format =  new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            System.out.println("AppActivity.startPushService: start time " + format.format(new Date(trigTimeLongFormat * 1000)));

            AlarmManager manager = (AlarmManager) sAppActivity.getSystemService(ALARM_SERVICE);
            Intent intent = PushService.newIntent(sAppActivity, id, content);
            PendingIntent pendingIntent = PendingIntent.getService(sAppActivity, id, intent, PendingIntent.FLAG_UPDATE_CURRENT);

            if (isRepeating == 0) {
                if (Build.VERSION.SDK_INT >= 19)
                    manager.setWindow(AlarmManager.RTC, trigTimeLongFormat * 1000, 60 * 1000, pendingIntent);
                else
                    manager.set(AlarmManager.RTC, trigTimeLongFormat * 1000, pendingIntent);
            } else {
                manager.setRepeating(AlarmManager.RTC, trigTimeLongFormat * 1000, repeatInterval * SEC_OF_DAY * 1000, pendingIntent);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void stopPushService(int id) {
        try {
            System.out.println("AppActivity.stopPushService: " + id);

            AlarmManager manager = (AlarmManager) sAppActivity.getSystemService(ALARM_SERVICE);
            Intent intent = PushService.newIntent(sAppActivity, id, "");
            PendingIntent pendingIntent = PendingIntent.getService(sAppActivity, id, intent, PendingIntent.FLAG_UPDATE_CURRENT);
            manager.cancel(pendingIntent);
            pendingIntent.cancel();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static boolean goToMarket(String markPackName){
        return JumpMark.goToMarket(sAppActivity, markPackName, "com.tencent.tmgp.summoner");
    }
    public static boolean goToMarketWithActivity(String markPackName, String markActivity){
        return JumpMark.goToMarketWithActivity(sAppActivity, markPackName, markActivity, "com.tencent.tmgp.summoner");
    }
    public static boolean goToSamsungappsMarket(){
        return JumpMark.goToSamsungappsMarket(sAppActivity, "com.tencent.tmgp.summoner");
    }
    public static boolean goToLeTVStoreDetail(){
        return JumpMark.goToLeTVStoreDetail(sAppActivity, "com.tencent.tmgp.summoner");
    }

    public static boolean isWifiConnected(){
        return JumpMark.isWifiConnected(sAppActivity);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            sAppActivity = this;

            //用于启动fmod功能
            org.fmod.FMOD.init(this);

            //startPushService(1, System.currentTimeMillis() / 1000 + 10, "test 1");
            //startPushService(2, System.currentTimeMillis() / 1000 + 15, "test 2");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onRestart() {
        super.onRestart();
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onStop() {
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            //用于关闭fmod功能
            org.fmod.FMOD.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
    }
}
