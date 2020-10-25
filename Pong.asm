## Abraham Fatehi
## Pong
.data 0x10010000
	xDir:			.word 1		# start going right (x always moves one so it doesnt need speed)
	ySpeed:			.word -1		# wait this long before you move over 1 y
	yDir:			.word -1		# start going to the down
	OneScore:		.word 0
	TwoScore:		.word 0
	mode:			.word 0  # 1 denotes 1 Player mode
					 # 2 denotes 2 Player mode

.text 0x00400000

	NewGame:
		jal NewBoard

	key_loop:	
		jal 	get_key			# get a key (if available)
		beq	$v0, $0, key_loop	# 0 means no valid key
	
	key1:
		bne	$v0, 1, key2
		beq	$v0, 1, up
		j	DrawPaddle

	key2:
		bne	$v0, 2, key3
		beq	$v0, 2, down
		j	DrawPaddle

	key3:
		bne	$v0, 3, key4
		beq	$v0, 3, SetOnePlayer
		j	SelectMode

	key4:
		bne	$v0, 4, key_loop	# read key again
		beq	$v0, 4, SetTwoPlayer
		j	SelectMode
	
	SelectMode:
		jal key_loop		# check to see which key has been pressed
		
		li $a0, 25	#
		jal pause
		
		j SelectMode    # Jump back to the top of the wait loop
		
	SetOnePlayer:
		li $t1, 1
		j BeginGame
	SetTwoPlayer:
		li $t1, 2
	BeginGame:
		sw $zero, 0xFFFF0000		# clear the button pushed bit
		sw $t1, mode
	
	NewRound:

		# Initialize all the regesters for a new iteration of the gameplay loop
		li $t0, 1
		li $t1, -1
		sw $t0, ySpeed
		sw $t1, yDir
		
		li $s0, 0 	# 0x01000000 up; 0x02000000 down; 0 stay
		li $s1, 0	# 0x01000000 up; 0x02000000 down; 0 stay
		lw $s2, xDir	# wait this long before you move over 1 x
		lw $s3, ySpeed	# wait this long before you move over 1 y
		li $s4, 13
		li $s5, 13
		li $s6, 32
		li $s7, 0

		jal NewBoard
		
		lw $a2, OneScore
		li $a3, 1
		jal DrawScore
		lw $a2, TwoScore
		li $a3, 54
		jal DrawScore
		
		li $a0, 13
		add $s4, $a1, $0
		lw $a2, 0
		jal DrawPaddle
		
		li $a0, 50
		add $s5, $a1, $0
		lw $a2, 0
		jal DrawPaddle

		li $a0, 100	#
		jal pause

	DrawObjects:
		add $s6, $a0, $0
		add $s7, $a1, $0
		jal CheckForCollisions
		jal MoveBall
		
		li $a0, 13
		add $s4, $a1, $0
		lw $a2, 0
		add $s0, $a3, $0
		jal DrawPaddle
		add $a1, $s4, $0	# a1 has the new top position stored
		add $a3, $s0, $0	# a3 has the new direction stored if it hit an edge
		
		li $a0, 50		
		add $s5, $a1, $0
		lw $a2, 0
	
	# Wait and read buttons
	Begin_standby:	
		li $t0, 0x00000002			# load 25 into the counter for a ~50 milisec standby
	
	Standby:
		slt $t9, $t0, $0
		beq $t9, 1, EndStandby
		beq $t0, 0, EndStandby
		li $a0, 1	#
		jal pause	#
		
		addi $t0, $t0, -1 		# decrement counter
		
		lw $t1, 0xFFFF0000		# check to see if a key has been pressed
		slt $t9, $t1, $0
		beq $t9, 1, Standby
		beq $t1, 0, Standby
				
		jal AdjustDir			# see what was pushed
		sw $zero, 0xFFFF0000		# clear the button pushed bit
		j Standby
	EndStandby:		
		j DrawObjects
		
	# $a0 contains the paddles x position
	# $a1 contains paddles y-top position
	# $a2 contains paddle color
	# $a3 contains the direction
	# $t0 is the loop counter
	# $t1 is the current y coordinate, the x coordinate does not change
	# after completed $a1 "returns" aka has stored the new y-top position, $a3 "returns" the direction
	# careful to make sure nothing inbetween alters these  $a registers
	DrawPaddle:
		# objective: look at the direction, draw a point on the correct side, erase a point on the correct side
		jal key_loop
	up:
		# erase bottom point
   		add $a2, $t2, $0
   		add $a2, $t1, $0
   		addi $a1, $a1, 5	# the bottom point
		lw $a2, 1
		addi $sp, $sp, -4
   		sw $ra, 0($sp)   	# saves $ra on stack
		jal DrawPoint
		lw $ra, 0($sp)		# put return back
   		addi $sp, $sp, 4	# change stack back
   		add $t1 $a1, $0		# put back top y position
   		add $t2, $a2, $0	# put back color
   		
		# move top y up (as long as its not at the top)
		beq $a1, 0, NoMove
		addi $a1, $a1, -1
		j Move
	down:
		# erase top point
		add $a2, $t1, $0
		lw $a2, 1
		addi $sp, $sp, -4
   		sw $ra, 0($sp)   	# saves $ra on stack
		jal DrawPoint
		lw $ra, 0($sp)		# put return back
   		addi $sp, $sp, 4	# change stack back
   		add $t1, $a2, $0	# put back color
   		
		# move down top y (as long as bottom is not at bottom)
		beq $a1, 26, NoMove	# height is 31 - 5 = 26
		addi $a1, $a1, 1
		j Move
	NoMove:
		# else do nothing, make sure the direction is nothing
		li $a3, 0
	Move:
		li $t0, 6
	StartPLoop:
		subi $t0, $t0, 1
		addu $t1, $a1, $t0
		
		# Converts to memory address
		sll $t1, $t1, 6   # multiply y-coordinate by 64 (length of the field)
		addu $v0, $a0, $t1
		sll $v0, $v0, 2
		addu $v0, $v0, $gp
		
		sw $a2, ($v0)
		beq $t0, $0, EndPLoop
		j StartPLoop
	EndPLoop:		
		jr $ra

	# $a2 contains the score of the player
	# $a3 contains the column of the leftmost scoring dot.
	# Using this information, draws along the top of the screen to display a player's score	
	DrawScore:
		addi $sp, $sp, -12	# Stores regiester values to the stack
   		sw $ra, 0($sp)
   		sw $s2, 4($sp)
   		sw $a2, 8($sp)
   		
   		add $a2 $s2, $0
   		lw $a2, 2
   		lw $t8, 5
   		slt $t9, $a2, $t8
		beq $t9, 1, DrawScoreRow1
		beq $s2, 5, DrawScoreRow1
   	DrawScoreRow2:			# Draws any score values along the second row
   	
   		sub $t1, $s2, 6
   		sll $t1, $t1, 1
   		add $a0, $t1, $a3
   		li $a1, 3
   		jal DrawPoint
   		
   		addi $s2, $s2 -1
   		
   		lw $t8, 6
   		slt $t9, $t8, $s2
		beq $t9, 1, DrawScoreRow2
		beq $s2, 6, DrawScoreRow2
   		
	DrawScoreRow1:			# Draws any score values along the first row
		beq $s2, $zero, DrawScoreEnd
		sub $t1, $s2, 1
		sll $t1, $t1, 1
   		add $a0, $t1, $a3
   		li $a1, 1
   		jal DrawPoint
   		
   		addi $s2, $s2, -1
   		
   		j DrawScoreRow1
	
	DrawScoreEnd:
		lw $ra, 0($sp)		# restores register values from the stack
		lw $s2, 4($sp)
		lw $a2, 8($sp)
   		addi $sp, $sp, 12
		
		jr $ra
		
	# $a0 contains x position
	# $a1 contains y position	
	MoveBall:		
		# draw over the last point
		lw $a2, 1
		addi $sp, $sp, -4
   		sw $ra, 0($sp)   	# saves $ra on stack
		jal DrawPoint
		lw $ra, 0($sp)		# put return back
   		addi $sp, $sp, 4	# change stack back
   		
   		add $s6, $s6, $s2	# add the x velocity to the x coord
   		# y doesnt always change, check if it needs to
   		addi $s3, $s3, -1
   		slt $t8, $0, $s3
		beq $t8, 1, NoYChange
	ChangeY:
		lw $t0, yDir	
		add $s7, $s7, $t0
		lw $s3, ySpeed
	NoYChange:
   		# do nothing
   		
   		# draw the new loc
		add $s6, $a0, $0
		add $s6, $a1, $0
		lw $a2, 2
		
	# $a0 contains x position, $a1 contains y position, $a2 contains the color	
	DrawPoint:
		sll $t0, $a1, 6   # multiply y-coordinate by 64 (length of the field)
		addu $v0, $a0, $t0
		sll $v0, $v0, 2
		addu $v0, $v0, $gp
		sw $a2, ($v0)		# draw the color to the location
		
		jr $ra

	# $a0 the x starting coordinate
	# $a1 the y coordinate
	# $a2 the color
	# $a3 the x ending coordinate
	DrawHorizontal:
		
		addi $sp, $sp, -4
   		sw $ra, 0($sp)
		
		sub $t9, $a3, $a0
		add $a0, $t1, $0
		
	HorizontalLoop:
		
		add $a0, $t1, $t9
		jal DrawPoint
		addi $t9, $t9, -1
		
		slt $t8, $0, $t9
		beq $t8, 1, HorizontalLoop
		beq $t9, 0, HorizontalLoop
		
		lw $ra, 0($sp)		# put return back
   		addi $sp, $sp, 4

		jr $ra
		
	# $a0 the x coordinate
	# $a1 the y starting coordinate
	# $a2 the color
	# $a3 the y ending coordinate
	DrawVertical:

		addi $sp, $sp, -4
   		sw $ra, 0($sp)
		
		sub $t9, $a3, $a1
		move $t1, $a1
		
	VerticalLoop:
		
		add $a1, $t1, $t9
		jal DrawPoint
		addi $t9, $t9, -1
		
		slt $t8, $0, $t9
		beq $t8, 1, VerticalLoop
		beq $t9, 0, VerticalLoop
		
		lw $ra, 0($sp)		# put return back
   		addi $sp, $sp, 4
   		
		jr $ra
		

	# AdjustDir  changes the players direction registers depending on the key pressed
	AdjustDir: 
		lw $a0, 0xFFFF0004		# Load button pressed
		
	AdjustDir_left_up:
		bne $a0, 97, AdjustDir_left_down  # a
		li $s0, 0x01000000	# up
		j AdjustDir_done		

	AdjustDir_left_down:
		bne $a0, 122, AdjustDir_right_up	# z
		li $s0, 0x02000000	# down
		j AdjustDir_done

	AdjustDir_right_up:
		bne $a0, 107, AdjustDir_right_down # k
		li $s1, 0x01000000	# up
		j AdjustDir_done

	AdjustDir_right_down: 
		bne $a0, 109, AdjustDir_none	# m
		li $s1, 0x02000000	# down
		j AdjustDir_done

	AdjustDir_none:
						# Do nothing
	AdjustDir_done:
		jr $ra				# Return

# Check for collisions and react accordingly
# $a0 contains balls x-pos $a1 contains balls y-pos
# first check if it is a normal collision
# then check if it is a valid corner collsion
	CheckForCollisions:
		beq $s6, 0, POneRoundLoss
		beq $s6, 63, PTwoRoundLoss
		bne $s6, 14, NoLeftCollision	# see if it is in the left-paddle collsion section
	LeftCollision:
		slt $t8, $s7, $s4
		beq $t8, 1, NoPaddleCollision
		addi $t3, $s4, 5		# calculate bottom of paddle
		slt $t8, $t3, $s7
		beq $t8, 1, NoPaddleCollision
		sub $t3, $s7, $s4		# store distance from top to hit
		li $s2, 1			# change x-dir
		j PaddleHit
   		
	NoLeftCollision:
		bne $s6, 49, NoPaddleCollision	# see if it is in the right-paddle collision section
	RightCollision:
		slt $t8, $s7, $s5
		beq $t8, 1, NoPaddleCollision
		addi $t3, $s5, 5
		slt $t8, $t3, $s7
		beq $t8, 1, NoPaddleCollision
		sub $t3, $s7, $s5		# store distance from top to hit
		li $s2, -1			# change x-dir
		j PaddleHit		

	NoPaddleCollision:
		j CheckHorizontalHit
		
	PaddleHit: 
		addi $sp, $sp, -8
   		sw $a0, 0($sp)   	# arguments on stack
   		sw $a1, 4($sp)
		
		li $a1, 1000
		sll $a0, $a1, 12		# Make the sound when the ball hits the paddle
		jal put_sound
		
   		lw $a0, 0($sp)   	# Puts arguments back in their registers for later use
   		lw $a1, 4($sp)
   		addi $sp, $sp, 8
		
		beq $t3, 0, tophigh
		beq $t3, 1, topmid
		beq $t3, 2, toplow
		beq $t3, 3, bottomhigh
		beq $t3, 4, bottommid
		beq $t3, 5, bottomlow
	tophigh:
		li $s3, 1
		sw $s3, ySpeed
		li $s3, -1
		sw $s3, yDir
		j CheckHorizontalHit
	topmid:
		li $s3, 2
		sw $s3, ySpeed
		li $s3, -1
		sw $s3, yDir
		j CheckHorizontalHit
	toplow:
		li $s3, 4
		sw $s3, ySpeed
		li $s3, -1
		sw $s3, yDir
		j CheckHorizontalHit
	bottomhigh:
		li $s3, 4
		sw $s3, ySpeed
		li $s3, 1
		sw $s3, yDir
		j CheckHorizontalHit
	bottommid:
		li $s3, 2
		sw $s3, ySpeed
		li $s3, 1
		sw $s3, yDir
		j CheckHorizontalHit
	bottomlow:
		li $s3, 1
		sw $s3, ySpeed
		li $s3, 1
		sw $s3, yDir
		
	CheckHorizontalHit:
		beq $s7, 31, HorizontalWallHit
		bne $s7, 0, NoCollision
		
	HorizontalWallHit: 
		# play a sound
		addi $sp, $sp, -8
   		sw $a0, 0($sp)   	# arguments on stack
   		sw $a1, 4($sp)
		
   		lw $a0, 0($sp)   	# Puts arguments back in their registers for later use
   		lw $a1, 4($sp)
   		addi $sp, $sp, 8
   		
		# change y direction if y-count=1 (prevents it from switching until y is about to change)
		lw $t7, 1
		slt $t8, $t7, $s3
		beq $t8, 1, NoCollision
		lw $t4, yDir
		xori $t4, $t4, 0xffffffff
		addi $t4, $t4, 1
		sw $t4, yDir
	NoCollision:
		jr $ra

	
	# Makes the entire bitmap display the background color (black)
	NewBoard:
		lw $t0, 1
		li $t1, 8192 # The number of pixels in the display
	StartCLoop:
		subi $t1, $t1, 4
		addu $t2, $t1, $gp
		sw $t0, ($t2)
		beq $t1, 0, EndCLoop
		j StartCLoop
	EndCLoop:
		jr $ra
		
	POneRoundLoss:
		# Increment player 2's score
		lw $t1, TwoScore
		addi $t1, $t1, 1
		sw $t1, TwoScore
		
		#Ready the next round
		li $t2, 1
		sw $t2, xDir
		
		li $a3, 54
		sw $zero, 0xFFFF0004  # Zeros the key press 
		beq $t1, 10, EndGame
		
		j PlayPointSound
	PTwoRoundLoss:	
		# Increment player 1's score
		lw $t1, OneScore
		addi $t1, $t1, 1
		sw $t1, OneScore
		
		#Ready the next round
		li $t2, -1
		sw $t2, xDir
		
		li $a3, 1
		sw $zero, 0xFFFF0004 # Zeros the key press
		beq $t1, 10, EndGame

	PlayPointSound:
		# play a sound
		li $a1, 1111		# Make the sound when a point is scored
		sll $a0, $a1, 12
		jal put_sound
		# sound off?
   		
   		j NewRound
	
	# Ends the game, wrapping up the process
	EndGame:
		jal NewBoard
		
		lw $t0, OneScore
		bne $t0, 10, WinTwo
		
		
	WinOne:	li $a0, 34 #the x coordinate
		li $a1, 12 #the y starting coordinate
		lw $a2, 2 #the color
		li $a3, 15 #the y ending coordinate
		jal DrawVertical
		
		li $a0, 33
		li $a1, 13
		jal DrawPoint
		
		li $a1, 16 #the y coordinate
		li $a3, 35 #the x ending coordinate
		jal DrawHorizontal
		
		j WinP
		
	WinTwo:	li $a0, 33 #the x starting coordinate
		li $a1, 16 #the y coordinate
		lw $a2, 2 #the color
		li $a3, 36 #the x ending coordinate
		jal DrawHorizontal
	
		li $a0, 34 #the x starting coordinate
		li $a1, 12 #the y coordinate
		li $a3, 35 #the x ending coordinate
		jal DrawHorizontal
	
		li $a1, 15
		jal DrawPoint
	
		li $a0, 35
		li $a1, 16
		jal DrawPoint
	
		li $a1, 14
		jal DrawPoint
	
		li $a0, 36
		li $a1, 13
		jal DrawPoint
	
		li $a0, 33
		jal DrawPoint
		
	WinP:	li $a0, 27 #the x coordinate
		li $a1, 12 #the y starting coordinate
		li $a3, 16 #the y ending coordinate
		jal DrawVertical
		
		li $a0, 30 #the x coordinate
		li $a3, 14 #the ending y coordinate
		jal DrawVertical
		
		li $a0, 28 #the x starting coordinate
		li $a3, 29 #the x ending coordinate
		jal DrawHorizontal
	
		li $a1, 14 #the y coordinate
		jal DrawHorizontal

		li $a0, 10 	#
		jal pause
		
		sw $zero, 0xFFFF0000

	WaitForReset:		
		li $a0, 1 	#
		jal pause
		
		lw $t0, 0xFFFF0000
		beq $t0, $0, WaitForReset
		
		j Reset
		
	Reset:		
		sw $zero, OneScore
		sw $zero, TwoScore
		sw $zero, 0xFFFF0000	# Zeros the keypress words in memory
		sw $zero, 0xFFFF0004
		
		jal NewBoard
		
		j NewGame

.include "procs_board.asm"
