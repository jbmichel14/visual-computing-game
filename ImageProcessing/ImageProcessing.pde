import java.util.Collections;

PImage img;
PImage img3;
PImage img5;
List<PVector> lines;
List<PVector> quad;

//thresholdBinary
int threshold = 180;

//thresholdHSB(PImage img, int minH, int maxH, int minS, int maxS, int minB, int maxB):
int minH = 70;
int maxH = 137;
int minS = 23;
int maxS = 255;
int minB = 40;
int maxB = 255;

//convolute(PImage img, float[][] kernel, float normFactor)
float[][] kernel1 = { { 0, 0, 0 }, { 0, 2, 0 }, { 0, 0, 0 }};
float[][] kernel2 = { { 0, 1, 0 }, { 1, 0, 1 }, { 0, 1, 0 }};
float normFactor = 1.f;
float[][] gaussianKernel = { { 9, 12, 9 }, { 12, 15, 12 }, { 9, 12, 9 }};
float gaussianNormFactor = 99.f;

//scharr(PImage img, float[][] verticalKernel, float[][] horizontalKernel, float normFactor)
float[][] hKernel = { { 3, 10, 3 }, { 0, 0, 0 }, { -3, -10, -3 }};
float[][] vKernel = { { 3, 0, -3 }, { 10, 0, -10 }, { 3, 0, -3 }};
float scharrNormFactor = 1.f;

//hough
float discretizationStepsPhi = 0.04f; 
float discretizationStepsR = 2.f;
int minVotes=8;
int regionSize = 55;
int nbLines = 4;
float[] tabCos;
float[] tabSin;

boolean kalmanFilter = true;
KalmanFilter2D[] KF2D = {new KalmanFilter2D(), new KalmanFilter2D(), new KalmanFilter2D(), new KalmanFilter2D()};
boolean forcedCorrect = true;
int kalmanRate = 3;

void settings() {
  size(1600, 800);
}

void setup() {
  //img = loadImage("board1.jpg");
  //noLoop();
  //cameraSetup();
  videoSetup();

  trigoLookup();
}

void draw() {
  //img = readCamera();
  img = readVideo();

  scale((float)width/(3*img.width));
  image(img, 0, 0);
  fill(255);
  if (kalmanFilter) {
    kalman();
    for (KalmanFilter2D kf : KF2D) {
      circle(kf.dhat().x, kf.dhat().y, 10);
    }
  } else {
    detect();
    for(PVector corner : quad) {
      circle(corner.x, corner.y, 10);
    }
  }

  translate(img.width, 0);
  image(img5, 0, 0);
  displayLines(lines, img);
  image(img3, img.width, 0);
}

void detect() {
  PImage img1 = thresholdHSB(img, minH, maxH, minS, maxS, minB, maxB);
  PImage img2 = convolute(img1, gaussianKernel, gaussianNormFactor);
  img3 = new BlobDetection().findConnectedComponentsBinary(img2, true);
  PImage img4 = scharr(img3, vKernel, hKernel, scharrNormFactor);
  img5 = thresholdBinary(img4, threshold);
  lines = hough(img5, nbLines);

  quad = new QuadGraph().findBestQuad(lines, img.width, img.height, 
    img.width*img.height, img.width*img.height/40, false);
}

void kalman() {
  if (frameCount%kalmanRate == 0 || forcedCorrect) {
    detect();
    if (quad.size() == 4) {
      for (int i = 0; i < 4; i++) {
        KF2D[i].predict_and_correct(quad.get(i));
      }
      forcedCorrect = false;
    } else {
      for (KalmanFilter2D kf : KF2D) {
        kf.predict();
      }
      forcedCorrect = true;
    }
  } else {
    for (KalmanFilter2D kf : KF2D) {
      kf.predict();
    }
  }
}

boolean inColorRange(int pixel, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
  float h = hue(pixel);
  float s = saturation(pixel);
  float b = brightness(pixel);
  if (h < minH || h > maxH || s < minS || s > maxS || b < minB || b > maxB) {
    return false;
  } else {
    return true;
  }
}

PImage thresholdHSB(PImage img, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
  PImage result = createImage(img.width, img.height, RGB);
  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    if (inColorRange(img.pixels[i], minH, maxH, minS, maxS, minB, maxB)) {
      result.pixels[i] = color(255);
    } else { 
      result.pixels[i] = color(0);
    }
  }
  result.updatePixels();
  return result;
}

PImage thresholdBinary(PImage img, float threshold) { 
  PImage result = createImage(img.width, img.height, RGB); 
  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    float b = brightness(img.pixels[i])>threshold ? 255 : 0;
    result.pixels[i] = color(b);
  }
  result.updatePixels();
  return result;
}

PImage scharr(PImage img, float[][] verticalKernel, float[][] horizontalKernel, float normFactor) {
  PImage result = createImage(img.width, img.height, ALPHA);
  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    result.pixels[i] = color(0);
  }

  float max = 0;
  float[] buffer = new float[img.width * img.height];

  for (int x = 1; x < img.width-1; x++) {
    for (int y = 1; y < img.height-1; y++) {
      float sum_h = 0;
      float sum_v = 0;
      for (int i = -1; i<=1; i++) {
        for (int j = -1; j<=1; j++) {
          sum_v += brightness(img.pixels[(y+i) * img.width + (x+j)]) * verticalKernel[i+1][j+1];
          sum_h += brightness(img.pixels[(y+i) * img.width + (x+j)]) * horizontalKernel[i+1][j+1];
        }
      }
      sum_h = sum_h / normFactor;
      sum_v = sum_v / normFactor;
      float sum = sqrt(pow(sum_h, 2) + pow(sum_v, 2));
      max = (sum>=max ? sum : max);
      buffer[y*img.width + x] = sum;
    }
  }

  for (int y = 1; y < img.height - 1; y++) { // Skip top and bottom edges 
    for (int x = 1; x < img.width - 1; x++) { // Skip left and right
      int val=(int) ((buffer[y * img.width + x] / max)*255);
      result.pixels[y * img.width + x]=color(val);
    }
  }
  result.updatePixels();
  return result;
}

PImage convolute(PImage img, float[][] kernel, float normFactor) {
  // create a greyscale image (type: ALPHA) for output
  PImage result = createImage(img.width, img.height, ALPHA);
  img.loadPixels();
  for (int x = 1; x < img.width-1; x++) {
    for (int y = 1; y < img.height-1; y++) {
      float sum = 0;
      for (int i = -1; i<=1; i++) {
        for (int j = -1; j<=1; j++) {
          sum += brightness(img.pixels[(y+i) * img.width + (x+j)]) * kernel[i+1][j+1];
        }
      }
      sum = sum / normFactor;
      result.pixels[y * img.width + x] = color(sum);
    }
  }
  result.updatePixels();
  return result;
}

//trigo lookup table
void trigoLookup() {
  int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
  tabSin=new float[phiDim];
  tabCos=new float[phiDim];
  float ang=0;
  float inverseR=1.f/discretizationStepsR;
  for (int accPhi=0; accPhi<phiDim; ang+=discretizationStepsPhi, accPhi++) {
    tabSin[accPhi]=(float)(Math.sin(ang)*inverseR);
    tabCos[accPhi]=(float)(Math.cos(ang)*inverseR);
  }
}

List<PVector> hough(PImage edgeImg, int nLines) {
  // dimensions of the accumulator
  int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
  //The max radius is the image diagonal, but it can be also negative 
  int rDim = (int) ((sqrt(edgeImg.width*edgeImg.width +
    edgeImg.height*edgeImg.height) * 2) / discretizationStepsR +1);
  // our accumulator
  int[] accumulator = new int[phiDim * rDim];

  edgeImg.loadPixels();

  // Fill the accumulator: on edge points,
  // store all possible (r, phi) pairs describing lines going 
  // through the point.
  for (int y = 0; y < edgeImg.height; y++) {
    for (int x = 0; x < edgeImg.width; x++) {
      if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {
        for (int phi = 0; phi<phiDim; phi++) {
          int r = (int) (x*tabCos[phi] +y*tabSin[phi]);
          accumulator[(phi*rDim) + (r+rDim/2)] += 1;
        }
      }
    }
  }

  //week 11 part 1 step 2
  ArrayList<Integer> bestCandidates = new ArrayList<Integer>();
  for (int idx = 0; idx < accumulator.length; idx++) {
    int ai = accumulator[idx];
    if (ai > minVotes) {
      boolean max = true;
      int radius = regionSize/2;
      int accPhi = (int) (idx / (rDim));
      int accR = idx - (accPhi) * (rDim);
      int fromPhi = accPhi-radius;
      int toPhi = accPhi+radius;
      //translate the region by phiDim for positive modulus, inverse the radius values
      boolean opp = false;
      if (fromPhi<0) {
        fromPhi = phiDim+fromPhi;
        toPhi = phiDim+toPhi;
        opp = true;
      }
      int fromR = (accR-radius<0) ? 0 : accR-radius;
      int toR = (accR+radius>rDim) ? rDim : accR+radius;

      for (int phi = fromPhi; phi<toPhi; phi++) {
        for (int r=fromR; r<toR; r++) {
          //allow checking neighbours values across the phi limits
          //a line with phi=0 is equivalent to one with phi=pi/2 with inverse radius
          int nidx = (phi%phiDim)*rDim+((opp^(phi<phiDim))?r:rDim-r-1);
          if (accumulator[nidx] > ai || (accumulator[nidx] == ai && nidx < idx)) {
            max = false;
          }
        }
      }
      if (max) {
        bestCandidates.add(idx);
      }
    }
  }

  Collections.sort(bestCandidates, new HoughComparator(accumulator));

  //Créer la liste de lignes
  ArrayList<PVector> lines=new ArrayList<PVector>(); 
  for (int i = 0; i < min(nLines, bestCandidates.size()); i++) {
    int idx = bestCandidates.get(i);
    int accPhi = (int) (idx / (rDim));
    int accR = idx - (accPhi) * (rDim);
    float r = (accR - (rDim) * 0.5f) * discretizationStepsR; 
    float phi = accPhi * discretizationStepsPhi;
    lines.add(new PVector(r, phi));
  }

  //display the accumulator
  /*
  PImage houghImg = createImage(rDim, phiDim, ALPHA);
   for (int i = 0; i < accumulator.length; i++) { 
   houghImg.pixels[i] = color(min(255, accumulator[i]));
   if (bestCandidates.contains(i)) houghImg.pixels[i] = color(255, 0, 0);
   }
   for (int i = 0; i < min(nLines, bestCandidates.size()); i++) {
   int idx = bestCandidates.get(i);
   houghImg.pixels[idx] = color(0, 255, 0);
   }
   houghImg.resize(600, 600);
   houghImg.updatePixels();
   image(houghImg, edgeImg.width, 0);
   */

  return lines;
}

boolean imagesEqual(PImage img1, PImage img2) {
  if (img1.width != img2.width || img1.height != img2.height)
    return false;
  img1.loadPixels();
  img2.loadPixels();
  for (int i = 0; i < img1.width*img1.height; i++)
    //assuming that all the three channels have the same value
    if (red(img1.pixels[i]) != red(img2.pixels[i]))
      return false;
  return true;
}

PImage changeColor(PImage img, int initColor, int newColor) {
  PImage result = img.copy();
  result.loadPixels();
  for (int i = 0; i < img.width*img.height; i++) {
    if (result.pixels[i] == initColor) 
      result.pixels[i] = newColor;
  }
  result.updatePixels();
  return result;
}

PImage addImages(PImage img1, PImage img2) {
  PImage result = createImage(img1.width, img1.height, ALPHA); 
  if (img1.width != img2.width || img1.height != img2.height)
    return result;
  img1.loadPixels();
  img2.loadPixels();
  for (int i = 0; i < img.width*img.height; i++) {
    if (img1.pixels[i] == color(0))
      result.pixels[i] = img2.pixels[i];
    else if (img2.pixels[i] == color(0))
      result.pixels[i] = img1.pixels[i];
    else {
      int c1 = img1.pixels[i];
      int c2 = img2.pixels[i];
      result.pixels[i] = color((red(c1)+red(c2))/2, (green(c1)+green(c2))/2, (blue(c1)+blue(c2))/2);
    }
  }
  result.updatePixels();
  return result;
}

void displayLines(List<PVector> lines, PImage edgeImg) {
  for (int idx = 0; idx < lines.size(); idx++) {
    PVector line=lines.get(idx);
    float r = line.x; 
    float phi = line.y;

    stroke(204, 102, 0);

    //divided by 0 cases 
    if (phi == 0) {
      line(r, 0, r, edgeImg.height);
    } else if (phi==PI/2.) {
      line(0, r, edgeImg.width, r);
    } else {

      // Cartesian equation of a line: y = ax + b
      // in polar, y = (-cos(phi)/sin(phi))x + (r/sin(phi)) // => y = 0 : x = r / cos(phi)
      // => x = 0 : y = r / sin(phi)
      // compute the intersection of this line with the 4 borders of the image
      int x0 = 0;
      int y0 = (int) (r / sin(phi));
      int x1 = (int) (r / cos(phi));
      int y1 = 0;
      int x2 = edgeImg.width;
      int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi)); 
      int y3 = edgeImg.width;
      int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));

      if (y0 > 0) {
        if (x1 > 0)
          line(x0, y0, x1, y1);
        else if (y2 > 0)
          line(x0, y0, x2, y2);
        else
          line(x0, y0, x3, y3);
      } else { //r<0
        if (x1 > 0) {
          if (y2 > 0)
            line(x1, y1, x2, y2);
          else 
          line(x1, y1, x3, y3);
        } else
          line(x2, y2, x3, y3);
      }
    }
  }
}
