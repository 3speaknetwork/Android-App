import 'dart:convert';

import 'package:acela/src/models/user_account/active_model.dart';
import 'package:acela/src/models/user_account/delayed_vote_model.dart';
import 'package:acela/src/models/user_account/downvote_manarbar_model.dart';
import 'package:acela/src/models/user_account/posting_json_meta_data.dart';
import 'package:acela/src/models/user_account/voting_manabar_model.dart';
import 'package:acela/src/utils/safe_convert.dart';

List<UserModel> userModelFromJson(String str) =>
    List<UserModel>.from(json.decode(str).map((x) => UserModel.fromJson(x)));

String userModelToJson(List<UserModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UserModel {
  final ActiveModel? active;
  final String balance;
  final bool? canVote;
  final int? commentCount;
  final DateTime created;
  final int? curationRewards;
  final List<DelayedVoteModel>? delayedVotes;
  final String? delegatedVestingShares;
  final DownvoteManabarModel? downvoteManabar;
  final DateTime? governanceVoteExpirationTs;
  final List<dynamic>? guestBloggers;
  final String hbdBalance;
  final DateTime? hbdLastInterestPayment;
  final String? hbdSeconds;
  final DateTime? hbdSecondsLastUpdate;
  final int id;
  final String? jsonMetadata;
  final DateTime? lastAccountRecovery;
  final DateTime? lastAccountUpdate;
  final DateTime? lastOwnerUpdate;
  final DateTime? lastPost;
  final DateTime? lastRootPost;
  final DateTime? lastVoteTime;
  final int? lifetimeVoteCount;
  final List<dynamic>? marketHistory;
  final String? memoKey;
  final bool? mined;
  final String name;
  final DateTime? nextVestingWithdrawal;
  final int? openRecurrentTransfers;
  final List<dynamic>? otherHistory;
  final ActiveModel? owner;
  final int? pendingClaimedAccounts;
  final int? pendingTransfers;
  final int? postBandwidth;
  final int? postCount;
  final List<dynamic>? postHistory;
  final String? postVotingPower;
  final ActiveModel? posting;
  final UserPostingJsonMetadata? postingJsonMetadata;
  final int? postingRewards;
  final DateTime? previousOwnerUpdate;
  final List<int>? proxiedVsfVotes;
  final String? proxy;
  final String? receivedVestingShares;
  final String? recoveryAccount;
  final int? reputation;
  final String? resetAccount;
  final String? rewardHbdBalance;
  final String? rewardHiveBalance;
  final String? rewardVestingBalance;
  final String? rewardVestingHive;
  final String? savingsBalance;
  final String? savingsHbdBalance;
  final DateTime? savingsHbdLastInterestPayment;
  final String? savingsHbdSeconds;
  final DateTime? savingsHbdSecondsLastUpdate;
  final int? savingsWithdrawRequests;
  final List<dynamic>? tagsUsage;
  final int? toWithdraw;
  final List<dynamic>? transferHistory;
  final String? vestingBalance;
  final String? vestingShares;
  final String? vestingWithdrawRate;
  final List<dynamic>? voteHistory;
  final VotingManabarModel? votingManabar;
  final int? votingPower;
  final int? withdrawRoutes;
  final int? withdrawn;
  final List<String>? witnessVotes;
  final int? witnessesVotedFor;

  UserModel({
    this.active,
    required this.balance,
    this.canVote,
    this.commentCount,
    required this.created,
    this.curationRewards,
    this.delayedVotes,
    this.delegatedVestingShares,
    this.downvoteManabar,
    this.governanceVoteExpirationTs,
    this.guestBloggers,
    required this.hbdBalance,
    this.hbdLastInterestPayment,
    this.hbdSeconds,
    this.hbdSecondsLastUpdate,
    required this.id,
    this.jsonMetadata,
    this.lastAccountRecovery,
    this.lastAccountUpdate,
    this.lastOwnerUpdate,
    this.lastPost,
    this.lastRootPost,
    this.lastVoteTime,
    this.lifetimeVoteCount,
    this.marketHistory,
    this.memoKey,
    this.mined,
    required this.name,
    this.nextVestingWithdrawal,
    this.openRecurrentTransfers,
    this.otherHistory,
    this.owner,
    this.pendingClaimedAccounts,
    this.pendingTransfers,
    this.postBandwidth,
    this.postCount,
    this.postHistory,
    this.postVotingPower,
    this.posting,
    this.postingJsonMetadata,
    this.postingRewards,
    this.previousOwnerUpdate,
    this.proxiedVsfVotes,
    this.proxy,
    this.receivedVestingShares,
    this.recoveryAccount,
    this.reputation,
    this.resetAccount,
    this.rewardHbdBalance,
    this.rewardHiveBalance,
    this.rewardVestingBalance,
    this.rewardVestingHive,
    this.savingsBalance,
    this.savingsHbdBalance,
    this.savingsHbdLastInterestPayment,
    this.savingsHbdSeconds,
    this.savingsHbdSecondsLastUpdate,
    this.savingsWithdrawRequests,
    this.tagsUsage,
    this.toWithdraw,
    this.transferHistory,
    this.vestingBalance,
    this.vestingShares,
    this.vestingWithdrawRate,
    this.voteHistory,
    this.votingManabar,
    this.votingPower,
    this.withdrawRoutes,
    this.withdrawn,
    this.witnessVotes,
    this.witnessesVotedFor,
  });

  bool hasThreeSpeakPostingAuthority() {
    if (posting != null &&
        posting!.accountAuths != null &&
        posting!.accountAuths!.isNotEmpty) {
      for (List? item in posting!.accountAuths!) {
        if (item != null && item.isNotEmpty && item.first == "threespeak") {
          return true;
        }
      }
    }
    return false;
  }

  double _vestingToDouble(String? arg) {
    double? value = 0;
    String result = arg ?? "";
    if (result.isNotEmpty) {
      int index = result.indexOf(" ");
      value = double.tryParse(result.substring(0, index));
    }
    return value ?? 0;
  }

  double get delegatedVestingSharesValue =>
      _vestingToDouble(delegatedVestingShares);

  double get receivedVestingSharesValue =>
      _vestingToDouble(receivedVestingShares);

  double get vestingSharesValue => _vestingToDouble(vestingShares);

  UserModel copyWith({
    ActiveModel? active,
    String? balance,
    bool? canVote,
    int? commentCount,
    DateTime? created,
    int? curationRewards,
    List<DelayedVoteModel>? delayedVotes,
    String? delegatedVestingShares,
    DownvoteManabarModel? downvoteManabar,
    DateTime? governanceVoteExpirationTs,
    List<dynamic>? guestBloggers,
    String? hbdBalance,
    DateTime? hbdLastInterestPayment,
    String? hbdSeconds,
    DateTime? hbdSecondsLastUpdate,
    int? id,
    String? jsonMetadata,
    DateTime? lastAccountRecovery,
    DateTime? lastAccountUpdate,
    DateTime? lastOwnerUpdate,
    DateTime? lastPost,
    DateTime? lastRootPost,
    DateTime? lastVoteTime,
    int? lifetimeVoteCount,
    List<dynamic>? marketHistory,
    String? memoKey,
    bool? mined,
    String? name,
    DateTime? nextVestingWithdrawal,
    int? openRecurrentTransfers,
    List<dynamic>? otherHistory,
    ActiveModel? owner,
    int? pendingClaimedAccounts,
    int? pendingTransfers,
    int? postBandwidth,
    int? postCount,
    List<dynamic>? postHistory,
    String? postVotingPower,
    ActiveModel? posting,
    UserPostingJsonMetadata? postingJsonMetadata,
    int? postingRewards,
    DateTime? previousOwnerUpdate,
    List<int>? proxiedVsfVotes,
    String? proxy,
    String? receivedVestingShares,
    String? recoveryAccount,
    int? reputation,
    String? resetAccount,
    String? rewardHbdBalance,
    String? rewardHiveBalance,
    String? rewardVestingBalance,
    String? rewardVestingHive,
    String? savingsBalance,
    String? savingsHbdBalance,
    DateTime? savingsHbdLastInterestPayment,
    String? savingsHbdSeconds,
    DateTime? savingsHbdSecondsLastUpdate,
    int? savingsWithdrawRequests,
    List<dynamic>? tagsUsage,
    int? toWithdraw,
    List<dynamic>? transferHistory,
    String? vestingBalance,
    String? vestingShares,
    String? vestingWithdrawRate,
    List<dynamic>? voteHistory,
    VotingManabarModel? votingManabar,
    int? votingPower,
    int? withdrawRoutes,
    int? withdrawn,
    List<String>? witnessVotes,
    int? witnessesVotedFor,
  }) =>
      UserModel(
        active: active ?? this.active,
        balance: balance ?? this.balance,
        canVote: canVote ?? this.canVote,
        commentCount: commentCount ?? this.commentCount,
        created: created ?? this.created,
        curationRewards: curationRewards ?? this.curationRewards,
        delayedVotes: delayedVotes ?? this.delayedVotes,
        delegatedVestingShares:
            delegatedVestingShares ?? this.delegatedVestingShares,
        downvoteManabar: downvoteManabar ?? this.downvoteManabar,
        governanceVoteExpirationTs:
            governanceVoteExpirationTs ?? this.governanceVoteExpirationTs,
        guestBloggers: guestBloggers ?? this.guestBloggers,
        hbdBalance: hbdBalance ?? this.hbdBalance,
        hbdLastInterestPayment:
            hbdLastInterestPayment ?? this.hbdLastInterestPayment,
        hbdSeconds: hbdSeconds ?? this.hbdSeconds,
        hbdSecondsLastUpdate: hbdSecondsLastUpdate ?? this.hbdSecondsLastUpdate,
        id: id ?? this.id,
        jsonMetadata: jsonMetadata ?? this.jsonMetadata,
        lastAccountRecovery: lastAccountRecovery ?? this.lastAccountRecovery,
        lastAccountUpdate: lastAccountUpdate ?? this.lastAccountUpdate,
        lastOwnerUpdate: lastOwnerUpdate ?? this.lastOwnerUpdate,
        lastPost: lastPost ?? this.lastPost,
        lastRootPost: lastRootPost ?? this.lastRootPost,
        lastVoteTime: lastVoteTime ?? this.lastVoteTime,
        lifetimeVoteCount: lifetimeVoteCount ?? this.lifetimeVoteCount,
        marketHistory: marketHistory ?? this.marketHistory,
        memoKey: memoKey ?? this.memoKey,
        mined: mined ?? this.mined,
        name: name ?? this.name,
        nextVestingWithdrawal:
            nextVestingWithdrawal ?? this.nextVestingWithdrawal,
        openRecurrentTransfers:
            openRecurrentTransfers ?? this.openRecurrentTransfers,
        otherHistory: otherHistory ?? this.otherHistory,
        owner: owner ?? this.owner,
        pendingClaimedAccounts:
            pendingClaimedAccounts ?? this.pendingClaimedAccounts,
        pendingTransfers: pendingTransfers ?? this.pendingTransfers,
        postBandwidth: postBandwidth ?? this.postBandwidth,
        postCount: postCount ?? this.postCount,
        postHistory: postHistory ?? this.postHistory,
        postVotingPower: postVotingPower ?? this.postVotingPower,
        posting: posting ?? this.posting,
        postingJsonMetadata: postingJsonMetadata ?? this.postingJsonMetadata,
        postingRewards: postingRewards ?? this.postingRewards,
        previousOwnerUpdate: previousOwnerUpdate ?? this.previousOwnerUpdate,
        proxiedVsfVotes: proxiedVsfVotes ?? this.proxiedVsfVotes,
        proxy: proxy ?? this.proxy,
        receivedVestingShares:
            receivedVestingShares ?? this.receivedVestingShares,
        recoveryAccount: recoveryAccount ?? this.recoveryAccount,
        reputation: reputation ?? this.reputation,
        resetAccount: resetAccount ?? this.resetAccount,
        rewardHbdBalance: rewardHbdBalance ?? this.rewardHbdBalance,
        rewardHiveBalance: rewardHiveBalance ?? this.rewardHiveBalance,
        rewardVestingBalance: rewardVestingBalance ?? this.rewardVestingBalance,
        rewardVestingHive: rewardVestingHive ?? this.rewardVestingHive,
        savingsBalance: savingsBalance ?? this.savingsBalance,
        savingsHbdBalance: savingsHbdBalance ?? this.savingsHbdBalance,
        savingsHbdLastInterestPayment:
            savingsHbdLastInterestPayment ?? this.savingsHbdLastInterestPayment,
        savingsHbdSeconds: savingsHbdSeconds ?? this.savingsHbdSeconds,
        savingsHbdSecondsLastUpdate:
            savingsHbdSecondsLastUpdate ?? this.savingsHbdSecondsLastUpdate,
        savingsWithdrawRequests:
            savingsWithdrawRequests ?? this.savingsWithdrawRequests,
        tagsUsage: tagsUsage ?? this.tagsUsage,
        toWithdraw: toWithdraw ?? this.toWithdraw,
        transferHistory: transferHistory ?? this.transferHistory,
        vestingBalance: vestingBalance ?? this.vestingBalance,
        vestingShares: vestingShares ?? this.vestingShares,
        vestingWithdrawRate: vestingWithdrawRate ?? this.vestingWithdrawRate,
        voteHistory: voteHistory ?? this.voteHistory,
        votingManabar: votingManabar ?? this.votingManabar,
        votingPower: votingPower ?? this.votingPower,
        withdrawRoutes: withdrawRoutes ?? this.withdrawRoutes,
        withdrawn: withdrawn ?? this.withdrawn,
        witnessVotes: witnessVotes ?? this.witnessVotes,
        witnessesVotedFor: witnessesVotedFor ?? this.witnessesVotedFor,
      );

  String? get location {
    return postingJsonMetadata?.profile?.location;
  }

  String? get website {
    return postingJsonMetadata?.profile?.website;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        active: json["active"] == null
            ? null
            : ActiveModel.fromJson(json["active"]),
        balance: asString(json, "balance"),
        canVote: json["can_vote"],
        commentCount: json["comment_count"],
        created: DateTime.parse(json["created"]),
        curationRewards: json["curation_rewards"],
        delayedVotes: json["delayed_votes"] == null
            ? []
            : List<DelayedVoteModel>.from(json["delayed_votes"]!
                .map((x) => DelayedVoteModel.fromJson(x))),
        delegatedVestingShares: json["delegated_vesting_shares"],
        downvoteManabar: json["downvote_manabar"] == null
            ? null
            : DownvoteManabarModel.fromJson(json["downvote_manabar"]),
        governanceVoteExpirationTs:
            json["governance_vote_expiration_ts"] == null
                ? null
                : DateTime.parse(json["governance_vote_expiration_ts"]),
        guestBloggers: json["guest_bloggers"] == null
            ? []
            : List<dynamic>.from(json["guest_bloggers"]!.map((x) => x)),
        hbdBalance: asString(json, "hbd_balance"),
        hbdLastInterestPayment: json["hbd_last_interest_payment"] == null
            ? null
            : DateTime.parse(json["hbd_last_interest_payment"]),
        hbdSeconds: json["hbd_seconds"],
        hbdSecondsLastUpdate: json["hbd_seconds_last_update"] == null
            ? null
            : DateTime.parse(json["hbd_seconds_last_update"]),
        id: json["id"],
        jsonMetadata: json["json_metadata"],
        lastAccountRecovery: json["last_account_recovery"] == null
            ? null
            : DateTime.parse(json["last_account_recovery"]),
        lastAccountUpdate: json["last_account_update"] == null
            ? null
            : DateTime.parse(json["last_account_update"]),
        lastOwnerUpdate: json["last_owner_update"] == null
            ? null
            : DateTime.parse(json["last_owner_update"]),
        lastPost: json["last_post"] == null
            ? null
            : DateTime.parse(json["last_post"]),
        lastRootPost: json["last_root_post"] == null
            ? null
            : DateTime.parse(json["last_root_post"]),
        lastVoteTime: json["last_vote_time"] == null
            ? null
            : DateTime.parse(json["last_vote_time"]),
        lifetimeVoteCount: json["lifetime_vote_count"],
        marketHistory: json["market_history"] == null
            ? []
            : List<dynamic>.from(json["market_history"]!.map((x) => x)),
        memoKey: json["memo_key"],
        mined: json["mined"],
        name: json["name"],
        nextVestingWithdrawal: json["next_vesting_withdrawal"] == null
            ? null
            : DateTime.parse(json["next_vesting_withdrawal"]),
        openRecurrentTransfers: json["open_recurrent_transfers"],
        otherHistory: json["other_history"] == null
            ? []
            : List<dynamic>.from(json["other_history"]!.map((x) => x)),
        owner:
            json["owner"] == null ? null : ActiveModel.fromJson(json["owner"]),
        pendingClaimedAccounts: json["pending_claimed_accounts"],
        pendingTransfers: json["pending_transfers"],
        postBandwidth: json["post_bandwidth"],
        postCount: json["post_count"],
        postHistory: json["post_history"] == null
            ? []
            : List<dynamic>.from(json["post_history"]!.map((x) => x)),
        postVotingPower: json["post_voting_power"],
        posting: json["posting"] == null
            ? null
            : ActiveModel.fromJson(json["posting"]),
        postingJsonMetadata: json["posting_json_metadata"].isNotEmpty
            ? UserPostingJsonMetadata.fromRawJson(json["posting_json_metadata"])
            : null,
        postingRewards: json["posting_rewards"],
        previousOwnerUpdate: json["previous_owner_update"] == null
            ? null
            : DateTime.parse(json["previous_owner_update"]),
        proxiedVsfVotes: json["proxied_vsf_votes"] == null
            ? []
            : List<int>.from(json["proxied_vsf_votes"]!.map((x) {
                if (x is String) {
                  return int.parse(x);
                } else {
                  return x;
                }
              })),
        proxy: json["proxy"],
        receivedVestingShares: json["received_vesting_shares"],
        recoveryAccount: json["recovery_account"],
        reputation: json["reputation"],
        resetAccount: json["reset_account"],
        rewardHbdBalance: json["reward_hbd_balance"],
        rewardHiveBalance: json["reward_hive_balance"],
        rewardVestingBalance: json["reward_vesting_balance"],
        rewardVestingHive: json["reward_vesting_hive"],
        savingsBalance: json["savings_balance"],
        savingsHbdBalance: json["savings_hbd_balance"],
        savingsHbdLastInterestPayment:
            json["savings_hbd_last_interest_payment"] == null
                ? null
                : DateTime.parse(json["savings_hbd_last_interest_payment"]),
        savingsHbdSeconds: json["savings_hbd_seconds"],
        savingsHbdSecondsLastUpdate:
            json["savings_hbd_seconds_last_update"] == null
                ? null
                : DateTime.parse(json["savings_hbd_seconds_last_update"]),
        savingsWithdrawRequests: json["savings_withdraw_requests"],
        tagsUsage: json["tags_usage"] == null
            ? []
            : List<dynamic>.from(json["tags_usage"]!.map((x) => x)),
        toWithdraw: json["to_withdraw"],
        transferHistory: json["transfer_history"] == null
            ? []
            : List<dynamic>.from(json["transfer_history"]!.map((x) => x)),
        vestingBalance: json["vesting_balance"],
        vestingShares: json["vesting_shares"],
        vestingWithdrawRate: json["vesting_withdraw_rate"],
        voteHistory: json["vote_history"] == null
            ? []
            : List<dynamic>.from(json["vote_history"]!.map((x) => x)),
        votingManabar: json["voting_manabar"] == null
            ? null
            : VotingManabarModel.fromJson(json["voting_manabar"]),
        votingPower: json["voting_power"],
        withdrawRoutes: json["withdraw_routes"],
        withdrawn: json["withdrawn"],
        witnessVotes: json["witness_votes"] == null
            ? []
            : List<String>.from(json["witness_votes"]!.map((x) => x)),
        witnessesVotedFor: json["witnesses_voted_for"],
      );

  Map<String, dynamic> toJson() => {
        "active": active?.toJson(),
        "balance": balance,
        "can_vote": canVote,
        "comment_count": commentCount,
        "created": created.toIso8601String(),
        "curation_rewards": curationRewards,
        "delayed_votes": delayedVotes == null
            ? []
            : List<dynamic>.from(delayedVotes!.map((x) => x.toJson())),
        "delegated_vesting_shares": delegatedVestingShares,
        "downvote_manabar": downvoteManabar?.toJson(),
        "governance_vote_expiration_ts":
            governanceVoteExpirationTs?.toIso8601String(),
        "guest_bloggers": guestBloggers == null
            ? []
            : List<dynamic>.from(guestBloggers!.map((x) => x)),
        "hbd_balance": hbdBalance,
        "hbd_last_interest_payment": hbdLastInterestPayment?.toIso8601String(),
        "hbd_seconds": hbdSeconds,
        "hbd_seconds_last_update": hbdSecondsLastUpdate?.toIso8601String(),
        "id": id,
        "json_metadata": jsonMetadata,
        "last_account_recovery": lastAccountRecovery?.toIso8601String(),
        "last_account_update": lastAccountUpdate?.toIso8601String(),
        "last_owner_update": lastOwnerUpdate?.toIso8601String(),
        "last_post": lastPost?.toIso8601String(),
        "last_root_post": lastRootPost?.toIso8601String(),
        "last_vote_time": lastVoteTime?.toIso8601String(),
        "lifetime_vote_count": lifetimeVoteCount,
        "market_history": marketHistory == null
            ? []
            : List<dynamic>.from(marketHistory!.map((x) => x)),
        "memo_key": memoKey,
        "mined": mined,
        "name": name,
        "next_vesting_withdrawal": nextVestingWithdrawal?.toIso8601String(),
        "open_recurrent_transfers": openRecurrentTransfers,
        "other_history": otherHistory == null
            ? []
            : List<dynamic>.from(otherHistory!.map((x) => x)),
        "owner": owner?.toJson(),
        "pending_claimed_accounts": pendingClaimedAccounts,
        "pending_transfers": pendingTransfers,
        "post_bandwidth": postBandwidth,
        "post_count": postCount,
        "post_history": postHistory == null
            ? []
            : List<dynamic>.from(postHistory!.map((x) => x)),
        "post_voting_power": postVotingPower,
        "posting": posting?.toJson(),
        "posting_json_metadata": postingJsonMetadata?.toJson(),
        "posting_rewards": postingRewards,
        "previous_owner_update": previousOwnerUpdate?.toIso8601String(),
        "proxied_vsf_votes": proxiedVsfVotes == null
            ? []
            : List<dynamic>.from(proxiedVsfVotes!.map((x) => x)),
        "proxy": proxy,
        "received_vesting_shares": receivedVestingShares,
        "recovery_account": recoveryAccount,
        "reputation": reputation,
        "reset_account": resetAccount,
        "reward_hbd_balance": rewardHbdBalance,
        "reward_hive_balance": rewardHiveBalance,
        "reward_vesting_balance": rewardVestingBalance,
        "reward_vesting_hive": rewardVestingHive,
        "savings_balance": savingsBalance,
        "savings_hbd_balance": savingsHbdBalance,
        "savings_hbd_last_interest_payment":
            savingsHbdLastInterestPayment?.toIso8601String(),
        "savings_hbd_seconds": savingsHbdSeconds,
        "savings_hbd_seconds_last_update":
            savingsHbdSecondsLastUpdate?.toIso8601String(),
        "savings_withdraw_requests": savingsWithdrawRequests,
        "tags_usage": tagsUsage == null
            ? []
            : List<dynamic>.from(tagsUsage!.map((x) => x)),
        "to_withdraw": toWithdraw,
        "transfer_history": transferHistory == null
            ? []
            : List<dynamic>.from(transferHistory!.map((x) => x)),
        "vesting_balance": vestingBalance,
        "vesting_shares": vestingShares,
        "vesting_withdraw_rate": vestingWithdrawRate,
        "vote_history": voteHistory == null
            ? []
            : List<dynamic>.from(voteHistory!.map((x) => x)),
        "voting_manabar": votingManabar?.toJson(),
        "voting_power": votingPower,
        "withdraw_routes": withdrawRoutes,
        "withdrawn": withdrawn,
        "witness_votes": witnessVotes == null
            ? []
            : List<dynamic>.from(witnessVotes!.map((x) => x)),
        "witnesses_voted_for": witnessesVotedFor,
      };
}
