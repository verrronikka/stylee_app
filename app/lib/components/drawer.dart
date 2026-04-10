import 'package:flutter/material.dart';
import 'package:stylee_app/components/my_list_title.dart';

class MyDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSignOut;
  const MyDrawer({
    super.key,
    required this.onProfileTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.pink.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // header
          Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 64,
                ),
              ),

              // home
              MyListTitle(
                icon: Icons.home, 
                text: 'HOME',
                onTap: () => Navigator.pop(context),
              ),
              // profile
              MyListTitle(
                icon: Icons.person, 
                text: 'PROFILE',
                onTap: onProfileTap,
              ),
            ]
          ),
          // logout list 

          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: MyListTitle(
              icon: Icons.logout, 
              text: 'LOGOUT',
              onTap: onSignOut,
            )
          )
        ],
      )
    );
  }
}