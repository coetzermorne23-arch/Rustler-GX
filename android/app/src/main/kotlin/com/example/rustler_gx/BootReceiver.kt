package com.example.rustler_gx

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(
        context: Context,
        intent: Intent
    ) {
        if (
            intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action !=
                "android.intent.action.QUICKBOOT_POWERON" &&
            intent.action !=
                "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        Handler(
            Looper.getMainLooper()
        ).postDelayed(
            {
                val launchIntent =
                    context.packageManager
                        .getLaunchIntentForPackage(
                            context.packageName
                        )

                launchIntent?.apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    )

                    context.startActivity(this)
                }
            },
            3000
        )
    }
}