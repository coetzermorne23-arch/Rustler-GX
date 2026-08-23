package com.example.rustler_gx

import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

class RustlerCarAppService : CarAppService() {

    override fun createHostValidator(): HostValidator {
        /*
         * V1 / development:
         * Allow Android Auto hosts while Rustler GX is being tested.
         *
         * Before a public Play Store release, replace this with a
         * production host allow-list / validator.
         */
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }

    override fun onCreateSession(): Session {
        return RustlerCarSession()
    }
}
