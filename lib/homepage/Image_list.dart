import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latest_mehndi_desig_admin/upload/add_image.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:path_provider/path_provider.dart';

class ImageList extends StatefulWidget {
  final String id, title;
  ImageList({required this.id, required this.title});

  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
          child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        margin: const EdgeInsets.symmetric(vertical: 5),
        // color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Categories')
              .doc(widget.id)
              .collection(widget.title)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            return snapshot.connectionState == ConnectionState.waiting
                ? const Center(
                    child: CircularProgressIndicator(
                    // backgroundColor: kPrimaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ))
                : snapshot.data!.docs.isEmpty
                    ? const Center(
                        child: Text("No Data Found"),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (BuildContext, index) {
                          DocumentSnapshot data = snapshot.data!.docs[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            width: MediaQuery.of(context).size.width,
                            height: 170,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
                                  child: CachedNetworkImage(
                                    imageUrl: "${data.get('image')}",
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                  // Image.asset("images/hand_mehndi.png",
                                  //     fit: BoxFit.fill),
                                ),
                                Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${data.get('title')}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22),
                                        ),
                                      ),
                                    )),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5, left: 10),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: GestureDetector(
                                      onTap: () {
                                        delete(context, data.id);
                                      },
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(Icons.delete),
                                          )),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5, left: 10),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        downloadFile(data.get('image'));
                                      },
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(Icons.download_rounded),
                                          )),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
          },
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddImage(
                        id: widget.id,
                        title: widget.title,
                      )));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  delete(
    BuildContext dialogContext,
    String id,
  ) async {
    var alertStyle = const AlertStyle(
      animationType: AnimationType.grow,
      overlayColor: Colors.black87,
      isCloseButton: true,
      isOverlayTapDismiss: true,
      titleStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      descStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      animationDuration: Duration(milliseconds: 400),
    );

    Alert(
        context: dialogContext,
        style: alertStyle,
        title: "Delete",
        desc: "You want to Delete the Chapter",
        buttons: [
          DialogButton(
            child: const Text(
              "Cancel",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            color: Colors.red,
          ),
          DialogButton(
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('Categories')
                  .doc(widget.id)
                  .collection(widget.title)
                  .doc(id)
                  .delete();
              print(' Chapters Delete');
            },
            color: Colors.blue,
          )
        ]).show();
  }

  bool downloading = true;
  String downloadingStr = "No data";
  String savePath = "";

  Future downloadFile(param0) async {
    try {
      print('download');
      print(param0);
      Dio dio = Dio();
      String fileName = getFileName(param0);
      savePath = await getFilePath(fileName);

      print(savePath);

      await dio.download(param0, savePath, onReceiveProgress: (rec, total) {
        setState(() {
          downloading = true;
          // download = (rec / total) * 100;
          downloadingStr = "Downloading Image : $rec";
        });
      });
      setState(() {
        downloading = false;
        downloadingStr = "Completed";
      });
      print('completed');
    } catch (e) {
      print(e.toString());
    }
  }

  String getFileName(String url) {
    RegExp regExp = new RegExp(r'.+(\/|%2F)(.+)\?.+');
    //This Regex won't work if you remove ?alt...token
    var matches = regExp.allMatches(url);

    var match = matches.elementAt(0);
    print("${Uri.decodeFull(match.group(2)!)}");
    return Uri.decodeFull(match.group(2)!);
  }

  Future<String> getFilePath(uniqueFileName) async {
    String path = '';
    String dir;
    dir = "/sdcard/download/";

    if (Platform.isAndroid) {
      dir;
    } else {
      // dirloc = (await getApplicationDocumentsDirectory()).path;
      Directory? dir = await getExternalStorageDirectory();
    }
    path = '${dir}$uniqueFileName';
    print('this is path $path');
    return path;
  }
}
