import 'package:moodiary/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'user_logic.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Bind.find<UserLogic>();
    //final state = Bind.find<UserLogic>().state;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          FilledButton(
            onPressed: () {
              logic.signOut();
            },
            child: Text(Get.context!.l10n.userLogout),
          ),
        ],
      ),
    );
  }
}
