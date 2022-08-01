# Knight-s-Tour

- Language: System Verilog
- Description: This is a project to solve the Knight's Tour problem using an algorithm. 


## Knight's Tour
Knight's Tour is a sequence of moves of a knight on a chessboard such that the knight visits every square exactly once. 

![SmartSelect_20220801-104057_Samsung Notes](https://user-images.githubusercontent.com/109056537/182056549-8af16472-7ad8-4ac4-a18d-50eb2e822858.jpg)

We implemented the algorithm using System Verilog. The FPGA virtually solves the problem and then re-plays all the moves of the solution to make "the knight" physically tour the board. 


## Composition
- TourLogic: Solves the Knight's Tour problem virtually to come up with a solution.
- TourCmd: Re-play module. Takes the moves stored in memory and makes them into movement commands to actually make the robot perform the tour. 
