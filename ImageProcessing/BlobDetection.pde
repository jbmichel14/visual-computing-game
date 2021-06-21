import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;

class BlobDetection {

  int[][] colors = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 255, 255}};

  PImage findConnectedComponentsBinary(PImage input, boolean onlyBiggest) {
    return findConnectedComponents(input, onlyBiggest, 0, 0, 0, 0, 1, 255);
  }

  PImage findConnectedComponents(PImage input, boolean onlyBiggest, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
    // First pass: label the pixels and store labels' equivalences

    int[] labels= new int[input.width*input.height];
    List<TreeSet<Integer>> labelsEquivalences= new ArrayList<TreeSet<Integer>>();

    int currentLabel= 0;

    for (int x = 0; x < input.width; x++) {
      for (int y = 0; y < input.height; y++) {
        int lab = 0;
        if (inColorRange(input.pixels[y*input.width+x], minH, maxH, minS, maxS, minB, maxB)) {
          TreeSet<Integer> neigh_labels = neighbors_labels(input, labels, x, y);
          if (neigh_labels.isEmpty()) {
            currentLabel++;
            lab = currentLabel;
            labelsEquivalences.add(new TreeSet<Integer>());
            labelsEquivalences.get(lab-1).add(lab);
          } else {
            lab = neigh_labels.first();
            for (int l : neigh_labels) {
              TreeSet<Integer> neigh_equi = labelsEquivalences.get(l-1);
              labelsEquivalences.get(lab-1).addAll(neigh_equi);
              labelsEquivalences.set(l-1, labelsEquivalences.get(lab-1));
            }
          }
        }
        labels[y*input.width+x] = lab;
      }
    }

    int[] blob_size = new int[labelsEquivalences.size()];

    // Second pass: re-label the pixels by their equivalent class
    // if onlyBiggest==true, count the number of pixels for each label

    for (int x = 0; x < input.width; x++) {
      for (int y = 0; y < input.height; y++) {
        int lab = labels[y*input.width+x];
        if (lab != 0) {
          labels[y*input.width+x] = labelsEquivalences.get(lab-1).first();
          blob_size[labels[y*input.width+x]-1]++;
        }
      }
    }

    // Finally:
    // if onlyBiggest==false, output an image with each blob colored in one uniform color
    // if onlyBiggest==true, output an image with the biggest blob in white and others in black

    PImage result = createImage(img.width, img.height, ALPHA);

    if (onlyBiggest == true) {
      int biggest = 0;
      for (int i = 0; i < blob_size.length; i++) {
        biggest = (blob_size[i] > blob_size[biggest] ? i : biggest);
      }
      for (int x = 0; x < input.width; x++) {
        for (int y = 0; y < input.height; y++) {
          int lab = labels[y*input.width+x];
          if (lab != 0 && lab-1 == biggest) {
            result.pixels[y*input.width+x] = color(255);
          } else {
            result.pixels[y*input.width+x] = color(0);
          }
        }
      }
    } else {
      for (int x = 0; x < input.width; x++) {
        for (int y = 0; y < input.height; y++) {
          int lab = labels[y*input.width+x];
          if (lab != 0) {
            if (lab < colors.length)
              result.pixels[y*input.width+x] = color(colors[lab-1][0], colors[lab-1][1], colors[lab-1][2]);
            else println("NO COLOR TO ASSIGN!!!");
          } else {
            result.pixels[y*input.width+x] = color(0);
          }
        }
      }
    }
    result.updatePixels();
    return result;
  }


  TreeSet<Integer> neighbors_labels(PImage input, int[] labels, int x, int y) {
    TreeSet<Integer> neigh_labels = new TreeSet<Integer>();
    if (y > 0) {
      neigh_labels.add(labels[(y-1)*input.width+x]);
      if (x > 0) {
        neigh_labels.add(labels[(y-1)*input.width+(x-1)]);
      }
      if (x+1 < input.width) {
        neigh_labels.add(labels[(y-1)*input.width+(x+1)]);
      }
    }
    if (x > 0) {
      neigh_labels.add(labels[y*input.width+(x-1)]);
    }

    neigh_labels.remove(0);
    return neigh_labels;
  }
}
