/*
package com.example.camerapack
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import java.text.SimpleDateFormat
import java.util.Locale
import android.provider.MediaStore
import android.os.Build
import androidx.camera.core.ImageCapture
import androidx.camera.lifecycle.ProcessCameraProvider
import com.google.common.util.concurrent.ListenableFuture

@Module
@InstallIn(SingletonComponent::class)
object CameraModule {

    @Provides
    fun provideCameraProvider(activity: Activity): ListenableFuture<ProcessCameraProvider> {
        return ProcessCameraProvider.getInstance(activity)
    }

    @Provides
    fun provideOutputDirectory(@ApplicationContext context: Context): ImageCapture.OutputFileOptions {

        val name = SimpleDateFormat("yyyy-MM-dd-HH-mm-ss-SSS", Locale.US)
            .format(System.currentTimeMillis())+".jpg"
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            if(Build.VERSION.SDK_INT > Build.VERSION_CODES.P) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CameraX-Image")
            }
        }


        val outputOptions = ImageCapture.OutputFileOptions.Builder(
            context.contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            contentValues
        )
            .build()

        return outputOptions
    }
}
*/
