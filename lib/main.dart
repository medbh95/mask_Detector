import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription>? cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mask Detection',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Mask Detector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage? camImg;
  CameraController? cameraController;
  bool isWorking = false;
  String result = "";
  var selectedCamera;
  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  initCamera() async {
    cameras = await availableCameras();
    if (cameras != null) {
      cameraController = CameraController(cameras![1], ResolutionPreset.max);
      //cameras[0] = first camera, change to 1 to another camera

      cameraController!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
        cameraController!.startImageStream((image) {
          if (!isWorking) {
            isWorking = true;
            camImg = image;
            runModulOnFrame();
          }
        });
      });
    } else {
      print("NO any camera found");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              result.toUpperCase(),
              style: TextStyle(
                fontSize: 22,
              ),
            ),
            (cameraController != null && cameraController!.value.isInitialized)
                ? Expanded(child: CameraPreview(cameraController!))
                : Container(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          onTap:
          () {
            setState(() {
              /// Change the current selected camera State.
              selectedCamera = this.selectedCamera == 0 ? 1 : 0;
            });
            cameraController!.dispose();
            cameraController = CameraController(
              cameras![selectedCamera],
              ResolutionPreset.max,
            );

            /// Reinit camera.
            cameraController!.initialize().then((_) {
              if (!mounted) {
                return;
              }
              setState(() {});
              cameraController!.startImageStream((image) {
                if (!isWorking) {
                  isWorking = true;
                  camImg = image;
                  runModulOnFrame();
                }
              });
            });
          };
        },
        child: Icon(Icons.flip_camera_ios),
      ),
    );
  }

  void runModulOnFrame() async {
    if (camImg != null) {
      var recognition = await Tflite.runModelOnFrame(
          bytesList: camImg!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: camImg!.height,
          imageWidth: camImg!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 1,
          threshold: 0.1,
          asynch: true);
      result = "";
      recognition!.forEach((res) {
        result += res["label"] + "\n";
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }
}
