class DownvoteManabarModel {
    final int? currentMana;
    final int? lastUpdateTime;

    DownvoteManabarModel({
        this.currentMana,
        this.lastUpdateTime,
    });

    DownvoteManabarModel copyWith({
        int? currentMana,
        int? lastUpdateTime,
    }) => 
        DownvoteManabarModel(
            currentMana: currentMana ?? this.currentMana,
            lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
        );

    factory DownvoteManabarModel.fromJson(Map<String, dynamic> json) => DownvoteManabarModel(
        currentMana: json["current_mana"],
        lastUpdateTime: json["last_update_time"],
    );

    Map<String, dynamic> toJson() => {
        "current_mana": currentMana,
        "last_update_time": lastUpdateTime,
    };
}
