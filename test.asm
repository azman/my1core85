; testbench for core85
	org 0000h
	jmp 0040h
	org 0020h
	ret
	org 002ch
	ret
	org 003ch
	ret
	org 0040h
init:
	mvi a, 0aah
	mov b, a
	xra a
	lxi sp, 3ff0h
	lxi h, 2000h
	lxi d, 2002h
	inr l
	mov c, m
	mvi m, 0ffh
	dcr m
	mov m, c
	dcr l
	mov h, a
	add m
	sui 3
	dad sp
	dad h
	inx h
	nop
	dcx b
	dcx sp
	stax b
	ldax d
	ldax b
	mvi a, 1bh
	sim
	xra a
	rim
	sta 2004h
	lda 0041h
	shld 2004h
	lhld 2002h
	rlc
	rrc
	rar
	ral
	daa
	cma
	cmc
	stc
	inx sp
	push d
	push psw
	pop b
	pop h
	jmp next
	org 1000h
next:
	mvi c, 2
loop:
	dcr c
	jnz loop
	out 80h
	in 81h
	call 1ff0h
	sphl
	lxi h, 1c00h
	xchg
	xthl
	ei
	di
	ei
	rst 4
	xchg
	pchl
	org 1a00h
	mvi c, 2
more:
	dcr c
	rz
	jmp more
	org 1c00h
	xra a
	cpe 1a00h
	hlt
	org 1ff0h
	ret
	org 2000h
	db 0fah,0ceh,0ach,0e5h
