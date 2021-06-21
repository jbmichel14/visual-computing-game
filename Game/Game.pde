ImageProcessing imgproc;

//data
int dataHeight = 300;
PGraphics gameSurface;
PGraphics dataBackground;
PGraphics topView;
PGraphics scoreBoard;
float velocityMag = 0; //updated every few frame
float score = 0; //updated in particleSystem
float lastScore = 0; //updated in particleSystem
PGraphics barChart;
HScrollbar chartScroll;
boolean clickedInGame = false;
FloatList scoreChart = new FloatList();
float scoreScale;

//view modes
float depth = 600;
boolean shift = false;
float shiftScaling;

//state
float speed = 1.0;
float wheelSpeed = 0.1;
float maxSpeed = 2;
float rotX = 0.;
float rotZ = 0.;

//plate
PVector plateDims = new PVector(400, 10, 400);
float angleMove = PI/360;
float angleLimit = PI/3;

//globe
Mover mover;
float ballRadius = 15;
PShape globe;

//cylinder
float cylinderBaseSize= 20;
float cylinderHeight= 40;
int cylinderResolution= 30;
PShape cylinder=new PShape();

//robotnik
PShape robotnik;
float robScale = 30;

//particle system
ParticleSystem particleSystem;
boolean existsParticleSystem = false;
int particleRate = 10;

void settings() {
  size(1200, 900, P3D);
}

void setup() {
  imgproc=new ImageProcessing();
  imgproc.imgType = 2; //0: static, 1: camera, 2: video
  //kalman filter does a good job on predicting the corners position but produces unusable rotation values (error of implementation ?)
  imgproc.kalmanFilter = false;
  //imgproc.kalmanRate = 5; //default 3
  if (imgproc.imgType == 0) imgproc.img = loadImage("board1.jpg");

  String[]args= {"Image processing window"};
  PApplet.runSketch(args, imgproc);

  gameSurface = createGraphics(width, height-dataHeight, P3D);
  dataBackground = createGraphics(width, dataHeight, P2D);
  topView = createGraphics(dataHeight, dataHeight, P2D);
  scoreBoard = createGraphics(dataHeight-20, dataHeight-20, P2D);
  barChart = createGraphics(width-2*dataHeight-20, dataHeight-20, P2D);
  chartScroll = new HScrollbar(0, (dataHeight-20)-20, width-2*dataHeight-20, 20);
  textFont(createFont("Rockwell", 30));
  textMode(SHAPE);
  frameRate(60);
  mover=new Mover();
  createGlobeShape();
  createCylinderShape();
  createRobotnik();
}

void draw() {
  //greatly different rotation values from one run to another (seems to come from twoDThreeD ?)
  PVector rot = imgproc.getRotations();
  rotX = rot.x;
  rotZ = rot.y;
  checkRot();

  drawGame();
  image(gameSurface, 0, 0);
  dataBackground.beginDraw();
  dataBackground.background(150);
  dataBackground.endDraw();
  image(dataBackground, 0, height-dataHeight);
  drawTopView();
  image(topView, 0, height-dataHeight);
  drawScore();
  image(scoreBoard, dataHeight+10, height-dataHeight+10);
  drawChart();
  image(barChart, 2*dataHeight+10, height-dataHeight+10);
  visualizeState();
}

void drawChart() {
  barChart.beginDraw();
  barChart.background(255);
  chartScroll.update(2*dataHeight+10, height-dataHeight+10);
  chartScroll.display(barChart);
  //chart
  //width-2*dataHeight-20, dataHeight-20
  barChart.translate(0, (2./3.)*(dataHeight-20));
  barChart.stroke(100);
  barChart.fill(110);
  float unitWidth = 10*chartScroll.getPos();
  if (!shift && existsParticleSystem && frameCount%20 == 0) {
    scoreChart.append(score);
    float max = scoreChart.max();
    float min = scoreChart.min();
    scoreScale = (0.95)*(dataHeight-20)/max(1.5*max, 3*abs(min));
  }
  for (int i = 0; i < min(scoreChart.size(), (width-2*dataHeight-20)/unitWidth); i++) {
    barChart.rect(i*unitWidth, 0, unitWidth, -scoreChart.get(i)*scoreScale);
  }
  barChart.fill(80);
  barChart.rect(0, -1, 2*dataHeight+10, 2);
  barChart.endDraw();
}

void drawScore() {
  scoreBoard.beginDraw();
  scoreBoard.background(180);
  scoreBoard.textSize(20);
  scoreBoard.translate(5, 20);
  scoreBoard.fill(0);
  scoreBoard.text("Total Score : ", 0, 0);
  scoreBoard.text(score, 0, 25);
  if (frameCount%4 == 0) {
    velocityMag = mover.velocity.mag();
  }
  scoreBoard.text("Velocity : ", 0, 75);
  scoreBoard.text(velocityMag, 0, 100);
  scoreBoard.text("Last Score : ", 0, 150);
  scoreBoard.text(lastScore, 0, 175);
  scoreBoard.endDraw();
}

void drawTopView() {
  topView.beginDraw();
  topView.noStroke();
  topView.fill(0, 50, 100);
  topView.rect(0, 0, dataHeight, dataHeight);
  topView.fill(0, 150, 250);
  topView.stroke(0);
  float scale = (float)dataHeight/plateDims.x;
  topView.ellipse(mover.location.x*scale+dataHeight/2, mover.location.y*scale+dataHeight/2, 
    ballRadius/scale, ballRadius/scale);
  if (existsParticleSystem) {
    topView.fill(150, 0, 0);
    topView.ellipse(particleSystem.origin.x*scale+dataHeight/2, particleSystem.origin.y*scale+dataHeight/2, 
      2*cylinderBaseSize*scale, 2*cylinderBaseSize*scale);
    topView.fill(255);
    for (int i = 1; i < particleSystem.particles.size(); i++) {
      PVector pos = particleSystem.particles.get(i).center;
      topView.ellipse(pos.x*scale+dataHeight/2, pos.y*scale+dataHeight/2, 
        2*cylinderBaseSize*scale, 2*cylinderBaseSize*scale);
    }
  }
  topView.endDraw();
}

void drawGame() {
  gameSurface.beginDraw();
  gameSurface.background(50);

  if (!shift) {
    gameSurface.perspective();
    //camera view to decide
    gameSurface.camera(width/2, height/2, depth, width/2, height/2, 0, 0, 1, 0);
  } else {
    //perspective might be better than ortho
    gameSurface.ortho();
    gameSurface.camera(width/2, -depth/2, 0, width/2, height/2, 0, 0, 1, 1);
    shiftScaling = float(width)/float(height);
  }

  gameSurface.directionalLight(50, 50, 50, -0.5, 1, -0.5);
  gameSurface.ambientLight(200, 200, 200);
  gameSurface.translate(width/2, height/2, 0);

  //matrix roation
  gameSurface.pushMatrix();
  if (!shift) {
    gameSurface.rotateX(rotX);
    gameSurface.rotateZ(rotZ);
  } else {
    gameSurface.scale(shiftScaling);
  }

  //box
  gameSurface.fill(180);
  gameSurface.noStroke();
  gameSurface.box(plateDims.x, plateDims.y, plateDims.z);

  if (existsParticleSystem) {
    if (!shift && frameCount%particleRate == 0) { 
      particleSystem.addParticle();
    }
    particleSystem.run(gameSurface);
  }

  //ball
  if (!shift) {
    mover.update(rotX, rotZ);
    //mover.checkEdges(); -> done in update
    if (existsParticleSystem) {
      mover.checkCylinderCollision(particleSystem.particles);
    }
  }
  mover.display(gameSurface);

  //drawAxis();
  gameSurface.popMatrix();
  gameSurface.endDraw();
}

void checkRot() {
  if (abs(rotX)>angleLimit) {
    if (rotX < 0)
      rotX = -angleLimit;
    else
      rotX = angleLimit;
  }
  if (abs(rotZ)>angleLimit) {
    if (rotZ < 0)
      rotZ = -angleLimit;
    else
      rotZ = angleLimit;
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      shift = true;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      shift = false;
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (e > 0 && speed < maxSpeed) {
    speed = min(speed + wheelSpeed, maxSpeed);
  } else if (e < 0 && speed > 0) {
    speed = max(speed - wheelSpeed, 0);
  }
}

void mouseDragged() 
{
  if (!shift && clickedInGame) {
    float moveX = mouseX-pmouseX;
    float moveY = -(mouseY-pmouseY);
    rotX = rotX + moveY*speed*angleMove;
    rotZ = rotZ + moveX*speed*angleMove;
    checkRot();
  }
}

void mouseReleased() {
  clickedInGame = false;
  chartScroll.clickedOnBar = false;
}

void mousePressed() {
  if (mouseY < height-dataHeight) {
    clickedInGame = true;
  }
  if (chartScroll.isMouseOver(2*dataHeight+10, height-dataHeight+10)) {
    chartScroll.clickedOnBar = true;
  }
  //else if(scrollChart.isMouseOver(
  if (shift) {
    if (abs(mouseX-width/2)/shiftScaling+cylinderBaseSize < plateDims.x/2 &&
      abs(mouseY-(height-dataHeight)/2)/shiftScaling+cylinderBaseSize < plateDims.z/2 &&
      dist((mouseX-width/2)/shiftScaling, (mouseY-(height-dataHeight)/2)/shiftScaling, mover.location.x, mover.location.y) > 
      ballRadius+cylinderBaseSize) {
      particleSystem = new ParticleSystem(new PVector(
        (mouseX-width/2)/shiftScaling, (mouseY-(height-dataHeight)/2)/shiftScaling));
      existsParticleSystem = true;
    }
  }
}

void createGlobeShape() {
  PImage img = loadImage("photo.png");
  globe= createShape(SPHERE, ballRadius);
  globe.setStroke(false);
  globe.setTexture(img);
}

void createCylinderShape() {
  float angle;
  float[] x =new float[cylinderResolution+ 1];
  float[] y =new float[cylinderResolution+ 1];
  PVector center = new PVector(0, 0);

  //get the x and y position on a circle for all the sides
  for (int i = 0; i < x.length; i++) {
    angle= (TWO_PI/ cylinderResolution) * i;
    x[i] = sin(angle) * cylinderBaseSize;
    y[i] = cos(angle) * cylinderBaseSize;
  }
  PShape tube= createShape();
  tube.beginShape(QUAD_STRIP);
  //draw the border of the cylinder
  for (int i = 0; i < x.length; i++) {
    tube.vertex(x[i], -plateDims.y/2, y[i]);
    tube.vertex(x[i], -(cylinderHeight + plateDims.y/2), y[i]);
  }
  tube.endShape();

  //top and bottom of the cylinder
  PShape cylinderTop = createShape();
  cylinderTop.beginShape(TRIANGLES);
  for (int i = 0; i < x.length-1; i++) {
    cylinderTop.vertex(x[i], -(cylinderHeight + plateDims.y/2), y[i]);
    cylinderTop.vertex(center.x, -(cylinderHeight + plateDims.y/2), center.y);
    cylinderTop.vertex(x[i+1], -(cylinderHeight + plateDims.y/2), y[i+1]);
    cylinderTop.vertex(x[i], -plateDims.y/2, y[i]);
    cylinderTop.vertex(center.x, -plateDims.y/2, center.y);
    cylinderTop.vertex(x[i+1], -plateDims.y/2, y[i+1]);
  }
  cylinderTop.endShape();

  cylinder = createShape(GROUP);
  cylinder.addChild(tube);
  cylinder.addChild(cylinderTop);
}

void createRobotnik() {
  robotnik = loadShape("robotnik.obj");
  robotnik.scale(robScale);
  robotnik.rotateX(PI);
  robotnik.rotateY(PI);
  robotnik.translate(0, -(cylinderHeight+plateDims.y/2), 0);
}

void drawAxis() {
  //axis
  strokeWeight(2.5);
  //X
  stroke(180, 0, 0);
  line(-400, 0, 0, 400, 0, 0);
  //Y
  stroke(0, 180, 0);
  line(0, -400, 0, 0, 400, 0);
  //Z
  stroke(0, 0, 180);
  line(0, 0, -400, 0, 0, 400);

  //axis text
  textSize(20);
  textAlign(RIGHT);
  fill(180, 0, 0);
  text("X", 400, -10);
  textAlign(LEFT);
  fill(0, 180, 0);
  text("Y", 10, 400);
  fill(0, 0, 180);
  text("Z", 10, 0, 400);
}

float px = 0;
float py = 0;
float vx = 0;
float vy = 0;

void visualizeState() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  noLights();
  float size = min(width, height)/40;
  textSize(size/2);
  fill(30);
  text("AngleX: " + nf(-rotX*(180/PI), 1, 1), 10, 15, 0);
  text("AngleZ: " + nf(rotZ*(180/PI), 1, 1), 10, 15 + size/2, 0);
  text("Speed: " + nf(speed, 1, 1), 10, 15 + size, 0);
  if (frameCount%4 == 0) {
    px = mover.location.x;
    py = mover.location.y;
    vx = mover.velocity.x;
    vy = mover.velocity.y;
  }
  text("Ball location: " + nf(px, 1, 2) + ", " +
    nf(py, 1, 2), 10, 15 + 3*size/2, 0);
  text("Ball velocity: " + nf(vx, 1, 2) + ", " +
    nf(vy, 1, 2), 10, 15 + 4*size/2, 0);

  hint(ENABLE_DEPTH_TEST);
}
