import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/screens/user_channel_screen/user_channel_screen.dart';
import 'package:acela/src/screens/user_channel_screen/user_favourite_provider.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:flutter/material.dart';

class FavouriteUsersBody extends StatelessWidget {
  const FavouriteUsersBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserFavoriteProvider dataProvider = UserFavoriteProvider();
    List items = dataProvider.getBookmarkedUsers();
    return items.isNotEmpty
        ? ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              String user = items[index];
              return Dismissible(
                key: Key(user),
                background: Center(child: Text("Delete")),
                onDismissed: (direction) {
                  dataProvider.storeLikedUserLocally(user, forceRemove: true);
                },
                child: ListTile(
                  onTap: () {
                    var screen = UserChannelScreen(owner: user);
                    var route = MaterialPageRoute(builder: (c) => screen);
                    Navigator.of(context).push(route);
                  },
                  leading: CustomCircleAvatar(
                    height: 36,
                    width: 36,
                    url: server.userOwnerThumb(user),
                  ),
                  title: Text(user),
                ),
              );
            },
          )
        : const Center(
            child: Text("No Bookmarked users found"),
          );
  }
}
