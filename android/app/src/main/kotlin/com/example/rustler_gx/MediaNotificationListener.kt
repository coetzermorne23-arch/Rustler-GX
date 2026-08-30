package com.example.rustler_gx

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MediaNotificationListener :
    NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()

        requestRebind(
            componentName
        )
    }

    override fun onNotificationPosted(
        sbn: StatusBarNotification?
    ) {
        super.onNotificationPosted(
            sbn
        )
    }

    override fun onNotificationRemoved(
        sbn: StatusBarNotification?
    ) {
        super.onNotificationRemoved(
            sbn
        )
    }

    private val componentName
        get() =
            android.content.ComponentName(
                this,
                MediaNotificationListener::
                    class.java
            )
}