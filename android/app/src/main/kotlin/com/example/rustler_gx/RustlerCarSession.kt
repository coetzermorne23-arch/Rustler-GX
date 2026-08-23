package com.example.rustler_gx

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

class RustlerCarSession : Session() {

    override fun onCreateScreen(intent: Intent): Screen {
        return RustlerCarScreen(carContext)
    }
}
