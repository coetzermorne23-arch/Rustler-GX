package com.example.rustler_gx

import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class OrganicMapsPlatformViewFactory(
    private val activityContext: Context
) : PlatformViewFactory(
    StandardMessageCodec.INSTANCE
) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        return OrganicMapsPlatformView(
            activityContext,
            context,
            viewId,
            args
        )
    }
}

private class OrganicMapsPlatformView(
    private val activityContext: Context,
    private val context: Context,
    private val viewId: Int,
    private val args: Any?
) : PlatformView {

    private val container =
        FrameLayout(context)

    private var organicMapView: View? = null

    init {
        container.setBackgroundColor(
            Color.rgb(11, 16, 19)
        )

        organicMapView =
            createOrganicMapView()

        val child =
            organicMapView ?: createErrorView()

        container.addView(
            child,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )
    }

    override fun getView(): View =
        container

    override fun dispose() {
        container.removeAllViews()
        organicMapView = null
    }

    private fun createOrganicMapView(): View? {
        return try {
            // Reflection is deliberate. Ranger GX can still compile and use
            // its existing MBTiles map before the locally-built Organic Maps
            // SDK AARs have been installed.
            val mapViewClass =
                Class.forName(
                    "app.organicmaps.sdk.MapView"
                )

            val constructor =
                mapViewClass.getConstructor(
                    Context::class.java
                )

            constructor.newInstance(
                activityContext
            ) as View
        } catch (error: Throwable) {
            android.util.Log.e(
                "RangerGXOrganicMaps",
                "Could not create embedded Organic Maps MapView",
                error
            )
            null
        }
    }

    private fun createErrorView(): View {
        return TextView(context).apply {
            text =
                "Organic Maps SDK could not initialise.\n" +
                "Ranger GX offline map is still available."
            setTextColor(Color.WHITE)
            textSize = 18f
            gravity = android.view.Gravity.CENTER
            setPadding(
                28,
                28,
                28,
                28
            )
        }
    }
}
