package com.example.camerapack
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.asExecutor
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream


class CameraViewModel : ViewModel() {

    private val _photoPath = MutableLiveData<String>()
    val photoPath: LiveData<String> get() = _photoPath

    fun capturePhoto(imageCapture: ImageCapture?,context: Context,cameraSelector: CameraSelector,customPath: String? = null) {

        val photoFile = if (customPath != null) {
            File(customPath)
        }else {
            File(
                context.externalCacheDir,
                "${System.currentTimeMillis()}.jpg"
            )
        }

        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()


        viewModelScope.launch(Dispatchers.IO) {
            imageCapture?.takePicture(
                outputOptions,
                Dispatchers.IO.asExecutor(),
                object : ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(result: ImageCapture.OutputFileResults) {
                      //  val isFrontCamera = cameraSelector == CameraSelector.DEFAULT_FRONT_CAMERA

                       // if (isFrontCamera) {
                                val savedUri = Uri.fromFile(photoFile)

                                val bitmap = BitmapFactory.decodeFile(savedUri.path)

                                val exif = ExifInterface(savedUri.path!!)
                                val rotation = when (exif.getAttributeInt(
                                    ExifInterface.TAG_ORIENTATION,
                                    ExifInterface.ORIENTATION_NORMAL
                                )) {
                                    ExifInterface.ORIENTATION_ROTATE_90 -> 90
                                    ExifInterface.ORIENTATION_ROTATE_180 -> 180
                                    ExifInterface.ORIENTATION_ROTATE_270 -> 270
                                    else -> 0
                                }

                                val matrix = Matrix()
                                matrix.postRotate(rotation.toFloat())

                                // Flip horizontally if front camera
                                if (cameraSelector == CameraSelector.DEFAULT_FRONT_CAMERA) {
                                    matrix.postScale(-1f, 1f)
                                }

                                val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)

                                FileOutputStream(savedUri.path!!).use { out ->
                                    rotatedBitmap.compress(Bitmap.CompressFormat.JPEG, 100, out)
                                }

                            _photoPath.postValue(photoFile.absolutePath)

                            //_photoPath.postValue(getRealPathFromURI(context,savedUri)!!)
                       // }
                       // _photoPath.postValue(photoFile.absolutePath)
                    }

                    override fun onError(exc: ImageCaptureException) {
                        Log.e("CameraViewModel", "Capture failed: ${exc.message}", exc)
                    }
                }
            )
        }
    }

    fun getRealPathFromURI(context: Context, uri: Uri): String? {
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            if (cursor.moveToFirst()) {
                return cursor.getString(columnIndex)
            }
        }
        return null
    }

}
