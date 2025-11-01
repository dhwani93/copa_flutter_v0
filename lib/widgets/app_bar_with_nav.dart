import 'package:flutter/material.dart';

/// AppBar for LandingPage
/// Uses glassy translucent teal with white text and icons
PreferredSizeWidget buildAppBar(BuildContext context) {
  return AppBar(
    centerTitle: true,
    title: const Text(
      "COPA",
      style: TextStyle(
        color: Colors.white, // White text
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 3.0,
            color: Color.fromARGB(80, 0, 0, 0),
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
    ),
    backgroundColor: const Color(0xFF0FB498).withOpacity(0.7), // Glassy translucent teal
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white), // White back arrow and icons
    actions: [
      GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.black),
                      title: const Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment, color: Colors.black),
                      title: const Text('Payment Details'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.black),
                      title: const Text('History'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.black),
                      title: const Text('Logout'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white, // White border
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/rahul_profile.jpeg'),
          ),
        ),
      ),
    ],
  );
}
