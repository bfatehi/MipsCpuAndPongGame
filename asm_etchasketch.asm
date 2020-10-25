#############################################################################################
#
# Montek Singh
# COMP 541 Final Projects
# Apr 12, 2017
#
# This is a MIPS program that tests the MIPS processor and the VGA display,
# using a very simple animation.
#
# This program assumes the memory-IO map introduced in class specifically for the final
# projects.  In MARS, please select:  Settings ==> Memory Configuration ==> Default.
#
# NOTE:  MEMORY SIZES.
#
# Instruction memory:  This program has 103 instructions.  So, make instruction memory
# have a size of 128 locations.
#
# Data memory:  Make data memory 64 locations.  This program only uses two locations for data,
# and a handful more for the stack.  Top of the stack is set at the word address
# [0x100100fc - 0x100100ff], giving a total of 64 locations for data and stack together.
# If you need larger data memory than 64 words, you will have to move the top of the stack
# to a higher address.
#
#############################################################################################
#
# THIS VERSION HAS LONG PAUSES:  Suitable for board deployment, NOT for Vivado simulation
#
#############################################################################################


.data 0x10010000 			# Start of data memory
a_sqr:	.space 4
a:	.word 3

.text 0x00400000			# Start of instruction memory
main:
	lui	$sp, 0x1001		# Initialize stack pointer to the 64th location above start of data
	ori 	$sp, $sp, 0x0100	# top of the stack is the word at address [0x100100fc - 0x100100ff]
	
	

	###############################################
	# ANIMATE character on screen                 #
	#                                             #
	# To eliminate pauses (for Vivado simulation) #
	# replace the two "jal pause" instructions    #
	# by nops.                                    #
	###############################################

	
	li	$a1, 20			# initialize to middle screen col (X=20)
	li	$a2, 15			# initialize to middle screen row (Y=15)

animate_loop:	
	li	$a0, 2			# draw character 2 here
	jal	putChar_atXY 		# $a0 is char, $a1 is X, $a2 is Y
	li	$a0, 25			# pause for 1/4 second
	jal	pause
	
key_loop:	
	jal 	get_key			# get a key (if available)
	beq	$v0, $0, key_loop	# 0 means no valid key
	
key1:
	bne	$v0, 1, key2
	addi	$a1, $a1, -1 		# move left
	slt	$1, $a1, $0		# make sure X >= 0
	beq	$1, $0, animate_loop
	li	$a1, 0			# else, set X to 0
	j	animate_loop

key2:
	bne	$v0, 2, key3
	addi	$a1, $a1, 1 		# move right
	slti	$1, $a1, 40		# make sure X < 40
	bne	$1, $0, animate_loop
	li	$a1, 39			# else, set X to 39
	j	animate_loop

key3:
	bne	$v0, 3, key4
	addi	$a2, $a2, -1 		# move up
	slt	$1, $a2, $0		# make sure Y >= 0
	beq	$1, $0, animate_loop
	li	$a2, 0			# else, set Y to 0
	j	animate_loop

key4:
	bne	$v0, 4, key_loop	# read key again
	addi	$a2, $a2, 1 		# move down
	slti	$1, $a2, 30		# make sure Y < 30
	bne	$1, $0, animate_loop
	li	$a2, 29			# else, set Y to 29
	j	animate_loop


			
					
	###############################
	# END using infinite loop     #
	###############################
	
				# program won't reach here, but have it for safety
end:
	j	end          	# infinite loop "trap" because we don't have syscalls to exit


######## END OF MAIN #################################################################################



.include "procs_mars.asm"
