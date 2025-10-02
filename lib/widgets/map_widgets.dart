import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/color_extensions.dart';

Widget buildMapControlButton(IconData icon, VoidCallback onPressed) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
  color: Colors.grey[900]!.withOpacitySafe(0.7),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.grey[800]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacitySafe(0.2),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: IconButton(
          icon: Icon(icon, size: 18, color: Colors.white),
          padding: EdgeInsets.zero,
          onPressed: onPressed,
        ),
      ),
    ),
  );
}

Widget buildSearchBar() {
  return Container(
    decoration: BoxDecoration(
      color: Color.fromRGBO(0, 0, 0, 0.85), // Black with 85% opacity
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.grey[800]!),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.2),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Find COPA locations...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    ),
  );
}
