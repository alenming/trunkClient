package com.tencent.tmgp.summoner;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;

/**
 * Created by Administrator on 2016/11/17.
 * 我也不清楚那种方法可行, 暂时都写上去
 */

public class JumpMark {
    public static boolean goToMarket(Context context, String markPackName, String packageName) {
        Intent goToMarket = new Intent(Intent.ACTION_VIEW);
        Uri uri = Uri.parse("market://details?id=" + packageName);//app包名
        goToMarket.setData(uri);
        goToMarket.setPackage(markPackName);//应用市场包名
        try{
            context.startActivity(goToMarket);
            return true;
        }catch (ActivityNotFoundException e) {
            return false;
        }
    }

    public static boolean goToMarketWithActivity(Context context, String markPackName, String markActivity, String packageName) {
        Uri uri = Uri.parse("market://details?id=" + packageName);
        Intent goToMarket = new Intent(Intent.ACTION_VIEW, uri);
        try {
            goToMarket.setClassName(markPackName, markActivity);
            context.startActivity(goToMarket);
            return  true;
        } catch (ActivityNotFoundException e) {
            e.printStackTrace();
            return  false;
        }
    }

    public static boolean goToSamsungappsMarket(Context context, String packageName) {
        Uri uri = Uri.parse("http://www.samsungapps.com/appquery/appDetail.as?appId=" + packageName);
        Intent goToMarket = new Intent();
        goToMarket.setClassName("com.sec.android.app.samsungapps", "com.sec.android.app.samsungapps.Main");
        goToMarket.setData(uri);
        try {
            context.startActivity(goToMarket);
            return  true;
        } catch (ActivityNotFoundException e) {
            e.printStackTrace();
            return  false;
        }
    }

    public static boolean goToLeTVStoreDetail(Context context, String packageName) {
        Intent intent = new Intent();
        intent.setClassName("com.letv.app.appstore", "com.letv.app.appstore.appmodule.details.DetailsActivity");
        intent.setAction("com.letv.app.appstore.appdetailactivity");
        intent.putExtra("packageName", packageName);
        try{
            context.startActivity(intent);
            return  true;
        }catch (ActivityNotFoundException e){
            e.printStackTrace();
            return  false;
        }
    }

    
    public static boolean isWifiConnected(Context context) {    
        if (context != null) {    
            ConnectivityManager mConnectivityManager = (ConnectivityManager) context
                    .getSystemService(Context.CONNECTIVITY_SERVICE);    
            NetworkInfo mWiFiNetworkInfo = mConnectivityManager
                    .getNetworkInfo(ConnectivityManager.TYPE_WIFI);    
            if (mWiFiNetworkInfo != null) {    
                return mWiFiNetworkInfo.isAvailable();    
            }    
        }    
        return false;    
    }  
}