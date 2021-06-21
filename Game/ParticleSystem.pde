// A class to describe a group of Particles
class ParticleSystem { 
  ArrayList<Particle> particles;
  PVector origin;
  //float particuleRadius; -> cylinderBaseSize in Game

  ParticleSystem(PVector origin) {
    this.origin = origin.copy();
    particles = new ArrayList<Particle>();
    particles.add(new Particle(origin));
    score = 0;
    scoreChart = new FloatList();
  }

  // Iteratively update and display every particle,
  // and remove them from the list if their lifetime is over. 
  void run(PGraphics surface) {
    if(particles.size() == 0) return;
    
    if (particles.get(0).isDead()) {
      particles = new ArrayList<Particle>();
      existsParticleSystem = false;
      return;
    } else {
      surface.pushMatrix();
      surface.translate(particles.get(0).center.x, 0, particles.get(0).center.y);
      particles.get(0).run(surface);
      displayRob(surface);
      surface.popMatrix();
    }


    for (int i = 1; i<particles.size(); i++) {
      if (particles.get(i).isDead()) {
        particles.remove(i);
        score += mover.velocity.mag();
        lastScore = mover.velocity.mag();
      }
    }

    for (int i=1; i<particles.size(); i++) {
      surface.pushMatrix();
      surface.translate(particles.get(i).center.x, 0, particles.get(i).center.y);
      particles.get(i).run(surface);
      surface.popMatrix();
    }
  }

  void addParticle() {
    PVector center;
    int numAttempts = 100;
    if (particles.size() == 0) return;

    for (int i=0; i<numAttempts; i++) {
      // Pick a cylinder and its center.
      int index = int(random(particles.size()));
      center = particles.get(index).center.copy();

      // Try to add an adjacent cylinder.
      float angle = random(TWO_PI);
      center.x += sin(angle) * 2*cylinderBaseSize; 
      center.y += cos(angle) * 2*cylinderBaseSize; 
      if (checkPosition(center)) {
        particles.add(new Particle(center));
        score -= 1;
        break;
      }
    }
  }

  // Check if a position is available, i.e.
  // - would not overlap with particles that are already created
  // (for each particle, call checkOverlap())
  // - is inside the board boundaries 
  boolean checkPosition(PVector center) {
    if (abs(center.x) > (plateDims.x/2-cylinderBaseSize) || 
      abs(center.y) > (plateDims.z/2-cylinderBaseSize) ||
      center.dist(mover.location) <= ballRadius+cylinderBaseSize) {
      return false;
    }
    for (int i=0; i<particles.size(); i++) {
      if (checkOverlap(center, particles.get(i).center)) {
        return false;
      }
    }
    return true;
  }

  // Check if a particle with center c1
  // and another particle with center c2 overlap. 
  boolean checkOverlap(PVector c1, PVector c2) {
    return (c1.dist(c2) < 2*cylinderBaseSize);
  }
  
  void displayRob(PGraphics surface) {
    surface.pushMatrix();
    float angle = atan2(mover.location.x - particles.get(0).center.x, 
    mover.location.y - particles.get(0).center.y);
    surface.rotateY(angle);
    surface.shape(robotnik);
    surface.popMatrix();
  }

  
}
