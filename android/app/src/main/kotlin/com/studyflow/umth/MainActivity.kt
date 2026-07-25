package com.studyflow.umth

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "studyflow/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                // Picu segarkan widget layar utama saat data tugas berubah
                // (FEATURE_ROADMAP #4). Dipanggil HomeWidgetService.
                if (call.method == "updateWidget") {
                    StudyFlowWidgetProvider.updateAll(applicationContext)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
