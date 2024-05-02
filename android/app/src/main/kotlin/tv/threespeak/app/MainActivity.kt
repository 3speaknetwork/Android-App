package tv.threespeak.app

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.webkit.WebViewAssetLoader
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity;


class MainActivity : AudioServiceActivity() {
    var webView: WebView? = null
    var result: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (webView == null) {
            setupView()
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "blog.hive.auth/bridge"
        ).setMethodCallHandler { call, result ->
            this.result = result
            val username = call.argument<String>("username")
            val authKey = call.argument<String>("authKey")
            val data = call.argument<String>("data")
            if (call.method == "getRedirectUriData" && username != null) {
                webView?.evaluateJavascript("getRedirectUriData('$username');", null)
            } else if (call.method == "getDecryptedHASToken" && username != null && authKey != null && data != null) {
                webView?.evaluateJavascript("getDecryptedHASToken('$username','$authKey','$data');", null)
            } else if (call.method == "getEncryptedChallenge" && username != null && authKey != null) {
                webView?.evaluateJavascript("getEncryptedChallenge('$username','$authKey');", null)
            } else if (call.method == "getDecryptedChallenge" && username != null && authKey != null && data != null) {
                webView?.evaluateJavascript("getDecryptedChallenge('$username','$authKey', '$data');", null)
            } else if (call.method == "doWeHavePostingAuth" && username != null) {
                webView?.evaluateJavascript("doWeHavePostingAuth('$username');", null)
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.acela/auth"
        ).setMethodCallHandler { call, result ->
            this.result = result
            val username = call.argument<String?>("username")
            val postingKey = call.argument<String?>("postingKey")
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
            val hasKey = call.argument<String?>("hasKey")
            val hasAuthkey =
                call.argument<String?>("hasAuthkey") ?: call.argument<String?>("hasAuthKey")
            val user = call.argument<String?>("user")
            val author = call.argument<String?>("author")
            val weight = call.argument<Double?>("weight")
            val comment = call.argument<String?>("comment")
            val seconds = call.argument<Int?>("seconds")
            val url = call.argument<String?>("url")
            val newBene = call.argument<String?>("newBene")
            val language = call.argument<String?>("language")
            val powerUp = call.argument<Boolean?>("powerUp")
            val enclosureUrl = call.argument<String?>("enclosureUrl")
            val string = call.argument<String?>("string")
            val proof = call.argument<String?>("proof")

            val data = call.argument<String?>("data")
            if (call.method == "playFullscreen" && url != null && seconds != null) {
                val intent = Intent(this, VideoPlayerActivity::class.java)
                val bundle = Bundle()
                bundle.putString("url", url)
                bundle.putInt("seconds", seconds)
                intent.putExtras(bundle);
                startActivity(intent)
            } else if (call.method == "validateHiveKey" && username != null && postingKey != null) {
                webView?.evaluateJavascript("validateHiveKey('$username','$postingKey');", null)
            } else if (call.method == "getProofOfPayload" && username != null && postingKey != null && proof != null) {
                webView?.evaluateJavascript("getProofOfPayload('$username','$postingKey','$proof');", null)
            } else if (call.method == "getHTMLStringForContent" && string != null) {
                webView?.evaluateJavascript("getHTMLStringForContent('$string');", null)
            } else if (call.method == "encryptedToken" && username != null
                && postingKey != null && encryptedToken != null
            ) {
                webView?.evaluateJavascript(
                    "decryptMemo('$username','$postingKey', '$encryptedToken');",
                    null
                )
            } else if (call.method == "postVideo" && data != null && postingKey != null) {
                webView?.evaluateJavascript("postVideo('$data','$postingKey');", null)
            } else if (call.method == "newPostVideo" && thumbnail != null && video_v2 != null
                && description != null && title != null && tags != null && username != null
                && permlink != null && duration != null && size != null && originalFilename != null
                && firstUpload != null && bene != null && beneW != null && community != null
                && ipfsHash != null && newBene != null && language != null && powerUp != null
            ) {
                webView?.evaluateJavascript(
                    "newPostVideo('$thumbnail','$video_v2', '$description', '$title', '$tags', '$username', '$permlink', $duration, $size, '$originalFilename', '$language', $firstUpload, '$bene', '$beneW', '$postingKey', '$community', '$ipfsHash', '$hasKey', '$hasAuthkey', '$newBene', $powerUp);",
                    null
                )
            } 
            else if (call.method == "newPostPodcast" && thumbnail != null && enclosureUrl != null
                && description != null && title != null && tags != null && username != null
                && permlink != null && duration != null && size != null && originalFilename != null
                && firstUpload != null && bene != null && beneW != null && community != null
                && ipfsHash != null && newBene != null && language != null && powerUp != null
            ) {
                webView?.evaluateJavascript(
                    "newPostPodcast('$thumbnail','$enclosureUrl', '$description', '$title', '$tags', '$username', '$permlink', $duration, $size, '$originalFilename', '$language', $firstUpload, '$bene', '$beneW', '$postingKey', '$community', '$ipfsHash', '$hasKey', '$hasAuthkey', '$newBene', $powerUp);",
                    null
                )
            }
            else if (call.method == "voteContent" && user != null && author != null
                && permlink != null && weight != null && postingKey != null && hasKey != null
                && hasAuthkey != null
            ) {
                webView?.evaluateJavascript("voteContent('$user', '$author', '$permlink', $weight, '$postingKey', '$hasKey', '$hasAuthkey');", null)
            } else if (call.method == "commentOnContent" && user != null && author != null
                && permlink != null && comment != null && postingKey != null && hasKey != null
                && hasAuthkey != null
            ) {
                webView?.evaluateJavascript("commentOnContent('$user', '$author', '$permlink', '$comment', '$postingKey', '$hasKey', '$hasAuthkey');", null)
            } else if (call.method == "getAccountInfo" && username != null ) {
                    webView?.evaluateJavascript(
                        "getAccountInfo('$username');",
                        null
                    )
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
        val client: WebViewClient = object : WebViewClient() {
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
                main.result?.success(message)
            }
            JSBridgeAction.GET_REDIRECT_URI_DATA.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.DECRYPTED_MEMO.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.GET_DECRYPTED_HAS_TOKEN.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.POST_VIDEO.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.COMMENT_ON_CONTENT.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.VOTE_CONTENT.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.GET_HTML.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.POST_AUDIO.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.GET_PROOF_PAYLOAD.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.GET_ENCRYPTED_CHALLENGE.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.GET_DECRYPTED_CHALLENGE.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.DO_WE_HAVE_POSTING_AUTH.value -> {
                main.result?.success(message)
            }
            JSBridgeAction.GET_ACCOUNT_INFO.value -> {
                main.result?.success(message)
            }
        }
    }
}

data class JSEvent(
    val type: String,
)

enum class JSBridgeAction(val value: String) {
    VALIDATE_HIVE_KEY("validateHiveKey"),
    DECRYPTED_MEMO("decryptedMemo"),
    POST_VIDEO("postVideo"),
    GET_REDIRECT_URI_DATA("getRedirectUriData"),
    GET_DECRYPTED_HAS_TOKEN("getDecryptedHASToken"),
    COMMENT_ON_CONTENT("commentOnContent"),
    VOTE_CONTENT("voteContent"),
    GET_HTML("getHTMLStringForContent"),
    POST_AUDIO("postAudio"),
    GET_PROOF_PAYLOAD("getProofOfPayload"),
    GET_ENCRYPTED_CHALLENGE("getEncryptedChallenge"),
    GET_DECRYPTED_CHALLENGE("getDecryptedChallenge"),
    DO_WE_HAVE_POSTING_AUTH("doWeHavePostingAuth"),
    GET_ACCOUNT_INFO("getAccountInfo"),
}
