import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/screens/my_account/update_video/add_bene_sheet.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/user_profile_image.dart';
import 'package:flutter/material.dart';

class BeneficiariesTile extends StatefulWidget {
  const BeneficiariesTile(
      {Key? key,
      required this.userName,
      required this.beneficiaries,
      required this.onChanged})
      : super(key: key);

  final String userName;
  final List<BeneficiariesJson> beneficiaries;
  final Function(List<BeneficiariesJson> beneficaries) onChanged;

  @override
  State<BeneficiariesTile> createState() => _BeneficiariesTileState();
}

class _BeneficiariesTileState extends State<BeneficiariesTile> {
  late List<BeneficiariesJson> beneficiaries;

  @override
  void initState() {
    beneficiaries = widget.beneficiaries;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        beneficiariesBottomSheet(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(kScreenHorizontalPaddingDigit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Video Participants:'),
                Spacer(),
                Icon(Icons.arrow_drop_down),
              ],
            ),
            Visibility(
              visible: beneficiaries.isNotEmpty,
              child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    children: List.generate(
                      beneficiaries.length,
                      (index) => _beneficarieNameTile(theme, index, context),
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }

  Visibility _beneficarieNameTile(
      ThemeData theme, int index, BuildContext context) {
    return Visibility(
      visible: !beneficiaries[index].isDefault,
      child: Container(
        margin: EdgeInsets.only(right: 6, bottom: 8),
        padding: EdgeInsets.only(top: 2, bottom: 2, right: 8, left: 3),
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserProfileImage(
                radius: 20, userName: beneficiaries[index].account),
            const SizedBox(
              width: 5,
            ),
            Text(
              beneficiaries[index].account,
              style: TextStyle(
                color: Theme.of(context).primaryColorLight.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void beneficiariesBottomSheet(BuildContext context) {
    var filteredBenes = beneficiaries
        .where((element) =>
            element.src != 'ENCODER_PAY' &&
            element.src != 'mobile' &&
            element.src != 'threespeak')
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: 400,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Video Participants'),
                actions: [
                  if (beneficiaries.length < 8)
                    IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showAlertForAddBene(beneficiaries);
                        },
                        icon: Icon(Icons.add))
                ],
              ),
              body: ListView.separated(
                itemBuilder: (c, i) {
                  return ListTile(
                    leading: CustomCircleAvatar(
                      height: 40,
                      width: 40,
                      url: server.userOwnerThumb(filteredBenes[i].account),
                    ),
                    title: Text(filteredBenes[i].account),
                    subtitle: Text(
                        '${filteredBenes[i].src} ( ${filteredBenes[i].weight} % )'),
                    trailing: (filteredBenes[i].src == 'participant')
                        ? IconButton(
                            onPressed: () {
                              var currentBenes = beneficiaries;
                              var author = currentBenes
                                  .where((e) => e.account == widget.userName)
                                  .firstOrNull;
                              if (author == null) return;
                              var otherBenes = currentBenes
                                  .where((e) =>
                                      e.src != 'author' &&
                                      e.account != filteredBenes[i].account)
                                  .toList();
                              author.weight =
                                  author.weight + filteredBenes[i].weight;
                              otherBenes.add(author);
                              setState(() {
                                beneficiaries = otherBenes;
                              });
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          )
                        : null,
                  );
                },
                separatorBuilder: (c, i) => const Divider(),
                itemCount: filteredBenes.length,
              ),
            ),
          ),
        );
      },
    );
  }

  void showAlertForAddBene(List<BeneficiariesJson> benes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return AddBeneSheet(
          benes: benes,
          onSave: (newBenes) {
            setState(() {
              beneficiaries = newBenes;
            });
            widget.onChanged(newBenes);
          },
        );
      },
    );
  }
}
