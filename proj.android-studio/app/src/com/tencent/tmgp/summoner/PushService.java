package com.tencent.tmgp.summoner;

/**
 * Created by Administrator on 2016/11/7.
 */

import android.app.AlarmManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.NotificationManagerCompat;

public class PushService extends Service {
    private static final String ACTION = "com.tencent.tmgp.summoner.pushservice.action";
    private static final String EXTRA_NOTE_ID = "com.tencent.tmgp.summoner.pushservice.extra_note_id";
    private static final String EXTRA_NOTE_CONTENT = "com.tencent.tmgp.summoner.pushservice.extra_note_content";

    class PushThread extends Thread {
        private int mId;
        private String mContent;

        public PushThread(int id, String content) {
            mId = id;
            mContent = content;
        }

        @Override
        public void run() {
            try {
                addNotification(mId, mContent);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        int ret = super.onStartCommand(intent, flags, startId);

        try {
            if (intent != null) {
                int id = intent.getIntExtra(EXTRA_NOTE_ID, 0);
                String content = intent.getStringExtra(EXTRA_NOTE_CONTENT);

                System.out.println("PushService.onStartCommand: id -> " + id);
                System.out.println("PushService.onStartCommand: " + content);

                Thread thread = new PushThread(id, content);
                thread.start();


            } else {
                System.out.println("PushService.onStartCommand: intent is null");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return ret;
    }

    public static Intent newIntent(Context context, int id, String content) {
        Intent intent = new Intent(context, PushService.class);
        intent.setAction(ACTION);
        intent.putExtra(EXTRA_NOTE_ID, id);
        intent.putExtra(EXTRA_NOTE_CONTENT, content);
        return intent;
    }

    public void addNotification(int id, String content) {
        try {
            System.out.println("PushService.addNotification");

            Intent intent = new Intent(this, AppActivity.class);
            PendingIntent pi = PendingIntent.getActivity(this, 0, intent, 0);
            Notification notification = new NotificationCompat.Builder(this)
                    .setTicker(content)
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentTitle(getResources().getString(R.string.app_name))
                    .setContentText(content)
                    .setContentIntent(pi)
                    .setAutoCancel(true)
                    .setDefaults(Notification.DEFAULT_SOUND | Notification.DEFAULT_VIBRATE)
                    .build();

            NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
            notificationManager.notify(id, notification);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
