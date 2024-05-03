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
	var postPodcastHandler: ((String) -> Void)?

	var getRedirectUriHandler: ((String) -> Void)? = nil
	var getRedirectUriDataHandler: ((String) -> Void)? = nil
	var hiveUserInfoHandler: ((String) -> Void)? = nil
	var getDecryptedHASTokenHandler: ((String) -> Void)? = nil
	var voteContentHandler: ((String) -> Void)? = nil
	var commentOnContentHandler: ((String) -> Void)? = nil
	var getHtmlHandler: ((String) -> Void)? = nil
	var getProofOfPayloadHandler: ((String) -> Void)? = nil
	var getEncryptedChallengeHandler: ((String) -> Void)? = nil
	var getDecryptedChallengeHandler: ((String) -> Void)? = nil
	var doWeHavePostingAuthHandler: ((String) -> Void)? = nil
	var getAccountInfoHandler: ((String) -> Void)? = nil

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
//#if DEBUG
		if #available(iOS 16.4, *) {
			self.webView?.isInspectable = true
		}
//#endif
	}

	func getHtml(string: String, handler: @escaping (String) -> Void) {
		getHtmlHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("getHTMLStringForContent('\(string)');")
		}
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

	func voteContent(
		user: String,
		author: String,
		permlink: String,
		weight: Double,
		postingKey: String,
		hasKey: String,
		hasAuthKey: String,
		handler: @escaping (String) -> Void
	) {
		voteContentHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("voteContent('\(user)', '\(author)', '\(permlink)', \(weight), '\(postingKey)', '\(hasKey)', '\(hasAuthKey)');")
		}
	}

	func commentOnContent(
		user: String,
		author: String,
		permlink: String,
		comment: String,
		postingKey: String,
		hasKey: String,
		hasAuthKey: String,
		handler: @escaping (String) -> Void
	) {
		commentOnContentHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("commentOnContent('\(user)', '\(author)', '\(permlink)', '\(comment)', '\(postingKey)', '\(hasKey)', '\(hasAuthKey)');")
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
		newBene: String,
		language: String,
		powerUp: Bool,
		handler: @escaping (String) -> Void
	) {
		postVideoHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("newPostVideo('\(thumbnail)','\(video_v2)', '\(description)', '\(title)', '\(tags)', '\(username)', '\(permlink)', \(duration), \(size), '\(originalFilename)', '\(language)', \(firstUpload ? "true" : "false"), '\(bene)', '\(beneW)', '\(postingKey)', '\(community)', '\(ipfsHash)', '\(hasKey)', '\(hasAuthkey)', '\(newBene)', \(powerUp ? "true" : "false"));")
		}
	}

	func getProofOfPayload(username: String, password: String, proof: String, handler: @escaping (String) -> Void) {
		getProofOfPayloadHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("getProofOfPayload('\(username)','\(password)', '\(proof)');")
		}
	}

	func getEncryptedChallenge(username: String, authKey: String, handler: @escaping (String) -> Void) {
		getEncryptedChallengeHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("getEncryptedChallenge('\(username)','\(authKey)');")
		}
	}

	func getDecryptedChallenge(username: String, authKey: String, data: String, handler: @escaping (String) -> Void) {
		getDecryptedChallengeHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("getDecryptedChallenge('\(username)','\(authKey)', '\(data)');")
		}
	}

	func doWeHavePostingAuth(username: String, handler: @escaping (String) -> Void) {
		doWeHavePostingAuthHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("doWeHavePostingAuth('\(username)');")
		}
	}

	func getAccountInfo(username: String, handler: @escaping (String) -> Void) {
		getAccountInfoHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("getAccountInfo('\(username)');")
		}
	}

	func postPodcast(
		thumbnail: String,
		enclosureUrl: String,
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
		newBene: String,
		language: String,
		powerUp: Bool,
		handler: @escaping (String) -> Void
	) {
		postPodcastHandler = handler
		OperationQueue.main.addOperation {
			self.webView?.evaluateJavaScript("newPostPodcast('\(thumbnail)','\(enclosureUrl)', '\(description)', '\(title)', '\(tags)', '\(username)', '\(permlink)', \(duration), \(size), '\(originalFilename)', '\(language)', \(firstUpload ? "true" : "false"), '\(bene)', '\(beneW)', '\(postingKey)', '\(community)', '\(ipfsHash)', '\(hasKey)', '\(hasAuthkey)', '\(newBene)', \(powerUp ? "true" : "false"));")
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

	func getDecryptedHASToken(
		username: String,
		authKey: String,
		data: String,
		handler: @escaping (String) -> Void
	) {
		getDecryptedHASTokenHandler = handler
		webView?.evaluateJavaScript("getDecryptedHASToken('\(username)','\(authKey)','\(data)');")
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
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
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
			case "postAudio":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				postPodcastHandler?(response)
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
			case "getDecryptedHASToken":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getDecryptedHASTokenHandler?(response)
			case "voteContent":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				voteContentHandler?(response)
			case "commentOnContent":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				commentOnContentHandler?(response)
			case "getHTMLStringForContent":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getHtmlHandler?(response)
			case "getProofOfPayload":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getProofOfPayloadHandler?(response)
			case "getEncryptedChallenge":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getEncryptedChallengeHandler?(response)
			case "getDecryptedChallenge":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getDecryptedChallengeHandler?(response)
			case "getAccountInfo":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				getAccountInfoHandler?(response)
			case "doWeHavePostingAuth":
				guard
					let response = ValidateHiveKeyResponse.jsonStringFrom(dict: dict)
				else { return }
				doWeHavePostingAuthHandler?(response)
			default: debugPrint("Do nothing here.")
		}
	}
}
