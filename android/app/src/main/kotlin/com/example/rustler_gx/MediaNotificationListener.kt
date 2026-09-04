package com.example.rustler_gx

import android.content.ComponentName
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MediaNotificationListener : NotificationListenerService() {
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        requestRebind(componentName)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        CallNotificationBridge.update(sbn)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        CallNotificationBridge.remove(sbn)
    }

    private val componentName
        get() = ComponentName(this, MediaNotificationListener::class.java)
}
