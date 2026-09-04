package com.example.rustler_gx

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.storage.StorageManager
import android.provider.Settings

object HeadUnitPlatform {
    fun isHomeApp(context: Context): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolved = context.packageManager.resolveActivity(intent, 0)
        return resolved?.activityInfo?.packageName == context.packageName
    }

    fun requestHomeRole(activity: Activity): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = activity.getSystemService(RoleManager::class.java)
                if (roleManager.isRoleAvailable(RoleManager.ROLE_HOME) &&
                    !roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
                    activity.startActivityForResult(
                        roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME), 8421
                    )
                    true
                } else {
                    roleManager.isRoleHeld(RoleManager.ROLE_HOME)
                }
            } else {
                activity.startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                true
            }
        } catch (_: Exception) {
            try {
                activity.startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    fun storageVolumes(context: Context): List<Map<String, Any?>> {
        val manager = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
        return manager.storageVolumes.map { volume ->
            val directory = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                volume.directory?.absolutePath
            } else null
            mapOf(
                "description" to volume.getDescription(context),
                "removable" to volume.isRemovable,
                "state" to volume.state,
                "path" to (directory ?: "")
            )
        }
    }
}
