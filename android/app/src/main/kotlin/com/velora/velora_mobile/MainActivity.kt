package com.velora.velora_mobile

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val APP_UPDATE_CHANNEL = "com.velora.mobile/app_update"
    private val PRINTER_CHANNEL = "com.velora.mobile/printer"
    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private fun getBluetoothAdapter(): BluetoothAdapter? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                manager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
            } else {
                @Suppress("DEPRECATION")
                BluetoothAdapter.getDefaultAdapter()
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getBondedDevices(): List<Map<String, String>> {
        val adapter = getBluetoothAdapter() ?: return emptyList()
        val list = mutableListOf<Map<String, String>>()
        try {
            val devices = adapter.bondedDevices
            if (devices != null) {
                for (dev in devices) {
                    list.add(mapOf(
                        "name" to (dev.name ?: "Unknown Device"),
                        "address" to dev.address
                    ))
                }
            }
        } catch (e: SecurityException) {
            // Permission not granted or restricted
        } catch (e: Exception) {
            // Ignored
        }
        return list
    }

    private fun printBluetooth(target: String, bytes: ByteArray): Boolean {
        val adapter = getBluetoothAdapter() ?: return false
        try {
            val devices = adapter.bondedDevices ?: return false
            val device = devices.firstOrNull {
                it.address.equals(target, ignoreCase = true) || it.name.equals(target, ignoreCase = true)
            } ?: return false

            try {
                adapter.cancelDiscovery()
            } catch (_: Exception) {}

            var socket: BluetoothSocket? = null
            try {
                socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                socket.connect()
            } catch (e: IOException) {
                try {
                    val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    socket = m.invoke(device, 1) as? BluetoothSocket
                    socket?.connect()
                } catch (e2: Exception) {
                    try { socket?.close() } catch (_: Exception) {}
                    return false
                }
            }

            socket?.use { s ->
                val os = s.outputStream
                os.write(bytes)
                os.flush()
                Thread.sleep(150)
            }
            return true
        } catch (e: Exception) {
            return false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. App Update Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(packageName, 0)
                        }
                        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pInfo.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode.toLong()
                        }
                        val map = mapOf(
                            "packageName" to packageName,
                            "versionName" to (pInfo.versionName ?: "1.0.0"),
                            "versionCode" to versionCode
                        )
                        result.success(map)
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.message, null)
                    }
                }
                "openPlayStore" -> {
                    val targetPackage = call.argument<String>("packageName") ?: packageName
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$targetPackage")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        try {
                            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$targetPackage")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(webIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("STORE_ERROR", e2.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Bluetooth POS Printer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPairedDevices" -> {
                    Thread {
                        val list = getBondedDevices()
                        runOnUiThread { result.success(list) }
                    }.start()
                }
                "printBluetooth" -> {
                    val target = call.argument<String>("target") ?: ""
                    val bytes = call.argument<ByteArray>("bytes")
                    if (target.isEmpty() || bytes == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    Thread {
                        val success = printBluetooth(target, bytes)
                        runOnUiThread { result.success(success) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }
}
