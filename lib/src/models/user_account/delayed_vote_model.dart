class DelayedVoteModel {
    final DateTime? time;
    final int? val;

    DelayedVoteModel({
        this.time,
        this.val,
    });

    DelayedVoteModel copyWith({
        DateTime? time,
        int? val,
    }) => 
        DelayedVoteModel(
            time: time ?? this.time,
            val: val ?? this.val,
        );

    factory DelayedVoteModel.fromJson(Map<String, dynamic> json) => DelayedVoteModel(
        time: json["time"] == null ? null : DateTime.parse(json["time"]),
        val: json["val"],
    );

    Map<String, dynamic> toJson() => {
        "time": time?.toIso8601String(),
        "val": val,
    };
}
