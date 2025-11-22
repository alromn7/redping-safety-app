package com.redping.redping

import android.content.Context
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.ToneGenerator
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.*

/**
 * Plugin to handle in-call audio injection for emergency AI calls
 * Routes TTS audio through VOICE_CALL stream so it's heard by call recipient
 */
class InCallAudioPlugin(private val context: Context) {
    
    companion object {
        private const val CHANNEL = "com.redping.redping/incall_audio"
        private const val TAG = "InCallAudioPlugin"
    }
    
    private var tts: TextToSpeech? = null
    private var audioManager: AudioManager? = null
    private var previousAudioMode: Int = AudioManager.MODE_NORMAL
    private var previousSpeakerphoneState: Boolean = false
    private var isTtsReady = false
    
    fun setupChannels(flutterEngine: FlutterEngine) {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeInCallTts" -> {
                        initializeInCallTts(result)
                    }
                    "speakDuringCall" -> {
                        val text = call.argument<String>("text")
                        if (text != null) {
                            speakDuringCall(text, result)
                        } else {
                            result.error("INVALID_ARGUMENT", "Text is required", null)
                        }
                    }
                    "stopSpeaking" -> {
                        stopSpeaking(result)
                    }
                    "dispose" -> {
                        dispose(result)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
    
    private fun initializeInCallTts(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Initializing in-call TTS")
            
            tts = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    tts?.let { engine ->
                        // Set language
                        val langResult = engine.setLanguage(Locale.US)
                        if (langResult == TextToSpeech.LANG_MISSING_DATA || 
                            langResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                            Log.e(TAG, "Language not supported")
                            result.error("TTS_ERROR", "Language not supported", null)
                            return@let
                        }
                        
                        // Configure for clear emergency speech
                        engine.setSpeechRate(0.9f) // Slightly slower for clarity
                        engine.setPitch(1.0f)
                        
                        // Set up progress listener
                        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                            override fun onStart(utteranceId: String?) {
                                Log.d(TAG, "TTS started: $utteranceId")
                            }
                            
                            override fun onDone(utteranceId: String?) {
                                Log.d(TAG, "TTS completed: $utteranceId")
                            }
                            
                            override fun onError(utteranceId: String?) {
                                Log.e(TAG, "TTS error: $utteranceId")
                            }
                        })
                        
                        isTtsReady = true
                        Log.i(TAG, "In-call TTS initialized successfully")
                        result.success(true)
                    }
                } else {
                    Log.e(TAG, "TTS initialization failed")
                    result.error("TTS_ERROR", "Failed to initialize TTS", null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing TTS", e)
            result.error("TTS_ERROR", e.message, null)
        }
    }
    
    private fun speakDuringCall(text: String, result: MethodChannel.Result) {
        try {
            if (!isTtsReady || tts == null) {
                result.error("TTS_NOT_READY", "TTS not initialized", null)
                return
            }
            
            Log.d(TAG, "Preparing to speak during call: $text")
            
            audioManager?.let { am ->
                // Save current audio state
                previousAudioMode = am.mode
                previousSpeakerphoneState = am.isSpeakerphoneOn
                
                Log.d(TAG, "Previous audio mode: $previousAudioMode, speakerphone: $previousSpeakerphoneState")
                
                // Configure audio for in-call
                // MODE_IN_COMMUNICATION routes audio through call stream
                am.mode = AudioManager.MODE_IN_COMMUNICATION
                
                // Enable speakerphone to ensure audio is captured by call microphone
                am.isSpeakerphoneOn = true
                
                // Set stream volume to maximum for call
                val maxVolume = am.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
                am.setStreamVolume(AudioManager.STREAM_VOICE_CALL, maxVolume, 0)
                
                Log.i(TAG, "Audio configured for in-call speech - mode: MODE_IN_COMMUNICATION, speaker: ON")
            }
            
            // Give audio system time to switch modes
            Handler(Looper.getMainLooper()).postDelayed({
                tts?.let { engine ->
                    // Use STREAM_VOICE_CALL for audio output
                    val params = Bundle()
                    params.putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_VOICE_CALL)
                    params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "emergency_call_${System.currentTimeMillis()}")
                    
                    val speakResult = engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, params.getString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID))
                    
                    if (speakResult == TextToSpeech.SUCCESS) {
                        Log.i(TAG, "TTS speech started successfully on VOICE_CALL stream")
                        result.success(true)
                    } else {
                        Log.e(TAG, "TTS speak failed with code: $speakResult")
                        restoreAudioState()
                        result.error("TTS_SPEAK_FAILED", "Failed to speak", null)
                    }
                } ?: run {
                    restoreAudioState()
                    result.error("TTS_NOT_AVAILABLE", "TTS engine not available", null)
                }
            }, 300) // 300ms delay for audio mode switch
            
        } catch (e: Exception) {
            Log.e(TAG, "Error speaking during call", e)
            restoreAudioState()
            result.error("SPEAK_ERROR", e.message, null)
        }
    }
    
    private fun stopSpeaking(result: MethodChannel.Result) {
        try {
            tts?.stop()
            restoreAudioState()
            Log.i(TAG, "Stopped speaking and restored audio state")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping speech", e)
            result.error("STOP_ERROR", e.message, null)
        }
    }
    
    private fun restoreAudioState() {
        try {
            audioManager?.let { am ->
                // Restore previous audio configuration
                am.mode = previousAudioMode
                am.isSpeakerphoneOn = previousSpeakerphoneState
                Log.d(TAG, "Audio state restored - mode: $previousAudioMode, speaker: $previousSpeakerphoneState")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring audio state", e)
        }
    }
    
    private fun dispose(result: MethodChannel.Result) {
        try {
            tts?.shutdown()
            tts = null
            isTtsReady = false
            restoreAudioState()
            Log.i(TAG, "In-call audio plugin disposed")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing plugin", e)
            result.error("DISPOSE_ERROR", e.message, null)
        }
    }
}
