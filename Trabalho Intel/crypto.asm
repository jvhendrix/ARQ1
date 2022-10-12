;Nome: João Vítor Schimuneck de Souza
;Matrícula: 00338443
;
;====================================================================
;						CRIPTOGRAFIA
;	
;====================================================================
;
	
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data


;--------------------------------------------------------------------
;
;							Variáveis
;
;--------------------------------------------------------------------



file_name_src	db		256 dup (?)		; Nome do arquivo a ser lido
file_name_dst	db		256 dup (?)		; Nome do arquivo a ser escrito
file_handle_src	dw		0				; Handler do arquivo origem
file_handle_dst	dw		0				; Handler do arquivo destino
file_buffer		db		10 dup (?)		; Buffer de leitura/escrita do arquivo

crypto_string			db	100	dup (?)		; Frase para ser encriptada
crypto_string_size		db	0
string_size_STRING		db  100 dup (?)

file_size		dw		00h
file_pos		dw		00h
file_byte_zero	dw		00h

file_size_STRING		db	100 dup (?), 0

crypto_array		dw	200 dup (?)
crypto_array_size	dw 	0


msg_pede_arquivo_src	db	"Nome do arquivo origem: ", 0
msg_fim					db	"Fim do programa.", CR, LF, 0
msg_erro_open_file		db	"Erro na abertura do arquivo.", CR, LF, 0
msg_erro_create_file	db	"Erro na criacao do arquivo.", CR, LF, 0
msg_erro_invalid_char	db	"Erro caractere invalido na string para ser encriptada", CR, LF, 0
msg_erro_file_size		db	"Erro tamanho de arquivo excede 65536 bytes", CR, LF, 0
msg_erro_string_too_big	db	"Erro string para ser encriptada ultrapassa o limite estabelecido", CR, LF, 0
msg_ask_crypto_string	db	"Entre com a frase para ser encriptada: ", 0
msg_erro_read_file		db	"Erro na leitura do arquivo.", CR, LF, 0
msg_erro_write_file		db	"Erro na escrita do arquivo.", CR, LF, 0
msg_erro_reset_file		db	"Erro no reset da posicao do arquivo.", CR, LF, 0
msg_erro_null_string	db	"Erro string fornecida e vazia.", CR, LF, 0
msg_erro_char_not_found	db	"Erro posicao valida para caractere da string nao foi encontrado.", CR, LF, 0

file_extenstion_txt 	db	".txt", 0	; Extensão .txt
file_extenstion_krp		db	".krp", 0	; Extensão .krp
msg_crlf				db	CR, LF, 0	; Caracteres '\r' e '\n'

msg_file_size			db	"O tamanho do arquivo de entrada e:", CR, LF, 0
msg_string_size			db	"O tamanho da string e: ", CR, LF, 0
msg_arquivo_final		db	"O nome do arquivo final e: ", CR, LF, 0


ajuda				db	"Esse eh teste", CR, LF, 0

MAXSTRING	equ		200
String	db		MAXSTRING dup (?)		; Usado na funcao gets

	.code
	.startup


;--------------------------------------------------------------------
;
;							Main
;
;--------------------------------------------------------------------

	call	getFileName					; Lê o nome do arquivo e coloca extensões
										; (file_name_src(.txt) e file_name_dst(.krp))

	lea 	dx, file_name_src			; Coloca o endereço de file_name_src em dx
	call	openFile					; Abre o arquivo file_name_src
	mov		file_handle_src, bx			; Coloca o handle do arquivo em file_handle_src
	jc		erro_open_file				; Se houve erro, ir para erro_open_file

	
	lea		dx, file_name_dst			; Coloca o endereço de file_name_dst em dx
	call	createFile					; Cria um arquivo com nome file_name_dst
	mov		file_handle_dst, bx			; Coloca o handle do arquivo em file_handle_dst
	jc		erro_create_file			; Se houve erro, ir para erro_create_file

	call	getCryptoString				; Lê a frase para ser encriptada (crypto_string)

	lea		cx, crypto_string			; Coloca o endereço de crypto_string em cx
	;dec		file_pos					; Decrementa file_pos (ajustar valor ao loop, que vai sempre incrementar file_pos)

	call	checkFileSize				; Verifica se o arquivo não excede 65536 bytes
	call	resetFilePos				; Reseta a posição do arquivo para o início
	jc		erro_reset_file				; Se (carry == 1), houve erro no reset da posição do arquivo
	lea		cx, crypto_string			; Coloca o endereço de crypto_string em cx
	
	mov		bx, file_handle_src			; Coloca em bx file_handle_src
	call	getChar						; Lê um char de file_handle_src para dl
	
	mov		file_pos, 0

	Continua2:
	

	inc		file_pos					; Incrementa file_pos
	mov		bx, file_handle_src			; Coloca em bx file_handle_src
	call	getChar						; Lê um char de file_handle_src para dl
	jc		erro_read_file				; Se (carry == 1), houve erro na leitura do arquivo
	
	cmp		ax,0						; Se (ax == 0), chegou ao final do arquivo (ax = bytes lidos)
	jz		EndOfFile				; 

	cmp		dl,'a'						; Esse bloco faz um toUpper em dl
	jb		dontUpper					;
	cmp		dl,'z'						;
	ja		dontUpper					;
	sub		dl,20h						;
	dontUpper:

	mov		bx, cx						; Coloca cx em bx (precisa ser base ou index register para acessar com [])
	cmp		[bx], 0						; Verifica se o conteúdo de bx (crypto_string) é 0 (terminador de string)
	je		TerminouArquivo				; Se for, acabou a string
	cmp		dl, [bx]					; Compara o caractere lido do arquivo com o caractere da string
	jne		Continua2					; Se forem diferentes, ler outro caractere do arquivo

	inc		cx							; Se forem iguais, incrementamos a string para seu próximo caractere

	
	call	checkCryptoArray			; Verifica se a posição já é válida
	cmp		dx, 1						; Compara dx com 1 (se dx = 1, achou a posição no vetor e continua busca, se dx = 0, não achou)
	je		Continua2					;
	
	mov		bx,file_handle_dst			; Coloca file_handle_dst em bx
	call	printAdressToFile			; Coloca o endereço do caractere lido no arquivo de saída
	jc		erro_write_file				; Se (carry == 1), houve erro na escrita do arquivo

	call	resetFilePos				; Reseta a posição do arquivo para o início
	jc		erro_reset_file				; Se (carry == 1), houve erro no reset da posição do arquivo

	mov		bx, file_handle_src			; Coloca em bx file_handle_src
	call	getChar						; Lê um char de file_handle_src para dl

	jmp		Continua2

EndOfFile:
	lea		bx,msg_crlf
	call 	printf_s
	lea		bx,msg_erro_char_not_found
	call    printf_s
	.exit	1

		
TerminouArquivo:


	mov		bx, file_handle_dst			; Coloca o handle do arquivo final em bx
	call	printFinalByte				; Escreve o byte final
	
	lea		bx, msg_file_size			; Coloca o endereço de msg_file_size em bx
	call	printf_s					; Printa a string
	
	mov		ax, file_size				; Coloca o tamanho do arquivo em ax
	call	printNumber					; Printa o número

	lea		bx, msg_crlf				;
	call	printf_s					;
	

	lea		bx, msg_string_size			; Coloca o endereço de msg_string_size em bx
	call	printf_s					; Printa a string

	lea		bx, crypto_string			; Coloca o endereço de crypto_string em bx
	call	getStringLenght				; Calcula o tamanho da string
	mov		ax, cx						; Coloca o tamanho da string em ax
	call	printNumber					; Printa o número

	lea		bx, msg_crlf				;
	call	printf_s					;
	
	
	
	mov		bx, file_handle_src			; Fecha o arquivo file_handle_src
	call	fclose						;

	mov		bx, file_handle_dst			; Fecha o arquivo file_handle_dst
	call	fclose						;
	
	
	
	
	lea		bx, msg_arquivo_final		; Coloca o endereço de msg_arquivo_final em bx
	call	printf_s					; Printa a mensagem

	lea		bx, file_name_dst			; Coloca o endereço de file_name_dst em bx
	call	printf_s					; Printa o nome do arquivo

	lea		bx, msg_crlf
	call	printf_s

	lea		bx, msg_fim					; Printa mensagem de fim
	call	printf_s					;

	.exit	0

;--------------------------------------------------------------------
;
;							Erros
;
;--------------------------------------------------------------------

erro_open_file:
	lea		bx, msg_erro_open_file		; Coloca o endereço de msg_erro_open_file em bx
	call	printf_s					; Printa a string
	.exit 	1

erro_create_file:
	lea		bx, msg_erro_create_file	; Coloca o enderelo de msg_erro_create_file em bx
	call 	printf_s					; Printa a string
	.exit	1

erro_invalid_char:
	lea		bx, msg_erro_invalid_char	; Coloca o endereço de msg_erro_invalid_char em bx
	call	printf_s					; Printa a string
	.exit	1	

erro_string_too_big:
	lea		bx, msg_erro_string_too_big	; Coloca o endereço de msg_erro_string_too_big em bx
	call	printf_s					; Printa a string
	.exit	1	

erro_read_file:
	lea		bx, msg_erro_read_file		; Coloca o endereço de msg_erro_read_file em bx
	call	printf_s					; Printa a string
	.exit	1

erro_write_file:
	lea		bx, msg_erro_write_file		; Coloca o endereço de msg_erro_write_file em bx
	call	printf_s					; Printa a string
	.exit	1

erro_reset_file:
	lea		bx, msg_erro_reset_file		; Coloca o endereço de msg_erro_reset_file em bx
	call	printf_s					; Printa a string
	.exit	1

erro_char_not_found:
	lea		bx, msg_erro_char_not_found	; Coloca o endereço de msg_erro_char_not_found em bx
	call	printf_s					; Printa a string
	.exit	1

erro_null_string:
	lea		bx, msg_erro_null_string	; Coloca o endereço de msg_erro_null_string
	call	printf_s					; Printa a string
	.exit	1

erro_file_size:
	lea		bx, msg_erro_file_size		; Coloca o endereço de msg_erro_file_size em bx
	call	printf_s					; Printa a string
	.exit	1

;--------------------------------------------------------------------
;getFileName
;
;	Funcao para ler o nome do arquivo
;--------------------------------------------------------------------
getFileName	proc	near
	
	lea		bx, msg_pede_arquivo_src		; Coloca endereço da string em bx
	call	printf_s						; Printa a string

	lea		bx, file_name_src				; Coloca o endereço de file_name_src em bx
	call	gets							; Coloca nome do arquivo em file_name_src

	lea		bx, msg_crlf					; Coloca o endereço de msg_crlf em bx
	call	printf_s						; Printa a string ("\r\n") (nova linha, no começo da linha)

	lea		bx, file_name_src				; Coloca o endereço de file_name_src em bx
	call	getStringLenght					; Calcula o tamanho de file_name_src (coloca em cx)
	
	lea		bx, file_name_src				; Coloca o endereço de file_name_src em bx
	lea		dx, file_name_dst				; Coloca o endereço de file_name_dst em dx
	call	copyFileName					; Copia o nome do arquivo para file_name_dst

	lea		bx, file_extenstion_txt			; Coloca o endereço de file_extenstion_txt em bx
	call	getStringLenght					; Calcula o tamanho de file_extenstion_txt (coloca em cx)

	lea		bx, file_name_src				; Coloca o endereço de file_name_src em bx
	lea		dx, file_extenstion_txt			; Coloca o endereço de file_extension_txt em dx
	call 	putFileExtenstion				; Coloca extensão em file_name_src

	lea		bx, file_extenstion_krp			; Coloca o endereço de file_extension_krp em bx
	call	getStringLenght					; Calcula o tamanho de file_extension_krp (coloca em cx)
		
	lea		bx, file_name_dst				; Coloca o endereço de file_name_dst em bx
	lea		dx, file_extenstion_krp			; Coloca o endereço de file_extension_krp em cx
	call 	putFileExtenstion				; Coloca extensão em file_name_dst

	ret

getFileName	endp

;--------------------------------------------------------------------
;checkFileSize
;
;	Funcao para verificar o tamanho do arquivo_src
;
;--------------------------------------------------------------------

checkFileSize 	proc	near
	
	loop_checkFileSize:
	inc		file_size					; Incrementa file_size
	cmp		file_size, 0
	je		erro_file_size				; Se houve overflow, o arquivo excedeu o limite de bytes

	mov		bx, file_handle_src			; Coloca em bx file_handle_src
	call	getChar						; Lê um char de file_handle_src para dl
	jc		erro_read_file				; Se (carry == 1), houve erro na leitura do arquivo
	
	cmp		ax,0						; Se (ax == 0), chegou ao final do arquivo (ax = bytes lidos)
	jz		end_loop_checkFileSize		; 

	jmp		loop_checkFileSize			; Volta para o loop

	end_loop_checkFileSize:				; Fim do loop


	ret


checkFileSize	endp

;--------------------------------------------------------------------
;getCryptoString
;
;	Funcao para ler a string que será encriptada
;--------------------------------------------------------------------

getCryptoString		proc	near

	lea		bx, msg_ask_crypto_string		; Coloca o endereço de msg_ask_crypto_string em bx
	call	printf_s						; Printa a string

	lea		bx, crypto_string				; Coloca o endereço de crypto_string em bx
	call	gets							; Coloca a string para ser encriptada em crypto_string



	lea		bx, msg_crlf					; Coloca o endereço de msg_crlf em bx
	call	printf_s						; Printa a string ("\r\n") (nova linha, no começo da linha)

	lea		bx, crypto_string				; Coloca o endereço de crypto_string em bx
	call	checkStringNULL					; Verifica se a string é vazia

	lea		bx, crypto_string				; Coloca o endereço de crypto_string em bx
	call	getStringLenght					; Calcula o tamanho da string
	cmp		cx, 101							; Compara o tamanho da string com 101
	ja		erro_string_too_big				; Se for maior que o limite estabelecido, ir para erro

	lea		bx, crypto_string				; Coloca o endereço de crypto_string em bx
	call	checkStringChar					; Verifica se a tem caracteres inválidos
	
	lea		bx, crypto_string				; Coloca o endereço de crypto_string em bx
	call	upperString						; Faz um toUpper em todos caracteres da string


	lea		bx, msg_crlf					; Coloca o endereço de msg_crlf em bx
	call	printf_s						; Printa a string ("\r\n") (nova linha, no começo da linha)


	lea		bx, crypto_string
	call	RemoveSpace

	ret

getCryptoString	endp
;--------------------------------------------------------------------
;checkStringNULL
;
;	Função para verificar se a string é vazia
;
;--------------------------------------------------------------------
checkStringNULL	proc	near
	
	cmp		[bx], 0							; Verifica se a primeira posição da string é NULL
	je		erro_null_string				; Se for, a string é vazia

	ret

checkStringNULL	endp
;--------------------------------------------------------------------
;checkStringChar
;
;	Função para verificar se a string contém chars inválidos ou se
;	seu tamnho excede 100 + 1 chars
;
;--------------------------------------------------------------------
checkStringChar	proc	near

	loop_checkStringChar:
	mov		dl, [bx]
	cmp		dl, 0							; Verifica se a string chegou no final
	je		end_checkStringChar
	
	cmp		dl, 020h						; Verifica se o caractere esá abaixo do limite
	jb		erro_invalid_char

	cmp		dl, 07Dh						; Verifica se o caractere esá acima do limite
	ja		erro_invalid_char

	inc		bx								; Incrementa a posição na string

	jmp		loop_checkStringChar			; Volta para o loop

	end_checkStringChar:
	ret
	
checkStringChar 	endp
;--------------------------------------------------------------------
;upperString
;
;	Funcao para fazer um toUpper em uma string
;
;	Entradas:
;
;	bx = endereço da string
;--------------------------------------------------------------------
upperString		proc	near


	loop_upperString:

	mov		al, [bx]
	mov		dl, al

	cmp		dl, 0							; Se a string estiver no final
	je		end_loop_upperString			; Sair do loop
	
	cmp		dl,'a'						; Faz um toUpper no caractere
	jb		dontUpperString					;

	cmp		dl, ' '
	je		dontUpperString

	cmp		dl,'z'					;
	ja		dontUpperString					;
	
	sub		dl,32							;
	mov		[bx], dl

	inc		bx								; Incrementa bx (bx tem o endereço da string)
	inc		crypto_string_size
	jmp		loop_upperString
	
	dontUpperString:

	inc		bx
	jmp		loop_upperString
	
	end_loop_upperString:
	ret

upperString		endp


;--------------------------------------------------------------------
;gets
;
;	Função lê um string do teclado e coloca no buffer apontado por BX
;
;	bx = endereço da string que terá o nome do arquivo
;--------------------------------------------------------------------
gets	proc	near
	
	push	bx

	mov		ah,0ah							; Lê uma linha do teclado
	lea		dx,String
	mov		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	int		21h

	lea		si,String+2						; Copia do buffer de teclado para o FileName
	pop		di
	mov		cl,String+1
	mov		ch,0
	mov		ax,ds							; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	mov		byte ptr es:[di], 0				; Coloca marca de fim de string
	ret

gets	endp

;--------------------------------------------------------------------
;putFileExtension
;	
;	Essa função coloca a extensão em uma string
;
;	Entradas:
;
;	bx = endereço da string com nome do arquivo
;	cx = tamanho da string com a extensão a ser colocada
;	dx = endereço da string com a extensão a ser colocada
;--------------------------------------------------------------------
putFileExtenstion	proc	near	
	
	mov		ax,ds							; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax							;

	loop_putFileExtenstion:					; Loop para procurar o final da string de file_name_src
		
		cmp  	[bx], 0						; Verifica se a string está no final
		je		end_loop_putFileExtenstion	; Se estiver, sair do loop
		inc		bx							; Caso contrário, incrementar endereço da string
		jmp		loop_putFileExtenstion		; Voltar para o loop

	end_loop_putFileExtenstion:	

	mov		di, bx							; Coloca o endereço final da string em di
	mov		si, dx							; Coloca o endereço da string da extensão do arquivo em si

	rep		movsb							; Copia a extensão para a string do nome do arquivo

	ret

putFileExtenstion	endp

;--------------------------------------------------------------------
;openFile
;	
;	Essa função abre um arquivo
;
;	Entradas:
;
;	dx = endereço da string com nome do arquivo
;	
;	Saídas:
;	
;	bx = handle do arquivo
;	cf = 0 se ok
;--------------------------------------------------------------------
openFile	proc	near

	mov		al, 0
	mov		ah, 3dh
	int		21h
	mov		bx, ax							; Coloca o handle do arquivo em bx
	
	ret

openFile	endp

;--------------------------------------------------------------------
;createFile
;
;	Essa função cria um arquivo 
;
;	Entradas:
;
;	dx = endereço da string com nome do arquivo
;
;	Saídas:
;
;	bx = handle do arquivo
;	cf = 0 se ok
;--------------------------------------------------------------------
createFile		proc	near

	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret

createFile		endp

;--------------------------------------------------------------------
;copyFileName
;	
;	Essa função copia uma string para outra string
;
;	Entradas:
;
;	bx = endereço da string original
;	cx = tamanho da string original
;	dx = endereço da string destino
;
;--------------------------------------------------------------------
copyFileName	proc	near

	mov		ax,ds							; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax							;

	mov 	di, dx							; Coloca o endereço da string destino em di
	mov		si, bx							; Coloca o endereço da string original em si
	rep		movsb							; Copia string original para string destino

	ret

copyFileName		endp

;--------------------------------------------------------------------
;getChar
;
;		Função lê um caractere do arquivo com seu handle em bx
;
;	Entradas: 
;		
;		BX -> file handle
;
;	Saídas:   
;		
;		dl -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	proc	near
	
	push	cx								; Salva cx na pilha
	
	mov		ah,3fh
	mov		cx,1
	lea		dx, file_buffer
	int		21h
	mov		dl, file_buffer

	pop		cx								; Coloca o valor da pilha em cx

	ret

getChar	endp

;--------------------------------------------------------------------
;setChar:
;
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	
	push	cx

	mov		ah,40h
	mov		cx,1
	mov		file_buffer,dl
	lea		dx,file_buffer
	int		21h

	pop		cx

	ret
setChar	endp	


;--------------------------------------------------------------------
;checkCryptoArray
;
;	Essa função verifica se a posição do caractere a ser colocada
;no arquivo é valida
;--------------------------------------------------------------------

checkCryptoArray	proc	near
	push	cx									; Salva cx na pilha

	mov		si, 0								; Coloca 0 em si

	mov		dx, 0								; Coloca 0 em dx
	
	mov		ax, crypto_array_size				; Coloca o valor de crypto_array_size em ax
	cmp		ax, 0								; Compara ax com 0
	je		end_loop_checkCryptoArray	

	loop_checkCryptoArray:

	cmp		si, crypto_array_size				; Compara si com crypto_array_size
	je		end_loop_checkCryptoArray
	
	mov		bx, [crypto_array + si]				; Coloca em bx o conteúdo do vetor
	cmp		bx, file_pos						; Compara o conteúdo do vetor com file_pos
	je		foundPos							; Se for igual, achou a posição


	inc		si									; Incremetna si
	inc		si									; Incrementa si
	jmp		loop_checkCryptoArray				; Volta para o loop

	foundPos:
	mov		dx, 1								; Coloca 1 em dx
	pop		cx									; Pega o valor de cx da pilha
	dec		cx									; Decrementa cx
	jmp		end_checkCryptoArray				; Vai para o fim
	
	end_loop_checkCryptoArray:
	pop		cx									; Pega o valor de cx da pilha

	end_checkCryptoArray:
	ret

checkCryptoArray	endp

;--------------------------------------------------------------------
;printAddressToFile
;
;	Entra: BX -> file handle
;       	DX -> endereço a ser escrito
;	Sai:   BX -> numero de bytes escritos
;			CF -> "0" se escrita ok
;--------------------------------------------------------------------
printAdressToFile	proc	near
	
	push	cx								; Salva cx na pilha
	mov		ah,40h
	mov		cx,2							; Coloca 2 em cx (valor de cx = número de bytes a serem escritos)
	
	lea		dx, file_pos					; Em file_pos tem o endereço do caractere do arquivo lido
	int		21h

	pop		cx								; Coloca o valor da pilha em cx
	
	mov		si, crypto_array_size			; Coloca em si o tamanho do vetor
	mov		ax, file_pos					; Coloca em ax a posição do arquivo
	mov		[si + crypto_array], ax			; Coloca ax no vetor

	inc		crypto_array_size				; Incrementa o tamanho do vetor
	inc		crypto_array_size				; Incrementa o tamanho do vetor

	mov		file_pos, 0						; Coloca 0 em file_pos

	ret			

printAdressToFile	endp


printFinalByte	 proc	near

	mov		ah,40h
	mov		cx,2							; Coloca 2 em cx (valor de cx = número de bytes a serem escritos)
	lea		dx, file_byte_zero				; 
	int		21h

	ret

printFinalByte 	endp

;--------------------------------------------------------------------
;resetFilePos
;
;	Reseta a posição do arquivo
;--------------------------------------------------------------------

resetFilePos	proc	near

	push	cx								; Coloca cx na pilha

	mov		al, 0							; origem
	mov		ah, 42h

	mov 	dx, 0							; offset
	mov		cx, 0							;

	mov		bx, file_handle_src				; coloca file handle em bx

	int		21H

	pop		cx								; Pega o valor de cx na pilha

	ret



resetFilePos		endp

;--------------------------------------------------------------------
;fclose
;
;	fecha o aruqivo
;
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah, 3eh
	int		21h
	ret
fclose	endp


;--------------------------------------------------------------------
;getStringLenght
;	
;	Essa função calcula o tamanho de uma string
;	(Retorna o tamanho da string em cx)
;	
;	bx = endereço da string
;--------------------------------------------------------------------
getStringLenght	proc	near

	mov		cx, 1							; Inicializa cx em 1

	loop_getStringLenght:
		
		cmp		[bx], 0						; Verifica se a string está no final
		je		end_getStringLenght			; Se for NULL, sair do loop
											; Caso contrário,
		inc		cx							; Incrementa cx
		inc		bx							; Incrementa bx
		jmp		loop_getStringLenght		; Volta para o loop

	end_getStringLenght:
	ret			

getStringLenght		endp

;====================================================================
;printf_s		
;	
;	Essa função printa uma string na tela
;	
;	bx = endereço da string
;====================================================================
printf_s	proc	near
	
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp


;====================================================================
;printNumber		
;	
;	Essa função printa um numero de 16 bits na tela
;	
;	ax = número
;====================================================================

printNumber	proc	near        
     
    ;inicializa a contagem
    mov cx,0
    mov dx,0

    loop_print_number:
        ; se ax for 0
        cmp ax,0
        je print_number     
         
        ;coloca 10 em bx
        mov bx,10       
         
        ; pega o ultimo digito
        div bx                 
         
        ; coloca dx na pilha
        push dx             
         
        ; incrementa a contagem
        inc cx             
         
        ; coloca 0 em dx
        xor dx,dx
        jmp loop_print_number
    print_number:
        
		; verifica se a contagem eh maior que 0
        cmp cx,0
        je exit_loop_print_number
         
        ; pega o valor da pilha
        pop dx
         
        ; coloca o valor em ascii
        add dx,48
         
        ; printa char
        mov ah,02h
        int 21h
         
        ; decrementa o contador
        dec cx
        jmp print_number

	exit_loop_print_number:

		ret
printNumber	endp


RemoveSpace	proc near
		mov ax,0
		lea si,crypto_string
loop_RemoveSpace:
		mov al,[bx]
		mov dl,al
		cmp dl, ' '
		je RemoveSpaceFunc
		cmp dl, 0
		je outRemoveSpace
		mov [si],dl
		inc si
		inc bx
		jmp loop_RemoveSpace
outRemoveSpace:
		mov	[si], 0
		ret
RemoveSpaceFunc:
		inc bx
		jmp loop_RemoveSpace
RemoveSpace endp

	end



