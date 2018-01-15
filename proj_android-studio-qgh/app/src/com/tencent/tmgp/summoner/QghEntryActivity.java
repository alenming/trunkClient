package com.tencent.tmgp.summoner;

import android.app.Activity;
import android.os.Bundle;
import android.os.SystemClock;
import android.widget.TextView;

import com.tencent.qqgame.sdk.model.BaseResponse;
import com.tencent.qqgame.sdk.model.LoginTicketResponse;
import com.tencent.qqgame.sdk.model.PayResponse;
import com.tencent.qqgame.sdk.openapi.IQghAPI;
import com.tencent.qqgame.sdk.openapi.IQghAPIEventHandler;
import com.tencent.qqgame.sdk.openapi.QghAPIFactory;
import com.tencent.tmgp.summoner.AppActivity;

import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;
import org.json.JSONException;
import org.json.JSONObject;


/**
 * Created by Administrator on 2017/1/5.
 */

public class QghEntryActivity extends Activity implements IQghAPIEventHandler {
    private IQghAPI mQghAPI;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_qgh_entry);

        /**
         * 处理QQ大厅返回的结果
         */
        mQghAPI = QghAPIFactory.createQghAPI(this, QghManager.APP_ID);
        mQghAPI.handleIntent(getIntent(), this);
    }

    @Override
    public void onResponse(BaseResponse baseResponse) {

        Bundle bundle = new Bundle();
        baseResponse.serialize(bundle);

        String response = bundle.toString();
        ((TextView) findViewById(R.id.tv_response)).setText(response);
        System.out.println("====="+baseResponse.getClass());
        if (baseResponse instanceof LoginTicketResponse) {
            LoginTicketResponse loginTicketResponse = (LoginTicketResponse)baseResponse;
            try {
                System.out.println("========resultMsg:"+loginTicketResponse.loginResult);
                JSONObject tempJect = new JSONObject(loginTicketResponse.loginResult);
                QghManager.mGameOpenid = tempJect.getString("openid");
                QghManager.mGameOpenkey = tempJect.getString("openkey");
                QghManager.mGamepf = tempJect.getString("pf");
                QghManager.mGamepfkey = tempJect.getString("pfkey");

                if (loginTicketResponse.resultCode == 0) {
                    System.out.println("QQGameHall login success");
                    Cocos2dxLuaJavaBridge.callLuaGlobalFunctionWithString("javaQghLoginSuccess",
                            QghManager.mGameOpenid + "|" + QghManager.mGameOpenkey);
                } else {
                    System.out.println("QQGameHall login fail");
                    Cocos2dxLuaJavaBridge.callLuaGlobalFunctionWithString("javaQghLoginFail", "");
                }
            } catch (JSONException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        } else if (baseResponse instanceof PayResponse) {
            PayResponse payResponse = (PayResponse) baseResponse;
            System.out.println(payResponse.resultCode+"=============="+payResponse.resultMsg);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        mQghAPI.detach();
    }
}

