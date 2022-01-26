import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class Category extends StatefulWidget {
  const Category({Key? key}) : super(key: key);

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  TextEditingController TitleController = TextEditingController();
  var _image;
  bool isloading = false;
  var imagevalue;

  Future getImage(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final PickedFile? image =
        await _picker.getImage(source: ImageSource.gallery);

    setState(() {
      _image = File(image!.path);

      print('Image Path $_image');
    });
    // uploadPic(context);
  }

  Future uploadPic(BuildContext context) async {
    // showLoaderDialog(context);

    String fileName = basename(_image.path);
    Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = firebaseStorageRef.putFile(_image);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {
      var snackBar = const SnackBar(content: const Text('Image Uploaded'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
    setState(() {
      print("Picture uploaded");
    });
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    if (downloadUrl != null) {
      await FirebaseFirestore.instance.collection("Categories").doc().set({
        'image': downloadUrl,
        'title': TitleController.text,
      }, SetOptions(merge: true));
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Categories'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: const [
                Text(
                  'Select Image:',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  getImage(context);
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black)),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.file(
                            _image,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : imagevalue != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: CachedNetworkImage(
                                imageUrl: imagevalue,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Container(
                              width: 200,
                              height: 200,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                              ),
                            ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextFormField(
              controller: TitleController,
              keyboardType: TextInputType.text,
              // onSaved: (newValue) => titleBUL = newValue!,
              cursorColor: Colors.blue,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  labelText: "Title",
                  labelStyle: TextStyle(color: Colors.blue),
                  hintText: "Enter Title Here",
                  // If  you are using latest version of flutter then lable text and hint text shown like this
                  // if you r using flutter less then 1.20.* then maybe this is not working properly
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10)),
            ),
          ),
          isloading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ElevatedButton(
                  onPressed: () {
                    if (_image != null) {
                      uploadPic(context);
                      setState(() {
                        isloading = true;
                      });
                    } else {
                      var snackBar =
                          const SnackBar(content: Text('Select Image First'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      print("Select Image First");
                      setState(() {
                        isloading = false;
                      });
                    }
                  },
                  child: const Text('Add'),
                )
        ],
      ),
    );
  }
}
