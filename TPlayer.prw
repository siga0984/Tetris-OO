#include "protheus.ch"

User Function TPlayer(oTetris)
Local aGridNow 
Local oTempGame                           
Local nAltura

// Auto-Player : Chamado pela interface, 
// apos desligar o timer de queda de peça

// Cria um objeto do tabuleiro do tetris 
// para fazer a simulação de movimentos

oTempGame := APTetris():New()

// Zera todos os codeblocks de callback 
oTempGame:bShowScore := {|cMsg| .T. } 
oTempGame:bShowElap := {|cMsg| .T. } 
oTempGame:bChangeState := {|nStat| .T. }
oTempGame:bPaintGrid := {|aGameGrid| .T. }
oTempGame:bPaintNext := {|aNextPiece| .T. }

// Inicializa o jogo 
oTempGame:Start()

// Agora atualiza as propriedades com o cenario do jogo oficial
oTempGame:aGameGrid  := aclone(oTetris:aGameGrid)
oTempGame:aGameCurr  := aclone(oTetris:aGameCurr)
oTempGame:aNextPiece := aClone(oTetris:aNextPiece)
oTempGame:nNextPiece := oTetris:nNextPiece

// Mostra as peças 
conout("====== Grid atual ")
ShowGrid(oTempGame:aGameGrid)

// Peça atual
conout("====== Peça em jogo")
ShowPiece(oTempGame:aGameCurr)

// Proxima peça na fila 
conout("====== Proxima peça = "+cValToChar(oTempGame:nNextPiece))

// Primeira coisa, avalia a altura atual do Grid
// Pra isso, remove a peça corrente do Grid

oTempGame:_DelPiece(oTempGame:aGameCurr,oTempGame:aGameGrid)

conout("====== Grid atual ")
ShowGrid(oTempGame:aGameGrid)

aInfo := GetGInfo(oTempGame:aGameGrid)
Varinfo('aInfo',aInfo)


Return





Static Function ShowGrid(aGridNow)
Local nI
For nI := 1 to len(aGridNow)
	conout(aGridNow[nI])
Next
Return              

Static Function ShowPiece(aCurrent)
varinfo("aCurrent",aCurrent)
Return              


/*
*/
STATIC Function GetGInfo(aGrid)
Local aGInfo := {}
Local nI := 1                         
Local nOcupados := 0
Local lGetHigh := .t.

// Calcula o tamanho da pilha de peças no grid
// e a quantidade de espaços ocupados 
// Varre de cima pra baixo 
While nI < 22
	cTeco := substr(aGrid[nI],3,10)
	cTeco := strtran(cTeco,'0','')
	nOcupados += len( cTeco )
	If lGetHigh .and. !empty(cTeco)
		// A primeira linha com alguma coisa define 
		// a altura da pilha
		aadd(aGInfo,{"Altura",22-nI})
		lGetHigh := .f.
	Endif
	nI++
Enddo           

If lGetHigh
	// Nao achou nada ocupado ? 
	// Jogo com tabuleiro vazio, altura = 0 
	aadd(aGInfo,{"Altura",0})
Endif

aadd(aGInfo,{"Ocupados",nOcupados})

return aGInfo




