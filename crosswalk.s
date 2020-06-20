.global main

/*
To compile: g++ crosswalk.s -lwiringPi -g -o crosswalk
Project Name: Crosswalk Simulator
Creator: Brandon Sanchez
Created on: 06/03/2020
*/

//Equates light pins and other useful light integers

.equ INPUT, 0
.equ OUTPUT, 1
.equ LOW, 0
.equ HIGH, 1

.equ STR_RED_PIN, 25 	//WPI 25 = BCM 26
.equ STR_YELLOW_PIN, 24 //WPI 24 = BCM 19
.equ STR_GREEN_PIN, 23  //WPI 23 = BCM 13, STR = Street

.equ CW_RED_PIN, 26 	//WPI 26 = BCM 12
.equ CW_GREEN_PIN, 27 	//WPI 27 = BCM 16, CW = Crosswalk

.equ TERMINATE_PIN, 3 	//WPI 3 = BCM 22
.equ CW_BUTTON_PIN, 29 	//WPI 29 = BCM 21

.equ PAUSE_S, 15 	//15s
.equ CW_DELAY, 15000 	//15s

.align 4	        //Ensures storage width is 4 bytes
.text

//Initializes all pins to their respective I/O modes
main:
	push {lr}
	bl wiringPiSetup

	mov r0, #CW_BUTTON_PIN
	bl setPinInput

	mov r0, #TERMINATE_PIN
	bl setPinInput

	mov r0, #CW_RED_PIN
	bl setPinOutput

	mov r0, #CW_GREEN_PIN
	bl setPinOutput

	mov r0, #STR_RED_PIN
	bl setPinOutput

	mov r0, #STR_YELLOW_PIN
	bl setPinOutput

	mov r0, #STR_GREEN_PIN
	bl setPinOutput

//Loops and calls action function, terminate button press = ends program, cw button press = switch colors
loop:
	mov r0, #CW_GREEN_PIN   //Pin to turn off
	mov r1, #CW_RED_PIN 	//Pin to turn on
	mov r2, #0 		//0 Delay to not interfere with the next delay call
	bl action

	mov r0, #STR_RED_PIN 	//Pin to turn off
	mov r1, #STR_GREEN_PIN 	//Pin to turn on
	mov r2, #PAUSE_S 	//15s delay
	bl action

	cmp r0, #1
	beq switch_colors

	cmp r0, #2
	beq end

	b loop

//If cw button is pressed, switch lights
switch_colors:
	mov r0, #CW_RED_PIN
	bl pinOff

	mov r0, #CW_GREEN_PIN
	bl pinOn

	mov r0, #STR_GREEN_PIN
	bl pinOff

	mov r0, #STR_RED_PIN
	bl pinOn

	ldr r0, =#10000
	bl delay

	mov r2, #1 	//Loop counter for flash function

//Loops 5 times for a total of 5 seconds
flash:
	push {r2} 		//Stores loop counter for later compare
	mov r0, #STR_YELLOW_PIN
	bl pinOn

	mov r0, #STR_GREEN_PIN
	bl pinOn

	ldr r0, =#500 		//Delay allows button to flash
	bl delay

	mov r0, #STR_YELLOW_PIN
	bl pinOff

	mov r0, #STR_GREEN_PIN
	bl pinOff

	ldr r0, =#500		//Delay allows button to flash
	bl delay

	pop {r2}
	cmp r2, #5
	beq loop 		//After 5 loops, go back to main loop

	add r2, r2, #1 		//Increment
	b flash 		//Recursive

//Sets pin in r0 to input mode
setPinInput:
	push {lr}
	mov r1, #INPUT
	bl pinMode
	pop {pc}

//Sets pin in r0 to output mode
setPinOutput:
	push {lr}
	mov r1, #OUTPUT
	bl pinMode
	pop {pc}

//Turns pin in r0 on
pinOn:
	push {lr}
	mov r1, #HIGH
	bl digitalWrite
	pop {pc}

//Turns pin in r0 off
pinOff:
	push {lr}
	mov r1, #LOW
	bl digitalWrite
	pop {pc}

//Checks if the cw button was pressed
readButton:
	push {lr}
	mov r0, #CW_BUTTON_PIN //r0 <- #29
	bl digitalRead
	pop {pc}

//Checks if the terminate button was pressed
readTerminate:
	push {lr}
	mov r0, #TERMINATE_PIN
	bl digitalRead
	pop {pc}

//r0 = turned off pin, r1 = turned on pin
//r3 = 15s delay
//return value: r0=0, no press | r1=1, cw pressed | r2=2, terminate pressed
action:
	push {r4, r5, lr}	//Saves registers according to ARM procedure

	mov r4, r1
	mov r5, r2
	bl pinOff

	mov r0, r4
	bl pinOn

	mov r0, #0
	bl time
	mov r4, r0 		//Saves current time to compare later

//Checks if buttons are pressed
do_while:
	bl readButton
	cmp r0, #HIGH
	beq action_done 	//If cw button pressed

	bl readTerminate
	cmp r0, #HIGH
	mov r0, #2
	beq action_done 	//If terminate button pressed

	mov r0, #0
	bl time

	sub r0, r0, r4 		//r0 = time(0) - r4, new r0 is # of seconds elapsed

	cmp r0, r5
	blt do_while
	mov r0, #0
action_done:
	pop {r4, r5, pc}

//Once terminate button is pressed, turn off all lights & terminate
end:
	mov r0, #CW_GREEN_PIN
	bl pinOff

	mov r0, #CW_RED_PIN
	bl pinOff

	mov r0, #STR_GREEN_PIN
	bl pinOff

	mov r0, #STR_YELLOW_PIN
	bl pinOff

	mov r0, #STR_RED_PIN
	bl pinOff

	mov r0, #0
	pop {pc} 	//Return 0
