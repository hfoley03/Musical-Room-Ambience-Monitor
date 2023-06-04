import oscP5.*;
import netP5.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Timer;
import java.util.TimerTask;
import java.util.LinkedList;
import java.util.Queue;

OscP5 oscP5;
NetAddress myRemoteLocation;
float counterSun = 180;
float counterMoon = 0;
float counterTrans = 0;
float moonX;
float moonY;
float sunX;
float sunY;

int but1X, but1Y;      // Position of square button
int but2X, but2Y;  // Position of circle button
int butSize = 93;   // Diameter of circle
color but1Color, but2Color, baseColor;
color but1Highlight, but2Highlight;
color currentColor;
boolean but1Over = false;
boolean but2Over = false;
int but1ColorB = 60;
int but2ColorB = 60;

int melodySelector= 0;
int fieldSelector = 0;

int hr = 9;
int min = 0;
String day_state = "Morning";
int day_state_int = 0;
PImage img;
int transVal = 255;
int skyR = 135;
float skyB = 180;
int skyG = 235;
float skyDelta = -1;
 // background(skyR, skyB, skyG);
Integer howCloudy = 0;
float light_sensor = 0.0;
Queue<Float> queue = new LinkedList<>();
int queueSize = 0;
Float averagedLightLevel = 0.0;


void setup() {
  size(720, 640);
  noStroke();
  rectMode(CENTER);
  ellipseMode(CENTER);
  frameRate(125);
  oscP5 = new OscP5(this, 7771);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
  Timer incCounter = new Timer();
  incCounter.schedule(new TimerTask() {
    @Override
      public void run() {
      //System.out.println("Increment!");
      counterSun -= 0.25;
      counterMoon -= 0.25;
      counterTrans -= 0.25;
      skyB = skyB + skyDelta;
      incCLock();
      stateOfDay();
      //System.out.println(day_state);
    }
  }
  , 0, 50);


  but1Color = color(182, 60, 71);
  but1Highlight = color(204);
  but2Color = color(136, 60, 119);
  but2Highlight = color(204);
  baseColor = color(102);
  currentColor = baseColor;
  but2X = width/3 + width/2 - width/10;
  but2Y = height/8;
  but1X = width/3 + width/2 + width/20;
  but1Y = but2Y;
  img = loadImage("SebImg.png");
}

void draw() {
  background(skyR, skyB, skyG);
  but1Color = color(182, but1ColorB, 71);
  but2Color = color(136, but2ColorB, 119);
  fill(255, 204);
  textSize(16);
  text("Synth Type          Field Recording", (width/3 + width/2 - width/48), height/25); 
  riseSet();

  cloudShape((width*averagedLightLevel - 100), 100, 80);
  cloudShape((width-(width*averagedLightLevel)) + 200, 300, 100);  
  cloudShape((width-(width*averagedLightLevel)) + 350, 200, 150);

  if (hr>17  ||  hr < 9 ){
      //System.out.println("start to darken");
      tint(255, transVal);
      transVal = transVal - 1;
      skyDelta = -0.5;
      if (transVal <= 180){
        transVal = 180;
      }
      if (skyB <= 100){
        skyB = 100;
      }
  }
   else {
      //System.out.println("start to bright");
      tint(255, transVal);
      transVal = transVal + 1;
      skyDelta = + 0.5;
      if (transVal >= 254){
        transVal = 255;
      } 
      if (skyB >= 180){
        skyB = 180;
      }
  }
  

  image(img, 0, 100, width, height);
  fill(205, 255, 255);
  digiClock();

  LocalDateTime myDateObj = LocalDateTime.now();
  DateTimeFormatter myFormatObj = DateTimeFormatter.ofPattern("ss");

  String formattedDate = myDateObj.format(myFormatObj);
  float secFloat = parseFloat(formattedDate);
  float sunYtoDecimal = scaleBetween(sunY, 0.0, 1.0, 1280, 320);

  OscMessage myMessage = new OscMessage("/pos");
  myMessage.add(sunYtoDecimal);
  myMessage.add(sunYtoDecimal);
  myMessage.add(melodySelector);
  myMessage.add(day_state_int);
  oscP5.send(myMessage, myRemoteLocation);

  update(mouseX, mouseY);

  if (but1Over) {
    fill(but1Highlight);
  } else {
    fill(but1Color);
  }
  ellipse(but1X, but1Y, butSize, butSize);

  if (but2Over) {
    fill(but2Highlight);
  } else {
    fill(but2Color);
  }
  ellipse(but2X, but2Y, butSize, butSize);
}



// controls position of Sun and Moon
void riseSet(){
  int orbitH = height + height/3;
  int orbitW = width + width/3;
  sunX = ((orbitW/2)*cos(radians(counterSun))+ width/2);
  sunY = ((-orbitH/2)*sin(radians(counterSun)) + height);
  moonX = ((orbitW/2)*cos(radians(counterMoon))+ width/2);
  moonY = ((-orbitH/2)*sin(radians(counterMoon)) + height);
  fill(255, 232, 67);
  circle(sunX, sunY, width/6);
  fill(254, 252, 215);
  circle(moonX, moonY , width/8);
}

// scales values in range 
float scaleBetween(float unscaledNum, float  minAllowed, float maxAllowed, float  min, float  max) {
  return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

// creates cloud shape
void cloudShape(float cloudX, float cloudY, float cloudSize){
  fill(248,246,246);
  circle(cloudX,cloudY,cloudSize);
  circle((cloudX - cloudSize/2),cloudY,cloudSize*0.8);
  rect((cloudX - cloudSize/3), (cloudY + cloudSize/4 ), cloudSize*2, cloudSize/2, cloudSize/4); 
}

//Button Functions 

void update(int x, int y) {
  if ( overCircle(but2X, but2Y, butSize) ) {
    but2Over = true;
    but1Over = false;
  } else if ( overCircle(but1X, but1Y, butSize) ) {
    but1Over = true;
    but2Over = false;
  } else {
    but2Over = but1Over = false;
  }
}

void mousePressed() {
  if (but2Over) {
    currentColor = but2Color;
    if (melodySelector == 0){
    melodySelector = 1;
    but2ColorB = 100;
  }
    else {
      melodySelector = 0;
      but2ColorB = 60;  
    }
  }
  if (but1Over) {
    currentColor = but1Color;
    if (fieldSelector == 0){
    fieldSelector = 1;
    but1ColorB = 100;  
}
    else {
      fieldSelector = 0;
      but1ColorB = 60;  
    }
  }
}

boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width &&
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}


// Clock Functions 

void incCLock() {
  if (min<60) {
    min += 1;
  } else {
    min = 0;
    hr += 1;
  }
  if (hr>=24) {
    hr = 0;
  }
}

void digiClock() {
  textSize(100);
  textAlign(CENTER);
  if (hr < 10) {
    text ("0" + hr + ":" + nf(min, 2), width/2, (9.5*height/10));
  } else {
    text (hr + ":" + nf(min, 2), width/2, (9.5*height/10));
  }

  textSize(25);
  text (day_state, width/2, (9.85*height/10));
}


// controls state of day Morning, Day, Evening, Night
void stateOfDay(){
  if (hr >= 6 && hr < 12) {day_state_int = 0; day_state = "Morning"; }
  else if (hr >= 12 && hr < 18) {day_state_int = 1; day_state = "Day"; }
  else if (hr >= 18 && hr < 21) {day_state_int = 2; day_state = "Evening"; }
  else {day_state_int = 3; day_state = "Night"; }
}

// Fucntion recives osc messages
void oscEvent(OscMessage messageIN){
  if(messageIN.addrPattern().equals("/cloudy")){
    howCloudy = messageIN.get(0).intValue();
    howCloudy = 1024 - howCloudy ;
    //System.out.printf(" cloudy ");
    float divide = 1024.0;
    light_sensor = howCloudy.floatValue() / 1024;
    System.out.printf("inst: " + Float.toString(light_sensor));
    lightDataBuffering();
  }
}



// buffering light data using the average value of a queue
void lightDataBuffering(){
  if (queue.size()>100){
    System.out.println("remove");
    queue.remove();
  }
  queue.add(light_sensor);
  Float total = sum(queue);
  averagedLightLevel = total/queue.size(); 
  System.out.printf(" avg: " + Float.toString(averagedLightLevel));
  System.out.println(" " + queue);
  System.out.printf("\n");

}

// used to get sum of queue
public static Float sum(Queue<Float> q) {
Float sum = 0.0;
for (int i = 0; i < q.size(); i++) {
Float n = q.remove();
sum += n;
q.add(n);
}
return sum;
}
