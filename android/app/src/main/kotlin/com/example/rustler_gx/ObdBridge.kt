package com.example.rustler_gx

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.util.UUID

class ObdBridge {
    companion object {
        private val SPP_UUID: UUID =
            UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private var socket: BluetoothSocket? = null
    private var input: BufferedInputStream? = null
    private var output: BufferedOutputStream? = null

    @Synchronized
    fun bondedDevices(): List<Map<String, String>> {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        return adapter.bondedDevices
            .sortedBy { it.name ?: it.address }
            .map { device ->
                mapOf(
                    "name" to (device.name ?: "Bluetooth device"),
                    "address" to device.address
                )
            }
    }

    @Synchronized
    fun connect(address: String): Map<String, Any> {
        disconnect()
        val adapter = BluetoothAdapter.getDefaultAdapter()
            ?: return mapOf("connected" to false, "error" to "Bluetooth unavailable")
        if (!adapter.isEnabled) {
            return mapOf("connected" to false, "error" to "Bluetooth is off")
        }

        return try {
            adapter.cancelDiscovery()
            val device: BluetoothDevice = adapter.getRemoteDevice(address)
            val newSocket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            newSocket.connect()
            socket = newSocket
            input = BufferedInputStream(newSocket.inputStream)
            output = BufferedOutputStream(newSocket.outputStream)

            command("ATZ", 2500)
            command("ATE0")
            command("ATL0")
            command("ATS0")
            command("ATH0")
            command("ATAT1")
            command("ATSP0", 1600)
            command("0100", 1800)

            mapOf(
                "connected" to true,
                "name" to (device.name ?: "OBD adapter"),
                "address" to address
            )
        } catch (error: Throwable) {
            disconnect()
            mapOf(
                "connected" to false,
                "error" to (error.message ?: error.javaClass.simpleName)
            )
        }
    }

    @Synchronized
    fun isConnected(): Boolean = socket?.isConnected == true

    @Synchronized
    fun query(command: String): String {
        if (!isConnected()) throw IllegalStateException("OBD adapter not connected")
        return command(command.trim().uppercase())
    }

    @Synchronized
    fun disconnect() {
        try { input?.close() } catch (_: Throwable) {}
        try { output?.close() } catch (_: Throwable) {}
        try { socket?.close() } catch (_: Throwable) {}
        input = null
        output = null
        socket = null
    }

    private fun command(command: String, timeoutMs: Long = 1000): String {
        val out = output ?: throw IllegalStateException("OBD output unavailable")
        val source = input ?: throw IllegalStateException("OBD input unavailable")

        while (source.available() > 0) source.read()
        out.write((command + "\r").toByteArray(Charsets.US_ASCII))
        out.flush()

        val deadline = System.currentTimeMillis() + timeoutMs
        val builder = StringBuilder()
        while (System.currentTimeMillis() < deadline) {
            while (source.available() > 0) {
                val value = source.read()
                if (value < 0) break
                val char = value.toChar()
                if (char == '>') return clean(builder.toString(), command)
                builder.append(char)
            }
            Thread.sleep(8)
        }
        return clean(builder.toString(), command)
    }

    private fun clean(raw: String, command: String): String {
        return raw
            .replace("\u0000", "")
            .replace("\r", " ")
            .replace("\n", " ")
            .replace(command, "", ignoreCase = true)
            .replace(Regex("\\s+"), " ")
            .trim()
    }
}
