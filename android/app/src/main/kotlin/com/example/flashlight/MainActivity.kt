package com.shiab.flashlight

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity()

{
	private val channelName = "flashlight"
	private var torchCameraId: String? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"isTorchAvailable" -> {
						val id = getTorchCameraId()
						result.success(id != null)
					}
					"setTorch" -> {
						val enabled = call.argument<Boolean>("enabled")
						if (enabled == null) {
							result.error("bad_args", "Missing 'enabled'", null)
							return@setMethodCallHandler
						}

						val id = getTorchCameraId()
						if (id == null) {
							result.error("unavailable", "No torch/flash available on this device", null)
							return@setMethodCallHandler
						}

						try {
							if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
								result.error("unsupported", "Torch control requires Android 6.0+", null)
								return@setMethodCallHandler
							}

							val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
							cameraManager.setTorchMode(id, enabled)
							result.success(true)
						} catch (e: SecurityException) {
							result.error("security", e.message, null)
						} catch (e: Exception) {
							result.error("error", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun getTorchCameraId(): String? {
		if (torchCameraId != null) return torchCameraId

		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
		val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager

		var fallbackId: String? = null
		for (id in cameraManager.cameraIdList) {
			val characteristics = cameraManager.getCameraCharacteristics(id)
			val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
			if (!hasFlash) continue

			val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
			if (lensFacing == CameraCharacteristics.LENS_FACING_BACK) {
				torchCameraId = id
				return id
			}

			if (fallbackId == null) fallbackId = id
		}

		torchCameraId = fallbackId
		return torchCameraId
	}

}
