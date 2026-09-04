package com.example.rustler_gx

import android.content.ComponentName
import android.Manifest
import android.content.pm.PackageManager
import android.location.GnssStatus
import android.location.LocationManager
import android.net.Uri
import android.content.pm.ApplicationInfo
import android.os.Build
import androidx.core.app.ActivityCompat
import android.content.Intent
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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

        private const val GNSS_CHANNEL =
            "rustler_gx/gnss"

        private const val YOUTUBE_MUSIC =
            "com.google.android.apps.youtube.music"
    }

    private lateinit var mediaSessionManager:
        MediaSessionManager

    private var gnssSnapshot: List<Map<String, Any>> = emptyList()
    private var gnssCallback: GnssStatus.Callback? = null

    private fun startGnssStatus() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) return

        val locationManager =
            getSystemService(LOCATION_SERVICE) as LocationManager

        if (gnssCallback != null) return

        gnssCallback = object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(status: GnssStatus) {
                val data = ArrayList<Map<String, Any>>(status.satelliteCount)
                for (i in 0 until status.satelliteCount) {
                    data.add(
                        mapOf(
                            "svid" to status.getSvid(i),
                            "constellation" to status.getConstellationType(i),
                            "cn0" to status.getCn0DbHz(i).toDouble(),
                            "elevation" to status.getElevationDegrees(i).toDouble(),
                            "azimuth" to status.getAzimuthDegrees(i).toDouble(),
                            "usedInFix" to status.usedInFix(i)
                        )
                    )
                }
                gnssSnapshot = data
            }
        }

        locationManager.registerGnssStatusCallback(
            gnssCallback!!,
            Handler(Looper.getMainLooper())
        )
    }

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

    override fun onResume() {
        super.onResume()
        startGnssStatus()
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
            GNSS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "snapshot" -> {
                    startGnssStatus()
                    result.success(gnssSnapshot)
                }
                else -> result.notImplemented()
            }
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
                    result.success(true)
                }

                "isDefaultHome" -> {
                    result.success(HeadUnitPlatform.isHomeApp(this))
                }

                "requestHomeRole" -> {
                    result.success(HeadUnitPlatform.requestHomeRole(this))
                }

                "storageVolumes" -> {
                    result.success(HeadUnitPlatform.storageVolumes(this))
                }

                "launcherApps" -> {
                    val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                    val pm = packageManager
                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PackageManager.MATCH_ALL else 0
                    val apps = pm.queryIntentActivities(intent, flags).map { info ->
                        val ai = info.activityInfo.applicationInfo
                        mapOf(
                            "packageName" to info.activityInfo.packageName,
                            "label" to info.loadLabel(pm).toString(),
                            "system" to ((ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
                        )
                    }.distinctBy { it["packageName"] }.sortedBy { (it["label"] as String).lowercase() }
                    result.success(apps)
                }

                "openAppDetails" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.success(false)
                    } else {
                        try {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("APP_DETAILS", e.message, null)
                        }
                    }
                }

                "getCallState" -> {
                    result.success(CallNotificationBridge.data())
                }

                "answerCall" -> {
                    result.success(CallNotificationBridge.action("answer"))
                }

                "declineCall" -> {
                    result.success(CallNotificationBridge.action("decline"))
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
                result.success(getPlaybackData())
            }

            "startDefaultMedia" -> {
                result.success(startDefaultMedia())
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

    private fun startDefaultMedia(): Boolean {
        val existing = getPreferredController()
        if (existing?.packageName == YOUTUBE_MUSIC) {
            existing.transportControls.play()
            return true
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(YOUTUBE_MUSIC)
            ?: return false
        return try {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
            Handler(Looper.getMainLooper()).postDelayed({
                getPreferredController()?.transportControls?.play()
                packageManager.getLaunchIntentForPackage(packageName)?.let { own ->
                    own.addFlags(
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    )
                    startActivity(own)
                }
            }, 1800)
            true
        } catch (_: Exception) {
            false
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
                it.packageName == YOUTUBE_MUSIC
            } ?: controllers.firstOrNull { controller ->
                val name = controller.packageName.lowercase()
                name.contains("bluetooth") ||
                    name.contains("btmusic") ||
                    name.contains("bt.music")
            } ?: controllers.firstOrNull { controller ->
                controller.playbackState?.state == PlaybackState.STATE_PLAYING
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