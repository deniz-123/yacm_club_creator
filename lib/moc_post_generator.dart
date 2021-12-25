import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MockPostGenerator extends StatefulWidget {
  const MockPostGenerator({Key? key}) : super(key: key);

  @override
  _MockPostGeneratorState createState() => _MockPostGeneratorState();
}

class _MockPostGeneratorState extends State<MockPostGenerator> {
  ImagePicker imagePicker = ImagePicker();
  List<File?> photos = [null, null, null, null, null, null, null, null];
  TextEditingController questionController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  List<TextEditingController> options = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool loading = false;
  String clubValue = "Young Entrepreneurs Society";
  String clubId = "BArBH91Vo8LRHtlcepdK";
  bool event = false;
  bool commentsOn = false;
  String publishDate = "Publish Date";
  String endDate = "End Date";
  String beginDate = "Begin Date";

  Widget _postImagePicker(int index) {
    return InkWell(
      onTap: () async {
        XFile? photo = await imagePicker.pickImage(source: ImageSource.gallery);
        if (photo != null) {
          setState(() {
            photos[index] = File(photo.path);
          });
        }
      },
      child: Container(
          width: (MediaQuery.of(context).size.width / 3) - 12,
          height: 100,
          color: Colors.black.withOpacity(.1),
          child: photos[index] == null
              ? Center(
                  child: Icon(Icons.add, color: Colors.black),
                )
              : Image.file(photos[index]!)),
    );
  }

  Widget datePicker(String text, Function(String) onPressed) {
    DateTime? date;
    return TextButton(
        onPressed: () async {
          date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(Duration(days: 365 * 10)),
              lastDate: DateTime.now().add(Duration(days: 365 * 10)));

          if (date != null) onPressed(date.toString());
        },
        child: Center(
          child: Text(text),
        ));
  }

  Widget pickClub(List<DocumentSnapshot> documents) {
    List<String> docs = [];
    for (DocumentSnapshot doc in documents) {
      docs.add(doc.get("clubName"));
    }
    return DropdownButton<String>(
      value: clubValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? newValue) {
        int index = docs.indexOf(newValue!);
        setState(() {
          clubValue = documents[index].get("clubName");
          clubId = documents[index].get("id");
        });
      },
      items: documents.map<DropdownMenuItem<String>>((DocumentSnapshot value) {
        return DropdownMenuItem<String>(
          value: value.get("clubName"),
          child: Text(value.get("clubName")),
        );
      }).toList(),
    );
  }

  Widget pickOptions() {
    Widget option(int index) => Container(
          child: TextField(
              controller: options[index],
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "If empty, this will be not used")),
        );

    return Column(
      children: [
        Container(
          child: TextField(
              controller: questionController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Question(cant be empty)")),
        ),
        option(0),
        option(1),
        option(2),
        option(3),
        option(4),
        datePicker(beginDate, (data) {
          setState(() {
            beginDate = data;
          });
        }),
        datePicker(endDate, (data) {
          setState(() {
            endDate = data;
          });
        }),
      ],
    );
  }

  Future<void> createPost() async {
    setState(() {
      loading = !loading;
    });

    if (event) {
      String? postId;
      List<String> postLinks = [];

      Map<String, dynamic> data = {
        "clubName": clubValue,
        "clubID": clubId,
        "message": messageController.text,
        "publishDate": DateTime.parse(publishDate),
        "beginDate": DateTime.parse(beginDate),
        "endDate": DateTime.parse(endDate),
        "commentsOn": commentsOn,
        "prerequisites": [],
        "type": "event",
        "id": ""
      };

      await FirebaseFirestore.instance
          .collection("posts")
          .add(data)
          .then((value) async {
        postId = value.id;
      });

      Future.forEach(photos, (File? element) async {
        if (element != null) {
          FirebaseStorage.instance
              .ref("postPhotos/$clubValue/$postId")
              .putFile(element)
              .then((photoLink) async {
            String url = await photoLink.ref.getDownloadURL();
            postLinks.add(url);
          });
        }
      });

      await FirebaseFirestore.instance
          .collection("posts")
          .doc(postId)
          .update({"id": postId, "images": postLinks});
    } else {
      String? postId;

      List<String> _options = [];

      for (TextEditingController controller in options) {
        if (controller.text.isNotEmpty) {
          _options.add(controller.text);
        }
      }

      List<int> votes = [];

      for (int i = 0; i < _options.length; i++) {
        votes.add(0);
      }

      Map<String, dynamic> data = {
        "clubName": clubValue,
        "clubID": clubId,
        "message": messageController.text,
        "publishDate": DateTime.parse(publishDate),
        "commentsOn": commentsOn,
        "votes": votes,
        "options": _options,
        "question": questionController.text,
        "type": "poll",
        "id": ""
      };

      String? postID;

      await FirebaseFirestore.instance
          .collection("posts")
          .add(data)
          .then((value) {
        postID = value.id;
      });

      await FirebaseFirestore.instance
          .collection("posts")
          .doc(postID)
          .update({"id": postID});
    }

    setState(() {
      photos = [null, null, null, null, null, null, null, null];
      options[0].clear();
      options[1].clear();
      options[2].clear();
      options[3].clear();
      options[4].clear();
      messageController.clear();
      questionController.clear();
      loading = false;
      clubValue = "Young Entrepreneurs Society";
      clubId = "BArBH91Vo8LRHtlcepdK";
      event = false;
      commentsOn = false;
      publishDate = "Publish Date";
      endDate = "End Date";
      beginDate = "Begin Date";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection("clubs").snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.active &&
                    snapshot.hasData) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SwitchListTile(
                              subtitle: Text("Post type is event: "),
                              value: event,
                              onChanged: (data) {
                                setState(() {
                                  event = data;
                                });
                              }),
                          event
                              ? Wrap(
                                  children: [
                                    _postImagePicker(0),
                                    _postImagePicker(1),
                                    _postImagePicker(2),
                                    _postImagePicker(3),
                                    _postImagePicker(4),
                                    _postImagePicker(5),
                                    _postImagePicker(6),
                                    _postImagePicker(7),
                                  ],
                                )
                              : pickOptions(),
                          pickClub(snapshot.data!.docs),
                          TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Enter message(cant be empty)")),
                          SwitchListTile.adaptive(
                              subtitle: const Text("Comments On"),
                              value: commentsOn,
                              onChanged: (data) {
                                setState(() {
                                  commentsOn = data;
                                });
                              }),
                          datePicker(publishDate, (data) {
                            setState(() {
                              publishDate = data;
                            });
                          }),
                          TextButton(
                              onPressed: () => createPost(),
                              child: const Center(
                                child: Text("create"),
                              ))
                        ],
                      ),
                    ),
                  );
                }
                return CircularProgressIndicator.adaptive();
              },
            ),
            Visibility(
              visible: loading,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black.withOpacity(.7),
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
