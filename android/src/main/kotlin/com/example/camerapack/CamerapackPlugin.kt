package com.example.camerapack

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
/** CamerapackPlugin */
class CamerapackPlugin: FlutterPlugin, MethodCallHandler,ActivityAware,PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private val REQUEST_CODE = 128
  private var pendingResult: MethodChannel.Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "imageCapture")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method == "oncameraClick") {
      val args = call.arguments as Map<*, *>
      val cameraPosition = args["cameraPosition"] as? String ?: "back"
      pendingResult = result
      val intent = Intent(activity, CameraActivity::class.java)
      intent.putExtra("camera_pos",cameraPosition)
      activity!!.startActivityForResult(intent, REQUEST_CODE)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?):Boolean {

    if (requestCode == REQUEST_CODE) {
      if(resultCode == Activity.RESULT_OK){
        val result = data?.getStringExtra("capturedphoto")
        //Log.d("MyFlutterActivity", "Got result: $result")
        pendingResult?.success(result)
      }else{
        pendingResult?.error("ACTIVITY_FAILED", "Activity canceled or failed", null)
      }
      pendingResult = null
      return true
      // Now pass it to Flutter
    }
    return false
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }
}
