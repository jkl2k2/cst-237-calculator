.data
    charExpr:
        .space 64
    formattedExpr:
        .space 66
    stackPostFix: .space 66
    
    stack: .space 40
    prompt: .asciiz "Enter Intfix exp: "
    disclaimer: .asciiz "ONLY WORKS FOR SINGLE DIGITS AND NO FLOATING NUMBERS\n"
    postFix: .asciiz "Postfix Expression: "
    result: .asciiz "The result of the expression = "
    
.text
main:
    li $v0, 4
    la $a0, disclaimer
    syscall
    
    #Printing prompt Message
    li $v0, 4
    la $a0, prompt
    syscall

    # Read 64 characters to expressionString
    li    $v0, 8
    la    $a0, charExpr
    #addi $a0, $a0, 1
    li    $a1, 64
    syscall
    
    # Loop through to find end and add parenthesis
    addClosingParenthesis:
        #subi $a0, $a0, 1
        la $a0, charExpr
        li $t0, 0
        #li $t1, '('
        #sb $t1, charExpr($t0)
        #addi $t0, $t0, 1
        addParenLoop:
            lb $t1, charExpr($t0)
            beqz $t1, addParenLoopExit
            addi $t0, $t0, 1
            j addParenLoop
        addParenLoopExit:
            # add closing parenthesis
            li $t1, ')'
            sb $t1, charExpr($t0)
            addi $t0, $t0, 1
            # Add null terminator
            li $t1, '\0'
            sb $t1, charExpr($t0)
            
            la $a2, charExpr
            la $a3, formattedExpr
            jal expToPostfix
    
            # Print the formatted expression
            #la $a0, ($v0)
            #jal printCharArray
    
            # Exit program
            li $v0, 10
            syscall
    
    printCharArray:
        move $t1, $a0
        printLoop:
            lb $a0, 0($t1)
            li $v0, 11
            syscall
            beqz $a0, printExit
            addi $t1, $t1, 1
            j printLoop
        printExit:
            jr $ra
    
    expToPostfix:
        # charExpr
        move $s0, $a2
        # formattedExpr
        move $s1, $a3
        # i
        li $t0, 0
        # j
        li $t1, 0
        
        # topPostFix index
        addi $t6, $zero, -1
        
        # Add opening parenthesis
        #li $a0, ')'
        #jal setPostFix
        li $a0, '('
        jal pushPostFix
        # Loop while not null character
        nullLoop:
            # Char at current index
            lb $t2, charExpr($t0)
            
            #li $v0, 1
            #la $a0, ($t2)
            #syscall
            
            #li $v0, 11
            #li $a0, '\n'
            #syscall
            
            # Break if null terminator
            beqz $t2, endNullLoop
            # Branch if '('
            beq $t2, '(', addOpenParenthesis
            # Check if >=0 and <=9
            move $a0, $t2
            jal checkGreater0Less9
            
            # Check if operator that we need to add into array
            move $a0, $t2
            jal operations
            beq $v0, 1, addOperator
            # Branch if ')'
            beq $t2, ')', sortParentheses
            # Loop again
            j increment
            increment:
                # Increment index
                addi $t0, $t0, 1
                # Jump back to beginning of loop
                j nullLoop
            sortParentheses:
                # x = popPostFix()
                jal popPostFix
                la $t3, ($v0)
                sortParenthesesLoop:
                    beq $t3, '(', endSortParenthesesLoop
                    move $a0, $t3
                    jal setPostFix
                    
                    jal popPostFix
                    la $t3, ($v0)
                    j sortParenthesesLoop
                endSortParenthesesLoop:
                    j increment
            addOpenParenthesis:
                # Add the current chat '(' to postfix
                la $a0, ($t2)
                jal pushPostFix
                # Loop again
                j increment
            # Check if a char is >='0' or <='9'
            checkGreater0Less9:
                bge $a0, '0', checkLess9
                # Return back to nullLoop
                jr $ra
                checkLess9:
                    ble $a0, '9', setPostFix
                    bgt $a0, '9', endOfCheckLess
                    # Return back to nullLoop
                    j increment
                    endOfCheckLess:
                        jr $ra
            addOperator:
                #**************************** NEED TO PUT POPPOSTFIX() STUFF ********************
                # jal popPostFix
                # would return a char to $v0
                jal popPostFix
                la $t3, ($v0)
                addOperatorWhile:
                    la $a0, ($t3)
                    jal operations
                    beq $v0, 0, endAddOperatorWhile
                    # pemdas() calls
                    la $a0, ($t3)
                    jal PEMDAS
                    la $t4, ($v0)
                    
                    la $a0, ($t2)
                    jal PEMDAS
                    la $t5, ($v0)
                    
                    
                    blt $t4, $t5, endAddOperatorWhile
                    # inside while
                    move $a0, $t3
                    #jal setPostFixInt
                    jal setPostFix
                    
                    jal popPostFix
                    la $t3, ($v0)
                    j addOperatorWhile
                endAddOperatorWhile:
                    # pushPostFix(x);
                    la $a0, ($t3)
                    jal pushPostFix
                    # pushPostFix(expChar);
                    la $a0, ($t2)
                    jal pushPostFix
                    # Jump to end of if statement structure
                    j increment            
        endNullLoop:
            # Add null terminator
            li $a0, '\0'
            jal setPostFix
            
            li $v0, 4
            la $a0, postFix
            syscall
            
            la $a0, formattedExpr
            jal printCharArray
            # Jump to end of program
            j solvePostFix
    pushPostFix:
        # I believe $a0 has character
        #li $v0, 11
        #syscall
        
        addi $t6, $t6, 1
        
        sb $a0, stackPostFix($t6)
        
        #li $v0, 1
        #syscall
        
        jr $ra
    popPostFix:
        
        lb $v0, stackPostFix($t6)
        
        subi $t6, $t6, 1
        
        jr $ra
    setPostFixInt:
        #
        sub $a0, $a0, '0'
        sb $a0, formattedExpr($t1)

        # Increment $a3 index (j)
        addi $t1, $t1, 1
        # Jump back
        jr $ra
    setPostFix:
        sb $a0, formattedExpr($t1)

        # Increment $a3 index (j)
        addi $t1, $t1, 1
        # Jump back
        jr $ra
    operations:
        beq $a0, '^', operationsTrue
        beq $a0, '*', operationsTrue
        beq $a0, '/', operationsTrue
        beq $a0, '+', operationsTrue
        beq $a0, '-', operationsTrue
        beq $a0, '%', operationsTrue
        li $v0, 0
        jr $ra
        operationsTrue:
            li $v0, 1
            jr $ra
    PEMDAS:
        beq $a0, '^', endPemdasE
        beq $a0, '%', endPemdasM
        beq $a0, '*', endPemdasMD
        beq $a0, '/', endPemdasMD
        beq $a0, '+', endPemdasAS
        beq $a0, '-', endPemdasAS
        li $v0, 0
        jr $ra
        
        endPemdasE:
            li $v0, 4
            jr $ra
        endPemdasM:
            li $v0, 3
            jr $ra
        endPemdasMD:
            li $v0, 2
            jr $ra
        endPemdasAS:
            li $v0, 1
            jr $ra
    
    
    #-------------------------------------------------------------------
    solvePostFix:
        # i
        addi $t0, $zero, 0
        # num1
        addi $t1, $zero, 0
        # num2
        addi $t2, $zero, 0
        # res
        addi $t3, $zero, 0
        # num
        addi $t4, $zero, 0
        # top
        addi $t5, $zero, -1
        
        
        whileSolve:
            lb $s0, formattedExpr($t0)
            
                beqz $s0, endWhileSolve
                
                blt $s0, '0', solveElse
                bgt $s0, '9', solveElse
                
                subi $t4, $s0, 48
                move $a0, $t4
                jal pushSolve
                
                j incrementSolve
                
                solveElse:
                    jal popSolve
                    la $t1, ($v0)
                    
                    jal popSolve
                    la $t2, ($v0)
                    
                    beq $s0, '+', solvePlus
                    beq $s0, '-', solveNeg
                    beq $s0, '*', solveMul
                    beq $s0, '/', solveDiv
                    beq $s0, '%', solveMod
                    beq $s0, '^', solvePow
                    solvePlus:
                        add $t3, $t1, $t2
                        la $a0, ($t3)
                        jal pushSolve
                        j incrementSolve
                    solveNeg:
                        sub $t3, $t2, $t1
                        la $a0, ($t3)
                        jal pushSolve
                        j incrementSolve
                    solveMul:
                        mult $t1, $t2
                        mflo $a0
                        jal pushSolve
                        j incrementSolve
                    solveDiv:
                        div $t2, $t1
                        mflo $a0
                        jal pushSolve
                        j incrementSolve
                    solveMod:
                        whileMod:
                            blt $t2, $t1, endWhileMod
                            sub $t2, $t2, $t1
                            j whileMod
                        endWhileMod:
                            la $a0, ($t2)
                            jal pushSolve
                            j incrementSolve
                    solvePow:
                        addi $t3, $zero, 1
                        
                        whilePow:
                            beq $t1, 0, endWhilePow
                            mult $t3, $t2
                            mflo $t3
                            subi $t1, $t1, 1
                            j whilePow
                        endWhilePow:
                            la $a0, ($t3)
                            jal pushSolve
                            j incrementSolve
        incrementSolve:
            addi $t0, $t0, 1
            j whileSolve
        endWhileSolve:
            li $a0, '\n'
            li $v0, 11
            syscall
            
            li $v0, 4
            la $a0, result
            syscall
            
            jal popSolve
            la $a0, ($v0)
            
            li $v0, 1
            syscall
            j endProgram
    
        pushSolve:
            addi $t5, $t5, 1
        
            sb $a0, stack($t5)
        
            jr $ra
        popSolve:
            lb $v0, stack($t5)
        
            subi $t5, $t5, 1
        
            jr $ra
    
    endProgram:
        # Exit program
        li $v0, 10
        syscall