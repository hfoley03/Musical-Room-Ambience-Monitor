import oscP5.*;
import netP5.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Timer;
import java.util.TimerTask;

OscP5 oscP5;
NetAddress myRemoteLocation;
float counterSun =180;
float counterMoon =0;
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

int melodySelector= 0;
int hr = 9;
int min =0;
String day_state = "Morning";
int day_state_int = 0;



void setup() {
  size(720, 640); 
  noStroke();
  rectMode(CENTER);
  ellipseMode(CENTER);
  frameRate(125);
  oscP5 = new OscP5(this,12000);
  myRemoteLocation = new NetAddress("127.0.0.1",57120);

  Timer incCounter = new Timer();
  incCounter.schedule(new TimerTask() {
      @Override
      public void run() {
        System.out.println("Increment!");
        counterSun -= 0.25;
        counterMoon -= 0.25;
        incCLock();
        stateOfDay();
        System.out.println(day_state);

        
      }
    }, 0, 100);
    
    
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
    
    
}

void draw() {
  background(135, 204*sin(radians(counterSun)), 235);
  fill(255, 204);
  textSize(16);
  text("Pink a Melody", (width/3 + width/2 - width/12), height/25); 
  //rect(mouseX, height/2, mouseY/2+10, mouseY/2+10);
  //int inverseX = width - mouseX;
  //int inverseY = height - mouseY;
  //rect(inverseX, height/2, (inverseY/2)+10, (inverseY/2)+10);

  
  fill(0, 154, 100);
  arc(width/2, height*1.25, width, height, PI, TWO_PI);

  fill(205, 255, 255);
  digiClock();
  
  riseSet();
  
  cloudShape((mouseX*1.5), 100, 80);
  
  cloudShape((width-mouseX)*1.5, 300, 100);
  
  cloudShape((width-mouseX)*2.5, 200, 150);

  
  LocalDateTime myDateObj = LocalDateTime.now();
  DateTimeFormatter myFormatObj = DateTimeFormatter.ofPattern("ss");

  String formattedDate = myDateObj.format(myFormatObj);
  //System.out.println("Time as String: " + formattedDate);
  float secFloat = parseFloat(formattedDate);
  //System.out.printf("%f\n", secFloat );
  float sunYtoDecimal = scaleBetween(sunY, 0.0, 1.0, 1280, 320);
  //System.out.printf("sun Decimal %f\n",  sunYtoDecimal );
  
  
  OscMessage myMessage = new OscMessage("/pos");
  myMessage.add(sunYtoDecimal);
  myMessage.add(sunYtoDecimal);
  myMessage.add(melodySelector);
  myMessage.add(day_state_int);

  oscP5.send(myMessage, myRemoteLocation); 
  myMessage.print();

  update(mouseX, mouseY);
  //background(currentColor);
  fill(currentColor);
  rect(0, 0, 100,100);
  
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


void riseSet(){
  //System.out.printf("%f\n",cos(radians(counter)));
  sunX = ((width/2)*cos(radians(counterSun))+ width/2);
  sunY = ((-height/2)*sin(radians(counterSun)) + height);
  moonX = ((width/2)*cos(radians(counterMoon))+ width/2);
  moonY = ((-height/2)*sin(radians(counterMoon)) + height);
  fill(255, 232, 67);
  circle(sunX, sunY, width/6);
  fill(254, 252, 215);
  circle(moonX, moonY , width/8);
}


 float scaleBetween(float unscaledNum, float  minAllowed, float maxAllowed, float  min, float  max) {
      return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

void cloudShape(float cloudX, float cloudY, float cloudSize){
  fill(248,246,246);
  circle(cloudX,cloudY,cloudSize);
  circle((cloudX - cloudSize/2),cloudY,cloudSize*0.8);
  rect((cloudX - cloudSize/3), (cloudY + cloudSize/4 ), cloudSize*2, cloudSize/2, cloudSize/4); 
}

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
    melodySelector = 0;
  }
  if (but1Over) {
    currentColor = but1Color;
    melodySelector = 1;
  }
}

boolean overRect(int x, int y, int width, int height)  {
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

void incCLock(){
    if(min<60){
        min += 1;
      }
    else{
    min = 0;
    hr += 1;
  }
  if (hr>=24){
  hr = 0;
}
}

void digiClock(){
  textSize(100);
  textAlign(CENTER);
  if (hr < 10){
  text ("0" + hr + ":" + nf(min, 2), width/2,(height/10)*9.5);
  }
  else {
  text (hr + ":" + nf(min, 2), width/2,(height/10)*9.5);
  }
  
  textSize(25);
  text (day_state, width/2,(height/10)*9.9);

  
}

void stateOfDay(){
  if (hr >= 6 && hr < 12) {day_state_int = 0; day_state = "Morning"; }
  else if (hr >= 12 && hr < 18) {day_state_int = 1; day_state = "Day"; }
  else if (hr >= 18 && hr < 21) {day_state_int = 2; day_state = "Evening"; }
  else {day_state_int = 2; day_state = "Night"; }

}
