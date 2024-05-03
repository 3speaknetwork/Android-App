//
//  AuthBridge.swift
//  Runner
//
//  Created by Sagar on 01/05/22.
//

import UIKit
import Flutter
import AVFoundation
import AVKit

class AuthBridge {
	var window: UIWindow?
	var acela: AcelaWebViewController?

	func initiate(controller: FlutterViewController, window: UIWindow?, acela: AcelaWebViewController?) {
		self.window = window
		self.acela = acela
		let authChannel = FlutterMethodChannel(
			name: "com.example.acela/auth",
			binaryMessenger: controller.binaryMessenger
		)
		authChannel.setMethodCallHandler({
			[weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
			// Note: this method is invoked on the UI thread.
			switch (call.method) {
				case "playFullscreen":
					guard
						let arguments = call.arguments as? NSDictionary,
						let stringUrl = arguments ["url"] as? String,
						let seconds = arguments ["seconds"] as? Int,
						let url = URL(string: stringUrl)
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					let myTime = CMTime(seconds: Double(seconds), preferredTimescale: 60000)
					let controller = AVPlayerViewController()
					let player = AVPlayer(url: url)
					controller.player = player
					player.seek(to: myTime, toleranceBefore: .zero, toleranceAfter: .zero)
					player.play()
					window?.rootViewController?.present(controller, animated: true)
					result("done")
				case "getHTMLStringForContent":
					guard
						let arguments = call.arguments as? NSDictionary,
						let string = arguments ["string"] as? String
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					self?.getHtml(string: string, result: result)
				case "validateHiveKey":
					guard
						let arguments = call.arguments as? NSDictionary,
						let username = arguments ["username"] as? String,
						let password = arguments["postingKey"] as? String
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					self?.authenticate(username: username, postingKey: password, result: result)
				case "encryptedToken":
					guard
						let arguments = call.arguments as? NSDictionary,
						let username = arguments ["username"] as? String,
						let password = arguments["postingKey"] as? String,
						let encryptedToken = arguments["encryptedToken"] as? String
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					self?.decryptMemo(username: username, postingKey: password, encryptedMemo: encryptedToken, result: result)
				case "getProofOfPayload":
					guard
						let arguments = call.arguments as? NSDictionary,
						let username = arguments ["username"] as? String,
						let password = arguments["postingKey"] as? String,
						let proof = arguments["proof"] as? String,
						let acela = acela
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					acela.getProofOfPayload(username: username, password: password, proof: proof) { data in
						result(data)
					}
				case "newPostPodcast":
					guard
						let arguments = call.arguments as? NSDictionary,
						let thumbnail = arguments["thumbnail"] as? String,
						let enclosureUrl = arguments["enclosureUrl"] as? String,
						let description = arguments["description"] as? String,
						let title = arguments["title"] as? String,
						let tags = arguments["tags"] as? String,
						let username = arguments["username"] as? String,
						let permlink = arguments["permlink"] as? String,
						let duration = arguments["duration"] as? Double,
						let size = arguments["size"] as? Double,
						let originalFilename = arguments["originalFilename"] as? String,
						let firstUpload = arguments["firstUpload"] as? Bool,
						let bene = arguments["bene"] as? String,
						let beneW = arguments["beneW"] as? String,
						let postingKey = arguments["postingKey"] as? String,
						let community = arguments["community"] as? String,
						let ipfsHash = arguments["ipfsHash"] as? String,
						let hasKey = arguments["hasKey"] as? String,
						let hasAuthKey = arguments["hasAuthKey"] as? String,
						let newBene = arguments["newBene"] as? String,
						let language = arguments["language"] as? String,
						let powerUp = arguments["powerUp"] as? Bool,
						let acela = acela
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					acela.postPodcast(
						thumbnail: thumbnail,
						enclosureUrl: enclosureUrl,
						description: description,
						title: title,
						tags: tags,
						username: username,
						permlink: permlink,
						duration: duration,
						size: size,
						originalFilename: originalFilename,
						firstUpload: firstUpload,
						bene: bene,
						beneW: beneW,
						postingKey: postingKey,
						community: community,
						ipfsHash: ipfsHash,
						hasKey: hasKey,
						hasAuthkey: hasAuthKey,
						newBene: newBene,
						language: language,
						powerUp: powerUp
					) { response in
						result(response)
					}
				case "newPostVideo":
					guard
						let arguments = call.arguments as? NSDictionary,
						let thumbnail = arguments["thumbnail"] as? String,
						let video_v2 = arguments["video_v2"] as? String,
						let description = arguments["description"] as? String,
						let title = arguments["title"] as? String,
						let tags = arguments["tags"] as? String,
						let username = arguments["username"] as? String,
						let permlink = arguments["permlink"] as? String,
						let duration = arguments["duration"] as? Double,
						let size = arguments["size"] as? Double,
						let originalFilename = arguments["originalFilename"] as? String,
						let firstUpload = arguments["firstUpload"] as? Bool,
						let bene = arguments["bene"] as? String,
						let beneW = arguments["beneW"] as? String,
						let postingKey = arguments["postingKey"] as? String,
						let community = arguments["community"] as? String,
						let ipfsHash = arguments["ipfsHash"] as? String,
						let hasKey = arguments["hasKey"] as? String,
						let hasAuthKey = arguments["hasAuthKey"] as? String,
						let newBene = arguments["newBene"] as? String,
						let language = arguments["language"] as? String,
						let powerUp = arguments["powerUp"] as? Bool,
						let acela = acela
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					acela.postVideo(
						thumbnail: thumbnail,
						video_v2: video_v2,
						description: description,
						title: title,
						tags: tags,
						username: username,
						permlink: permlink,
						duration: duration,
						size: size,
						originalFilename: originalFilename,
						firstUpload: firstUpload,
						bene: bene,
						beneW: beneW,
						postingKey: postingKey,
						community: community,
						ipfsHash: ipfsHash,
						hasKey: hasKey,
						hasAuthkey: hasAuthKey,
						newBene: newBene,
						language: language,
						powerUp: powerUp
					) { response in
						result(response)
					}
				case "voteContent":
					guard
						let arguments = call.arguments as? NSDictionary,
						let user = arguments["user"] as? String,
						let author = arguments["author"] as? String,
						let permlink = arguments["permlink"] as? String,
						let weight = arguments["weight"] as? Double,
						let postingKey = arguments["postingKey"] as? String,
						let hasKey = arguments["hasKey"] as? String,
						let hasAuthKey = arguments["hasAuthKey"] as? String,
						let acela = acela
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					acela.voteContent(user: user, author: author, permlink: permlink, weight: weight, postingKey: postingKey, hasKey: hasKey, hasAuthKey: hasAuthKey)  { response in
						result(response)
					}
				case "commentOnContent":
					guard
						let arguments = call.arguments as? NSDictionary,
						let user = arguments["user"] as? String,
						let author = arguments["author"] as? String,
						let permlink = arguments["permlink"] as? String,
						let comment = arguments["comment"] as? String,
						let postingKey = arguments["postingKey"] as? String,
						let hasKey = arguments["hasKey"] as? String,
						let hasAuthKey = arguments["hasAuthKey"] as? String,
						let acela = acela
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					acela.commentOnContent(user: user, author: author, permlink: permlink, comment: comment, postingKey: postingKey, hasKey: hasKey, hasAuthKey: hasAuthKey)  { response in
						result(response)
					}
				case "getAccountInfo":
					guard
						let arguments = call.arguments as? NSDictionary,
						let username = arguments["username"] as? String,
						let acela = acela
					else {
						result(FlutterMethodNotImplemented)
						return
					}
					acela.getAccountInfo(username: username)  { response in
						result(response)
					}
				default: debugPrint("do nothing")
			}
		})
	}

	private func getHtml(string: String, result: @escaping FlutterResult) {
		guard let acela = acela else {
			result(FlutterError(code: "ERROR",
													message: "Error setting up Hive",
													details: nil))
			return
		}
		acela.getHtml(string: string) { response in
			result(response)
		}
	}

	private func authenticate(username: String, postingKey: String, result: @escaping FlutterResult) {
		guard let acela = acela else {
			result(FlutterError(code: "ERROR",
													message: "Error setting up Hive",
													details: nil))
			return
		}
		acela.validatePostingKey(username: username, postingKey: postingKey) { response in
			result(response)
		}
	}

	private func decryptMemo(
		username: String,
		postingKey: String,
		encryptedMemo: String,
		result: @escaping FlutterResult
	) {
		guard let acela = acela else {
			result(FlutterError(code: "ERROR",
													message: "Error setting up Hive",
													details: nil))
			return
		}
		acela.decryptMemo(username: username, postingKey: postingKey, encryptedMemo: encryptedMemo) { response in
			result(response)
		}
	}
}
