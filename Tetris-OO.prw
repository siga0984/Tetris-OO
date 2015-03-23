#include 'protheus.ch'
#include 'tetris-core.ch'

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

Local oDlg, oBGGame , oBGNext
Local oFont , oLabel 
Local oScore , oTimer
Local nC , nL
Local oTetris 
Local aBMPGrid   
Local aBMPNext   
Local aResources 

// Arrays de componentes e recursos de Interface
aBMPGrid   := array(20,10) // Array de bitmaps de interface do jogo 
aBMPNext   := array(4,5)   // Array de bitmaps da proxima peça
aResources := { "BLACK","YELOW2","LIGHTBLUE2","ORANGE2","RED2","GREEN2","BLUE2","PURPLE2" }

// Fonte default usada na caixa de diálogo 
// e respectivos componentes filhos
oFont := TFont():New('Courier new',,-16,.T.,.T.)

// Interface principal do jogo
DEFINE DIALOG oDlg TITLE "Object Oriented Tetris AdvPL" FROM 10,10 TO 450,365 ;
   FONT oFont COLOR CLR_WHITE,CLR_BLACK PIXEL

// Cria um fundo cinza, "esticando" um bitmap
@ 8, 8 BITMAP oBGGame RESOURCE "GRAY" ;
	SIZE 104,204  Of oDlg ADJUST NOBORDER PIXEL

// Desenha na tela um grid de 20x10 com Bitmaps
// para desenhar o Game

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

// Label fixo, Pontuação do Jogo 
@ 80,120 SAY oLabel1 PROMPT "[Score]" SIZE 60,20 OF oDlg PIXEL
                                    
// Label para Mostrar score
@ 90,120 SAY oScore PROMPT "        " SIZE 60,120 OF oDlg PIXEL

// Label fixo, Tempo de Jogo
@ 110,120 SAY oLabel2 PROMPT "[Time]" SIZE 60,20 OF oDlg PIXEL
                                    
// Label para Mostrar Tempo de Jogo
@ 120,120 SAY oElapTime PROMPT "        " SIZE 60,120 OF oDlg PIXEL

// Label para Mostrar Status do Jogo 
@ 140,120 SAY oGameMsg PROMPT "        " SIZE 60,120 OF oDlg PIXEL

// Botões com atalho de teclado
// para as teclas usadas no jogo
// colocados fora da area visivel da caixa de dialogo

@ 480,10 BUTTON oDummyB0 PROMPT '&A'  ACTION ( oTetris:DoAction('A') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB1 PROMPT '&S'  ACTION ( oTetris:DoAction('S') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB2 PROMPT '&D'  ACTION ( oTetris:DoAction('D') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB3 PROMPT '&W'  ACTION ( oTetris:DoAction('W') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB4 PROMPT '&J'  ACTION ( oTetris:DoAction('J') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB5 PROMPT '&K'  ACTION ( oTetris:DoAction('K') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB6 PROMPT '&L'  ACTION ( oTetris:DoAction('L') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB7 PROMPT '&I'  ACTION ( oTetris:DoAction('I') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB8 PROMPT '& '  ACTION ( oTetris:DoAction(' ') )  SIZE 1, 1 OF oDlg PIXEL
@ 480,20 BUTTON oDummyB9 PROMPT '&P'  ACTION ( oTetris:DoPause()     )  SIZE 1, 1 OF oDlg PIXEL

// Inicializa o objeto do core do jogo 
oTetris := APTetris():New()

// Define um timer, para fazer a peça em jogo
// descer uma posição a cada um segundo
// ( Nao pode ser menor, o menor tempo é 1 segundo )
// A ação '#' é diferente de "S" ou "K", pois nao atualiza 
// o score quando a peça está descento "sozinha" por tempo 
oTimer := TTimer():New(1000, {|| oTetris:DoAction('#') }, oDlg )

// Registra evento para atualização de score
// Apos uma ação ser processada pelo objeto Tetris, caso o score 
// tenha mudado, este codeclobk será disparado com o novo score 
oTetris:bShowScore := {|cMsg| oScore:SetText(cMsg) } 

// Registra evento para atualização do tempo decorrido de jogo 
// Apos uma ação ser processada pelo objeto Tetris, caso o tempo 
// de jogo tenha mudado, este codeclobk será disparado com o tempo 
// decorrido de jogo atualizado. 
oTetris:bShowElap := {|cMsg| oElapTime:SetText(cMsg) } 

// Registra evento de mudança de estado do jogo 
// Running , Pause, Game Over. Caso seja disparado um
// pause ou continue, ou mesmo a última peça nao caber 
// na TEla ( Game Over ), este bloco é disparado, informando o novo 
// estado de jogo 
oTetris:bChangeState := {|nStat| GameState( nStat , oTimer , oGameMsg ) }

// Registra evento de pintura do grid 
// Apos processamento de ação, caso o grid precise ser repintado, 
// este bloco de código será disparado
oTetris:bPaintGrid := {|aGameGrid| PaintGame( aGameGrid, aBmpGrid , aResources ) }

// Registra evento de pintura da proxima peça 
// Apos processamento de ação, caso seja sorteada uma nova próxima peça, 
// este bloco de código será disparado para pintar a proxima peça na interface
oTetris:bPaintNext := {|aNextPiece| PaintNext(aNextPiece, aBMPNext, aResources) }

// Na inicialização do Dialogo, começa o jogo 
oDlg:bInit := {|| oTetris:Start() }

ACTIVATE DIALOG oDlg CENTER

Return

/* -------------------------------------------------------
Notificação de mudança de estado de jogo
GAME_RUNNING, GAME_PAUSED ou GAME_OVER
------------------------------------------------------- */

STATIC Function GameState( nStat , oTimer , oGameMsg ) 
Local cMsg

If nStat == GAME_RUNNING

	// Jogo em execuçao, ativa timer de interface
	oTimer:Activate()

	cMsg := "*********"+CRLF+;
          "* PLAY  *"+CRLF+;
          "*********"

ElseIf nStat == GAME_PAUSED

	// Jogo em pausa
  // desativa timer de interface	
	oTimer:DeActivate()
	
	// e acrescenta mensagem de pausa
	cMsg := "*********"+CRLF+;
          "* PAUSE *"+CRLF+;
          "*********"

ElseIf nStat == GAME_OVER

	// Game Over
  // desativa timer de interface	
	oTimer:DeActivate()

	// e acresenta a mensagem de "GAME OVER"
	cMsg := "********"+CRLF+;
					"* GAME *"+CRLF+;	
					"********"+CRLF+;
					"* OVER *"+CRLF+;
					"********"

Endif

// Atualiza a mensagem na interface
oGameMsg:SetText(cMsg)

Return


/* ----------------------------------------------------------
Função PaintGame()
Pinta o Grid do jogo da memória para a Interface
Chamada pelo objeto Tetris via code-block
Optimizada para apenas trocar os resources diferentes
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
Pinta na interface a próxima peça a ser usada no jogo 
Chamada pelo objeto Tetris via code-block
Optimizada para apenas trocar os resources diferentes
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

