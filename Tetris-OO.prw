#include "protheus.ch"

#DEFINE GRID_EMPTY_LINE   "11000000000011"
#DEFINE GRID_BOTTOM_LINE  "11111111111111"

#DEFINE PIECE_NUMBER     1
#DEFINE PIECE_ROTATION   2
#DEFINE PIECE_ROW        3
#DEFINE PIECE_COL        4


/* ========================================================
Função       U_TETRISOO
Autor        Júlio Wittwer
Data         21/03/2015
Versão       1.150321
Descriçao    Réplica do jogo Tetris, feito em AdvPL

Remake reescrito a partir do Tetris.PRW, utiliando Orientação a Objetos

Para jogar, utilize as letras :

A ou J = Move esquerda
D ou L = Move Direita
S ou K = Para baixo
W ou I = Rotaciona sentido horario
Barra de Espaço = Dropa a peça

======================================================== */
                 
// =======================================================

USER Function TetrisOO()
Local nC , nL
Local oDlg
Local oBGGame , oBGNext
Local oFont , oLabel , oMsg
Local oScore , oTimer
Local aBMPGrid   := array(20,10) // Array de bitmaps de interface do jogo 
Local aBMPNext   := array(4,5)   // Array de bitmaps da proxima peça
Local aResources := { "BLACK","YELOW2","LIGHTBLUE2","ORANGE2","RED2","GREEN2","BLUE2","PURPLE2" }
Local oTetris 

// Fonte default usada na caixa de diálogo 
// e respectivos componentes filhos
oFont := TFont():New('Courier new',,-16,.T.,.T.)

DEFINE DIALOG oDlg TITLE "Object Oriented Tetris AdvPL" FROM 10,10 TO 450,365 ;
   FONT oFont COLOR CLR_WHITE,CLR_BLACK PIXEL

// Cria um fundo cinza, "esticando" um bitmap
@ 8, 8 BITMAP oBGGame RESOURCE "GRAY" ;
	SIZE 104,204  Of oDlg ADJUST NOBORDER PIXEL

// Desenha na tela um grid de 20x10 com Bitmaps
// para ser utilizado para desenhar a tela do jogo

For nL := 1 to 20
	For nC := 1 to 10
		
		@ nL*10, nC*10 BITMAP oBmp RESOURCE "BLACK" ;
      SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		aBMPGrid[nL][nC] := oBmp
		
	Next
Next
               
// Monta um Grid 4x4 para mostrar a proxima peça
// ( Grid deslocado 110 pixels para a direita )

@ 8, 118 BITMAP oBGNext RESOURCE "GRAY" ;
	SIZE 54,44  Of oDlg ADJUST NOBORDER PIXEL

For nL := 1 to 4
	For nC := 1 to 5
		
		@ nL*10, (nC*10)+110 BITMAP oBmp RESOURCE "BLACK" ;
      SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		aBMPNext[nL][nC] := oBmp
		
	Next
Next

// Label fixo, título do Score.
@ 80,120 SAY oLabel PROMPT "[Score]" SIZE 60,10 OF oDlg PIXEL
                                    
// Label para Mostrar score, timers e mensagens do jogo
@ 90,120 SAY oScore PROMPT "        " SIZE 60,120 OF oDlg PIXEL

// Botões com atalho de teclado
// para as teclas usadas no jogo
// colocados fora da area visivel da caixa de dialogo

@ 480,10 BUTTON oDummyB1 PROMPT '&A'  ACTION ( oTetris:DoAction('A') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB2 PROMPT '&S'  ACTION ( oTetris:DoAction('S') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB3 PROMPT '&D'  ACTION ( oTetris:DoAction('D') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB4 PROMPT '&W'  ACTION ( oTetris:DoAction('W') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB5 PROMPT '&J'  ACTION ( oTetris:DoAction('J') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB6 PROMPT '&K'  ACTION ( oTetris:DoAction('K') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB7 PROMPT '&L'  ACTION ( oTetris:DoAction('L') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB8 PROMPT '&I'  ACTION ( oTetris:DoAction('I') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB9 PROMPT '& '  ACTION ( oTetris:DoAction(' ') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyBA PROMPT '&P'  ACTION ( oTetris:DoPause()     )  SIZE 1, 1 OF oDlg PIXEL

// Inicializa o objeto do core do jogo 
oTetris := APTetris():New()

// Define um timer, para fazer a peça em jogo
// descer uma posição a cada um segundo
// ( Nao pode ser menor, o menor tempo é 1 segundo )
// A ação '#' é diferente de "S" ou "K", pois nao atualiza 
// o score quando a peça está descento "sozinha"
oTimer := TTimer():New(1000, {|| oTetris:DoAction('#') }, oDlg )

// Seta codeblock para atualizar o score na interface
oTetris:bShowScore := {|cMsg| oScore:SetText(cMsg) } 

// Registra evento de mudança de estado do jogo 
// Jogo em progresso, timer ligado, caso contrario timer desligado 
oTetris:bChangeState := {|nStat| IIF( nStat == 0 , oTimer:Activate(), oTimer:DeActivate() ) }

// Reistra evento de pintura da interface do jogo 
oTetris:bPaintGame := {|aGameGrid| PaintGame( aGameGrid, aBmpGrid , aResources ) }

// Registra evento de pintura da proxima peça 
oTetris:bPaintNext := {|aNextPiece| PaintNext(aNextPiece, aBMPNext, aResources) }

// Na inicialização do Dialogo começa o jogo 
oDlg:bInit := {|| oTetris:Start() }

ACTIVATE DIALOG oDlg CENTER

Return



/* ----------------------------------------------------------
Função PaintGame()
Pinta o Grid do jogo da memória para a Interface

Release 20150222 : Optimização na camada de comunicação, apenas setar
o nome do resource / bitmap caso o resource seja diferente do atual.

Release 20150307 : colocar mais uma linha no topo do grid, para a 
proxima peça surgir uma linha mais para cima
---------------------------------------------------------- */

STATIC Function PaintGame( aGameGrid, aBmpGrid , aResources ) 
Local nL, nc , cLine, nPeca

For nL := 1 to 20
	cLine := aGameGrid[nL+1]
	For nC := 1 to 10
		nPeca := val(substr(cLine,nC+2,1))
		If aBmpGrid[nL][nC]:cResName != aResources[nPeca+1]
			// Somente manda atualizar o bitmap se houve
			// mudança na cor / resource desta posição
			aBmpGrid[nL][nC]:SetBmp(aResources[nPeca+1])
		endif
	Next
Next

Return

/* -----------------------------------------------------------------
Pinta na interface a próxima peça 
a ser usada no jogo 
----------------------------------------------------------------- */

STATIC Function PaintNext(aNext,aBMPNext,aResources) 
Local nL, nC, cLine , nPeca

For nL := 1 to 4
	cLine := aNext[nL]
	For nC := 1 to 5
		nPeca := val(substr(cLine,nC,1))
		If aBMPNext[nL][nC]:cResName != aResources[nPeca+1]
			aBMPNext[nL][nC]:SetBmp(aResources[nPeca+1])
		endif
	Next
Next

Return


// ============================================================================

CLASS APTETRIS

  DATA aGamePieces     // Peças que compoe o jogo 
  DATA nGameTimer      // Tempo de jogo 
  DATA nGameNext       // Proxima peça a ser usada
  DATA nGameStatus     // 0 = Running  1 = PAuse 2 == Game Over
  DATA aGameNext       // Array com a definição e posição da proxima peça
  DATA aGameCurr       // Array com a definição e posição da peça em jogo
  DATA nGameScore      // pontuação da partida
  DATA aGameGrid       // Array de strings com os blocos da interface representados em memoria
  DATA bShowScore      // CodeBlock para interface de score e mensagens
  DATA bChangeState    // CodeBlock para indicar mudança de estado 
	DATA bPaintGame      // CodeBlock para evento de pintura do Jogo
	DATA bPaintNext      // CodeBlock para evento de pintura da PRoxima peça
  
  METHOD New()
  METHOD Start() 
  METHOD DoAction(cAct)  
  METHOD DoPause() 

  METHOD _LoadPieces() 
  METHOD _MoveDown(lDrop) 
  METHOD _PutPiece(aPiece,aGrid)  
  METHOD _DelPiece(aPiece,aGrid) 
  METHOD _FreeLines() 
  METHOD _UpdateStat() 
  METHOD _GetEmptyGrid()

ENDCLASS

/* ----------------------------------------------------------
---------------------------------------------------------- */

METHOD NEW() CLASS APTETRIS

::aGamePieces := ::_LoadPieces()   // Array de peças do jogo 
::nGameTimer := 0             // Tempo de jogo 
::aGameNext := {}                 // Array com a definição e posição da proxima peça
::aGameCurr := {}             // Array com a definição e posição da peça em jogo
::nGameScore := 0                 // pontuação da partida
::aGameGrid := {}             // Array de strings com os blocos da interface representados em memoria
::nGameStatus := 0              // 0 = Running  1 = Pause 2 == Game Over

Return self

/* ----------------------------------------------------------
Inicializa o Grid na memoria
Em memoria, o Grid possui 14 colunas e 22 linhas
Na tela, são mostradas apenas 20 linhas e 10 colunas
As 2 colunas da esquerda e direita, e as duas linhas a mais
sao usadas apenas na memoria, para auxiliar no processo
de validação de movimentação das peças.
---------------------------------------------------------- */

METHOD Start() CLASS APTETRIS
Local aDraw, nPiece

// Inicializa o grid de imagens do jogo na memória
// Sorteia a peça em jogo
// Define a peça em queda e a sua posição inicial
// [ Peca, rotacao, linha, coluna ]
// e Desenha a peça em jogo no Grid
// e Atualiza a interface com o Grid

// Inicializa o grid do jogo  
::aGameGrid := aClone(::_GetEmptyGrid())

// Sorteia peça em queda do inicio do jogo 
nPiece := randomize(1,len(::aGamePieces)+1)

// E coloca ela no topo da tela 
::aGameCurr := {nPiece,1,1,6}
::_PutPiece(::aGameCurr,::aGameGrid)

// Dispara a pintura do Grid do Jogo
Eval( ::bPaintGame , ::aGameGrid) 

// Sorteia a proxima peça e desenha 
// ela no grid reservado para ela 
::aGameNext := array(4,"00000")
::nGameNext := randomize(1,len(::aGamePieces)+1)

aDraw := {::nGameNext,1,1,1}
::_PutPiece(aDraw,::aGameNext)

// Dispara a pintura da próxima peça
Eval( ::bPaintNext , ::aGameNext )

// Chama o codeblock de mudança de estado - Jogo em execução 
Eval(::bChangeState , ::nGameStatus ) 

// Marca timer do inicio de jogo 
::nGameTimer := seconds()

Return


/* ----------------------------------------------------------
Metodo SetGridPiece
Aplica a peça no Grid.
Retorna .T. se foi possivel aplicar a peça na posicao atual
Caso a peça não possa ser aplicada devido a haver
sobreposição, a função retorna .F. e o grid não é atualizado
Serve tanto para o Grid do Jogo quando para o Grid da próxima peça
---------------------------------------------------------- */

METHOD _PutPiece(aPiece,aGrid)  CLASS APTETRIS
Local nPiece := aPiece[PIECE_NUMBER] // Numero da peça
Local nPos   := aPiece[PIECE_ROTATION] // Rotação 
Local nRow   := aPiece[PIECE_ROW] // Linha no Grid
Local nCol   := aPiece[PIECE_COL] // Coluna no Grid
Local nL , nC
Local aTecos := {}
Local cTecoGrid, cPeca , cPieceStr

cPieceStr := str(nPiece,1)

For nL := nRow to nRow+3
	cTecoGrid := substr(aGrid[nL],nCol,4)
	cPeca := ::aGamePieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1) == '1'
			If substr(cTecoGrid,nC,1) != '0'
				// Vai haver sobreposição,
				// a peça nao cabe ... 
				Return .F.
			Endif
			cTecoGrid := Stuff(cTecoGrid,nC,1,cPieceStr)
		Endif
	Next
  // Array temporario com a peça já colocada
	aadd(aTecos,cTecoGrid)
Next

// Aplica o array temporario no array do grid
For nL := nRow to nRow+3
	aGrid[nL] := stuff(aGrid[nL],nCol,4,aTecos[nL-nRow+1])
Next

// A peça "coube", retorna .T. 
Return .T.

/* -----------------------------------------------------------------
Carga do array de peças do jogo 
Array multi-dimensional, contendo para cada 
linha a string que identifica a peça, e um ou mais
arrays de 4 strings, onde cada 4 elementos 
representam uma matriz binaria de caracteres 4x4 
para desenhar cada peça 

Exemplo - Peça "O"      

aLPieces[1][1] C "O"
aLPieces[1][2][1] "0000" 
aLPieces[1][2][2] "0110" 
aLPieces[1][2][3] "0110" 
aLPieces[1][2][4] "0000" 

----------------------------------------------------------------- */

METHOD _LoadPieces() CLASS APTETRIS
Local aLPieces := {}

// Peça "O" , uma posição
aadd(aLPieces,{'O',	{	'0000','0110','0110','0000'}})

// Peça "I" , em pé e deitada
aadd(aLPieces,{'I',	{	'0000','1111','0000','0000'},;
                    {	'0010','0010','0010','0010'}})

// Peça "S", em pé e deitada
aadd(aLPieces,{'S',	{	'0000','0011','0110','0000'},;
                    {	'0010','0011','0001','0000'}})

// Peça "Z", em pé e deitada
aadd(aLPieces,{'Z',	{	'0000','0110','0011','0000'},;
                    {	'0001','0011','0010','0000'}})

// Peça "L" , nas 4 posições possiveis
aadd(aLPieces,{'L',	{	'0000','0111','0100','0000'},;
                    {	'0010','0010','0011','0000'},;
                    {	'0001','0111','0000','0000'},;
                    {	'0110','0010','0010','0000'}})

// Peça "J" , nas 4 posições possiveis
aadd(aLPieces,{'J',	{	'0000','0111','0001','0000'},;
                    {	'0011','0010','0010','0000'},;
                    {	'0100','0111','0000','0000'},;
                    {	'0010','0010','0110','0000'}})

// Peça "T" , nas 4 posições possiveis
aadd(aLPieces,{'T',	{	'0000','0111','0010','0000'},;
                    {	'0010','0011','0010','0000'},;
                    {	'0010','0111','0000','0000'},;
                    {	'0010','0110','0010','0000'}})


Return aLPieces


/* ----------------------------------------------------------
Função _MoveDown()

Movimenta a peça em jogo uma posição para baixo.
Caso a peça tenha batido em algum obstáculo no movimento
para baixo, a mesma é fica e incorporada ao grid, e uma nova
peça é colocada em jogo. Caso não seja possivel colocar uma
nova peça, a pilha de peças bateu na tampa -- Game Over

---------------------------------------------------------- */

METHOD _MoveDown(lDrop) CLASS APTETRIS
Local aOldPiece
Local nMoved := 0

If ::nGameStatus != 0
	Return
Endif

// Clona a peça em queda na posição atual
aOldPiece := aClone(::aGameCurr)

If lDrop
	
	// Dropa a peça até bater embaixo
	// O Drop incrementa o score em 1 ponto
	// para cada linha percorrida. Quando maior a quantidade
	// de linhas vazias, maior o score acumulado com o Drop
	
	// Remove a peça do Grid atual
	::_DelPiece(::aGameCurr,::aGameGrid)
	
	// Desce uma linha pra baixo
	::aGameCurr[PIECE_ROW]++
	
	While ::_PutPiece(::aGameCurr,::aGameGrid)
		
		// Encaixou, remove e tenta de novo
		::_DelPiece(::aGameCurr,::aGameGrid)
		
		// Incrementa o numero de movimentos dentro do Drop
		nMoved++
		
		// Guarda a peça na posição atual
		aOldPiece := aClone(::aGameCurr)
		
		// Desce a peça mais uma linha pra baixo
		::aGameCurr[PIECE_ROW]++
		
		// Incrementa o Score
		::nGameScore++
		
	Enddo
	
	// Nao deu mais pra pintar, "bateu"
	
	If nMoved > 0

		// Caso tenha havido movimento no Drop
		// Volta a peça anterior, pinta o grid e retorna
		// isto permite ainda movimentos laterais
		// caso tenha espaço. 
		
		::aGameCurr := aClone(aOldPiece)
		::_PutPiece(::aGameCurr,::aGameGrid)
		
		// Dispara a pintura do Grid do Jogo 
		Eval( ::bPaintGame , ::aGameGrid) 

		// E retorna daqui mesmo 
		Return
		
	Endif
	
	// Caso tenha sido solicitado um drop, mas nao tenha 
	// espaco para a peça descer nenhuma linha, encaixa ela 
	// Volta a peça no seu estado original 
	// e prossegue como se fosse solicitado um movedown 
	// de apenas uma linha -- encaixando a peça
	::aGameCurr := aClone(aOldPiece)
	::_PutPiece(::aGameCurr,::aGameGrid)

Endif

// Move a peça apenas uma linha pra baixo

// Primeiro remove a peça do Grid atual
::_DelPiece(::aGameCurr,::aGameGrid)

// Agora move a peça apenas uma linha pra baixo
::aGameCurr[PIECE_ROW]++

// Recoloca a peça no Grid
If ::_PutPiece(::aGameCurr,::aGameGrid)
	
	// Nao bateu em nada, continua 
	// Dispara a pintura do Grid do Jogo 
	Eval( ::bPaintGame , ::aGameGrid) 
	
	// e retorna imediatamente
	Return
	
Endif

// Opa ... Esbarrou em alguma peça ou fundo do grid
// Volta a peça pro lugar anterior e recoloca a peça no Grid
::aGameCurr :=  aClone(aOldPiece)
::_PutPiece(::aGameCurr,::aGameGrid)

// Encaixou uma pela .. Incrementa o score em 4 pontos
// Nao importa a peça ou como ela foi encaixada
::nGameScore += 4

// Verifica apos a pea encaixada, se uma ou mais linhas 
// foram preenchidas e podem ser eliminadas
::_FreeLines()

// Pega a proxima peça e coloca em jogo 
nPiece := ::nGameNext
::aGameCurr := {nPiece,1,1,6} // Peca, direcao, linha, coluna

If !::_PutPiece(::aGameCurr,::aGameGrid)
	
	// Acabou, a peça nova nao entra (cabe) no Grid
	// "** GAME OVER** " 
	
	::nGameStatus := 2 // GAme Over
	
	// volta os ultimos 4 pontos ...
	::nGameScore -= 4
	
	// Cacula o tempo de operação do jogo
	::nGameTimer := round(seconds()-::nGameTimer,0)
	If ::nGameTimer < 0
		// Ficou negativo, passou da meia noite
		::nGameTimer += 86400
	Endif
	
	// Chama o codeblock de mudança de estado - Game Over
	Eval(::bChangeState , ::nGameStatus ) 
	
Endif

// Se a peca tem onde entrar, beleza
// Dispara a pintura do Grid do Jogo 
Eval( ::bPaintGame , ::aGameGrid) 

// Inicializa proxima peça em branco
::aGameNext := array(4,"00000")

If ::nGameStatus != 2

	// Se o jogo nao terminou, sorteia a proxima peça
	::nGameNext := randomize(1,len(::aGamePieces)+1)
	::_PutPiece( {::nGameNext,1,1,1} , ::aGameNext)

Endif

// Dispara a pintura da próxima peça
Eval( ::bPaintNext , ::aGameNext )

Return


/* ----------------------------------------------------------
Recebe uma ação da interface, através de uma das letras
de movimentação de peças, e realiza a movimentação caso
haja espaço para tal.
---------------------------------------------------------- */
METHOD DoAction(cAct)  CLASS APTETRIS
Local aOldPiece

If ::nGameStatus != 0 
   Return
Endif

// Clona a peça em queda
aOldPiece := aClone(::aGameCurr)

if cAct $ 'AJ'

	// Movimento para a Esquerda (uma coluna a menos)
	// Remove a peça do grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	::aGameCurr[PIECE_COL]--
	If !::_PutPiece(::aGameCurr,::aGameGrid)
		// Se nao foi feliz, pinta a peça de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_PutPiece(::aGameCurr,::aGameGrid)
	Endif

	// Dispara a repintura do Grid
	Eval( ::bPaintGame , ::aGameGrid) 
	
Elseif cAct $ 'DL'

	// Movimento para a Direita ( uma coluna a mais )
	// Remove a peça do grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	::aGameCurr[PIECE_COL]++
	If !::_PutPiece(::aGameCurr,::aGameGrid)
		// Se nao foi feliz, pinta a peça de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_PutPiece(::aGameCurr,::aGameGrid)
	Endif

	// Dispara a repintura do Grid
	Eval( ::bPaintGame , ::aGameGrid) 
	
Elseif cAct $ 'WI'
	
	// Movimento para cima  ( Rotaciona sentido horario )
	
	// Remove a peça do Grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	
	// Rotaciona
	::aGameCurr[PIECE_ROTATION]--
	If ::aGameCurr[PIECE_ROTATION] < 1
		::aGameCurr[PIECE_ROTATION] := len(::aGamePieces[::aGameCurr[1]])-1
	Endif
	
	If !::_PutPiece(::aGameCurr,::aGameGrid)
		// Se nao consegue colocar a peça no Grid
		// Nao é possivel rotacionar. Pinta a peça de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_PutPiece(::aGameCurr,::aGameGrid)
	Endif
	
	// Dispara a repintura do Grid
	Eval( ::bPaintGame , ::aGameGrid) 
	
ElseIF cAct $ 'SK#'
	
	// Desce a peça para baixo uma linha intencionalmente 
	::_MoveDown(.F.)

	If 	cAct $ 'SK'
		// se o movimento foi intencional, ganha + 1 ponto 
		::nGameScore++
	Endif
	
ElseIF cAct == ' '
	
	// Dropa a peça - empurra para baixo até a última linha
	// antes de baer a peça no fundo do Grid
	::_MoveDown(.T.)
	
Endif

// Antes de retornar, repinta o score / status na interface
::_UpdateStat()

Return .T.


/* ----------------------------------------------------------
Coloca e retira o jog em pausa
---------------------------------------------------------- */
METHOD DoPause() CLASS APTETRIS
Local lChanged := .F.

If ::nGameStatus == 0
	// Jogo em execução = Pausa
	// Desativa o timer 
	::nGameStatus := 1
	lChanged := .T.
ElseIf ::nGameStatus == 1
	// Jogo em pausa = Sai da pausa
	// Ativa o timer 
	::nGameStatus := 0
	lChanged := .T.
Endif

IF	lChanged 

	// Chama o codeblock de mudança de estado - Entrou ou saiu de pausa
	Eval(::bChangeState , ::nGameStatus ) 

	If ::nGameStatus == 1

		// Se houve mudança, na pausa deve apagar o estado do jogo
		// para nao dar tempo do jogador "ficar pensando" onde encaixar 
		// a peça em queda ... 
	    
		// Dispara a pintura do Grid do Jogo vazio 
		Eval( ::bPaintGame , ::_GetEmptyGrid() ) 

	Else

		// Game voltou ao movimento, repinta as peças 	
		Eval( ::bPaintGame , ::aGameGrid) 

	Endif

Endif

// Antes de retornar, atualiza o score na interface
::_UpdateStat()

Return

/* -----------------------------------------------------------------------
Remove a peça informada do grid informado 
----------------------------------------------------------------------- */
METHOD _DelPiece(aPiece,aGrid) CLASS APTETRIS

Local nPiece := aPiece[PIECE_NUMBER]
Local nPos   := aPiece[PIECE_ROTATION]
Local nRow   := aPiece[PIECE_ROW]
Local nCol   := aPiece[PIECE_COL]
Local nL, nC
Local cTecoGrid, cPeca

// Como a matriz da peça é 4x4, trabalha em linhas e colunas
// Separa do grid atual apenas a área que a peça está ocupando
// e desliga os pontos preenchidos da peça no Grid.
For nL := nRow to nRow+3
	cTecoGrid := substr(aGrid[nL],nCol,4)
	cPeca := ::aGamePieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1)=='1'
			cTecoGrid := Stuff(cTecoGrid,nC,1,'0')
		Endif
	Next
	aGrid[nL] := stuff(aGrid[nL],nCol,4,cTecoGrid)
Next

Return

/* -----------------------------------------------------------------------
Verifica e elimina as linhas "completas" 
após uma peça ser encaixada no Grid
----------------------------------------------------------------------- */
METHOD _FreeLines() CLASS APTETRIS
Local nErased := 0
Local cTecoGrid 

For nL := 21 to 2 step -1
	
	// Sempre varre de baixo para cima
	cTecoGrid := substr(::aGameGrid[nL],3)
	
	If !('0'$cTecoGrid)
		// Se a linha nao tem nenhum espaço em branco 
		// Elimina esta linha e acrescenta uma nova linha
		// em branco no topo do Grid
		adel(::aGameGrid,nL)
		ains(::aGameGrid,1)
		::aGameGrid[1] := GRID_EMPTY_LINE 
		nL++
		nErased++
	Endif
	
Next

// Pontuação por linhas eliminadas 
// Quanto mais linhas ao mesmo tempo, mais pontos
If nErased == 4
	::nGameScore += 100
ElseIf nErased == 3
	::nGameScore += 50
ElseIf nErased == 2
	::nGameScore += 25
ElseIf nErased == 1
	::nGameScore += 10
Endif

Return


/* ------------------------------------------------------
Atualiza score e status do jogon a interface
------------------------------------------------------*/
METHOD _UpdateStat() CLASS APTETRIS
Local cMessage 

If ::nGameStatus == 0

	// JOgo em andamento, apenas atualiza score e timer
	cMessage := str(::nGameScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+str(seconds()-::nGameTimer,7,0)+' s.'

ElseIf ::nGameStatus == 1

	// Pausa, acresenta a mensagem de "GAME OVER"
	cMessage := str(::nGameScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+str(seconds()-::nGameTimer,7,0)+' s.'+CRLF+CRLF+;
		"*********"+CRLF+;
		"* PAUSE *"+CRLF+;
		"*********"

ElseIf ::nGameStatus == 2

	// Terminou, acresenta a mensagem de "GAME OVER"
	cMessage := str(::nGameScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+str(::nGameTimer,7,0)+' s.'+CRLF+CRLF+;
		"********"+CRLF+;
		"* GAME *"+CRLF+;
		"********"+CRLF+;
		"* OVER *"+CRLF+;
		"********"

Endif

// Dispara o codeblock que atualiza o score                  
Eval( ::bShowScore , cMessage ) 

Return

/* ------------------------------------------------------
Retorna um grid de jogo vazio / inicializado 
------------------------------------------------------ */
METHOD _GetEmptyGrid() CLASS APTETRIS

Local aEmptyGrid := array(21,GRID_EMPTY_LINE)
aadd(aEmptyGrid,GRID_BOTTOM_LINE)
aadd(aEmptyGrid,GRID_BOTTOM_LINE)

Return aEmptyGrid

