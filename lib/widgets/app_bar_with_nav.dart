import 'package:flutter/material.dart';

PreferredSizeWidget buildAppBar(BuildContext context) {
  return AppBar(
    centerTitle: true,
    title: const Text(
      "COPA",
      style: TextStyle(
        shadows: [
          Shadow(
            blurRadius: 3.0,
            color: Color.fromARGB(66, 67, 62, 62),
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
    ),
    backgroundColor: Color.fromARGB(255, 173, 216, 230),
    actions: [
      GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment),
                      title: const Text('Payment Details'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('History'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () {},
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          margin: EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/profile-placeholder.png'),
          ),
        ),
      ),
    ],
  );
}
