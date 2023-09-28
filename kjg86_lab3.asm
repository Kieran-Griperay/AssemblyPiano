# YOUR NAME HERE
# YOUR USERNAME HERE

# preserves a0, v0
.macro print_str %str
	# DON'T PUT ANYTHING BETWEEN .macro AND .end_macro!!
	.data
	print_str_message: .asciiz %str
	.text
	push a0
	push v0
	la a0, print_str_message
	li v0, 4
	syscall
	pop v0
	pop a0
.end_macro

# named constants, static FINAL constants
#they behave just like numbers, so they aren't variables
.eqv NOTE_DURATION_MS 400
.eqv NOTE_VOLUME      100

.data
	instrument: .word 0

	demo_notes: .byte
		67 67 64 67 69 67 64 64 62 64 62
		67 67 64 67 69 67 64 62 62 64 62 60
		#60 60 64 67 72 69 69 72 69 67
		#67 67 64 67 69 67 64 62 64 65 64 62 60
		-1 # ends the song!

	demo_times: .word
		250 250 250 250 250 250 500 250 750 250 750
		250 250 250 250 250 250 500 375 125 250 250 1000
		#375 125 250 250 1000 375 125 250 250 1000
		#250 250 250 250 250 250 500 250 125 125 250 250 1000
		0

	# maps from ASCII to MIDI note numbers, or -1 if invalid.
	key_to_note_table: .byte
		-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 # control characters
		-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
		-1 -1 -1 75 -1 78 82 -1 85 87 -1 -1 60 -1 -1 -1 # symbols and numbers
		75 -1 61 63 -1 66 68 70 -1 73 -1 -1 48 -1 -1 -1
		73 -1 43 40 39 76 -1 42 44 84 46 -1 -1 47 45 86 # uppercase
		88 72 77 37 79 83 41 74 38 81 36 -1 -1 -1 80 -1
		-1 -1 55 52 51 64 -1 54 56 72 58 -1 -1 59 57 74 # lowercase
		76 60 65 49 67 71 53 62 50 69 48 -1 -1 -1 -1 -1
.text

# -------------------------------------------------

.globl main
main:
	
	_loop:
		print_str " command? [d]emo, [k]eyboard, [q]uit: "
		
		li v0, 12
		syscall
		print_str "\n"
		beq v0, 'd', _case0
		beq v0, 'k', _case1
		beq v0, 'q', _case2
		j _default
		_case0: 
			
			jal demo
			j _break
		_case1: 
			jal keyboard
			j _break
		_case2:
			li v0, 10
			syscall
			j _break
		
		_default:
			print_str "Sorry I don't understand"
		_break:
		
	j _loop
# --------------------------------------------------------------------
demo:
push ra 
push s0

#initializing i...
li s0, 0

_loopy: #loop start
lb a0 demo_notes(s0) 
jal play_note

beq a0, -1, _break #branch conditional a0 = -1
mul s1 s0 4 #multiply so that you can index words
lw a0 demo_times(s1) #this be the time inbeween each note
li v0 32
syscall
add s0 s0 1 #multiple of 4 bits = 1 byte

j _loopy
_break: 
print_str "\n"
pop s0
pop ra
jr ra
# --------------------------------------------------------------------
play_note:
push ra

li a1 NOTE_DURATION_MS 
lw a2 instrument 
li a3 NOTE_VOLUME

li v0 31 
syscall

pop ra
jr ra
# --------------------------------------------------------------------
keyboard: 
print_str " play notes with letters and top row of numbers.\n"
print_str "change instrument with ` and then type the number.\n"
print_str "exit with enter.\n"

print_str "instrument: "
lw a0 instrument
add a0 a0 1
li v0 1
syscall
print_str "\n"
_loop:
push ra 
#promt user for a value

li v0, 12
syscall
#start of switch branch tree
beq v0, '\n', _break
beq v0, '`', _change
j _default

print_str "\n"

_change: 
jal _change_instrument
j _break_switch

_default:
beq v0, '\n', _break_switch
blt v0, 0, _break_switch
bgt v0, 127, _break_switch
lb a0 key_to_note_table(v0)
beq a0, -1, _break_switch
jal play_note
j _break_switch

_break_switch:
j _loop
_break:
pop ra
jr ra
# --------------------------------------------------------------------
_change_instrument:
push ra

_loop1:
print_str "\n Please Enter an instrument value from 1 - 128:"
li v0 8
syscall #prompt
blt v0, 0, _loop1
bgt v0, 127, _loop1

sub t0 v0 1
sw t0, instrument
_brake:
pop ra
jr ra
