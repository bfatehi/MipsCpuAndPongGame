#############################################################################################
#
# Montek Singh
# COMP 541 Final Projects
# Apr 17, 2017
#
# This is a collection of helpful procedures for developing your final project demos.
#
# Use these in your MIPS code ONLY FOR SIMULATION IN MARS.
# (A separate version of these procedures is available for deployment on the boards.
#
#############################################################################################

.text	
		
	#########################################
	# pause(N), N is hundredths of a second #
	# assuming 12.5 MHz clock.              #
	# N is placed in $a0.                   #
	#########################################

.globl pause
pause:
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$a0, 4($sp)
	sw	$v0, 0($sp)
	mul     $a0, $a0, 10		# $a0*10 (milliseconds)
	li	$v0, 32
	syscall				# sleep for $a0 milliseconds
		
	lw	$ra, 8($sp)
	lw	$a0, 4($sp)
	lw	$v0, 0($sp)
	addi	$sp, $sp, 12
	jr	$ra



	#####################################
	# proc putChar_atXY                 #
	# write one char to (x,y) on screen #
	#                                   #
	#   $a0:  char                      #
	#   $a1:  x (col)                   #
	#   $a2:  y (row)                   #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
.eqv screen_ctl 0xFFFF0008 		# Control register in MARS for MMIO display tool
.eqv screen_transmit_data 0xFFFF000C 	# Data to transmit


.globl putChar_atXY
putChar_atXY:	
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)
	
	li	$t1, 1
	sw	$t1, screen_ctl($0)	# makes the transmit data register ready to send to display	
	sll	$t1, $a1, 20		# X goes in bit positions 20-31
	sll	$t2, $a2, 8		# Y goes in bit positions 8-19
	or	$t0, $t1, $t2		# OR these together
	ori	$t0, $t0, 7		# ASCII code 7 is for positioning
	sw	$t0, screen_transmit_data($0)
					# position cursor at (X, Y)
					 
	li	$t1, 1
	sw	$t1, screen_ctl($0)	# makes the transmit data register ready to send to display	
	addi 	$t0, $a0, '0'		# convert character code 0 to letter '0', etc.
	sw	$t0, screen_transmit_data($0)					# write at cursor location
	li	$t1, 1
	sw	$t1, screen_ctl($0)	# makes the transmit data register ready to send to display	
		
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra


	#####################################
	# proc get_key                      #
	# gets a key from the kayboard      #
	#                                   #
	#   $v0: 0 if no valid key          #
	#      : index 1 to N if valid key  #
	#                                   #
	# restores all registers            #
	#   before returning                #
	#####################################
	
.data
key_array:	.word	'a', 's', 'w', 'z'
num_keys:	.word	4

.eqv keyb_ctl 0xFFFF0000 		# Control register in MARS for MMIO display tool
.eqv keyb_receive_data 0xFFFF0004 	# Data to transmit

.text
.globl get_key
get_key:
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t2, 0($sp)

	lw	$v0, keyb_ctl($0)
	beq	$v0, $0, get_key_exit	# return 0 if no key available
	lw	$t1, keyb_receive_data($0)
	
	li	$v0, 0
	lw	$t2, num_keys($0)
	sll	$t2, $t2, 2		# multiply by 4 to get max offset
get_key_loop:				# iterate through key_array to find match
	lw	$t0, key_array($v0)
	addi	$v0, $v0, 4		# go to next array element
	beq	$t0, $t1, get_key_exit
	blt	$v0, $t2, get_key_loop
	li	$v0, 0			# key not found in key_array
	
get_key_exit:
	srl	$v0, $v0, 2		# index of key found = offset by 4
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t2, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra
	