package com.bayesa.safaksayar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SafakWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
        val name = prefs.getString("name", "Asker") ?: "Asker"
        val endDateStr = prefs.getString("end_date", "") ?: ""
        
        var daysLeft = prefs.getInt("remainingDays", 0)
        
        if (endDateStr.isNotEmpty()) {
            try {
                // ISO 8601 format (e.g. 2026-06-07T00:00:00.000)
                val cleanDateStr = if (endDateStr.contains(".")) {
                    endDateStr.substring(0, endDateStr.indexOf("."))
                } else {
                    endDateStr
                }
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                val endDate = format.parse(cleanDateStr)
                if (endDate != null) {
                    val diff = endDate.time - System.currentTimeMillis()
                    // Add half a day of milliseconds to round up correctly if it is partial
                    val days = (diff / (1000 * 60 * 60 * 24)).toInt()
                    daysLeft = if (days > 0) days else 0
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.safak_widget)
            views.setTextViewText(R.id.widget_user_name, name)
            views.setTextViewText(R.id.widget_days_value, daysLeft.toString())
            
            val statusText = when {
                daysLeft <= 0 -> "Şafak Doğan Güneş! Görev Tamamlandı."
                daysLeft <= 10 -> "Şafak tek hanelerde, yol göründü!"
                daysLeft <= 30 -> "Son 1 ay, bitiyor!"
                daysLeft <= 100 -> "Çift hanelere az kaldı!"
                else -> "Vatan sana minnettar!"
            }
            views.setTextViewText(R.id.widget_status, statusText)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
