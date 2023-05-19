int M_sensor = 2;            // the pin that the sensor is atteched to
int val = 0;                 // variable to store the sensor status (value)
int counter = 0;
void setup()
{
  pinMode(M_sensor, INPUT);   // initialize sensor as an input
  Serial.begin(9600);         // initialize serial
}
void loop()
{
  int light, motion;
  delay(100);
  light = analogRead(1);      //connect light sensor to Analog 0
  Serial.print(light);        //print the value to serial
  Serial.print("a");          //print "a" to indicate that is light sensor value 

  motion = digitalRead(M_sensor);   // read sensor value         
  Serial.print("\n");

  if (motion == 1) {          // check if the sensor is HIGH  
    counter = 10*5;           // reset counter 
    Serial.print(1);          // send 1 to SC
    Serial.print("b");        //print "b" to indicate that is motion sensor value 
  }
  else if (counter > 0){      // if counter > 0 countinue sending 1 to SC 
    Serial.print(1); 
    Serial.print("b");
    counter = counter - 1;
  }
  else {                      // else there has been no motion in the defined period of recent time                         
    Serial.print(0);          //so send SC 0
    Serial.print("b");
  }  
}