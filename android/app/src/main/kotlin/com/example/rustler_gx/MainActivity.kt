package com.example.rustler_gx

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "rustler_gx/media"
        private const val YOUTUBE_MUSIC =
            "com.google.android.apps.youtube.music"
    }

    private lateinit var mediaSessionManager:
        MediaSessionManager

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        mediaSessionManager =
            getSystemService(
                Context.MEDIA_SESSION_SERVICE
            ) as MediaSessionManager

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getPlayback" -> {
                    result.success(
                        getPlayback()
                    )
                }

                "playPause" -> {
                    val controller =
                        getYouTubeMusicController()

                    if (controller == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    val state =
                        controller.playbackState

                    if (
                        state?.state ==
                        android.media.session.PlaybackState.STATE_PLAYING
                    ) {
                        controller.transportControls.pause()
                    } else {
                        controller.transportControls.play()
                    }

                    result.success(true)
                }

                "next" -> {
                    val controller =
                        getYouTubeMusicController()

                    if (controller == null) {
                        result.success(false)
                    } else {
                        controller.transportControls
                            .skipToNext()

                        result.success(true)
                    }
                }

                "previous" -> {
                    val controller =
                        getYouTubeMusicController()

                    if (controller == null) {
                        result.success(false)
                    } else {
                        controller.transportControls
                            .skipToPrevious()

                        result.success(true)
                    }
                }

                "hasNotificationAccess" -> {
                    result.success(
                        hasNotificationAccess()
                    )
                }

                "openNotificationAccess" -> {
                    try {
                        val intent =
                            Intent(
                                Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
                            )

                        startActivity(intent)

                        result.success(true)
                    } catch (error: Exception) {
                        result.error(
                            "SETTINGS_ERROR",
                            error.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getPlayback():
        Map<String, Any?> {

        val controller =
            getYouTubeMusicController()

        if (controller == null) {
            return mapOf(
                "title" to "Nothing playing",
                "artist" to "YouTube Music",
                "album" to "",
                "playing" to false,
                "packageName" to null
            )
        }

        val metadata =
            controller.metadata

        val state =
            controller.playbackState

        return mapOf(
            "title" to (
                metadata?.getString(
                    android.media.MediaMetadata.METADATA_KEY_TITLE
                ) ?: "Unknown track"
            ),
            "artist" to (
                metadata?.getString(
                    android.media.MediaMetadata.METADATA_KEY_ARTIST
                ) ?: ""
            ),
            "album" to (
                metadata?.getString(
                    android.media.MediaMetadata.METADATA_KEY_ALBUM
                ) ?: ""
            ),
            "playing" to (
                state?.state ==
                android.media.session.PlaybackState.STATE_PLAYING
            ),
            "packageName" to
                controller.packageName
        )
    }

    private fun getYouTubeMusicController():
        MediaController? {

        if (!hasNotificationAccess()) {
            return null
        }

        return try {
            val component =
                ComponentName(
                    this,
                    MediaNotificationListener::class.java
                )

            val controllers =
                mediaSessionManager
                    .getActiveSessions(component)

            controllers.firstOrNull {
                it.packageName ==
                    YOUTUBE_MUSIC
            }
        } catch (error: SecurityException) {
            null
        }
    }

    private fun hasNotificationAccess():
        Boolean {

        val enabled =
            Settings.Secure.getString(
                contentResolver,
                "enabled_notification_listeners"
            ) ?: return false

        return enabled.contains(
            packageName
        )
    }
}