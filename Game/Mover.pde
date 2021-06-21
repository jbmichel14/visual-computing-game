class Mover {
  PVector limits;
  PVector rotation;
  PVector location;
  PVector velocity;
  PVector gravity;
  float gravityConstant = 1;
  float bouncingCoef = 0.8;
  float mu = 0.1;
  PVector normalForce;
  PVector frictionMagnitude;
  PVector friction;

  Mover() {
    limits=new PVector(plateDims.x/2-ballRadius, plateDims.z/2-ballRadius);
    location=new PVector(0, 0);
    velocity=new PVector(0, 0);
    gravity=new PVector(0, 0);
    normalForce=new PVector(0, 0);
  }

  void update(float rotX, float rotZ) {
    gravity.x = sin(rotZ) * gravityConstant;
    gravity.y = sin(-rotX) * gravityConstant;
    velocity.add(gravity);
    
    //check friction
    normalForce.x = cos(rotZ) * gravityConstant;
    normalForce.y = cos(-rotX) * gravityConstant;
    frictionMagnitude = normalForce.copy();
    frictionMagnitude.mult(mu); 
    friction = velocity.copy().mult(-1).normalize();
    friction.x = friction.x * frictionMagnitude.x;
    friction.y = friction.y * frictionMagnitude.y;
    if (abs(velocity.x) < abs(friction.x))
      velocity.x = 0;
    else
      velocity.x += friction.x;
    if (abs(velocity.y) < abs(friction.y))
      velocity.y = 0;
    else
      velocity.y += friction.y;
    
    location.add(velocity);
    rotation = velocity.copy().div(ballRadius);
    checkEdges();
    float mag = rotation.mag();
    rotation.normalize();
    globe.rotate(mag, -rotation.y, 0, rotation.x);
  }

  void display(PGraphics surface) {
    surface.pushMatrix();
    surface.translate(location.x, -(plateDims.y/2 + ballRadius), location.y);
    surface.shape(globe);
    surface.popMatrix();
  }
  
  //energy loss during rebound but good enough
  void checkEdges() {
    if (abs(location.x) > limits.x) {
      int side;
      if(location.x > 0) side = 1;
      else side = -1;
      location.x = side*limits.x;
      velocity.x = -bouncingCoef*velocity.x;
      rotation.x = 0;
    }
    if (abs(location.y) > limits.y) {
      int side;
      if(location.y > 0) side = 1;
      else side = -1;
      location.y = side*limits.y;
      velocity.y = -bouncingCoef*velocity.y;
      rotation.y = 0;
    }
  }

  void checkCylinderCollision(ArrayList<Particle> cylinderList) {
    for (int i = 0; i < cylinderList.size(); i++) {
      if (location.dist(cylinderList.get(i).center) < cylinderBaseSize+ballRadius) {
        PVector n = ((cylinderList.get(i).center.copy()).sub(location)).normalize();
        float v1n = velocity.dot(n);

        velocity = velocity.sub(n.mult(2*v1n));
        //rotation?
        //location?
        cylinderList.get(i).lifespan = 0;
      }
    }
  }
}
