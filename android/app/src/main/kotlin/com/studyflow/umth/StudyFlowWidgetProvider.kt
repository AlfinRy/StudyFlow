package com.studyflow.umth

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Widget layar utama StudyFlow (FEATURE_ROADMAP #4).
 *
 * Menampilkan maksimal 4 tugas hari ini yang belum selesai, dibaca dari
 * SharedPreferences `FlutterSharedPreferences` (ditulis Flutter lewat plugin
 * `shared_preferences`, key `flutter.widget_today_tasks` berisi JSON).
 *
 * - [onUpdate] dipanggil sistem saat widget dipasang & tiap 30 menit
 *   (updatePeriodMillis).
 * - [updateAll] dipanggil dari MainActivity (MethodChannel) saat data tugas
 *   berubah supaya widget langsung segar.
 */
class StudyFlowWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREFS_KEY = "flutter.widget_today_tasks"

        /** Segarkan semua instance widget yang sedang ada di home screen. */
        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, StudyFlowWidgetProvider::class.java)
            )
            for (id in ids) {
                mgr.updateAppWidget(id, buildViews(context))
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_studyflow)

            // Tanggal hari ini (format singkat Indonesia).
            val cal = java.util.Calendar.getInstance()
            val dateLabel = "${cal.get(java.util.Calendar.DAY_OF_MONTH)} ${monthIdn(cal.get(java.util.Calendar.MONTH))}"
            views.setTextViewText(R.id.widget_date, dateLabel)

            // Baca ringkasan tugas dari SharedPreferences (ditulis Flutter).
            val items = readItems(context)

            val taskViewIds = intArrayOf(
                R.id.widget_task1,
                R.id.widget_task2,
                R.id.widget_task3,
                R.id.widget_task4,
            )
            for (i in taskViewIds.indices) {
                if (i < items.size) {
                    val (title, time) = items[i]
                    val label = if (time.isNotEmpty()) "• $time  $title" else "•  $title"
                    views.setTextViewText(taskViewIds[i], label)
                    views.setViewVisibility(taskViewIds[i], View.VISIBLE)
                } else {
                    views.setViewVisibility(taskViewIds[i], View.GONE)
                }
            }
            views.setViewVisibility(
                R.id.widget_empty,
                if (items.isEmpty()) View.VISIBLE else View.GONE,
            )

            // Tap widget mana pun → buka StudyFlow.
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(context, 0, openIntent, pendingFlags),
            )

            return views
        }

        private fun readItems(context: Context): List<Pair<String, String>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(PREFS_KEY, null) ?: return emptyList()
            return try {
                val arr = JSONObject(json).optJSONArray("items") ?: return emptyList()
                val out = mutableListOf<Pair<String, String>>()
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    out.add(o.optString("title") to o.optString("time"))
                }
                out
            } catch (_: Exception) {
                emptyList()
            }
        }

        private fun monthIdn(m: Int): String = arrayOf(
            "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
            "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
        )[m]
    }
}
