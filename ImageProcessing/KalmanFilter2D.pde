class KalmanFilter2D {
  float q=1; // process variance
  float r=1.0; // estimate of measurement variance, change to see effect
  PVector dhat= new PVector(0.0, 0.0); // a posteriori estimate of {x,y}
  PVector dhatminus; // a priori estimate of {x,y}
  PVector p=new PVector(1.0, 1.0); // a posteriori error estimate
  PVector pminus; // a priori error estimate
  PVector kG=new PVector(0.0, 0.0); // kalman gain

  KalmanFilter2D() {
  }

  KalmanFilter2D(float q, float r) {
    q(q);
    r(r);
  }

  void q(float q) {
    this.q=q;
  }

  void r(float r) {
    this.r=r;
  }

  PVector dhat() {
    return this.dhat;
  }

  void predict() {
    dhatminus=dhat;
    pminus=p.add(q, q);
  }

  PVector correct(PVector d) {
    kG.x=pminus.x/(pminus.x+r);
    kG.y=pminus.y/(pminus.y+r);
    dhat.x=dhatminus.x+kG.x*(d.x-dhatminus.x);
    dhat.y=dhatminus.y+kG.y*(d.y-dhatminus.y);
    p.x=(1-kG.x)*pminus.x;
    p.y=(1-kG.y)*pminus.y;
    return dhat;
  }

  PVector predict_and_correct(PVector d) {
    predict();
    return correct(d);
  }
}
