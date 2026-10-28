package vn.phuongloan.bakery

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createPushChannel()
    }

    /**
     * The channel push notifications arrive in (Android 8+). High importance
     * so order updates show as a heads-up banner. Creating an existing
     * channel again is a no-op, so this runs on every start.
     */
    private fun createPushChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.push_channel_id),
            getString(R.string.push_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = getString(R.string.push_channel_description) }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}
