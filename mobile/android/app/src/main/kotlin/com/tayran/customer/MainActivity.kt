package com.tayran.customer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrdersChannel()
    }

    /**
     * The "orders" channel the backend sends every order push on. High importance so the update
     * shows as a heads-up banner. Its name follows the phone's language (values / values-en).
     * Creating it again on each launch only refreshes the name and description.
     */
    private fun createOrdersChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            ORDERS_CHANNEL,
            getString(R.string.orders_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = getString(R.string.orders_channel_description) }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private companion object {
        const val ORDERS_CHANNEL = "orders"
    }
}
