class ActiveModel {
    final List<List<dynamic>>? accountAuths;
    final List<List<dynamic>>? keyAuths;
    final int? weightThreshold;

    ActiveModel({
        this.accountAuths,
        this.keyAuths,
        this.weightThreshold,
    });

    ActiveModel copyWith({
        List<List<dynamic>>? accountAuths,
        List<List<dynamic>>? keyAuths,
        int? weightThreshold,
    }) => 
        ActiveModel(
            accountAuths: accountAuths ?? this.accountAuths,
            keyAuths: keyAuths ?? this.keyAuths,
            weightThreshold: weightThreshold ?? this.weightThreshold,
        );

    factory ActiveModel.fromJson(Map<String, dynamic> json) => ActiveModel(
        accountAuths: json["account_auths"] == null ? [] : List<List<dynamic>>.from(json["account_auths"]!.map((x) => List<dynamic>.from(x.map((x) => x)))),
        keyAuths: json["key_auths"] == null ? [] : List<List<dynamic>>.from(json["key_auths"]!.map((x) => List<dynamic>.from(x.map((x) => x)))),
        weightThreshold: json["weight_threshold"],
    );

    Map<String, dynamic> toJson() => {
        "account_auths": accountAuths == null ? [] : List<dynamic>.from(accountAuths!.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "key_auths": keyAuths == null ? [] : List<dynamic>.from(keyAuths!.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "weight_threshold": weightThreshold,
    };
}
