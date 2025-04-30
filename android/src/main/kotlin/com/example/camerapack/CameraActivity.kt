package com.example.camerapack

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModelProvider
import java.io.File

class CameraActivity : AppCompatActivity() {

   // private lateinit var binding: ActivityCameraBinding
    private lateinit var imageCapture: ImageCapture
    private var cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

    private lateinit var viewModel: CameraViewModel
    private lateinit var captureButton:ImageButton
    private lateinit var galleryButton:ImageButton
    private lateinit var flipCameraButton:ImageButton
    private var customPath: String? = null
    private var isFlashOn = false
    private lateinit var cameraPreview:PreviewView

    // Define MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_camera)

        // Manually initialize the views
         captureButton = findViewById<ImageButton>(R.id.captureButton)
         galleryButton = findViewById<ImageButton>(R.id.galleryButton)
         flipCameraButton = findViewById<ImageButton>(R.id.flipCameraButton)
         cameraPreview = findViewById<PreviewView>(R.id.cameraPreview)
        viewModel = ViewModelProvider(this)[CameraViewModel::class.java]
       // binding.viewModel = viewModel
        supportActionBar?.hide()
        val cameraPosition = intent.getStringExtra("camera_pos") ?: "back"
        val isFrontCamera = cameraPosition == "front"
        customPath = intent.getStringExtra("custom_path")
        if(!isFrontCamera){
            cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
        }
        // Initialize FlutterEngine & MethodChannel

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            == PackageManager.PERMISSION_GRANTED
        ) {
            startCamera()
        } else {
            requestPermissionLauncher.launch(REQUIRED_PERMISSIONS)
        }
        captureButton.setOnClickListener { takePhoto() }
        viewModel.photoPath.observe(this) {
            //Toast.makeText(this, "Photo saved: $it", Toast.LENGTH_SHORT).show()
            val resultIntent = Intent()
            resultIntent.putExtra("capturedphoto", it)
            setResult(RESULT_OK, resultIntent)
            finish()
        }
        flipCameraButton.setOnClickListener {
            cameraSelector = if (cameraSelector == CameraSelector.DEFAULT_FRONT_CAMERA)
                CameraSelector.DEFAULT_BACK_CAMERA
            else CameraSelector.DEFAULT_FRONT_CAMERA
            startCamera()
        }
        galleryButton.setOnClickListener {
            galleryLauncher.launch("image/*")
        }

        findViewById<ImageView>(R.id.imgFlash).setOnClickListener {
            isFlashOn = !isFlashOn
            updateFlashIcon()
        }
    }

    private fun updateFlashIcon() {
        val flashIcon = if (isFlashOn) R.drawable.baseline_flash_on_24 else R.drawable.baseline_flash_off_24
        findViewById<ImageView>(R.id.imgFlash).setImageResource(flashIcon)
    }

    private val galleryLauncher = registerForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri?.let {
            val imageFile = uriToFile(it)
            val resultIntent = Intent()
            resultIntent.putExtra("capturedphoto", imageFile.absolutePath) // You can convert to file path if needed
            setResult(RESULT_OK, resultIntent)
            finish()
        }
    }

    private fun uriToFile(uri: android.net.Uri): File {
        val inputStream = contentResolver.openInputStream(uri)
        val file = File.createTempFile("camera_image_${System.currentTimeMillis()}", ".jpg", cacheDir)
        val outputStream = file.outputStream()
        inputStream?.copyTo(outputStream)
        inputStream?.close()
        outputStream.close()
        return file
    }

    private val requestPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { granted ->
            var permissionGranted = true
            granted.entries.forEach {
                if (it.key in REQUIRED_PERMISSIONS && it.value == false)
                    permissionGranted = false
            }
            if (permissionGranted) startCamera()
            else Toast.makeText(this, "Permission Denied", Toast.LENGTH_SHORT).show()
        }

    private fun startCamera() {
        ProcessCameraProvider.getInstance(this).addListener({
            val cameraProvider = ProcessCameraProvider.getInstance(this).get()
            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(cameraPreview.surfaceProvider)
            }

            imageCapture = ImageCapture.Builder().build().apply {
                setFlashMode(if (isFlashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF)
            }

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageCapture)
            } catch (exc: Exception) {
                Log.e("CameraX", "Use case binding failed", exc)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun takePhoto() {
        viewModel.capturePhoto(imageCapture,this,cameraSelector, customPath)
    }

    companion object {
        private const val TAG = "CameraXApp"
        private const val FILENAME_FORMAT = "yyyy-MM-dd-HH-mm-ss-SSS"
        private val REQUIRED_PERMISSIONS =
            mutableListOf (
                Manifest.permission.CAMERA,
                Manifest.permission.RECORD_AUDIO
            ).apply {
                if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                    add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                }
            }.toTypedArray()
    }


}
