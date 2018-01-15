package org.cocos2dx.summoner;


import android.os.Build;

/**
 * Created by Administrator on 2016/9/9.
 */
public class Help {
    public static String getFingerPrint() {
        return Build.FINGERPRINT;
    }

    public static String getModel() {
        return Build.MODEL;
    }
}
