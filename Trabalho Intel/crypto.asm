;
;====================================================================
;	- Escrever um programa para ler um arquivo texto e 
;		apresent�-lo na tela
;	- O usu�rio devem informar o nome do arquivo, 
;		assim que for apresentada a mensagem: �Nome do arquivo: �
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data

file_name_src	db		256 dup (?)		; Nome do arquivo a ser lido
file_name_dst	db		256 dup (?)		; Nome do arquivo a ser escrito
file_handle_src	dw		0				; Handler do arquivo origem
file_handle_dst	dw		0				; Handler do arquivo destino
file_buffer		db		10 dup (?)		; Buffer de leitura/escrita do arquivo

crypto_string	db		100	dup (?)		; Frase para ser encriptada

msg_pede_arquivo_src	db	"Nome do arquivo origem: ", 0
msg_erro_open_file		db	"Erro na abertura do arquivo.", CR, LF, 0
msg_erro_create_file	db	"Erro na criacao do arquivo.", CR, LF, 0
msg_ask_crypto_string	db	"Entre com a frase para ser encriptada: ", 0
MsgErroReadFile			db	"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWriteFile		db	"Erro na escrita do arquivo.", CR, LF, 0

file_extenstion_txt 	db	".txt", 0	; Extensão .txt
file_extenstion_krp		db	".krp", 0	; Extensão .krp
msg_crlf				db	CR, LF, 0	; Caracteres '\r' e '\n'




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
	
	
	
	
	
	
	
	
	.exit	 0

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



getCryptoString	proc	near

	lea		bx, msg_ask_crypto_string		; Coloca o endereço de msg_ask_crypto_string em bx
	call	printf_s						; Printa a string

	lea		bx, crypto_string				; Coloca o endereço de crypto_string em bx
	call	gets							; Coloca a string para ser encriptada em crypto_string

	lea		bx, msg_crlf					; Coloca o endereço de msg_crlf em bx
	call	printf_s						; Printa a string ("\r\n") (nova linha, no começo da linha)

	ret

getCryptoString	endp

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
;copyFileName
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

	end



