# Morse Code 
#### with LED and transducer
2016 BYU CS 224 Lab 6


### Description:
"Use your Morse Code main assembly lab code to write a C program that outputs alphanumeric Morse code messages using an LED and a transducer (magnetic speaker). Use the watchdog as an interval timer whose interrupt service routine (ISR) pulse width modulates (PWM) the transducer device creating a tone. Use a C string to store the message. Use Switch #1 to toggle the tones on and off."
 
### Learn:
- Translate assembly language code to C.
- Use a C header file to share assembly/C constants and definitions among different program modules.
- Interface C code with external functions including assembly and other C modules.
- Strengthen function data coherency by passing pointer variables to functions altering external data.
- Demonstrate "callee-save" protocol when calling C/assembly subroutines.
- Link symbolic values together from different program files.

### Specs:
- 1 point	Your Morse II Lab includes C and assembly code, and contains header comments stating your name and a declaration that the completed assignment is your own work.
- 2 points	Your Morse Code "main" function and at least one ISR are written in C. At least one assembly function is called from C using correct C calling convention and is callee-safe.
- 1 point	Assembly arrays numbers and letters in morse_codes.asm are correctly referenced in your C program as character pointer arrays.
- 2 points	A C header file containing all C #define's and assembly equates(.equ's changed to #define's) is included in all .c and .asm files. NO VARIABLE OR FUNCTION DEFINITIONS ARE FOUND IN THE HEADER FILE (ie, only declarations, pre-processor commands, and function prototypes).
- 2 points	Your commented assembly code appears to the right of the C statements. (Small blocks of assembly code are acceptable. See example above.)
- 2 points	Your C Morse Code II machine meets all the same requirements as the assembly Morse Code lab.


https://students.cs.byu.edu/~clement/cs224/labs/L07b-morse2/morse2.php?Preparation=1&TheLab=1
