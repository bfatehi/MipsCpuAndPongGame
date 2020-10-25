# Abraham Fatehi
# Pong
.data 0x10010000
	xpos:		.word 14
	ypos:		.word 13
	xMove:		.word 1
	yMove:		.word -1
	ySpeed: 	.word -1
	OneScore:	.word 0
	TwoScore:	.word 0
	Mode: 		.word 0
	ModeSelected:	.word 0
	RoundStarted:	.word 0
	turn:		.word 0

.text 0x00400000

main:
	lui	$sp, 0x1001		# Initialize stack pointer to the 64th location above start of data
	ori 	$sp, $sp, 0x0100	# top of the stack is the word at address [0x100100fc - 0x100100ff]
		
NewGame:

	li $t0, 0

SelectMode:
	jal 	key_loop		# check to see which key has been pressed
	
	li 	$a0, 25	#
	jal 	pause
		
	j 	SelectMode    # Jump back to the top of the wait loop

GameLoop:
	beq $t0, 0, key_loop
	jal MoveBall

AccelLoop:
	bne $s5, 2, key_loop
	jal get_accelX
	slti $a3, $v1, 8
	bne $a3, 1, Up2
	slti $a3, $v1, -8
	beq $a3, 1, Down2	
	
key_loop:
   	
	jal 	get_key			# get a key (if available)
	beq	$v0, $0, GameLoop	# 0 means no valid key

	#r	
key1:
	beq	$v0, 1, Reset

	#a
key2:
	bne	$v0, 2, key3
	slti	$a3, $t1, 14
	beq	$a3, $0, Up1
	li	$t1, 14
	j	Up1

	#z
key3:
	bne	$v0, 3, key4
	slti	$a3, $t2, 27
	bne	$a3, 1, Down1
	li	$a2, 27
	j	Down1
	#1
key4:
	bne	$v0, 4, key5
	beq	$v0, 4, SetOnePlayer
	j GameLoop
	#2
key5:
	bne	$v0, 5, key6	# read key again
	beq	$v0, 5, SetTwoPlayer
	j GameLoop
	#space
key6:
	bne $v0, 6, GameLoop
	beq	$v0, 6, StartRound


#sets up 1 player game	
SetOnePlayer:
	
	li 	$s5, 1
	jal 	DrawPaddle1
	j	GameLoop

#sets up 2 player game	
SetTwoPlayer:

	li 	$s5, 2
	jal 	DrawPaddle1
	jal 	DrawPaddle2
	j	GameLoop
	
	
DrawPaddle1:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4
   	
	li 	$a0, 2
	li 	$a1, 1
	li	$t5, 1
	li 	$a2, 20
	li	$t1, 20 #for paddle1 location
	li	$t2, 21
	jal 	putChar_atXY
	addi 	$a2, $a2, 1
	jal	putChar_atXY
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure

DrawPaddle2:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4

	li 	$a0, 2
	li 	$a1, 28
	li	$t6, 28
	li 	$a2, 20
	li	$t3, 20 #for paddle2 location
	li	$t4, 21
	jal 	putChar_atXY
	addi 	$a2, $a2, 1
	jal	putChar_atXY
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure

#starts Round
StartRound:

	beq 	$s0, 10, p1Win
	beq 	$s1, 10, p2Win
	li	$t7, 1
	li	$t8, 1
	li	$s2, 13
	li	$s3, 14
	li	$s4, -1
	li	$t0, 1
	jal	MoveBall
	
	j GameLoop          # Return from procedure

#moves 1player up	
Up1:
	li	$a0, 10
	jal	pause
	beq $t1, 14, key_loop
	
	
	addi	$t1, $t1, -1
	
	li $a0, 2
	addi $a1, $t5, 0
	addi $a2, $t1, 0
	jal putChar_atXY
	
	li $a0, 1
	addi $a2, $t2, 0
	jal putChar_atXY
	add $t2, $t2, -1
	
	jal MoveBall
	
	j key_loop

#moves 1player Down
Down1:
	li	$a0, 10
	jal	pause
	beq $t2, 27, key_loop
	
	addi	$t2, $t2, 1
	
	li $a0, 2
	addi $a1, $t5, 0
	addi $a2, $t2, 0
	jal putChar_atXY
	
	li $a0, 1
	addi $a2, $t1, 0
	jal putChar_atXY
	add $t1, $t1, 1
	
	jal MoveBall
	
	j key_loop
	
Up2:
	li	$a0, 10
	jal	pause
	beq $t3, 14, key_loop
	
	
	addi	$t3, $t3, -1
	
	li $a0, 2
	addi $a1, $t6, 0
	addi $a2, $t3, 0
	jal putChar_atXY
	
	li $a0, 1
	addi $a2, $t4, 0
	jal putChar_atXY
	add $t4, $t4, -1
	
	jal MoveBall
	
	j key_loop
	
Down2:
	li	$a0, 10
	jal	pause
	beq $t4, 27, key_loop
	
	addi	$t4, $t4, 1
	
	li $a0, 2
	addi $a1, $t6, 0
	addi $a2, $t4, 0
	jal putChar_atXY
	
	li $a0, 1
	addi $a2, $t3, 0
	jal putChar_atXY
	add $t3, $t3, 1
	
	jal MoveBall
	
	j key_loop

#erases last point of ball and moves to next	
MoveBall:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4
	
	li	$a0, 5
	jal	pause
	
	jal CheckCollision1

	li $a0, 1
	addi $a1, $s2, 0
	addi $a2, $s3, 0
	jal putChar_atXY
	
	add $s2, $s2, $t7
	add $s3, $s3, $t8
	
	li $a0, 2
	addi $a1, $s2, 0
	addi $a2, $s3, 0
	jal putChar_atXY
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure
#1player Collision logic
CheckCollision1:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4

TopCollision:
	bne $s3, 14, BottomCollision

	li	$a0, 5
	jal	pause
	li 	$t8, 1
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure


BottomCollision:
	bne $s3, 27, CheckPaddle2
	
	li	$a0, 5
	jal	pause
	li 	$t8, -1
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure
    	
CheckPaddle2:
	bne $s2, 27, P2RoundLoss

	
	slt $a3, $s3, $t3
	beq $a3, 1, EndCollisionLoop
	slt $a3, $t4, $s3
	beq $a3, 1, EndCollisionLoop
	li $t7, -1
	li $a0, 100
	sll $a0, $a0, 12
	jal put_sound
	li $a0, 10
	jal sound_off
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure

P2RoundLoss:
	beq $s5, 1, RightCollision1
	bne $s2, 29, EndCollisionLoop
	
	addi $s6, $s6, 1 #increment Score
	li $a0, 500
	sll $a0, $a0, 12
	jal put_sound	#play sound
	
	li $a0, 50
	jal pause
	jal sound_off
	
	li $t0, 0	
	li $t7, -1
	li $t8, 1
	li $s2, 13
	li $s3, 14
	jal DrawScore2
	jal Reset

RightCollision1:
	beq $s5, 5, CheckPaddle1 
	bne $s2, 29, CheckPaddle1

	addi $t7, $t7, -2
	li $a0, 1
	sll $a0, $a0, 12
	jal put_sound
	li $a0, 5
	jal pause
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure

	
CheckPaddle1:
	bne $s2, 2, P1RoundLoss
	
	slt $a3, $s3, $t1
	beq $a3, 1, EndCollisionLoop
	slt $a3, $t2, $s3
	beq $a3, 1, EndCollisionLoop
	li $t7, 1
	li $a0, 100
	sll $a0, $a0, 12
	jal put_sound
	li $a0, 10
	jal sound_off
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure


#Ends Round    	
P1RoundLoss:
	bne $s2, 0, EndCollisionLoop
	
	addi $s7, $s7, 1 #increment Score
	li $a0, 500
	sll $a0, $a0, 12
	jal put_sound	#play sound
	
	li $a0, 50
	jal pause
	jal sound_off
	
	li $t0, 0	
	li $t7, -1
	li $t8, 1
	li $s2, 13
	li $s3, 14
	jal DrawScore1
	jal Reset

EndCollisionLoop:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure



#draws score
DrawScore1:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4
   	
   	add $a0, $a0, $s7
   	jal put_leds

	li $a0, 0
	li $a1, 37
	li $a2, 16
	add $a2, $a2, $s7
	jal ScoreLoop
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure
    	
DrawScore2:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4
	
	add $a0, $a0, $s6
	jal put_leds

	li $a0, 0
	li $a1, 32
	li $a2, 16
	add $a2, $a2, $s6
	jal ScoreLoop
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure
	
#Makes Board Black
NewBoard:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4

	li 	$a0, 1
	li 	$a1, 0
	li 	$a2, 14
	bne	$a2, 28, backgroundXLoop
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure
    	
backgroundXLoop:

	jal 	putChar_atXY
	addi 	$a1, $a1, 1
	bne 	$a1, 30, backgroundXLoop
	
backgroundYLoop:
	

	lw 	$a1, 0
	addi 	$a2, $a2, 1
	bne 	$a2, 28, backgroundXLoop
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure
	
ScoreLoop:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4

	jal	putChar_atXY
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure

#resets for next round	
Reset:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
   	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
   	addi    $fp, $sp, 4

	jal 	NewBoard
	li	$s3, 0
	li	$s2, 0
	beq	$s5, 0, key_loop
	beq	$s5, 1, SetOnePlayer
	beq	$s5, 2, SetTwoPlayer
	
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
    	jr      $ra             # Return from procedure

#Reset Game conditions and Start New Game
p1Win:
	li $a0, 2
	sll $a0, $a0, 12
	jal put_sound
	li $a0, 10
	jal pause
	li $a0, 2
	sll $a0, $a0, 12
	jal put_sound
	li $s5, 0
	li $s6, 0
	li $s7, 0
	j NewGame

p2Win:
	li $a0, 1
	sll $a0, $a0, 12
	jal put_sound
	li $a0, 10
	jal pause
	li $a0, 2
	sll $a0, $a0, 12
	jal put_sound
	li $s5, 0
	li $s6, 0
	li $s7, 0
	J NewGame


end:
	j 	end
	
.include "procs_board.asm"
	
