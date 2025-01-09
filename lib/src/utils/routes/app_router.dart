import 'package:acela/src/models/navigation_models/new_video_detail_screen_navigation_model.dart';
import 'package:acela/src/screens/home_screen/default_screen.dart';
import 'package:acela/src/screens/policy_aggrement/policy_repo/policy_repo.dart';
import 'package:acela/src/screens/policy_aggrement/presentation/policy_aggrement_view.dart';
import 'package:acela/src/screens/user_channel_screen/user_channel_screen.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/new_video_details_screen.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter router = GoRouter(routes: routes());

  static List<RouteBase> routes() {
    // PolicyRepo().writePolicyStatus(false);
    return [
      GoRoute(
        path: '/',
        name: Routes.initialView,
        builder: (context, state) => DefaultView(),
        redirect: (context, state) =>
            PolicyRepo().isPolicyTermsAccepted() ? null : "/policy",
      ),
      GoRoute(
          path: '/policy',
          name: Routes.policyView,
          builder: (context, state) => PolicyAggrementView()),
      GoRoute(
        path: '/${Routes.videoDetailsView}/:author/:permlink',
        name: Routes.videoDetailsView,
        builder: (context, state) {
          NewVideoDetailScreenNavigationParameter? parameters =
              (state.extra) as NewVideoDetailScreenNavigationParameter?;
          return NewVideoDetailsScreen(
            item: parameters?.item,
            onPop: parameters?.onPop,
            betterPlayerController: parameters?.betterPlayerController,
            author: state.pathParameters['author']!,
            permlink: state.pathParameters['permlink']!,
          );
        },
        redirect: (context, state) {
          final author = state.pathParameters['author'];
          final permlink = state.pathParameters['permlink'];
          if (author == null || permlink == null) {
            return '/';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/${Routes.userView}/:author',
        name: Routes.userView,
        builder: (context, state) {
          return UserChannelScreen(
            owner: state.pathParameters['author']!,
            onPop: (state.extra) as VoidCallback?,
          );
        },
        redirect: (context, state) {
          final author = state.pathParameters['author'];
          if (author == null) {
            return '/';
          }
          return null;
        },
      ),
    ];
  }
}
