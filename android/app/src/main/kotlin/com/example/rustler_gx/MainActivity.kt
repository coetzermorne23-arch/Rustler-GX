package com.example.rustler_gx

import android.content.ComponentName
import android.content.Intent
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Bundle
import android.provider.Settings
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val MEDIA_CHANNEL =
            "rustler_gx/media"

        private const val HEAD_UNIT_CHANNEL =
            "rustler_gx/head_unit"

        private const val YOUTUBE_MUSIC =
            "com.google.android.apps.youtube.music"
    }

    private lateinit var mediaSessionManager:
        MediaSessionManager

    override fun onCreate(
        savedInstanceState: Bundle?
    ) {
        super.onCreate(
            savedInstanceState
        )

        mediaSessionManager =
            getSystemService(
                MEDIA_SESSION_SERVICE
            ) as MediaSessionManager

    }

    override fun dispatchKeyEvent(
        event: KeyEvent
    ): Boolean {
        if (
            event.action != KeyEvent.ACTION_DOWN ||
            event.repeatCount != 0
        ) {
            return super.dispatchKeyEvent(event)
        }

        val controller =
            getPreferredController()

        when (event.keyCode) {
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            KeyEvent.KEYCODE_HEADSETHOOK -> {
                if (controller == null) {
                    return super.dispatchKeyEvent(event)
                }

                val state =
                    controller.playbackState?.state

                if (
                    state ==
                    PlaybackState.STATE_PLAYING
                ) {
                    controller.transportControls.pause()
                } else {
                    controller.transportControls.play()
                }

                return true
            }

            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                if (controller == null) {
                    return super.dispatchKeyEvent(event)
                }

                controller.transportControls.play()
                return true
            }

            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                if (controller == null) {
                    return super.dispatchKeyEvent(event)
                }

                controller.transportControls.pause()
                return true
            }

            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                if (controller == null) {
                    return super.dispatchKeyEvent(event)
                }

                controller.transportControls.skipToNext()
                return true
            }

            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                if (controller == null) {
                    return super.dispatchKeyEvent(event)
                }

                controller.transportControls.skipToPrevious()
                return true
            }
        }

        return super.dispatchKeyEvent(event)
    }

    override fun configureFlutterEngine(
        @NonNull flutterEngine:
            FlutterEngine
    ) {
        super.configureFlutterEngine(
            flutterEngine
        )

        MethodChannel(
            flutterEngine
                .dartExecutor
                .binaryMessenger,
            MEDIA_CHANNEL
        ).setMethodCallHandler {
                call,
                result ->

            handleMediaMethod(
                call,
                result
            )
        }

        MethodChannel(
            flutterEngine
                .dartExecutor
                .binaryMessenger,
            HEAD_UNIT_CHANNEL
        ).setMethodCallHandler {
                call,
                result ->

            when (call.method) {

                "keepScreenOn" -> {
                    keepScreenOn()

                    result.success(
                        true
                    )
                }

                "immersiveMode" -> {
                    immersiveMode()

                    result.success(
                        true
                    )
                }

                "normalSystemUi" -> {
                    normalSystemUi()

                    result.success(
                        true
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun keepScreenOn() {
        window.addFlags(
            WindowManager
                .LayoutParams
                .FLAG_KEEP_SCREEN_ON
        )
    }

    @Suppress("DEPRECATION")
    private fun immersiveMode() {
        window.decorView.systemUiVisibility =
            (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or
                View.SYSTEM_UI_FLAG_FULLSCREEN
                    or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
    }

    @Suppress("DEPRECATION")
    private fun normalSystemUi() {
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_VISIBLE
    }

    private fun handleMediaMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {

            "getPlayback" -> {
                result.success(
                    getPlaybackData()
                )
            }

            "hasNotificationAccess" -> {
                result.success(
                    hasNotificationAccess()
                )
            }

            "openNotificationAccess" -> {
                openNotificationAccess()

                result.success(
                    true
                )
            }

            "playPause" -> {
                val controller =
                    getPreferredController()

                if (controller == null) {
                    result.success(
                        false
                    )

                    return
                }

                val state =
                    controller
                        .playbackState
                        ?.state

                if (
                    state ==
                    PlaybackState.STATE_PLAYING
                ) {
                    controller
                        .transportControls
                        .pause()
                } else {
                    controller
                        .transportControls
                        .play()
                }

                result.success(
                    true
                )
            }

            "play" -> {
                val controller =
                    getPreferredController()

                controller
                    ?.transportControls
                    ?.play()

                result.success(
                    controller != null
                )
            }

            "pause" -> {
                val controller =
                    getPreferredController()

                controller
                    ?.transportControls
                    ?.pause()

                result.success(
                    controller != null
                )
            }

            "next" -> {
                val controller =
                    getPreferredController()

                controller
                    ?.transportControls
                    ?.skipToNext()

                result.success(
                    controller != null
                )
            }

            "previous" -> {
                val controller =
                    getPreferredController()

                controller
                    ?.transportControls
                    ?.skipToPrevious()

                result.success(
                    controller != null
                )
            }

            "seekTo" -> {
                val controller =
                    getPreferredController()

                val positionMs =
                    call.argument<Number>(
                        "positionMs"
                    )?.toLong() ?: 0L

                controller
                    ?.transportControls
                    ?.seekTo(
                        positionMs
                    )

                result.success(
                    controller != null
                )
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getPlaybackData():
        Map<String, Any> {

        val controller =
            getPreferredController()

        if (controller == null) {
            return mapOf(
                "title" to "",
                "artist" to "",
                "album" to "",
                "packageName" to "",
                "playing" to false,
                "active" to false,
                "positionMs" to 0L,
                "durationMs" to 0L
            )
        }

        val metadata =
            controller.metadata

        val state =
            controller.playbackState

        val title =
            metadata
                ?.getString(
                    MediaMetadata
                        .METADATA_KEY_TITLE
                )
                ?: ""

        val artist =
            metadata
                ?.getString(
                    MediaMetadata
                        .METADATA_KEY_ARTIST
                )
                ?: metadata
                    ?.getString(
                        MediaMetadata
                            .METADATA_KEY_ALBUM_ARTIST
                    )
                ?: ""

        val album =
            metadata
                ?.getString(
                    MediaMetadata
                        .METADATA_KEY_ALBUM
                )
                ?: ""

        val duration =
            metadata
                ?.getLong(
                    MediaMetadata
                        .METADATA_KEY_DURATION
                )
                ?: 0L

        val position =
            state?.position
                ?: 0L

        val playing =
            state?.state ==
                PlaybackState.STATE_PLAYING

        return mapOf(
            "title" to title,
            "artist" to artist,
            "album" to album,
            "packageName" to
                controller.packageName,
            "playing" to playing,
            "active" to true,
            "positionMs" to position,
            "durationMs" to duration
        )
    }

    private fun getPreferredController():
        MediaController? {

        if (!hasNotificationAccess()) {
            return null
        }

        return try {
            val component =
                ComponentName(
                    this,
                    MediaNotificationListener::
                        class.java
                )

            val controllers =
                mediaSessionManager
                    .getActiveSessions(
                        component
                    )

            controllers.firstOrNull {
                it.packageName ==
                    YOUTUBE_MUSIC
            } ?: controllers.firstOrNull()

        } catch (
            exception: SecurityException
        ) {
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

        val component =
            ComponentName(
                this,
                MediaNotificationListener::
                    class.java
            )

        return enabled.contains(
            component.flattenToString()
        )
    }

    private fun openNotificationAccess() {
        try {
            startActivity(
                Intent(
                    "android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"
                )
            )
        } catch (
            exception: Exception
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_SETTINGS
                )
            )
        }
    }
}