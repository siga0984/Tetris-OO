#include 'protheus.ch'    	
#include 'tetris-core.ch'

// ============================================================================
// Classe "CORE" do Jogo Tetris
// ============================================================================

CLASS APTETRIS
  
	// Propriedades publicas
	
  DATA aGamePieces     // Peças que compoe o jogo 
  DATA nGameStart      // Momento de inicio de jogo 
  DATA nGameTimer      // Tempo de jogo em segundos
  DATA nGamePause      // Controle de tempo de pausa
  DATA nNextPiece      // Proxima peça a ser usada
  DATA nGameStatus     // 0 = Running  1 = PAuse 2 == Game Over
  DATA aNextPiece      // Array com a definição e posição da proxima peça
  DATA aGameCurr       // Array com a definição e posição da peça em jogo
  DATA nGameScore      // pontuação da partida
  DATA aGameGrid       // Array de strings com os blocos da interface representados em memoria

	// Eventos disparados pelo core do Jogo 
	
  DATA bShowScore      // CodeBlock para interface de score 
	DATA bShowElap       // CodeBlock para interface de tempo de jogo 
  DATA bChangeState    // CodeBlock para indicar mudança de estado ( pausa / continua /game over )
	DATA bPaintGrid      // CodeBlock para evento de pintura do Grid do Jogo
	DATA bPaintNext      // CodeBlock para evento de pintura da Proxima peça em jogo
  
  // Metodos Publicos
  
  METHOD New()          // Construtor
  METHOD Start()        // Inicio de Jogo
  METHOD DoAction(cAct) // Disparo de ações da Interface
  METHOD DoPause()      // Dispara Pause On/Off

  // Metodos privados ( por convenção, prefixados com "_" ) 

	METHOD _LoadPieces()   // Carga do array de peças do Jogo 
  METHOD _MoveDown()     // Movimenta a peça corrente uma posição para baixo
  METHOD _DropDown()     // Movimenta a peça corrente direto até onde for possível
  METHOD _SetPiece(aPiece,aGrid)  // Seta uma peça no Grid em memoria do jogo 
  METHOD _DelPiece(aPiece,aGrid)  // Remove uma peça no Grid em memoria do jogo 
  METHOD _FreeLines()    // Verifica e eliminha linhas totalmente preenchidas 
  METHOD _GetEmptyGrid() // Retorna um Grid em memoria inicializado vazio 

ENDCLASS

/* ----------------------------------------------------------
Construtor da classe
---------------------------------------------------------- */

METHOD NEW() CLASS APTETRIS

::aGamePieces := ::_LoadPieces()
::nGameTimer  := 0
::nGameStart  := 0
::aNextPiece  := {}
::aGameCurr   := {}
::nGameScore  := 0
::aGameGrid   := {}
::nGameStatus := GAME_RUNNING

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
Local aDraw, nPiece, cScore

// Inicializa o grid de imagens do jogo na memória
// Sorteia a peça em jogo
// Define a peça em queda e a sua posição inicial
// [ Peca, rotacao, linha, coluna ]
// e Desenha a peça em jogo no Grid
// e Atualiza a interface com o Grid

// Inicializa o grid do jogo "vazio"
::aGameGrid := aClone(::_GetEmptyGrid())

// Sorteia peça em queda do inicio do jogo
nPiece := randomize(1,len(::aGamePieces)+1)

// E coloca ela no topo da tela
::aGameCurr := {nPiece,1,1,6}
::_SetPiece(::aGameCurr,::aGameGrid)

// Dispara a pintura do Grid do Jogo
Eval( ::bPaintGrid , ::aGameGrid)

// Sorteia a proxima peça e desenha
// ela no grid reservado para ela
::aNextPiece := array(4,"00000")
::nNextPiece := randomize(1,len(::aGamePieces)+1)

aDraw := {::nNextPiece,1,1,1}
::_SetPiece(aDraw,::aNextPiece)

// Dispara a pintura da próxima peça
Eval( ::bPaintNext , ::aNextPiece )

// Marca timer do inicio de jogo
::nGameStart := seconds()

// Chama o codeblock de mudança de estado - Jogo em execução
Eval(::bChangeState , ::nGameStatus )

// E chama a pintura do score inicial 
cScore := str(::nGameScore,7)
Eval( ::bShowScore , cScore )

Return

/* ----------------------------------------------------------
Recebe uma ação de movimento de peça, e realiza o movimento
da peça corrente caso exista espaço para tal.
---------------------------------------------------------- */
METHOD DoAction(cAct)  CLASS APTETRIS
Local aOldPiece
Local cScore, cElapTime 
Local cOldScore, cOldElapTime 

If ::nGameStatus != GAME_RUNNING
	// Jogo não está rodando, nao aceita ação nenhuma
	Return .F. 
Endif

// Pega pontuação e tempo decorridos agora 
cOldScore := str(::nGameScore,7)
cOldElapTime := STOHMS(::nGameTimer)

// Clona a peça em queda
aOldPiece := aClone(::aGameCurr)

if cAct $ 'AJ'
	
	// Movimento para a Esquerda (uma coluna a menos)
	// Remove a peça do grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	::aGameCurr[PIECE_COL]--
	If !::_SetPiece(::aGameCurr,::aGameGrid)
		// Se nao foi feliz, pinta a peça de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_SetPiece(::aGameCurr,::aGameGrid)
	Endif
	
Elseif cAct $ 'DL'
	
	// Movimento para a Direita ( uma coluna a mais )
	// Remove a peça do grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	::aGameCurr[PIECE_COL]++
	If !::_SetPiece(::aGameCurr,::aGameGrid)
		// Se nao foi feliz, pinta a peça de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_SetPiece(::aGameCurr,::aGameGrid)
	Endif
	
Elseif cAct $ 'WI'
	
	// Movimento para cima  ( Rotaciona sentido horario )
	
	// Remove a peça do Grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	
	// Rotaciona a peça 
	::aGameCurr[PIECE_ROTATION]--
	If ::aGameCurr[PIECE_ROTATION] < 1
		::aGameCurr[PIECE_ROTATION] := len(::aGamePieces[::aGameCurr[PIECE_NUMBER]])-1
	Endif
	
	If !::_SetPiece(::aGameCurr,::aGameGrid)
		// Se nao consegue colocar a peça no Grid
		// Nao é possivel rotacionar. Pinta a peça de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_SetPiece(::aGameCurr,::aGameGrid)
	Endif
	
ElseIF cAct $ 'SK#'
	
	// Desce a peça para baixo uma linha intencionalmente
	::_MoveDown()
	
	If 	cAct $ 'SK'
		// se o movimento foi intencional, ganha + 1 ponto
		::nGameScore++
	Endif
	
ElseIF cAct == ' '
	
	// Dropa a peça - empurra para baixo até a última linha
	// antes de bater a peça no fundo do Grid. Isto vai permitir
	// movimentos laterais e roração, caso exista espaço 

	If !::_DropDown()
		// Se nao tiver espaço para o DropDown, faz apenas o MoveDown 
		// e "assenta" a peça corrente
		::_MoveDown()
	Endif
	
Else

	UserException("APTETRIS:DOACTION() ERROR: Unknow Action ["+cAct+"]")
	
Endif

// Dispara a repintura do Grid
Eval( ::bPaintGrid , ::aGameGrid)

// Calcula tempo decorrido
::nGameTimer := seconds() - ::nGameStart
	
If ::nGameTimer < 0
	// Ficou negativo, passou da meia noite
	::nGameTimer += 86400
Endif

// Pega Score atualizado e novo tempo decorrido
cScore := str(::nGameScore,7)
cElapTime := STOHMS(::nGameTimer)

If ( cOldScore <> cScore ) 
	// Dispara o codeblock que atualiza o score
	Eval( ::bShowScore , cScore )
Endif

If ( cOldElapTime <> cElapTime ) 
	// Dispara atualizaçao de tempo decorrido
	Eval( ::bShowElap , cElapTime )
Endif

Return .T.


/* ----------------------------------------------------------
Coloca e retira o jog em pausa
Este metodo foi criado isolado, pois é o unico 
que poderia ser chamado dentro de uma pausa
---------------------------------------------------------- */
METHOD DoPause() CLASS APTETRIS
Local lChanged := .F.
Local nPaused
Local cElapTime 
Local cOldElapTime 

cOldElapTime := STOHMS(::nGameTimer)

If ::nGameStatus == GAME_RUNNING
	// Jogo em execução = Pausa : Desativa o timer
	lChanged      := .T.
	::nGameStatus := GAME_PAUSED
	::nGamePause  := seconds()
ElseIf ::nGameStatus == GAME_PAUSED
	// Jogo em pausa = Sai da pausa : Ativa o timer
	lChanged      := .T.
	::nGameStatus := GAME_RUNNING
	// Calcula quanto tempo o jogo ficou em pausa
	// e acrescenta esse tempo do start do jogo
	nPaused := seconds()-::nGamePause
	If nPaused < 0
		nPaused += 86400
	Endif
	::nGameStart += nPaused
Endif

If lChanged
	
	// Chama o codeblock de mudança de estado - Entrou ou saiu de pausa
	Eval(::bChangeState , ::nGameStatus )
	
	If ::nGameStatus == GAME_PAUSED
		// Em pausa, Dispara a pintura do Grid do Jogo vazio
		Eval( ::bPaintGrid , ::_GetEmptyGrid() )
	Else
		// Game voltou da pausa, pinta novamente o Grid
		Eval( ::bPaintGrid , ::aGameGrid)
	Endif
	
	// Calcula tempo de jogo sempre ao entrar ou sair de pausa
	::nGameTimer := seconds() - ::nGameStart
	
	If ::nGameTimer < 0
		// Ficou negativo, passou da meia noite
		::nGameTimer += 86400
	Endif	

	// Pega novo tempo decorrido
	cElapTime := STOHMS(::nGameTimer)

	If ( cOldElapTime <> cElapTime ) 
		// Dispara atualizaçao de tempo decorrido
		Eval( ::bShowElap , cElapTime )
	Endif

Endif


Return

/* ----------------------------------------------------------
Metodo SetGridPiece
Aplica a peça informada no array do Grid.
Retorna .T. se foi possivel aplicar a peça na posicao atual
Caso a peça não possa ser aplicada devido a haver
sobreposição, a função retorna .F. e o grid não é atualizado
Serve tanto para o Grid do Jogo quando para o Grid da próxima peça
---------------------------------------------------------- */

METHOD _SetPiece(aPiece,aGrid)  CLASS APTETRIS
Local nPiece   := aPiece[PIECE_NUMBER] // Numero da peça
Local nRotate  := aPiece[PIECE_ROTATION] // Rotação
Local nRow     := aPiece[PIECE_ROW] // Linha no Grid
Local nCol     := aPiece[PIECE_COL] // Coluna no Grid
Local nL , nC
Local aTecos := {}
Local cTecoGrid, cPeca , cPieceId

conout("_SetPiece on COL "+cValToChar(nCol))

cPieceId := str(nPiece,1)

For nL := nRow to nRow+3
	cPeca := ::aGamePieces[nPiece][1+nRotate][nL-nRow+1]
	If nL > len(aGrid) 
		  // Se o grid acabou, verifica se o teco 
		  // da peça tinha alguma coisa a ser ligada
		  // Se tinha, nao cabe, se não tinha, beleza
			If  '1' $ cPeca 
				Return .F.
			Else
				EXIT
			Endif
	Endif
	cTecoGrid := substr(aGrid[nL],nCol,4)
	For nC := 1 to 4
		If Substr(cPeca,nC,1) == '1'
			If SubStr(cTecoGrid,nC,1) != '0'
				// Vai haver sobreposição,
				// a peça nao cabe ...
				Return .F.
			Endif
			cTecoGrid := Stuff(cTecoGrid,nC,1,cPieceId)
		Endif
	Next
	// Array temporario com a peça já colocada
	aadd(aTecos,cTecoGrid)
Next

// Aplica o array temporario no array do grid
For nL := nRow to nRow+len(aTecos)-1
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

METHOD _MoveDown() CLASS APTETRIS
Local aOldPiece
Local nMoved := 0

If ::nGameStatus != GAME_RUNNING
	Return
Endif

// Clona a peça em queda na posição atual
aOldPiece := aClone(::aGameCurr)

// Primeiro remove a peça do Grid atual
::_DelPiece(::aGameCurr,::aGameGrid)

// Agora move a peça apenas uma linha pra baixo
::aGameCurr[PIECE_ROW]++

// Recoloca a peça no Grid
If ::_SetPiece(::aGameCurr,::aGameGrid)
	
	// Nao bateu em nada, beleza. 
	// Retorna aqui mesmo 
	Return
	
Endif

// Opa ... Esbarrou em alguma peça ou fundo do grid
// Volta a peça pro lugar anterior e recoloca a peça no Grid
::aGameCurr :=  aClone(aOldPiece)
::_SetPiece(::aGameCurr,::aGameGrid)

// Encaixou uma peça .. Incrementa o score em 4 pontos
// Nao importa a peça ou como ela foi encaixada
::nGameScore += 4

// Verifica apos a pea encaixada, se uma ou mais linhas
// foram preenchidas e podem ser eliminadas
::_FreeLines()

// Pega a proxima peça e coloca em jogo
nPiece := ::nNextPiece
::aGameCurr := {nPiece,1,1,6} // Peca, direcao, linha, coluna

If !::_SetPiece(::aGameCurr,::aGameGrid)
	
	// Acabou, a peça nova nao entra (cabe) no Grid
	// "** GAME OVER** "
	::nGameStatus := GAME_OVER
	
	// Chama o codeblock de mudança de estado - Game Over
	Eval(::bChangeState , ::nGameStatus )
	
	// E retorna aqui mesmo
	Return
	
Endif

// Inicializa proxima peça em branco
::aNextPiece := array(4,"00000")

// Sorteia a proxima peça que vai cair
::nNextPiece := randomize(1,len(::aGamePieces)+1)
::_SetPiece( {::nNextPiece,1,1,1} , ::aNextPiece)

// Dispara a pintura da próxima peça
Eval( ::bPaintNext , ::aNextPiece )

// e retorna para o processamento de ações 

Return


METHOD _DropDown() CLASS APTETRIS
Local aOldPiece
Local nMoved := 0

If ::nGameStatus != GAME_RUNNING
	Return .F.
Endif

// Clona a peça em queda na posição atual
aOldPiece := aClone(::aGameCurr)

// Dropa a peça até bater embaixo
// O Drop incrementa o score em 1 ponto
// para cada linha percorrida. Quando maior a quantidade
// de linhas vazias, maior o score acumulado com o Drop

// Remove a peça do Grid atual
::_DelPiece(::aGameCurr,::aGameGrid)

// Desce uma linha pra baixo
::aGameCurr[PIECE_ROW]++

While ::_SetPiece(::aGameCurr,::aGameGrid)
	
	// Peça desceu mais uma linha
	// Incrementa o numero de movimentos dentro do Drop
	nMoved++

	// Incrementa o Score
	::nGameScore++

	// Remove a peça da interface
	::_DelPiece(::aGameCurr,::aGameGrid)
	
	// Guarda a peça na posição atual
	aOldPiece := aClone(::aGameCurr)
	
	// Desce a peça mais uma linha pra baixo
	::aGameCurr[PIECE_ROW]++
	
Enddo

// Volta a peça na última posição válida, 
::aGameCurr := aClone(aOldPiece)
::_SetPiece(::aGameCurr,::aGameGrid)
	
// Se conseguiu mover a peça com o Drop
// pelo menos uma linha, retorna .t. 
Return (nMoved > 0)


/* -----------------------------------------------------------------------
Remove a peça informada do grid informado
----------------------------------------------------------------------- */
METHOD _DelPiece(aPiece,aGrid) CLASS APTETRIS

Local nPiece := aPiece[PIECE_NUMBER]
Local nRotate   := aPiece[PIECE_ROTATION]
Local nRow   := aPiece[PIECE_ROW]
Local nCol   := aPiece[PIECE_COL]
Local nL, nC
Local cTecoGrid, cTecoPeca

// Como a matriz da peça é 4x4, trabalha em linhas e colunas
// Separa do grid atual apenas a área que a peça está ocupando
// e desliga os pontos preenchidos da peça no Grid.
// Esta função não verifica se a peça que está sendo removida
// é a correta, apenas apaga do grid os pontos ligados que
// a peça informada ocupa nas coordenadas especificadas

For nL := nRow to nRow+3
	cTecoPeca := ::aGamePieces[nPiece][1+nRotate][nL-nRow+1]
	If nL > len(aGrid)
	  // O Grid acabou, retorna
		Return
	Endif
	cTecoGrid := substr(aGrid[nL],nCol,4)
	For nC := 1 to 4
		If Substr(cTecoPeca,nC,1)=='1'
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
Retorna um grid de jogo vazio / inicializado
O Grid no core do tetris contem 21 linhas por 14 colunas
As limitações nas laterais esquerda e direita para 
facilitar os algoritmos para fazer a manutenção no Grid 
A área visivel nas colunas do Grid está indicada usando 
"." Logo, mesmo que o grid em memoria 
tenha 21x14, o grid de bitmaps de interface tem apenas 20x10, 
a partir da coordenada 2,3 ( linha,coluna ) do Grid do Jogo 

"11000000000011" -- Primeira linha, não visivel 
"11..........11" -- demais 20 linhas, visiveis da coluna 2 a 11 

------------------------------------------------------ */
METHOD _GetEmptyGrid() CLASS APTETRIS
Local aEmptyGrid 
aEmptyGrid := array(21,GRID_EMPTY_LINE)
Return aEmptyGrid


/* ------------------------------------------------------
Função auxiliar de conversão de segundos para HH:MM:SS
------------------------------------------------------ */

STATIC Function STOHMS(nSecs)
Local nHor
Local nMin

nHor := int(nSecs/3600)
nSecs -= (3600*nHor)

nMin := int(nSecs/60)
nSecs -= (60*nMin)

Return strzero(nHor,2)+':'+Strzero(nMin,2)+':'+strzero(nSecs,2)

