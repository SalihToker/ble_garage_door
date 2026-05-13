# BLE Garage Door Prototype

Hello! This repository contains a simple garage door prototype I developed to learn hardware-software communication using Flutter and Arduino. 

My goal was to grasp the logic of sending commands to physical hardware via Bluetooth Low Energy (BLE) through a mobile app. It might have some shortcomings, but it has been a great learning project that helped me understand the core concepts of IoT (Internet of Things).

## Key Features
* **Connectivity:** Communication with Android devices via the HM-10 (BLE) module.
* **Interface:** A mobile UI built with Flutter, featuring a simple PIN screen for basic security.
* **Hardware:** Arduino UNO R4, a Servo Motor (SG90) to simulate the door mechanism, and status LEDs.

## Circuit Diagram
When setting up the connections, I used a simple voltage divider to safely step down the signal to the 3.3V logic level required by the HM-10 module's RX pin. You can see the circuit diagram of the project below:

![Circuit Diagram](devre_semasi/garajj.png)

## Technologies Used
* **Software:** Flutter, Dart, C++ (Arduino IDE)
* **Packages:** flutter_blue_plus
* **Hardware:** Arduino UNO, HM-10 BLE, Servo Motor, LEDs, and Resistors

Thanks for checking it out!
