package com.example.acela

import android.annotation.SuppressLint
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import android.webkit.WebView
import android.webkit.WebViewClient
import android.content.Context
import com.google.gson.Gson

import android.annotation.TargetApi
import android.app.Activity
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.widget.FrameLayout
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import android.net.Uri
import android.util.Log
import android.webkit.ValueCallback
import android.webkit.WebResourceResponse
import androidx.annotation.RequiresApi
import androidx.webkit.WebViewAssetLoader
import android.webkit.WebChromeClient




class MainActivity: FlutterActivity() {
    var webView: WebView? = null
    var result: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (webView == null) {
            setupView()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.acela/auth").setMethodCallHandler {
                call, result ->
            this.result = result
            val username = call.argument<String>("username")
            val postingKey = call.argument<String>("postingKey")
            val params = call.argument<String>("params")
            val encryptedToken = call.argument<String?>("encryptedToken")

            val thumbnail = call.argument<String?>("thumbnail")
            val video_v2 = call.argument<String?>("video_v2")
            val description = call.argument<String?>("description")
            val title = call.argument<String?>("title")
            val tags = call.argument<String?>("tags")
            val permlink = call.argument<String?>("permlink")
            val duration = call.argument<Double?>("duration")
            val size = call.argument<Int?>("size")
            val originalFilename = call.argument<String?>("originalFilename")
            val firstUpload = call.argument<Boolean?>("firstUpload")
            val bene = call.argument<String?>("bene")
            val beneW = call.argument<String?>("beneW")
            val community = call.argument<String?>("community")
            val ipfsHash = call.argument<String?>("ipfsHash")

            val data = call.argument<String?>("data")
            if (call.method == "validate" && username != null && postingKey != null) {
                webView?.evaluateJavascript("validateHiveKey('$username','$postingKey');", null)
            } else if (call.method == "encryptedToken" && username != null
                && postingKey != null && encryptedToken != null) {
                webView?.evaluateJavascript("decryptMemo('$username','$postingKey', '$encryptedToken');", null)
            } else if (call.method == "postVideo" && data != null && postingKey != null ) {
                webView?.evaluateJavascript("postVideo('$data','$postingKey');", null)
            } else if (call.method == "newPostVideo" && thumbnail != null && video_v2 != null
                && description != null && title != null && tags != null && username != null
                && permlink != null && duration != null && size != null && originalFilename != null
                && firstUpload != null && bene != null && beneW != null && community != null && ipfsHash != null) {
                webView?.evaluateJavascript("newPostVideo('$thumbnail','$video_v2', '$description', '$title', '$tags', '$username', '$permlink', $duration, $size, '$originalFilename', 'en', $firstUpload, '$bene', '$beneW', '$postingKey', '$community', '$ipfsHash');", null)
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupView() {
        val params = FrameLayout.LayoutParams(0, 0)
        webView = WebView(activity)
        val decorView = activity.window.decorView as FrameLayout
        decorView.addView(webView, params)
        webView?.visibility = View.GONE
        webView?.settings?.javaScriptEnabled = true
        webView?.settings?.domStorageEnabled = true
//        webView?.webChromeClient = WebChromeClient()
        WebView.setWebContentsDebuggingEnabled(true)
        val assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()
        val client: WebViewClient = object: WebViewClient() {
            @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? {
                return assetLoader.shouldInterceptRequest(request.url)
            }

            override fun shouldInterceptRequest(
                view: WebView,
                url: String
            ): WebResourceResponse? {
                return assetLoader.shouldInterceptRequest(Uri.parse(url))
            }
        }
        webView?.webViewClient = client
        webView?.addJavascriptInterface(WebAppInterface(this), "Android")
        webView?.loadUrl("https://appassets.androidplatform.net/assets/index.html")
    }
}

class WebAppInterface(private val mContext: Context) {
    @JavascriptInterface
    fun postMessage(message: String) {
        val main = mContext as? MainActivity ?: return
        val gson = Gson()
        val dataObject = gson.fromJson(message, JSEvent::class.java)
        when (dataObject.type) {
            JSBridgeAction.VALIDATE_HIVE_KEY.value -> {
                // now respond back to flutter
                main.result?.success(message)
            }
            JSBridgeAction.DECRYPTED_MEMO.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.POST_VIDEO.value -> {
                main.result?.success(message)
            }
        }
    }
}

data class JSEvent (
    val type: String,
)

enum class JSBridgeAction(val value: String) {
    VALIDATE_HIVE_KEY("validateHiveKey"),
    DECRYPTED_MEMO("decryptedMemo"),
    POST_VIDEO("postVideo")
}
