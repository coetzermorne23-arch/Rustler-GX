package com.example.rustler_gx

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

class BootReceiver :
    BroadcastReceiver() {

    override fun onReceive(
        context: Context,
        intent: Intent
    ) {
        val action =
            intent.action ?: return

        val validAction =
            action ==
                Intent.ACTION_BOOT_COMPLETED ||
            action ==
                Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action ==
                "android.intent.action.QUICKBOOT_POWERON" ||
            action ==
                "com.htc.intent.action.QUICKBOOT_POWERON"

        if (!validAction) {
            return
        }

        val pendingResult =
            goAsync()

        Handler(
            Looper.getMainLooper()
        ).postDelayed(
            {
                try {
                    val launchIntent =
                        context
                            .packageManager
                            .getLaunchIntentForPackage(
                                context.packageName
                            )

                    launchIntent?.apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK
                        )

                        addFlags(
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                        )

                        addFlags(
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                        )
                    }

                    if (
                        launchIntent != null
                    ) {
                        context.startActivity(
                            launchIntent
                        )
                    }
                } catch (
                    exception: Exception
                ) {
                    exception.printStackTrace()
                } finally {
                    pendingResult.finish()
                }
            },
            250
        )
    }
}