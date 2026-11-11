package kr.co.teeq.app

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 통화 화면 효과음 정책용: 기기 벨소리 모드(AudioManager.ringerMode)를 돌려준다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRingerMode" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        result.success(audioManager.ringerMode)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CALL_AUDIO_CHANNEL = "teeq/call_audio"
    }
}
