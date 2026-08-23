package com.example.rustler_gx

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template

class RustlerCarScreen(
    carContext: CarContext,
) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        /*
         * V1 proves that Rustler GX is discoverable and renders
         * correctly inside Android Auto.
         *
         * Next step: bridge live Rustler GX data into this screen
         * (battery, solar, charger, fridge, tanks and alarms).
         */
        val pane = Pane.Builder()
            .addRow(
                Row.Builder()
                    .setTitle("Rustler GX")
                    .addText("Android Auto integration is active.")
                    .build()
            )
            .addRow(
                Row.Builder()
                    .setTitle("Vehicle systems")
                    .addText("Live device data bridge coming next.")
                    .build()
            )
            .addRow(
                Row.Builder()
                    .setTitle("Bluetooth / Victron")
                    .addText("Managed by the Rustler GX phone app.")
                    .build()
            )
            .build()

        return PaneTemplate.Builder(pane)
            .setTitle("Rustler GX")
            .setHeaderAction(Action.APP_ICON)
            .build()
    }
}
