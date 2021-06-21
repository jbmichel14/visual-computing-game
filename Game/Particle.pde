// A simple Particle class
class Particle {
  PVector center;
  //float radius; -> cylinderBaseSize
  float lifespan;

  Particle(PVector center /*, float radius */) {
    this.center= center.copy();
    this.lifespan= 1;
    //this.radius= radius;
  }

  void run(PGraphics surface) {
    update();
    display(surface);
  }

  // Method to update the particle's remaining lifetime
  void update() {
    //do nothing
  }

  // Method to display
  void display(PGraphics surface) {
    surface.shape(cylinder);
  }

  // Is the particle still useful?
  // Check if the lifetime is over.
  boolean isDead() {
    // ...
    return lifespan == 0;
  }
}
