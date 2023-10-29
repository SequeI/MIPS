.data
    inputStr: .space 20  # Allocating space for input string
    len1: .word 0
    str2float: .float 0.0
    prompt: .asciiz "$ Enter a number (xxx.yyy) : "
    signBit: .asciiz "$ Sign Bit: "
    exponentInHex: .asciiz "\n$ Exponent in hex : "
    fractionInHex: .asciiz "\n$ Fraction in hex : "
    hexDigits: .asciiz "0123456789ABCDEF"
    hexValue: .space 10
    exponentHex: .space 3
    fractionHex: .space 10
    null: .asciiz "\0"

.text

main:
    # Print the prompt
    li $v0, 4
    la $a0, prompt
    syscall

    # Read the input string
    li $v0, 8
    la $a0, inputStr
    li $a1, 10
    syscall

    # Initialize registers and floating-point variable
    la $t0, inputStr  # Load the address of the input string
    li $t6, 100  # Multiplier for exponent conversion
    li $t7, 10  # Divisor for exponent conversion
    li $t4, 10  # Divisor for fraction conversion
    lwc1 $f10, str2float  # Load the initial float value

exponent_conversion:
    lb $t2, 0($t0)  
    beq $t2, 46, fraction_conversion  
    beq $t2, 45, negative_exponent_conversion 
    subi $t2, $t2, 48  # Convert ASCII to integer value
    mul $t2, $t2, $t6  # Multiply the integer value
    div $t6, $t6, $t7  # Divide the multiplier
    mtc1 $t2, $f0  
    cvt.s.w $f0, $f0  # Convert integer to floating-point
    add.s $f10, $f10, $f0 
    addi $t0, $t0, 1  
    j exponent_conversion  # Repeat the process

fraction_conversion:
    addi $t0, $t0, 1  
    lb $t2, 0($t0) 
    beqz $t2, store_float 
    beq $t2, 10, store_float # Check for a new line
    subi $t2, $t2, 48  # Convert ASCII to integer value
    mtc1 $t2, $f0  
    cvt.s.w $f0, $f0  
    add $t5, $zero, $t4  # Load the divisor value
    mtc1 $t5, $f4  
    li $t5, 0  
    cvt.s.w $f4, $f4  
    mul $t4, $t4, $t7 
    div.s $f0, $f0, $f4  
    add.s $f10, $f10, $f0  
    j fraction_conversion  

negative_exponent_conversion:
    addi $t0, $t0, 1  
    lb $t2, 0($t0)  # Load the byte from the current address
    beq $t2, 46, negative_fraction_conversion  # Check for the decimal point
    subi $t2, $t2, 48  
    mul $t2, $t2, $t6  
    div $t6, $t6, $t7  # Divide the multiplier
    mtc1 $t2, $f0  
    cvt.s.w $f0, $f0 
    sub.s $f10, $f10, $f0  
    j negative_exponent_conversion 

negative_fraction_conversion:
        addi $t0, $t0, 1 
        lb $t2, 0($t0)  
        beqz $t2, store_float  
        beq $t2, 10, store_float  
        subi $t2, $t2, 48 
        mtc1 $t2, $f0  
        cvt.s.w $f0, $f0  
        add $t5, $zero, $t4  
        mtc1 $t5, $f4  
        li $t5, 0  
        cvt.s.w $f4, $f4 
        mul $t4, $t4, $t7  
        div.s $f0, $f0, $f4  
        sub.s $f10, $f10, $f0 
        j negative_fraction_conversion

store_float:
    swc1 $f10, str2float  # Store the final float value

bit_sign_extraction:
	lwc1, $f12, str2float
	mfc1 $t0, $f12
	srl $t0, $t0, 31
	li $v0, 4
    	la $a0, signBit
   	syscall
	li $v0, 1
	move $a0, $t0
	syscall
	
exponent_bit_extraction:
	mfc1 $t2, $f12
	andi $t2, $t2, 0x7F800000
	srl $t2, $t2, 23
	
	la $s0, exponentHex
	li $t6, 0
	la $s7, null
	lb $s5, ($s7)
	sb $s5, 2($s0)
	
exponent_bit_conversion:
	li $t0, 0
	andi $t0, $t2, 0xF
	la $t3, hexDigits
	addi $t0, $t0, 48
	loop:
		lb $t7, 0($t3)
		beqz $t7, A_F
		beq $t0, $t7, store_ascii
		addi $t3, $t3, 1
		j loop
		
	A_F:
		addi $t0, $t0, 7
		la $t3, hexDigits
		j loop
store_ascii:
	sb $t7, ($s0)
	addi $s0, $s0, 1
	addi $t6, $t6, 1
	srl $t2, $t2, 4
	beq $t6, 2, print_ex
	j exponent_bit_conversion

print_ex:
	la $t0, exponentHex
	lb $t1, 0($t0)
	lb $t2, 1($t0)
	sb $t2, 0($t0) 
	sb $t1, 1($t0)
    	li $v0, 4
    	la $a0, exponentInHex
    	syscall
	li $v0, 4
    	la $a0, exponentHex
    	syscall
	
fraction_bit_extraction:
	mfc1 $t2, $f12
	andi $t2, $t2, 0x007FFFFF
	la $s0, fractionHex
	li $t6, 0
	la $s7, null
	lb $s5, ($s7)
	sb $s5, 9($s0)
	
fraction_bit_conversion:
	li $t0, 0
	andi $t0, $t2, 0xF
	la $t3, hexDigits
	addi $t0, $t0, 48
	loop2:
		lb $t7, 0($t3)
		beqz $t7, A_F2
		beq $t0, $t7, store_fraction
		addi $t3, $t3, 1
		j loop2
	A_F2:
		addi $t0, $t0, 7
		la $t3, hexDigits
		j loop2
		
store_fraction:
	sb $t7, ($s0)
	addi $s0, $s0, 1
	addi $t6, $t6, 1
	srl $t2, $t2, 4
	beq $t6, 6, reverser
	j fraction_bit_conversion

reverser:
	la $s0, fractionHex
	la $t0, 0($s0)  
	addi $t1, $s0, 5 

reverse_loop:
    bge $t0, $t1, space_adder
    lb $t2, 0($t0)  
    lb $t3, 0($t1)  
    sb $t3, 0($t0) 
    sb $t2, 0($t1)  
    addi $t0, $t0, 1  
    subi $t1, $t1, 1 
    j reverse_loop  
    
space_adder:
	la $s0, fractionHex
	li $t1, 0x20
	lb $t2, 2($s0)
	lb $t3, 3($s0)
	lb $t4, 4($s0)
	lb $t5, 5($s0)
	sb $t1, 2($s0)
	sb $t2, 3($s0)
	sb $t3, 4($s0)
	sb $t1, 5($s0)
	sb $t4, 6($s0)
	sb $t5, 7($s0)
    
print_fr:
    	li $v0, 4
    	la $a0, fractionInHex
    	syscall
	li $v0, 4
    	la $a0, fractionHex
    	syscall


	
	

	
	
		

		
	
	

	
	
		
		
		
	
		