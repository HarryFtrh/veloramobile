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

    private fun checkBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val hasConnect = checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
            if (!hasConnect) {
                requestPermissions(arrayOf(
                    android.Manifest.permission.BLUETOOTH_CONNECT,
                    android.Manifest.permission.BLUETOOTH_SCAN
                ), 101)
                return false
            }
        }
        return true
    }

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
        checkBluetoothPermissions()
        val adapter = getBluetoothAdapter() ?: return emptyList()
        if (!adapter.isEnabled) return emptyList()
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
        } catch (e: Exception) {
            // Permission or state error
        }
        return list
    }

    private fun printBluetooth(target: String, bytes: ByteArray): Map<String, Any> {
        if (!checkBluetoothPermissions()) {
            return mapOf(
                "success" to false,
                "message" to "Izin Bluetooth (BLUETOOTH_CONNECT) belum diberikan. Silakan izinkan pada dialog izin sistem."
            )
        }

        val adapter = getBluetoothAdapter()
            ?: return mapOf("success" to false, "message" to "Perangkat ini tidak memiliki modul Bluetooth.")

        if (!adapter.isEnabled) {
            return mapOf("success" to false, "message" to "Bluetooth tablet/HP sedang nonaktif. Silakan aktifkan Bluetooth Anda.")
        }

        try {
            val devices = adapter.bondedDevices
                ?: return mapOf("success" to false, "message" to "Tidak dapat mengakses daftar perangkat Bluetooth terpasang.")

            // Cocokkan alamat MAC atau nama printer (termasuk pencocokan parsial)
            val device = devices.firstOrNull {
                it.address.equals(target, ignoreCase = true) ||
                (it.name != null && it.name.equals(target, ignoreCase = true)) ||
                (it.name != null && it.name.contains(target, ignoreCase = true)) ||
                (it.name != null && target.contains(it.name, ignoreCase = true))
            } ?: return mapOf(
                "success" to false,
                "message" to "Printer '$target' tidak ditemukan di daftar Paired Bluetooth. Buka Pengaturan Bluetooth Android & pasangkan (pair) printer terlebih dahulu."
            )

            try {
                adapter.cancelDiscovery()
            } catch (_: Exception) {}

            var socket: BluetoothSocket? = null
            var lastError: Exception? = null

            // Coba 1: SPP Standard UUID
            try {
                socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                socket.connect()
            } catch (e: Exception) {
                lastError = e
                try { socket?.close() } catch (_: Exception) {}
                socket = null
            }

            // Coba 2: Insecure RFCOMM Socket
            if (socket == null) {
                try {
                    socket = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
                    socket.connect()
                } catch (e: Exception) {
                    lastError = e
                    try { socket?.close() } catch (_: Exception) {}
                    socket = null
                }
            }

            // Coba 3: Reflection Channel 1 (Sangat kompatibel untuk printer thermal POS portable)
            if (socket == null) {
                try {
                    val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    socket = m.invoke(device, 1) as? BluetoothSocket
                    socket?.connect()
                } catch (e: Exception) {
                    lastError = e
                    try { socket?.close() } catch (_: Exception) {}
                    socket = null
                }
            }

            if (socket == null) {
                return mapOf(
                    "success" to false,
                    "message" to "Gagal menghubungkan ke printer '${device.name}'. Pastikan printer dalam keadaan HIDUP dan berada dalam jangkauan: ${lastError?.message ?: ""}"
                )
            }

            socket.use { s ->
                val os = s.outputStream
                // Chunk bytes into 512-byte blocks with pacing to prevent thermal printer hardware buffer overflow
                val chunkSize = 512
                var offset = 0
                while (offset < bytes.size) {
                    val length = Math.min(chunkSize, bytes.size - offset)
                    os.write(bytes, offset, length)
                    os.flush()
                    offset += length
                    if (offset < bytes.size) {
                        Thread.sleep(15)
                    }
                }
                // Allow the physical thermal print head enough time to burn dots and feed paper before closing socket
                val drainWaitMs = if (bytes.size > 2000) 2000L else 500L
                Thread.sleep(drainWaitMs)
            }
            return mapOf("success" to true, "message" to "Berhasil mencetak ke '${device.name}'")
        } catch (e: Exception) {
            return mapOf("success" to false, "message" to "Gagal mencetak: ${e.message}")
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
                        result.success(mapOf("success" to false, "message" to "Target printer atau data cetak kosong."))
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
