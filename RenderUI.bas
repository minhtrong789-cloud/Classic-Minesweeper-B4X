B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@

Sub Class_Globals
	Private xui As XUI
	Public Canvas As B4XCanvas
	Type ShapePosition (Left, Top, Right, Bottom, Width, Height, Thickness As Float, sprite As String)

	'Sprite Assets Maps
	Public Assets_Faces As Map
	Public Assets_Mines As Map
	Public Assets_TimeNumber As Map

	'Sprite Face Constants
	Public Const Face_Down As String = "Face_Down"
	Public Const Face_Win As String = "Face_Win"
	Public Const Face_Lose As String = "Face_Lose"
	Public Const Face_Clicked As String = "Face_clicked"
	Public Const Face_Default As String = "Face_Default"

	'Infrastructure
	Public Root As B4XView
	Public GameMenu As B4XView

	'Layout Positions
	Public posFrame_Status As ShapePosition
	Public posFrame_MineCount As ShapePosition
	Public posFrame_Timer As ShapePosition
	Public posFrame_MineZone As ShapePosition

	Public posFace As ShapePosition
	Public posDigit_MineCount(3) As ShapePosition
	Public posDigit_Timer(3) As ShapePosition
	Public posGrid_MineZone(, ) As ShapePosition
End Sub

'Initializes the renderer and binds it to the target parent view.

Public Sub Initialize (TargetForm As B4XView)
	Root = TargetForm
	Canvas.Initialize(Root)

	'Get MenuSize
	For Each v As B4XView In Root.GetAllViewsRecursive
		If v.Tag = "MainMenu" Then
			GameMenu = v
			Exit
		End If
	Next
End Sub

'Resizes form/canvas and draws initial board frame and empty states.

Public Sub LoadGameUI
	'Calculate window size based on board difficulty
	Dim numCols As Int = BoardLogic.SelectedLevel.numColumns
	Dim numRows As Int = BoardLogic.SelectedLevel.numRows
	Dim resizeWidth As Float = 10 + numCols * 16 + 3 + 20
	Dim resizeHeight As Float = GameMenu.Height + 10 + 3 + 48 + 10 + 3 + numRows * 16 + 6 + 20

	Canvas.Resize(resizeWidth, resizeHeight)
	Dim frm As Form = B4XPages.GetNativeParent(B4XPages.MainPage)
	frm.WindowWidth = resizeWidth
	frm.WindowHeight = frm.WindowHeight - frm.Height + resizeHeight

	'Resize Root Panel
	Root.Width = resizeWidth
	Root.Height = resizeHeight

	'Adjust Game Pane
	B4XPages.MainPage.gamePane.Left = Root.Left
	B4XPages.MainPage.gamePane.Top = Root.Top
	B4XPages.MainPage.gamePane.Width = Root.Width
	B4XPages.MainPage.gamePane.Height = Root.Height

	GameMenu.BringToFront

	'Fill gray background (RGB: 192, 192, 192)
	Canvas.DrawRect(Canvas.TargetRect, 0xFFC0C0C0, True, 1)

	'1. PLACEMENT PHASE (Calculate positions for all UI elements)
	Dim frameStatus    As ShapePosition = placeFrame_Status
	Dim frameMineCount As ShapePosition = placeFrame_MineCount(frameStatus)
	Dim frameTimer     As ShapePosition = placeFrame_Timer(frameStatus)
	Dim frameMineZone  As ShapePosition = placeFrame_MineZone(frameStatus)

	Dim face           As ShapePosition = placeFace(frameStatus)
	Dim digitsMine()   As ShapePosition = placeDigit_MineCount(frameMineCount)
	Dim digitsTimer()  As ShapePosition = placeDigit_Timer(frameTimer)
	Dim gridMines(, )   As ShapePosition = placeMines(frameMineZone)

	'2. DRAW PHASE (Render initial UI)
	'Draw 3D borders
	draw3DBox(frameStatus)
	draw3DBox(frameMineCount)
	draw3DBox(frameTimer)
	draw3DBox(frameMineZone)

	'Draw default sprites
	drawSprite(face, Assets_Faces, "Face_Default")

	For i = 0 To 2
		drawSprite(digitsMine(i), Assets_TimeNumber, "Digit_Empty")
		drawSprite(digitsTimer(i), Assets_TimeNumber, "Digit_Empty")
	Next

	For row = 0 To numRows - 1
		For col = 0 To numCols - 1
			drawSprite(gridMines(row, col), Assets_Mines, "mine_normal")
		Next
	Next
End Sub

'Renders the 3-digit timer display based on elapsed game time.

Public Sub RenderTime (Start As Boolean)
	If Start = True Then
		Dim Count As Int = Floor((DateTime.Now - BoardLogic.StartTime) / 1000)
		If Count > 999 Then Count = 999
		If Count < 0 Then Count = 0

		Dim ones As Int = Count Mod 10
		Dim tens As Int = (Count / 10) Mod 10
		Dim hundreds As Int = (Count / 100) Mod 10

		drawSprite(posDigit_Timer(0), Assets_TimeNumber, "Digit_" & hundreds)
		drawSprite(posDigit_Timer(1), Assets_TimeNumber, "Digit_" & tens)
		drawSprite(posDigit_Timer(2), Assets_TimeNumber, "Digit_" & ones)
	Else
		drawSprite(posDigit_Timer(0), Assets_TimeNumber, "Digit_0")
		drawSprite(posDigit_Timer(1), Assets_TimeNumber, "Digit_0")
		drawSprite(posDigit_Timer(2), Assets_TimeNumber, "Digit_0")
	End If
End Sub

'Renders the 3-digit remaining mine count counter.

Public Sub RenderMineCount
	'Read remaining mines directly from BoardLogic.MinesLeft
	Dim NumberOfMines As Int = BoardLogic.MinesLeft
	Dim digits() As ShapePosition = posDigit_MineCount

	Dim ones As Int = NumberOfMines Mod 10
	Dim tens As Int = Floor(NumberOfMines / 10) Mod 10
	Dim hundreds As Int = Floor(NumberOfMines / 100) Mod 10
	drawSprite(digits(0), Assets_TimeNumber, "Digit_" & hundreds)
	drawSprite(digits(1), Assets_TimeNumber, "Digit_" & tens)
	drawSprite(digits(2), Assets_TimeNumber, "Digit_" & ones)
End Sub



'Redraws all cells in the mine grid on the canvas.

Public Sub RenderMineZone
	'Copy module-level and BoardLogic references to local variables before looping
	Dim grid(, ) As ShapePosition = posGrid_MineZone
	Dim numRows As Int = BoardLogic.SelectedLevel.numRows
	Dim numCols As Int = BoardLogic.SelectedLevel.numColumns

	For r = 0 To numRows - 1
		For c = 0 To numCols - 1
			Dim selShape As ShapePosition = grid(r, c)
			drawSprite(selShape, Assets_Mines, selShape.sprite)
		Next
	Next
End Sub

#Region Placement

	Private Sub placeFrame_Status As ShapePosition
		Dim width As Float = 3 + BoardLogic.SelectedLevel.numColumns * 16 + 3
		Dim frame As ShapePosition = createShape(10dip, GameMenu.Height + 20dip, width, 48dip, 3dip, "")
		posFrame_Status = frame
		Return posFrame_Status
	End Sub

	Private Sub placeFrame_MineCount (parentFrame As ShapePosition) As ShapePosition
		Dim frame As ShapePosition = createShape(parentFrame.Left + 10dip, parentFrame.Top + 10dip, 1 + 13*3 + 1, 1dip + 23dip + 1dip, 1dip, "")
		posFrame_MineCount = frame
		Return posFrame_MineCount
	End Sub

	Private Sub placeFrame_Timer (parentFrame As ShapePosition) As ShapePosition
		Dim width As Float = 1 + 13*3 + 1
		Dim frame As ShapePosition = createShape(parentFrame.Right - 10dip - width, parentFrame.Top + 10dip, width, 1dip + 23dip + 1dip, 1dip, "")
		posFrame_Timer = frame
		Return posFrame_Timer
	End Sub

	Private Sub placeFrame_MineZone (parentFrame As ShapePosition) As ShapePosition
		Dim height As Float = 3dip + BoardLogic.SelectedLevel.numRows * 16dip + 3dip + 3dip
		Dim frame As ShapePosition = createShape(parentFrame.Left, parentFrame.Bottom + 10dip, parentFrame.Width, height, 3dip, "")
		posFrame_MineZone = frame
		Return posFrame_MineZone
	End Sub

	Private Sub placeMines (parentFrame As ShapePosition) As ShapePosition(, )
		Dim numRows As Int = BoardLogic.SelectedLevel.numRows
		Dim numCols As Int = BoardLogic.SelectedLevel.numColumns
		Dim mineZone(numRows, numCols) As ShapePosition
		For row = 0 To numRows - 1
			For col = 0 To numCols - 1
				mineZone(row, col) = createShape(parentFrame.Left + 3dip + 16 * col, _
				parentFrame.Top + 3dip + 16 * row, _
				16, 16, 0dip, "mine_normal")
			Next
		Next
		posGrid_MineZone = mineZone
		Return posGrid_MineZone
	End Sub

	Private Sub placeDigit_MineCount(parentFrame As ShapePosition) As ShapePosition()
		Dim digits(3) As ShapePosition
		For i = 0 To 2
			digits(i) = createShape(parentFrame.Left + 1 + 13*i, parentFrame.Top + 1, 13, 23, 0dip, "Digit_Empty")
		Next
		posDigit_MineCount = digits
		Return posDigit_MineCount
	End Sub

	Private Sub placeDigit_Timer(parentFrame As ShapePosition) As ShapePosition()
		Dim digits(3) As ShapePosition
		For i = 0 To 2
			digits(i) = createShape(parentFrame.Left + 1 + 13*i, parentFrame.Top + 1, 13, 23, 0dip, "Digit_Empty")
		Next
		posDigit_Timer = digits
		Return posDigit_Timer
	End Sub

	Private Sub placeFace(parentFrame As ShapePosition) As ShapePosition
		Dim x As Float = parentFrame.Left + parentFrame.Width / 2 - 12
		Dim y As Float = parentFrame.Top + parentFrame.Height / 2 - 12
		Dim face As ShapePosition = createShape(x, y, 24, 24, 0dip, "Face_Default")
		posFace = face
		Return posFace
	End Sub
#End Region

#Region Draw Primitive

	Public Sub drawSprite(shapePos As ShapePosition, sprAssets As Map, sprName As String)
		Dim rect As B4XRect
		rect.Initialize(shapePos.Left, shapePos.Top, shapePos.Right, shapePos.Bottom)
		shapePos.sprite = sprName
		Canvas.DrawBitmap(sprAssets.Get(shapePos.sprite), rect)
	End Sub

	Private Sub draw3DBox(shape As ShapePosition)
		Dim ColorTopLeft As Int = 0xFF808080  'Dark Gray
		Dim ColorBottomRight As Int = 0xFFFFFFFF  'White

		Dim Thickness As Float = shape.Thickness
		If Thickness <= 0 Then Thickness = 1dip

		'Top & Left borders
		Canvas.DrawLine(shape.Left, shape.Top + Thickness/2, shape.Right, shape.Top + Thickness/2, ColorTopLeft, Thickness)  'TOP
		Canvas.DrawLine(shape.Left + Thickness/2, shape.Top + Thickness, shape.Left + Thickness/2, shape.Bottom - Thickness, ColorTopLeft, Thickness)  'LEFT

		'Bottom & Right borders
		Canvas.DrawLine(shape.Right - Thickness/2, shape.Top + Thickness, shape.Right - Thickness/2, shape.Bottom - Thickness, ColorBottomRight, Thickness)  'RIGHT
		Canvas.DrawLine(shape.Left + Thickness, shape.Bottom - 1.5*Thickness, shape.Right - Thickness, shape.Bottom - 1.5*Thickness, ColorBottomRight, Thickness)  'BOTTOM
	End Sub

	Private Sub createShape(Left As Float, Top As Float, Width As Float, Height As Float, Thickness As Float, Sprite As String) As ShapePosition
		Dim s As ShapePosition
		s.Initialize
		s.Left = Left
		s.Top = Top
		s.Width = Width
		s.Height = Height
		s.Right = Left + Width
		s.Bottom = Top + Height
		s.Thickness = Thickness
		s.sprite = Sprite
		Return s
	End Sub

#End Region

#Region ASSETS

	'Loads and slices sprite sheets (faces, numbers, mines) from assets.
	'Public Sub InitializeAssets (HaveColor As Boolean)
	'new name loadAssets (isColor)

	Public Sub loadAssets (isColor As Boolean)
		Assets_Faces.Initialize
		Assets_Mines.Initialize
		Assets_TimeNumber.Initialize

		'INITIALIZE ASSETS FOR THE GAME
		Dim tFace, Mine, Digits As B4XBitmap
		If isColor = True Then
			Dim fileNameDigits As String = "Number_Color.bmp"
			If File.Exists(File.DirAssets, "Number_Color .bmp") Then fileNameDigits = "Number_Color .bmp"
				tFace = xui.LoadBitmap(File.DirAssets, "Face_Color.bmp")
				Mine = xui.LoadBitmap(File.DirAssets, "Mine_Color.bmp")
				Digits = xui.LoadBitmap(File.DirAssets, fileNameDigits)
			Else
				tFace = xui.LoadBitmap(File.DirAssets, "Face_BlackWhite.bmp")
				Mine = xui.LoadBitmap(File.DirAssets, "Mine_BlackWhite.bmp")
				Digits = xui.LoadBitmap(File.DirAssets, "Number_BlackWhite.bmp")
			End If

			'Face Icon (5 frames, 24x24)
			Dim faceNames() As String = Array As String( _
			"Face_Down", "Face_Win", "Face_Lose", "Face_clicked", "Face_Default")
			For i = 0 To 4
				Assets_Faces.Put(faceNames(i), tFace.Crop(0, i * 24, 24, 24))
			Next

			'Mine Cell (16 frames, 16x16)
			Dim mineNames() As String = Array As String( _
			"mine_normal", _
			"mine_flag", _
			"mine_questioned", _
			"mine_exploded", _
			"mine_eliminated", _
			"mine_mineleft", _
			"mine_questionpressed", _
			"Mine_8", "Mine_7", "Mine_6", "Mine_5", "Mine_4", "Mine_3", "Mine_2", "Mine_1", "Mine_0")
			For i = 0 To 15
				Assets_Mines.Put(mineNames(i), Mine.Crop(0, i * 16, 16, 16))
			Next

			'Virtual Digit (12 frames, 13x23)
			Dim digitNames() As String = Array As String( _
			"Digit_Dash", "Digit_Empty", _
			"Digit_9", "Digit_8", "Digit_7", "Digit_6", "Digit_5", _
			"Digit_4", "Digit_3", "Digit_2", "Digit_1", "Digit_0")
			For i = 0 To 11
				Assets_TimeNumber.Put(digitNames(i), Digits.Crop(0, i * 23, 13, 23))
			Next
		End Sub
	#End Region

	'Maps game board cell states into sprite identifiers.

	Public Sub GetSpriteForMineZone (CurrentCell() As Int)
		'Copy module-level and BoardLogic references to local variables before looping
		Dim grid(, ) As ShapePosition = posGrid_MineZone
		Dim board(, ) As mine = BoardLogic.GameBoard
		Dim numRows As Int = BoardLogic.SelectedLevel.numRows
		Dim numCols As Int = BoardLogic.SelectedLevel.numColumns

		For r = 0 To numRows - 1
			For c = 0 To numCols - 1
				Dim selMine As mine = board(r, c)
				Dim selShape As ShapePosition = grid(r, c)

				If selMine.Reveal = False Then
					Select selMine.Mark
						Case BoardLogic.Mark_None
							selShape.sprite = "mine_normal"
						Case BoardLogic.Mark_Flag
							selShape.sprite = "mine_flag"
						Case BoardLogic.Mark_Question
							selShape.sprite = "mine_questioned"
					End Select
				Else
					'Revealed cell (Reveal = True)
					If selMine.MineNumber <> BoardLogic.Cell_Mine And selMine.Mark = BoardLogic.Mark_Question Then
						selShape.sprite = "mine_questionpressed"
					Else If selMine.MineNumber <> BoardLogic.Cell_Mine Then
						selShape.sprite = "Mine_" & selMine.MineNumber
					Else If selMine.MineNumber = BoardLogic.Cell_Mine And selMine.Mark = BoardLogic.Mark_Flag Then
						selShape.sprite = "mine_eliminated"
					Else If selMine.MineNumber = BoardLogic.Cell_Mine And selMine.Mark <> BoardLogic.Mark_Flag Then
						selShape.sprite = "mine_mineleft"
					End If
				End If
			Next
		Next

		'Highlight the specific mine cell that exploded on click (if applicable)
		If CurrentCell <> Null And CurrentCell.Length >= 2 Then
			Dim curR As Int = CurrentCell(0)
			Dim curC As Int = CurrentCell(1)
			If curR >= 0 And curR < numRows And curC >= 0 And curC < numCols Then
				Dim curMine As mine = board(curR, curC)
				Dim curShape As ShapePosition = grid(curR, curC)
				If curMine.MineNumber = BoardLogic.Cell_Mine And curMine.Reveal = True And curMine.Mark <> BoardLogic.Mark_Flag Then
					curShape.sprite = "mine_exploded"
				End If
			End If
		End If
	End Sub


