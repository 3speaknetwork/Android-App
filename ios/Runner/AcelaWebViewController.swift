//
//  AcelaWebViewController.swift
//  Runner
//
//  Created by Sagar on 01/05/22.
//

import UIKit
import WebKit

class AcelaWebViewController: UIViewController {
	let acela = "acela"
	let config = WKWebViewConfiguration()
	let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
	var webView: WKWebView?
	var didFinish = false
	var postingKeyValidationHandler: ((String) -> Void)?
	var decryptTokenHandler: ((String) -> Void)?
	var postVideoHandler: ((String) -> Void)?

	var getRedirectUriHandler: ((String) -> Void)? = nil
	var getRedirectUriDataHandler: ((String) -> Void)? = nil
	var hiveUserInfoHandler: ((String) -> Void)? = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		config.userContentController.add(self, name: acela)
		webView = WKWebView(frame: rect, configuration: config)
		webView?.navigationDelegate = self
		guard
			let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "public")
		else { return }
		let dir = url.deletingLastPathComponent()
		webView?.loadFileURL(url, allowingReadAccessTo: dir)
	}

	func validatePostingKey(
		username: String,
		postingKey: String,
		handler: @escaping (String) -> Void
	) {
		postingKeyValidationHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("validateHiveKey('\(username)', '\(postingKey)');")
		}
	}

	func decryptMemo(
		username: String,
		postingKey: String,
		encryptedMemo: String,
		handler: @escaping (String) -> Void
	) {
		decryptTokenHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("decryptMemo('\(username)', '\(postingKey)', '\(encryptedMemo)');")
		}
	}

	func postVideo(
		thumbnail: String,
		video_v2: String,
		description: String,
		title: String,
		tags: String,
		username: String,
		permlink: String,
		duration: Double,
		size: Double,
		originalFilename: String,
		firstUpload: Bool,
		bene: String,
		beneW: String,
		postingKey: String,
		community: String,
		ipfsHash: String,
		hasKey: String,
		hasAuthkey: String,
		handler: @escaping (String) -> Void
	) {
		postVideoHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("newPostVideo('\(thumbnail)','\(video_v2)', '\(description)', '\(title)', '\(tags)', '\(username)', '\(permlink)', \(duration), \(size), '\(originalFilename)', 'en', \(firstUpload ? "true" : "false"), '\(bene)', '\(beneW)', '\(postingKey)', '\(community)', '\(ipfsHash)', '\(hasKey)', '\(hasAuthkey)');")
		}
	}

	func getRedirectUri(_ username: String, handler: @escaping (String) -> Void) {
		getRedirectUriHandler = handler
		webView?.evaluateJavaScript("getRedirectUri('\(username)');")
	}

	func getRedirectUriData(_ username: String, handler: @escaping (String) -> Void) {
		getRedirectUriDataHandler = handler
		webView?.evaluateJavaScript("getRedirectUriData('\(username)');")
	}

	func getUserInfo(_ handler: @escaping (String) -> Void) {
		hiveUserInfoHandler = handler
		webView?.evaluateJavaScript("getUserInfo();")
	}
}

extension AcelaWebViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		didFinish = true
	}
}

extension AcelaWebViewController: WKScriptMessageHandler {
	func userContentController(
		_ userContentController: WKUserContentController,
		didReceive message: WKScriptMessage
	) {
		guard message.name == acela else { return }
		guard let dict = message.body as? [String: AnyObject] else { return }
		guard let type = dict["type"] as? String else { return }
		switch type {
			case "validateHiveKey":
				guard
					let isValid = dict["valid"] as? Bool,
					let accountName = dict["accountName"] as? String,
					let error = dict["error"] as? String,
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				debugPrint("Is it valid? \(isValid ? "TRUE" : "FALSE")")
				debugPrint("account name is \(accountName)")
				debugPrint("Error is \(error)")
				postingKeyValidationHandler?(response)
			case "decryptedMemo":
				guard
					let accountName = dict["accountName"] as? String,
					let error = dict["error"] as? String,
					let decrypted = dict["decrypted"] as? String,
					let response = DecryptMemoResponse.jsonStringFrom(dict: dict)
				else { return }
				debugPrint("account name is \(accountName)")
				debugPrint("Error is \(error)")
				debugPrint("decrypted is \(decrypted)")
				decryptTokenHandler?(response)
			case "postVideo":
				guard
					let isValid = dict["valid"] as? Bool,
					let error = dict["error"] as? String,
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				debugPrint("Is it valid? \(isValid ? "TRUE" : "FALSE")")
				debugPrint("Error is \(error)")
				postVideoHandler?(response)
			case "hiveAuthUserInfo":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				hiveUserInfoHandler?(response)
			case "getRedirectUri":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getRedirectUriHandler?(response)
			case "getRedirectUriData":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getRedirectUriDataHandler?(response)
			default: debugPrint("Do nothing here.")
		}
	}
}
