import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  mergeAndStore() async {
    final image1 = img.decodeImage(_image.readAsBytesSync());
    final waterMark = await getImageFileFromAssets('icon.png');

    final image2 = img.decodeImage(waterMark.readAsBytesSync());
    final canvas = img.Image(image1.width, image1.height);
    img.copyInto(canvas, image1, blend: false);
    img.copyInto(
      canvas,
      image2,
      dstX: (image1.width / 2 - image2.width/2).round(),
      dstY: (image1.height / 2-image2.height/2).round(),
      blend: true,
    );

    final documentDirectory = await getTemporaryDirectory();
    final file = File('${documentDirectory.path}/merged_image.jpg');
    final newFile = await file.writeAsBytes(img.encodeJpg(canvas));
    GallerySaver.saveImage(newFile.path);
    setState(() {
      if (newFile != null) {
        _image = newFile;
        print('${newFile.path}');
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker Example'),
      ),
      body: Center(
        child: _image == null ? Text('No image selected.') : Image.file(_image),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: mergeAndStore,
            child: Icon(Icons.sd_storage),
          ),
          FloatingActionButton(
            onPressed: getImage,
            child: Icon(Icons.add_a_photo),
          ),
        ],
      ),
    );
  }
}
