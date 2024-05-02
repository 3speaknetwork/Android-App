import 'dart:convert';

import 'package:acela/src/utils/safe_convert.dart';

class UserPostingJsonMetadata {
  final UserPostingJsonMetadataProfile? profile;

  UserPostingJsonMetadata({
    this.profile,
  });

  UserPostingJsonMetadata copyWith({
    UserPostingJsonMetadataProfile? profile,
  }) =>
      UserPostingJsonMetadata(
        profile: profile ?? this.profile,
      );

  factory UserPostingJsonMetadata.fromJson(Map<String, dynamic> json) =>
      UserPostingJsonMetadata(
        profile: json["profile"] == null
            ? null
            : UserPostingJsonMetadataProfile.fromJson(json["profile"]),
      );

  factory UserPostingJsonMetadata.fromRawJson(String str) =>
      UserPostingJsonMetadata.fromJson(json.decode(str));

  Map<String, dynamic> toJson() => {
        "profile": profile?.toJson(),
      };
}

class UserPostingJsonMetadataProfile {
  final String? name;
  final String? about;
  final String? coverImage;
  final String? profileImage;
  final String? website;
  final String? location;
  final String? pinned;
  final int? version;
  final bool? trail;
  final String? witnessDescription;
  final List<dynamic>? tokens;

  UserPostingJsonMetadataProfile({
    this.name,
    this.about,
    this.coverImage,
    this.profileImage,
    this.website,
    this.location,
    this.pinned,
    this.version,
    this.trail,
    this.witnessDescription,
    this.tokens,
  });

  UserPostingJsonMetadataProfile copyWith({
    String? name,
    String? about,
    String? coverImage,
    String? profileImage,
    String? website,
    String? location,
    String? pinned,
    int? version,
    bool? trail,
    String? witnessDescription,
    List<dynamic>? tokens,
  }) =>
      UserPostingJsonMetadataProfile(
        name: name ?? this.name,
        about: about ?? this.about,
        coverImage: coverImage ?? this.coverImage,
        profileImage: profileImage ?? this.profileImage,
        website: website ?? this.website,
        location: location ?? this.location,
        pinned: pinned ?? this.pinned,
        version: version ?? this.version,
        trail: trail ?? this.trail,
        witnessDescription: witnessDescription ?? this.witnessDescription,
        tokens: tokens ?? this.tokens,
      );

  factory UserPostingJsonMetadataProfile.fromJson(Map<String, dynamic> json) =>
      UserPostingJsonMetadataProfile(
        name: json["name"],
        about: json["about"],
        coverImage: json["cover_image"],
        profileImage: json["profile_image"],
        website: json["website"],
        location: json["location"],
        pinned: json["pinned"],
        version: json["version"],
        trail: json["trail"],
        witnessDescription: json["witness_description"],
        tokens: asList(json, "tokens")
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "about": about,
        "cover_image": coverImage,
        "profile_image": profileImage,
        "website": website,
        "location": location,
        "pinned": pinned,
        "version": version,
        "trail": trail,
        "witness_description": witnessDescription,
        "tokens":
            tokens == null ? [] : List<dynamic>.from(tokens!.map((x) => x)),
      };
}
