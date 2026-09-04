package com.example.rustler_gx

import android.app.Notification
import android.app.PendingIntent
import android.service.notification.StatusBarNotification

object CallNotificationBridge {
    @Volatile private var current: StatusBarNotification? = null

    fun update(sbn: StatusBarNotification?) {
        if (sbn == null) return
        if (sbn.notification.category == Notification.CATEGORY_CALL) current = sbn
    }

    fun remove(sbn: StatusBarNotification?) {
        if (sbn != null && current?.key == sbn.key) current = null
    }

    fun data(): Map<String, Any?> {
        val sbn = current ?: return mapOf("active" to false)
        val extras = sbn.notification.extras
        return mapOf(
            "active" to true,
            "packageName" to sbn.packageName,
            "title" to (extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: "Incoming call"),
            "text" to (extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "")
        )
    }

    fun action(wanted: String): Boolean {
        val notification = current?.notification ?: return false
        val tokens = when (wanted) {
            "answer" -> listOf("answer", "accept", "pickup", "pick up")
            "decline" -> listOf("decline", "reject", "hang up", "end")
            else -> emptyList()
        }
        val action = notification.actions?.firstOrNull { item ->
            val title = item.title?.toString()?.lowercase() ?: ""
            tokens.any { title.contains(it) }
        } ?: return false
        return try {
            action.actionIntent.send()
            true
        } catch (_: PendingIntent.CanceledException) {
            false
        }
    }
}
