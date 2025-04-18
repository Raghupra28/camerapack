package com.example.camerapack

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.io.File
import java.io.FileOutputStream

/** CamerapackPlugin */
class CamerapackPlugin: FlutterPlugin, MethodCallHandler,ActivityAware,PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private val REQUEST_CODE = 128
  private val REQUEST_GALLERY_CODE = 12828
  private var pendingResult: MethodChannel.Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "imageCapture")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method == "onCameraClick") {
      val args = call.arguments as Map<*, *>
      val cameraPosition = args["cameraPosition"] as? String ?: "back"
      val customPath = args["path"] as? String
      pendingResult = result
      val intent = Intent(activity, CameraActivity::class.java)
      intent.putExtra("camera_pos",cameraPosition)
      if (customPath != null) {
        intent.putExtra("custom_path", customPath)  // <-- Pass to activity
      }
      activity!!.startActivityForResult(intent, REQUEST_CODE)
    } else if (call.method == "onGalleryClick") {
      // Handle gallery image picking
      val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
      intent.type = "image/*"
      activity!!.startActivityForResult(intent, REQUEST_GALLERY_CODE)
      pendingResult = result
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
    }else if(requestCode == REQUEST_GALLERY_CODE){
      if(resultCode == Activity.RESULT_OK && data != null){
        val selectedImageUri: Uri? = data.data
        val imagePath = getPathFromUri(selectedImageUri)
        if (imagePath != null) {
          pendingResult?.success(imagePath)
        } else {
          pendingResult?.error("FILE_PATH_ERROR", "Unable to get image path from URI", null)
        }
      }else{
        pendingResult?.error("IMAGE_PICKING_FAILED", "Failed to pick image from gallery", null)
      }
      pendingResult = null
      return true
    }
    return false
  }

  private fun getPathFromUri(uri: Uri?): String? {
    val fileName = "gallery_image_${System.currentTimeMillis()}.jpg"
    val inputStream = activity?.contentResolver?.openInputStream(uri!!)
    val tempFile = File(activity?.cacheDir, fileName)

    return try {
      inputStream?.use { input ->
        FileOutputStream(tempFile).use { output ->
          input.copyTo(output)
        }
      }
      tempFile.absolutePath
    } catch (e: Exception) {
      e.printStackTrace()
      null
    }
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
