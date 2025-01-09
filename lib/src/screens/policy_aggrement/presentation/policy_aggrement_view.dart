import 'package:acela/src/screens/policy_aggrement/policy_repo/policy_repo.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PolicyAggrementView extends StatelessWidget {
  const PolicyAggrementView({super.key, this.hideButton = false});

  final bool hideButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          "3Speak",
        ),
        subtitle: const Text("End User License Agreement"),
      )),
      bottomNavigationBar: !hideButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 5, horizontal: kScreenHorizontalPaddingDigit),
                child: FilledButton(
                  onPressed: () {
                    PolicyRepo().writePolicyStatus(true);
                    context.pushReplacementNamed(Routes.initialView);
                  },
                  child: Text("Accept and Continue"),
                ),
              ),
            )
          : null,
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('''## 1. Acknowledgement
This End-User License Agreement („EULA“) is a legal agreement between you and SN AnyDevice Software Solutions.

This agreement is between You and SN AnyDevice Software Solutions only, and not Apple Inc. („Apple“). SN AnyDevice Software Solutions, not Apple is solely responsible for the 3Speak Mobile App App and their content. Although Apple ist not a party to this agreement, Apple has the right to enforce this agreement against you as a third party beneficiary relating to your use of the 3Speak Mobile App App.

## 2. Scope of License
SN AnyDevice Software Solutions grants you a limited, non-exclusive, non-transferrable , revocable license to use the 3Speak Mobile App Apps for your personal, non-commercial purposes. You may only use the 3Speak Mobile App Apps on an iPhone, iPod Touch, iPad, or other Apple device that you own or control and as permitted by the Apple App Store Terms of Service.

## 3. Maintenance and Support
Because the 3Speak Mobile App App is free to download and use, SN AnyDevice Software Solutions does not provide any maintenance or support for them. To the extent that any maintenance or support is required by applicable law, SN AnyDevice Software Solutions, not Apple, shall be obligated to furnish any such maintenance or support.

## 4. Warranty
The 3Speak Mobile App App is provided for free on an “as is” basis. As such, SN AnyDevice Software Solutions disclaims all warranties about the 3Speak Mobile App App to the fullest extent permitted by law. To the extent any warranty exists under law that cannot be disclaimed, SN AnyDevice Software Solutions, not Apple, shall be solely responsible for such warranty.

## 5. Product Claims
SN AnyDevice Software Solutions does not make any warranties concerning the 3Speak Mobile App App. To the extent you have any claim arising from or relating to your use of the 3Speak Mobile App, SN AnyDevice Software Solutions, not Apple is responsible for addressing any such claims, which may include, but not limited to: (i) product liability claims; (ii) any claim that the Licensed Application fails to conform to any applicable legal or regulatory requirement; and (iii) claims arising under consumer protection, privacy, or similar legislation, including in connection with the Licensed Application’s use of 3Speak Mobile App and the Hive Blockchain. The EULA may not limit the liability of SN AnyDevice Software Solutions to you what is permitted by applicable law.

## 6. Intellectual Property Rights
SN AnyDevice Software Solutions shall not be obligated to idemnify or defend you with respect to any third party claim arising out or relating to the 3Speak Mobile App App. To the extent SN AnyDevice Software Solutions is required to provide idemnification by applicable law, SN AnyDevice Software Solutions, not Apple shall be solely responsible for the investigation, defense, settlement and discharge of any claims that the 3Speak Mobile App or your use of it infringes any third party intellectual property right.

## 7. Legal Compliance
You represent and warrant that (i) you are not located in a country that is subject to a U.S. Government embargo, or that has been designated by the U.S. Government as a “terrorist supporting” country; and (ii) you are not listed on any U.S. Government list of prohibited or restricted parties.

## 8. Developer Name and Address
Contact
SN AnyDevice Software Solutions
Pune, India
We can be reached via e-mail at 3Speak Mobile snanydevicess@gmail.com

## 9. Third Party Terms of Agreement
You must comply with applicable third party terms of agreement when using the 3Speak Mobile App (e. g. your wireless data service agreement). Your right to use the 3Speak Mobile App will terminate immediately if you violate any provision of this License Agreement. The party providing your mobile OS (Apple) has no obligation whatsoever to furnish any maintenance and support services with respect to the 3Speak Mobile App.

## 10. Third Party Beneficiary
Apple and Apple subsidiaries are third party beneficiaries of the EULA, and that, upon your acceptance, such third party beneficiary will have the right (and will be deemed to have accepted right) to enforce the agreement against you.

## 11. User Generated Contributions
The App may invite you to chat, contribute to, or participate in blogs, message boards, online forums, and other functionality, and may provide you with the opportunity to create, submit, post, display, transmit, perform, publish, distribute, or broadcast content and materials to us or on the App, including but not limited to text, writings, video, audio, photographs, graphics, comments, suggestions, or personal information or other material (collectively, „Contributions“).
Contributions may be viewable by other users of the App and through third-party websites. As such, any Contributions you transmit may be treated as non-confidential and non-proprietary. When you create or make available any Contributions, you thereby represent and warrant that:

1. the creation, distribution, transmission, public display, or performance, and the accessing, downloading, or copying of your Contributions do not and will not infringe the proprietary rights, including but not limited to the copyright, patent, trademark, trade secret, or moral rights of any third party.
2. you are the creator and owner of or have the necessary licenses, rights, consents, releases, and permissions to use and to authorize us, the App, and other users of the App to use your Contributions in any manner contemplated by the App and these Terms of Use.
3. you have the written consent, release, and/or permission of each and every identifiable individual person in your Contributions to use the name or likeness of each and every such identifiable individual person to enable inclusion and use of your Contributions in any manner contemplated by the App and these Terms of Use.
4. your Contributions are not false, inaccurate, or misleading.
5. your Contributions are not unsolicited or unauthorized advertising, promotional materials, pyramid schemes, chain letters, spam, mass mailings, or other forms of solicitation.
6. your Contributions are not obscene, lewd, lascivious, filthy, violent, harassing, libelous, slanderous, or otherwise objectionable (as determined by us).
7. your Contributions do not ridicule, mock, disparage, intimidate, or abuse anyone.
8. your Contributions do not advocate the violent overthrow of any government or incite, encourage, or threaten physical harm against another.
9. your Contributions do not violate any applicable law, regulation, or rule.
10. your Contributions do not violate the privacy or publicity rights of any third party.
11. your Contributions do not include sexual or pornographic material, defined by Webster’s Dictionary as „explicit descriptions or displays of sexual organs or activities intended to stimulate erotic rather than aesthetic or emotional feelings.
12. your Contributions do not contain any material that solicits personal information from anyone under the age of 18 or exploits people under the age of 18 in a sexual or violent manner.
13. your Contributions do not violate any federal or state law concerning pornography, or otherwise intended to protect the health or well-being of minors
14. your Contributions do not include any offensive comments that are connected to race, national origin, gender, sexual preference, or physical handicap.
15. your Contributions do not otherwise violate, or link to material that violates, any provision of these Terms of Use, or any applicable law or regulation.

There is no tolerance for objectionable content or abusive users in the App.
Any use of the App in violation of the foregoing violates these Terms of Use and may result in, among other things, termination or suspension of your rights to use the App.
SN AnyDevice Software Solutions addresses all objectionable content within 24 hours.'''),
        ),
      ),
    );
  }
}
