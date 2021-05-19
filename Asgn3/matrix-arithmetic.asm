# Sophie Cao - 260645315

.data
TestNumber:	.word 2		# TODO: Which test to run!
				# 0 compare matrices stored in files Afname and Bfname
				# 1 test Proc using files A through D named below
				# 2 compare MADD1 and MADD2 with random matrices of size Size
				
Proc:		MADD1		# Procedure used by test 2, set to MADD1 or MADD2		
				
Size:		.word 64		# matrix size (MUST match size of matrix loaded for test 0 and 1)

Afname: 		.asciiz "A64.bin"
Bfname: 		.asciiz "B64.bin"
Cfname:		.asciiz "C64.bin"
Dfname:	 	.asciiz "D64.bin"
bsize:		.word 64

#################################################################
# Main function for testing assignment objectives.
# Modify this function as needed to complete your assignment.
# Note that the TA will ultimately use a different testing program.
.text
main:		la $t0 TestNumber
		lw $t0 ($t0)
		beq $t0 0 compareMatrix
		beq $t0 1 testFromFile
		beq $t0 2 compareMADD
		li $v0 10 # exit if the test number is out of range
        		syscall	

compareMatrix:	la $s7 Size	
		lw $s7 ($s7)		# Let $s7 be the matrix size n

		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix A
		move $s0 $v0		# $s0 is a pointer to matrix A
		la $a0 Afname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s0
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix B
		move $s1 $v0		# $s1 is a pointer to matrix B
		la $a0 Bfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s1
		jal loadMatrix
	
		move $a0 $s0
		move $a1 $s1
		move $a2 $s7
		jal check
		
		li $v0 10      	# load exit call code 10 into $v0
        		syscall         	# call operating system to exit	

testFromFile:	la $s7 Size	
		lw $s7 ($s7)		# Let $s7 be the matrix size n

		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix A
		move $s0 $v0		# $s0 is a pointer to matrix A
		la $a0 Afname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s0
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix B
		move $s1 $v0		# $s1 is a pointer to matrix B
		la $a0 Bfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s1
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix C
		move $s2 $v0		# $s2 is a pointer to matrix C
		la $a0 Cfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s2
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix A
		move $s3 $v0		# $s3 is a pointer to matrix D
		la $a0 Dfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s3
		jal loadMatrix		# D is the answer, i.e., D = AB+C 
	
		# TODO: add your testing code here
		move $a0, $s0	# A
		move $a1, $s1	# B
		move $a2, $s2	# C
		move $a3, $s7	# n
		
		la $ra ReturnHere
		la $t0 Proc	# function pointer
		lw $t0 ($t0)	
		jr $t0		# like a jal to MADD1 or MADD2 depending on Proc definition

ReturnHere:	move $a0 $s2	# C
		move $a1 $s3	# D
		move $a2 $s7	# n
		jal check	# check the answer

		li $v0, 10      	# load exit call code 10 into $v0
	        	syscall         	# call operating system to exit	

compareMADD:	la $s7 Size
		lw $s7 ($s7)	# n is loaded from Size
		mul $s4 $s7 $s7	# n^2
		sll $s5 $s4 2	# n^2 * 4

		move $a0 $s5
		li   $v0 9	# malloc A
		syscall	
		move $s0 $v0
		move $a0 $s5	# malloc B
		li   $v0 9
		syscall
		move $s1 $v0
		move $a0 $s5	# malloc C1
		li   $v0 9
		syscall
		move $s2 $v0
		move $a0 $s5	# malloc C2
		li   $v0 9
		syscall
		move $s3 $v0	
	
		move $a0 $s0	# A
		move $a1 $s4	# n^2
		jal  fillRandom	# fill A with random floats
		move $a0 $s1	# B
		move $a1 $s4	# n^2
		jal  fillRandom	# fill A with random floats
		move $a0 $s2	# C1
		move $a1 $s4	# n^2
		jal  fillZero	# fill A with random floats
		move $a0 $s3	# C2
		move $a1 $s4	# n^2
		jal  fillZero	# fill A with random floats

		move $a0 $s0	# A
		move $a1 $s1	# B
		move $a2 $s2	# C1	# note that we assume C1 to contain zeros !
		move $a3 $s7	# n
		jal MADD1

		move $a0 $s0	# A
		move $a1 $s1	# B
		move $a2 $s3	# C2	# note that we assume C2 to contain zeros !
		move $a3 $s7	# n
		jal MADD2

		move $a0 $s2	# C1
		move $a1 $s3	# C2
		move $a2 $s7	# n
		jal check	# check that they match
	
		li $v0 10      	# load exit call code 10 into $v0
        		syscall         	# call operating system to exit	

###############################################################
# mallocMatrix( int N )
# Allocates memory for an N by N matrix of floats
# The pointer to the memory is returned in $v0	
mallocMatrix: 	mul  $a0, $a0, $a0	# Let $s5 be n squared
		sll  $a0, $a0, 2	# Let $s4 be 4 n^2 bytes
		li   $v0, 9		
		syscall			# malloc A
		jr $ra
	
###############################################################
# loadMatrix( char* filename, int width, int height, float* buffer )
.data
errorMessage: .asciiz "FILE NOT FOUND" 
.text
loadMatrix:	mul $t0 $a1 $a2 	# words to read (width x height) in a2
		sll $t0 $t0  2	  	# multiply by 4 to get bytes to read
		li $a1  0     		# flags (0: read, 1: write)
		li $a2  0     		# mode (unused)
		li $v0  13    		# open file, $a0 is null-terminated string of file name
		syscall
		slti $t1 $v0 0
		beq $t1 $0 fileFound
		la $a0 errorMessage
		li $v0 4
		syscall		  	# print error message
		li $v0 10         	# and then exit
		syscall		
fileFound:	move $a0 $v0     	# file descriptor (negative if error) as argument for read
  		move $a1 $a3     	# address of buffer in which to write
		move $a2 $t0	  	# number of bytes to read
		li  $v0 14       	# system call for read from file
		syscall           	# read from file
		# $v0 contains number of characters read (0 if end-of-file, negative if error).
                	# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0 $a3	# start address
		add $t1 $a3 $a2  	# end address
loadloop:	lw $t2 ($t0)
		sw $t2 ($t0)
		addi $t0 $t0 4
		bne $t0 $t1 loadloop		
		li $v0 16	# close file ($a0 should still be the file descriptor)
		syscall
		jr $ra	

##########################################################
# Fills the matrix $a0, which has $a1 entries, with random numbers
fillRandom:	li $v0 43
		syscall		# random float, and assume $a0 unmodified!!
		swc1 $f0 0($a0)
		addi $a0 $a0 4
		addi $a1 $a1 -1
		bne  $a1 $zero fillRandom
		jr $ra

##########################################################
# Fills the matrix $a0 , which has $a1 entries, with zero
fillZero:	sw $zero 0($a0)	# $zero is zero single precision float
		addi $a0 $a0 4
		addi $a1 $a1 -1
		bne  $a1 $zero fillZero
		jr $ra



######################################################
# TODO: void subtract( float* A, float* B, float* C, int N )  C = A - B 
# $a0 = pointer to A
# $a1 = pointer to B
# $a2 = pointer to C
# $a3 = n

subtract:	addi $sp $sp -12	# This is a stack to store my initial addresses
		sw $a0 0($sp)	# First element of stack will be address to A
		sw $a1 4($sp)	# Second element is the address to b
		sw $a2 8($sp)
		addi $t4 $t4 0	# int i = 0 -> count
		mul $t0 $a3 $a3	# $t0 = $a3 ^ 2 = n^2
		sll $t0 $t0  2	# Number of bytes to read
		add $t5, $t0, $a0	# End address
		
		Loop :	lwc1 $f1 ($a0)	# $t1 = value at pointer A
			lwc1 $f2 ($a1)	# $t2 = value at pointer B
			sub.s $f3 $f1 $f2	# $t3 = $t1 - $t2 = difference to store at C
			swc1 $f3 ($a2)	# Store the difference in matrix C where pointer is at
			addi $a0 $a0 4
			addi $a1 $a1 4
			addi $a2 $a2 4	# Increment pointer
			addi $t4 $t4 1	# Increment count
			ble $a0 $t5 Loop	# Loop back again if end is not reached
			
		lw $a0 0($sp)	# Load back arguments to initial addres
		lw $a1 4($sp)
		lw $a2 8($sp)
		addi $sp $sp 8	# Restore the stack
		jr $ra
		

#################################################
# TODO: float frobeneousNorm( float* A, int N )
frobeneousNorm: 	mul $t0 $a3 $a3
			addi $sp $sp -4
			sw $a0 0($sp)
			li $t3 0	# count j = 0
			mtc1 $zero, $f2
			
			Loop1 :	lwc1 $f4 ($a0)
				mul.s $f4 $f4 $f4
				add.s $f2, $f2, $f4	# sum += value^2
				addi $a0, $a0, 4
				addi $t3, $t3, 1	# Increment count
				blt $t3 $t0 Loop1
			
			sqrt.s $f2 $f2
			mov.s $f12 $f2
			li $v0 2
			syscall
			mtc1 $zero, $f2
			mtc1 $zero, $f4
			lw $a0 0($sp)
			addi $sp $sp 4
			jr $ra

#################################################
# TODO: void check ( float* C, float* D, int N )
# Print the forbeneous norm of the difference of C and D
check: 		move $s0 $ra
		move $a3, $a2	# $a2 = n
		move $a2, $a0	# $a2 = A
		jal subtract
		move $a0, $a2
		jal frobeneousNorm
		move $ra $s0
		jr $ra

##############################################################
# TODO: void MADD1( float*A, float* B, float* C, N )
# $a0 = A; a1 = B; a2 = C; a3 = n
# To access a certain value within a 2D array, we can use the
# formula (row*rowsize + col)*floatsize
# i is the row; n is the size (# columns & rows); 
# k is the column; 4 is the size of a float

MADD1: 		addi $sp $sp -28	# stack to store the start addresses of the matrices
		sw $a0 0($sp)
		sw $a1 4($sp)
		sw $a2 8($sp)
		sw $s2 12($sp)
		sw $s0 16($sp)
		sw $s1 20($sp)
		sw $s3 24($sp)
		
		
		li $t0 0	# i = 0
		li $t1 0	# j = 0
		li $t2 0	# k = 0
		
		li $t3 4	# sizeof(float)
		
		FirstLoop :	bge $t0 $a3 end	# if i >= n, branch
				li $t1 0	# j = 0
		
		SecondLoop:	bge $t1, $a3, end2	# if j >= n, branch
				mtc1 $zero, $f2
				j ThirdLoop		# else : go to third loop
				
		# C[i][j] = a2 + ((i*n)+j)*4
		Store:		mul $s2, $t0, $a3	# s2 = i*n
				add $s2, $s2, $t1	# s2 += j
				mul $s2, $s2, $t3	# s2 * 4
				add $a2 $a2 $s2		# address of value
				lwc1 $f14, ($a2)	# c[i][j]
				add.s $f14, $f14, $f2	# c[i][j] + sum
				swc1 $f14, ($a2)	# c[i][j] = c[i][j] + sum
				lw $a2 8($sp)
				
				addi $t1, $t1, 1	# j++
				li $t2, 0		# k = 0
				j SecondLoop
		
		ThirdLoop:	bge $t2, $a3, Store	# if k >= n, store the final value
		
				# Get A[i][k]
				# A[i][k] = $a0 + ((i*n)+k)*4
				mul $s0, $t0, $a3	# s0 = i*n
				add $s0, $s0, $t2	# s0 += k
				mul $s0, $s0, $t3	# s0 * 4
				add $a0, $a0, $s0	# address of value
				lwc1 $f4, ($a0)		# f4 = value at address
				lw $a0 0($sp)
				
				# B[k][j] = a1 + ((k*n)+j)*4
				mul $s1, $t2, $a3	# s1 = k*n
				add $s1, $s1, $t1	# s1 += j
				mul $s1, $s1, $t3	# s1 * 4
				add $a1, $a1, $s1	# address of value
				lwc1 $f6, ($a1)		# f6 = value at address
				lw $a1 4($sp)
				
				mul.s $f8, $f4, $f6	# A[i][k]*B[k][j]
				add.s $f2, $f2, $f8	# sum += f8
				
				addi $t2, $t2, 1	# k++
				j ThirdLoop
				
				
		end:		lw $s2 12($sp)
				lw $s0 16($sp)
				lw $s1 20($sp)
				lw $s3 24($sp)
				addi $sp $sp 16		# restoring the stack
				jr $ra

		end2:		addi $t0, $t0, 1	# i++
				j FirstLoop
				
#########################################################
# TODO: void MADD2( float*A, float* B, float* C, N )
# a0 = a; a1 = b; a2 = c; a3 = n
# t0 = i; t1 = j; t2 = k; t3 = size of float; t4 = jj; t5 = kk; t6 = jj + bsize; t7 = kk + bsize
# s0 = a[i][k]; s1 = b[k][j]; s2 = c[i][j]; s3 = bsize
# f2 = sum

MADD2: 	addi $sp $sp -20	# stack to store the start addresses of the matrices
	sw $a0 0($sp)
	sw $a1 4($sp)
	sw $a2 8($sp)
	sw $s3 12($sp)
	sw $s2 16($sp)
		
	li $t0 0	# i = 0
	li $t1 0	# j = 0
	li $t2 0	# k = 0
	mul $t4, $t1, $t1	# t4 = jj
	
	
	li $s3, 4	# bsize = 4

	FirstLoop2 :	bge $t4 $a3 Exit	# if jj >= n, branch
			li $t5, 0	# kk = 0
			
	SecondLoop2:	bge $t5, $a3, Exit1	# if kk >= n, branch out
			li $t0, 0	# i = 0
				
	ThirdLoop2:	bge $t0, $a3, Exit2	# if i >= n, branch
			move $t1, $t4	# j = jj
							
	FourthLoop2:	add $t6, $t4, $s3	# t6 = jj + bsize
			blt $t6, $a3, setcompare
			bge $t1, $a3, Exit3	# if j < n
			mtc1 $zero, $f2		# sum = 0.0
			move $t2, $t5		# k = kk					
									
	setcompare:	bge $t1, $t6, Exit3	# if j < jj + bsize
			mtc1 $zero, $f2		# sum = 0.0
			move $t2, $t5		# k = kk
									
	FifthLoop2:	add $t7, $t5, $s3	# t7 = kk + bsize
			blt $t7, $a3, setcompare1
	
			bge $t2, $a3, Store2	# if k >= n, store the final value
	
			# Get A[i][k]
			# A[i][k] = $a0 + ((i*n)+k)*4
			mul $s0, $t0, $a3	# s0 = i*n
			add $s0, $s0, $t2	# s0 += k
			mul $s0, $s0, $t3	# s0 * 4
			add $a0, $a0, $s0	# address of value
			lwc1 $f4, ($a0)		# f4 = value at address
			lw $a0 0($sp)
			
			# B[k][j] = a1 + ((k*n)+j)*4
			mul $s1, $t2, $a3	# s1 = k*n
			add $s1, $s1, $t1	# s1 += j
			mul $s1, $s1, $t3	# s1 * 4
			add $a1, $a1, $s1	# address of value
			lwc1 $f6, ($a1)		# f6 = value at address
			lw $a1 4($sp)
			
			mul.s $f8, $f4, $f6	# A[i][k]*B[k][j]
			add.s $f2, $f2, $f8	# sum += f8
			addi $t2, $t2, 1	# k++
			j FifthLoop2
									
	setcompare1:	bge $t2, $t7, Store2	# if k >= kk+bsize, store the final value
	
			# Get A[i][k]
			# A[i][k] = $a0 + ((i*n)+k)*4
			mul $s0, $t0, $a3	# s0 = i*n
			add $s0, $s0, $t2	# s0 += k
			mul $s0, $s0, $t3	# s0 * 4
			add $a0, $a0, $s0	# address of value
			lwc1 $f4, ($a0)		# f4 = value at address
			lw $a0 0($sp)
			
			# B[k][j] = a1 + ((k*n)+j)*4
			mul $s1, $t2, $a3	# s1 = k*n
			add $s1, $s1, $t1	# s1 += j
			mul $s1, $s1, $t3	# s1 * 4
			add $a1, $a1, $s1	# address of value
			lwc1 $f6, ($a1)		# f6 = value at address
			lw $a1 4($sp)
			
			mul.s $f8, $f4, $f6	# A[i][k]*B[k][j]
			add.s $f2, $f2, $f8	# sum += f8
			
			addi $t2, $t2, 1	# k++
			j FifthLoop2
									
	Store2:		mul $s2, $t0, $a3	# s2 = i*n
			add $s2, $s2, $t1	# s2 += j
			mul $s2, $s2, $t3	# s2 * 4
			add $a2 $a2 $s2		# address of value
			lwc1 $f14, ($a2)	# c[i][j]
			add.s $f14, $f14, $f2	# c[i][j] + sum
			swc1 $f14, ($a2)	# c[i][j] = c[i][j] + sum
			lw $a2 8($sp)
			
			addi $t1, $t1, 1	# j++
			li $t2, 0		# k = 0
			j FourthLoop2
											
	Exit:	lw $s3 12($sp)
		lw $s2 16($sp)
		addi $sp $sp 20		# restore the stack
		jr $ra
		
	Exit1:	add $t4, $t4, $s3	# jj += bsize
		j FirstLoop2
			
	Exit2:	add $t5, $t5, $s3	# kk += bsize
		j SecondLoop2
	
	Exit3:	addi $t0, $t0, 1	# i++
		j ThirdLoop2
					
		
		
												
												
										
					
