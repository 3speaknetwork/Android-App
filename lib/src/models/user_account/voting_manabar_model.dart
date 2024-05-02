class VotingManabarModel {
    final int? currentMana;
    final int? lastUpdateTime;

    VotingManabarModel({
        this.currentMana,
        this.lastUpdateTime,
    });

    VotingManabarModel copyWith({
        int? currentMana,
        int? lastUpdateTime,
    }) => 
        VotingManabarModel(
            currentMana: currentMana ?? this.currentMana,
            lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
        );

    factory VotingManabarModel.fromJson(Map<String, dynamic> json) => VotingManabarModel(
        currentMana: json["current_mana"],
        lastUpdateTime: json["\"last_update_time"],
    );

    Map<String, dynamic> toJson() => {
        "current_mana": currentMana,
        "\"last_update_time": lastUpdateTime,
    };
}
