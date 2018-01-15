package com.tencent.tmgp.summoner;

import android.content.Context;

import com.tencent.qqgame.sdk.constants.Protocol;
import com.tencent.qqgame.sdk.model.LoginTicketRequest;
import com.tencent.qqgame.sdk.openapi.IQghAPI;
import com.tencent.qqgame.sdk.openapi.QghAPIFactory;

/**
 * Created by Administrator on 2017/1/6.
 */

public class QghManager {
    private static Context mContext;

    public final static String APP_ID = "1105897582";
    public final static String OFFER_ID = "";

    public static String mGameOpenid   = "";
    public static String mGameOpenkey   = "";
    public static String mGamepf   = "";
    public static String mGamepfkey   = "";

    public static void setContext(Context context) {
        mContext = context;
    }

    public static void sendLoginRequest() {
        IQghAPI qghAPI = QghAPIFactory.createQghAPI(mContext, APP_ID);
        LoginTicketRequest request = new LoginTicketRequest();
        request.ticketType = Protocol.TicketType.OPEN_ID;
        request.gameType = Protocol.GameType.COCOS;
        request.appId = APP_ID;
        request.loginType = Protocol.LoginType.QQ;
        boolean isSuccess = qghAPI.sendRequest(request);
        if (!isSuccess) {
            System.out.println("QghManager sendLoginRequest not success");
        }
    }
}
