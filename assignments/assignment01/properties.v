// Instructions:
// - Implement the properties in this file.
// - Submit this file only.
// - Don't change the name of the file when submitting.

module properties(clk, rst, pedestrian_btn, car_light, pedestrian_light);
input clk;
input rst;
input wire pedestrian_btn;
input reg [1:0] car_light;
input reg [1:0] pedestrian_light;
// Note that both car_light and pedestrian_light are defined as inputs above,
// even though they are defined as outputs in the module we want to monitor.

import state_pkg::*;

// *************** INSTRUCTION FOR PART A:   ***************
// *************** EDIT ONLY BELOW THIS LINE ***************
// *********************************************************
   
// NOTE: 
// - Don't change the property names (P1, P2, ...) below.
// - Don't change the labels (A1, A2, ...) below.
// - Edit only the lines where you see "EDIT HERE".
// - The answer for the first assert (A1) is given as an example.

// Example solution for the first specificaton:
// A1: Always either the car light is red, or the pedestrian light is red (or both).
property P1;
   (@(posedge clk) (car_light == RED || pedestrian_light == RED));
endproperty
A1: assert property (P1);

property P2;
//A2: Red car light can only change to green, or remain red.
  (@(posedge clk) ((car_light == RED |=> (car_light == GREEN || car_light == RED))));
endproperty
A2: assert property (P2);

property P3;
  //A3: Green car light can only change to yellow, or remain green.
  (@(posedge clk) (car_light == GREEN |=> (car_light == YELLOW || car_light == GREEN)));
endproperty
A3: assert property (P3);

property P4;
  //A4: Yellow car light can only change to red, or remain yellow.
  (@(posedge clk) (car_light == YELLOW |=> (car_light == RED || car_light == YELLOW)));
endproperty
A4: assert property (P4);

property P5;
  // A5: The car light can only be either red, or green, or yellow.
  (@(posedge clk) (car_light == YELLOW || car_light == RED || car_light == GREEN));
endproperty
A5: assert property (P5);

property P6;
  // A6: The pedestrian light can only be either red, or green.
  (@(posedge clk) (pedestrian_light == RED || pedestrian_light == GREEN));
endproperty
A6: assert property (P6);

property P7;
  // A7: If pedestrian light is green, then car light is red.
 (@(posedge clk) (pedestrian_light == GREEN |-> car_light == RED));
endproperty
A7: assert property (P7);

property P8;
  // A8: If car light is green, then pedestrian light is red.
  (@(posedge clk) (car_light == GREEN |-> pedestrian_light == RED));
endproperty
A8: assert property (P8);

property P9;
  // A9: If pedestrian light is green, then car light in the previous cycle is red.
  (@(posedge clk) 1 ##1 (pedestrian_light == GREEN) |-> $past(car_light, 1) == RED );
endproperty
A9: assert property (P9);

property P10;
  //A10: If car light is green, then pedestrian light in the previous cycle is red.
  (@(posedge clk) 1 ##1 (car_light == GREEN) |-> $past(pedestrian_light, 1) == RED);
endproperty
A10: assert property (P10);

property P11;
  //  A11: Car light is never stuck at green
  (@(posedge clk) (car_light == GREEN) |-> s_eventually (car_light == YELLOW || car_light == RED));
endproperty
A11: assert property (P11);

property P12;
  // A12: Pedestrian light is never stuck at red.
  (@(posedge clk) (pedestrian_light == RED) |-> not always (pedestrian_light == RED));
endproperty
A12: assert property (P12);

// *************** EDIT ONLY ABOVE THIS LINE *****************

endmodule

// This binds the properties to traffic_light:
bind traffic_light properties properties_i(.*);
