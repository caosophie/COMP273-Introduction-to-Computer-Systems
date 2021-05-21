# Sophie Cao
#######################################################################

#######################################################################
# Menu options
# r - read text buffer from file 
# p - print text buffer
# e - encrypt text buffer
# d - decrypt text buffer
# w - write text buffer to file
# g - guess the key
# q - quit

.data
MENU:              .asciiz "Commands (read, print, encrypt, decrypt, write, guess, quit):"
REQUEST_FILENAME:  .asciiz "Enter file name:"
REQUEST_KEY: 	 .asciiz "Enter key (upper case letters only):"
REQUEST_KEYLENGTH: .asciiz "Enter a number (the key length) for guessing:"
REQUEST_LETTER: 	 .asciiz "Enter guess of most common letter:"
ERROR:		 .asciiz "There was an error.\n"

FILE_NAME: 	.space 256	# maximum file name length, should not be exceeded
KEY_STRING: 	.space 256 	# maximum key length, should not be exceeded

.align 2		# ensure word alignment in memory for text buffer (not important)
TEXT_BUFFER:  	.space 10000
.align 2		# ensure word alignment in memory for other data (probably important)
# TODO: define any other spaces you need, for instance, an array for letter frequencies

alphabet:	.asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
list:		.space 1000 #An array for letter frequencies

##############################################################
.text
		move $s1 $0 	# Keep track of the buffer length (starts at zero)
MainLoop:	li $v0 4		# print string
		la $a0 MENU
		syscall
		li $v0 12	# read char into $v0
		syscall
		move $s0 $v0	# store command in $s0			
		jal PrintNewLine

		beq $s0 'r' read
		beq $s0 'p' print
		beq $s0 'w' write
		beq $s0 'e' encrypt
		beq $s0 'd' decrypt
		beq $s0 'g' guess
		beq $s0 'q' exit
		b MainLoop

read:		jal GetFileName
		li $v0 13	# open file
		la $a0 FILE_NAME 
		li $a1 0		# flags (read)
		li $a2 0		# mode (set to zero)
		syscall
		move $s0 $v0
		bge $s0 0 read2	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
read2:		li $v0 14	# read file
		move $a0 $s0
		la $a1 TEXT_BUFFER
		li $a2 9999
		syscall
		move $s1 $v0	# save the input buffer length
		bge $s0 0 read3	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		move $s1 $0	# set buffer length to zero
		la $t0 TEXT_BUFFER
		sb $0 ($t0) 	# null terminate the buffer 
		b MainLoop
read3:		la $t0 TEXT_BUFFER
		add $t0 $t0 $s1
		sb $0 ($t0) 	# null terminate the buffer that was read
		li $v0 16	# close file
		move $a0 $s0
		syscall
		la $a0 TEXT_BUFFER
		jal ToUpperCase
print:		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop	

write:		jal GetFileName
		li $v0 13	# open file
		la $a0 FILE_NAME 
		li $a1 1		# flags (write)
		li $a2 0		# mode (set to zero)
		syscall
		move $s0 $v0
		bge $s0 0 write2	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
write2:		li $v0 15	# write file
		move $a0 $s0
		la $a1 TEXT_BUFFER
		move $a2 $s1	# set number of bytes to write
		syscall
		bge $v0 0 write3	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
		write3:
		li $v0 16	# close file
		move $a0 $s0
		syscall
		b MainLoop

encrypt:		jal GetKey
		la $a0 TEXT_BUFFER
		la $a1 KEY_STRING
		jal EncryptBuffer
		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop

decrypt:		jal GetKey
		la $a0 TEXT_BUFFER
		la $a1 KEY_STRING
		jal DecryptBuffer
		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop

guess:		li $v0 4		# print string
		la $a0 REQUEST_KEYLENGTH
		syscall
		li $v0 5		# read an integer
		syscall
		move $s2 $v0
		
		li $v0 4		# print string
		la $a0 REQUEST_LETTER
		syscall
		li $v0 12	# read char into $v0
		syscall
		move $s3 $v0	# store command in $s0			
		jal PrintNewLine

		move $a0 $s2
		la $a1 TEXT_BUFFER
		la $a2 KEY_STRING
		move $a3 $s3
		jal GuessKey
		li $v0 4		# print String
		la $a0 KEY_STRING
		syscall
		jal PrintNewLine
		b MainLoop

exit:		li $v0 10 	# exit
		syscall

###########################################################
PrintBuffer:	li $v0 4          # print contents of a0
		syscall
		li $v0 11	# print newline character
		li $a0 '\n'
		syscall
		jr $ra

###########################################################
PrintNewLine:	li $v0 11	# print char
		li $a0 '\n'
		syscall
		jr $ra

###########################################################
PrintSpace:	li $v0 11	# print char
		li $a0 ' '
		syscall
		jr $ra

#######################################################
GetFileName:	addi $sp $sp -4
		sw $ra ($sp)
		li $v0 4		# print string
		la $a0 REQUEST_FILENAME
		syscall
		li $v0 8		# read string
		la $a0 FILE_NAME  # up to 256 characters into this memory
		li $a1 256
		syscall
		la $a0 FILE_NAME 
		jal TrimNewline
		lw $ra ($sp)
		addi $sp $sp 4
		jr $ra

###########################################################
GetKey:		addi $sp $sp -4
		sw $ra ($sp)
		li $v0 4		# print string
		la $a0 REQUEST_KEY
		syscall
		li $v0 8		# read string
		la $a0 KEY_STRING  # up to 256 characters into this memory
		li $a1 256
		syscall
		la $a0 KEY_STRING
		jal TrimNewline
		la $a0 KEY_STRING
		jal ToUpperCase
		lw $ra ($sp)
		addi $sp $sp 4
		jr $ra

###########################################################
# Given a null terminated text string pointer in $a0, if it contains a newline
# then the buffer will instead be terminated at the first newline
TrimNewline:	lb $t0 ($a0)
		beq $t0 '\n' TNLExit
		beq $t0 $0 TNLExit	# also exit if find null termination
		addi $a0 $a0 1
		b TrimNewline
TNLExit:		sb $0 ($a0)
		jr $ra

##################################################
# converts the provided null terminated buffer to upper case
# $a0 buffer pointer
ToUpperCase:	lb $t0 ($a0)
		beq $t0 $zero TUCExit
		blt $t0 'a' TUCSkip
		bgt $t0 'z' TUCSkip
		addi $t0 $t0 -32	# difference between 'A' and 'a' in ASCII
		sb $t0 ($a0)
TUCSkip:		addi $a0 $a0 1
		b ToUpperCase
TUCExit:		jr $ra

##################################################
# null terminated buffer is in $a0
# null terminated key is in $a1
##################################################
# PSEUDOCODE
# for (int i = 0; i < string.length(); i++) {
# int x = (string.charAt(i) + key.charAt(i)) % 26 }
# if string.charAt(i) < 'A' || string.charAt(i) > 'Z'
# 	no shifting, just keep the same character
# else
#	x += 'A'
#	add shift to character
##################################################
EncryptBuffer:	# TODO: Implement this function!
		li $t0, 0	# Iterator for string
		li $t4, 0	# Iterator key
		li $t5, 'A'	# to check if letter or not
		li $t7, 'Z'

Loop:		add $s1, $a0, $t0	# $s1 = buffer[i]
		lb $s2, 0($s1)		# Load char into $s2
		beq $s2, $zero, Exit 	# Break out of loop if at the end
		add $t3, $a1, $t4
		lb $s3, ($t3)
		slt $t6, $s2, $t5	# if char < 'A'
		slt $t8, $t7, $s2	# if char > 'Z'
		beq $t6, 1, NotLetter	
		beq $t8, 1, NotLetter
		bnez $s3, Continue
		beqz $s3, Reset		# If char is zero, go back to beginning
		
Shift:		sub $s2, $s2, 65	# message - 65
		sub $s3, $s3, 65	# key - 65
		add $s4, $s3, $s2	# $s4 = buffer[i] + key[i]
		li $t1, 26		# $t1 = 26
		div $s4, $t1		# #s4 / $t1
		mfhi $t2		# $t2 = mod
		add $t2, $t2, 65 	# $t2 + 'A'
		sb $t2 ($s1)
		addi $t0, $t0, 1	# i++
		addi $t4, $t4, 1	# j++
		j Loop
		
Exit:		jr $ra

Reset:		li $t4, 0		# set iterator for the key back to 0
		add $t3, $a1, $t4	# go back to beginning of the key
		lb $s3, ($t3)		# get first character of the key
		j Shift	
		
Reset0:		li $t4, 0		# Reset is called when the character is not a letter & we are at the end of the key
		add $t3, $a1, $t4
		lb $s3, ($t3)
		addi $t4, $t4, 1
		j Loop

Continue:	j Shift

NotLetter:	sb $s2 ($s1)
		addi $t0, $t0, 1
		addi $t4, $t4, 1
		beqz $s3, Reset0
		j Loop


##################################################
# null terminated buffer is in $a0
# null terminated key is in $a1
##################################################
# PSEUDOCODE
# for (int i = 0; i < string.length(); i++) {
# int x = (string.charAt(i) - key.charAt(i) + 26) % 26 }
# if string.charAt(i) < 'A' || string.charAt(i) > 'Z'
# 	no shifting, just keep the same character
# else
#	x += 'A'
#	add shift to character
##################################################
DecryptBuffer:	# TODO: Implement this function!
		li $t0, 0	# Iterator
		li $t4, 0	# Iterator key
		li $t5, 'A'	# to check if letter or not
		li $t7, 'Z'

Loop1:		add $s1, $a0, $t0	# $s1 = buffer[i]
		lb $s2, 0($s1)		# Load char into $s2
		beq $s2, $zero, Exit1 	# Break out of loop if at the end
		add $t3, $a1, $t4
		lb $s3, ($t3)
		slt $t6, $s2, $t5	# if char < 'A'
		slt $t8, $t7, $s2	# if char > 'Z'
		beq $t6, 1, NotLetter1
		beq $t8, 1, NotLetter1
		bnez $s3, Continue1
		beqz $s3, Reset1	# If char is zero, go back to beginning
		
Shift1:		sub $s2, $s2, 65	# message - 65
		sub $s3, $s3, 65	# key - 65
		sub $s4, $s2, $s3	# $s4 = buffer[i] - key[i]
		li $t1, 26		# $t1 = 26
		add $s4, $s4, 26	# (buffer[i] - key[i]) + 26
		div $s4, $t1		# #s4 / $t1
		mfhi $t2		# $t2 = mod
		add $t2, $t2, 65 	# $t2 + 'A'
		sb $t2 ($s1)
		addi $t0, $t0, 1	# i++
		addi $t4, $t4, 1	# j++
		j Loop1
		
Exit1:		jr $ra

Reset1:		li $t4, 0
		add $t3, $a1, $t4
		lb $s3, ($t3)
		j Shift1

Reset2:		li $t4, 0
		add $t3, $a1, $t4
		lb $s3, ($t3)
		addi $t4, $t4, 1
		j Loop1

Continue1:	j Shift1

NotLetter1:	sb $s2 ($s1)
		addi $t0, $t0, 1
		addi $t4, $t4, 1
		beqz $s3, Reset2
		j Loop1


###########################################################
# a0 keySize - size of key length to guess
# a1 Buffer - pointer to null terminated buffer to work with
# a2 KeyString - on return will contain null terminated string with guess
# a3 common letter guess - for instance 'E' 
GuessKey:	li $t0, 0
		li $t1, 0
		li $t2, 0
		li $t3, 0
		li $t4, 0
		li $t5, 0
		li $t6, 0
		li $t7, 0
		li $t8, 0
		li $s0, 0
		li $s1, 0
		li $s2, 0

GetLetter:	la $s0, alphabet
		add $s0, $s0, $t0	# alphabet[i]
		lb $t1, ($s0)		# $a0 contains alphabet[i]
		beqz $t1, Exit2		# If $a0 is 0, terminate
		j CheckString		# Check for letter frequency in string

CheckString:	add $s2, $a1, $t2	# string[j]
		lb $t3, 0($s2)
		beq $t3, $t1, Count	# if string[j] == alphabet[i], increase count
		beqz $t3, StoreCount	# when end of string reached, store the count
		addi $t2, $t2, 1	# j++
		j CheckString

Count:		addiu $t4, $t4, 1	# Count++
		addi $t2, $t2 1		# j++
		j CheckString		# Loop back to string
		
StoreCount:	add $t7, $t7, $t4
		bgt $t7, $t6, BiggestCountUpdate	# if the current count is larger than the one stored, update stored value
		li $t4, 0		# Set back count to be 0
		addi $t0, $t0, 1	# i++
		li $t2, 0		# Set back j = 0
		addu $t5, $t5, 1
		li $t7, 0
		j GetLetter

BiggestCountUpdate:	la $t6 ($t7)	# update biggest count variable with current count
			              la $a2, ($t1)	# store the letter for that count
			              li $t7, 0	
			              li $t4, 0
			              addi $t0, $t0, 1
			              li $t2, 0
			              addi $t5, $t5, 1
			              j GetLetter
			
Exit2:		sub $t8, $a2, $a3	# find the difference between the guess key and the most common letter
		      add $t8, $t8, 'A'	# add 'A' to the difference => this is the guess key
		      sb $t8, KEY_STRING
		jr $ra
