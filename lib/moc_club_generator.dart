import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MockClubGenerator extends StatefulWidget {
  const MockClubGenerator({Key? key}) : super(key: key);

  @override
  _MockClubGeneratorState createState() => _MockClubGeneratorState();
}

class _MockClubGeneratorState extends State<MockClubGenerator> {
  TextEditingController advisorController = TextEditingController();
  TextEditingController clubNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? photo;
  bool enrollable = false;
  bool creating = false;

  Widget _inputGetter(
      TextEditingController textEditingController, String hint) {
    return TextField(
      decoration: InputDecoration(border: InputBorder.none, hintText: hint),
      controller: textEditingController,
    );
  }

  Map<String, dynamic> data = {
    "members": [],
    "managers": [],
    "mutedMembers": []
  };

  Future<void> createClub() async {
    if (photo == null) return;

    setState(() {
      creating = true;
    });

    String? photoURL;

    await FirebaseStorage.instance
        .ref('clubProfilePhotos/${clubNameController.text}.png')
        .putFile(photo!)
        .then((p0) async {
      photoURL = await p0.ref.getDownloadURL();
    });

    Map<String, dynamic> club = data;

    club["clubPhoto"] = photoURL!;
    club["advisor"] = advisorController.text;
    club["clubName"] = clubNameController.text;
    club["enrollable"] = enrollable;

    String? clubID;

    await FirebaseFirestore.instance
        .collection("clubs")
        .add(club)
        .then((value) {
      clubID = value.id;
    });

    await FirebaseFirestore.instance
        .collection("clubs")
        .doc(clubID!)
        .update({"id": clubID});

    advisorController.clear();
    clubNameController.clear();
    photo = null;

    setState(() {
      creating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    photo == null
                        ? const SizedBox(
                            height: 40,
                          )
                        : Image.file(photo!),
                    TextButton(
                        onPressed: () async {
                          XFile? result = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (result != null) {
                            setState(() {
                              photo = File(result.path);
                            });
                          }
                        },
                        child: const Center(child: Text("pick image"))),
                    _inputGetter(advisorController, "advisor"),
                    _inputGetter(clubNameController, "clubName"),
                    SwitchListTile.adaptive(
                        subtitle: const Text("enrollable"),
                        value: enrollable,
                        onChanged: (data) {
                          setState(() {
                            enrollable = data;
                          });
                        }),
                    TextButton(
                        onPressed: () => createClub(),
                        child: const Center(
                          child: Text("create"),
                        ))
                  ],
                ),
              ),
            ),
            Visibility(
              visible: creating,
              child: Container(
                color: Colors.black.withOpacity(.7),
                child: const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
