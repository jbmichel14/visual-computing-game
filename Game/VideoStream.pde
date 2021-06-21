import processing.video.*;

Movie vid;

void videoSetup() {
  vid = new Movie(this, "testvideo.avi");
  vid.loop();
}

PImage readVideo() {
  if (vid.available() ==true) {
    vid.read();
  }
  return vid.get();
}
