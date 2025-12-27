import 'package:flutter/material.dart';

class CharacterPage extends StatefulWidget {
  final int characterId;
  
  const CharacterPage({super.key, required this.characterId});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Character Page - ID: ${widget.characterId}'),
      ),
    );
  }
}

