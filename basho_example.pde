Basho basho;

float a = 0;
float[][] b = new float[2][2];

void setup(){
  size(400, 400);
  basho = new Basho(this);
}

void draw(){
  a = sin(0.1 * frameCount);
}
