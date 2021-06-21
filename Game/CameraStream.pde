import processing.video.*;

Capture cam;

void cameraSetup() {
  String[] cameras= Capture.list();
  if (cameras.length== 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i + " " + cameras[i]);
    }
  }
  //If you're using gstreamer0.1 (Ubuntu 16.04 and earlier),
  //select your predefined resolution from the list:
  cam =new Capture(this, cameras[15]);
  //If you're using gstreamer1.0 (Ubuntu 16.10 and later),
  //select your resolution manually instead:
  //cam = new Capture(this, 640, 480, cameras[0]);
  cam.start();
}

PImage readCamera() {
  if (cam.available() ==true) {
    cam.read();
  }
  return cam.get();
}
