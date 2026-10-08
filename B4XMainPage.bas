B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
	#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
	'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

#Macro: Title, Export B4XPages, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip

Sub Class_Globals
	'Core Framework
	Private Root As B4XView
	Private xui As XUI

	'UI & Controls
	Public gamePane As B4XView = xui.CreatePanel("gamePane")
	Private GameMenu As B4XView
	Private Renderer As RenderUI

	'Game Loop & State
	Private gameTimer As Timer
	Private isSound As Boolean = True
	Private Const File_BestTimes As String = "besttimes.txt"

	'Audio Media Players
	Public Media_GamePlaying As MediaPlayer
	Public Media_Winning As MediaPlayer
	Public Media_Clicked As MediaPlayer
	Public Media_BombExploded As MediaPlayer
	Public Media_Winned As MediaPlayer
End Sub

Public Sub Initialize

End Sub

'This event will be called once, before the page becomes visible.

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "Minesweeper Classic")

	'Initialize Renderer and Assets
	Renderer.Initialize(Root)
	Renderer.loadAssets(True)

	'Add input panel over the canvas
	Root.AddView(gamePane, 0, 0, Root.Width, Root.Height)

	'Initialize Game Board & Level
	BoardLogic.ApplyLevel(BoardLogic.Level_Intermediate)
	BoardLogic.NewGame
	Renderer.LoadGameUI

	'Setup Game Timer
	gameTimer.Initialize("Timer1", 1000)
	gameTimer.Enabled = False

	'Initialize Audio Media
	Media_GamePlaying.Initialize("Media_GamePlaying", File.GetUri(File.DirAssets, "RoccoW_PartyCancelled.mp3"))
	Media_Winning.Initialize("Media_Winning", File.GetUri(File.DirAssets, "RoccoW_DontDishIt.mp3"))
	Media_Clicked.Initialize("Media_Clicked", File.GetUri(File.DirAssets, "Media_Clicked.wav"))
	Media_BombExploded.Initialize("Media_BombExploded", File.GetUri(File.DirAssets, "Media_Exploded.wav"))
	Media_Winned.Initialize("Media_Winned", File.GetUri(File.DirAssets, "Media_Winned.wav"))

	Media_GamePlaying.CycleCount = -1
	Media_GamePlaying.Volume = 0.5

	Media_Winning.CycleCount = -1
	Media_Winning.Volume = 0.5

	Media_Clicked.CycleCount = 1
	Media_Clicked.Volume = 0.5

	Media_BombExploded.CycleCount = 1
	Media_BombExploded.Volume = 0.5

	Media_Winned.CycleCount = 1
	Media_Winned.Volume = 0.5
End Sub

Private Sub B4XPage_Appear

End Sub

Private Sub gamePane_MousePressed (EventData As MouseEvent)
	'GET CURRENT SELECTION
	Dim mouseX As Float = EventData.X
	Dim mouseY As Float = EventData.Y

	'CLICK FACE
	Dim GameFace As ShapePosition = Renderer.posFace
	If mouseX > GameFace.Left And mouseX < GameFace.Right And _
		mouseY > GameFace.Top And mouseY < GameFace.Bottom Then

		'Press face button: show pressed face (Face_Down)
		Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Down)
		Renderer.Canvas.Invalidate
		Return
	End If

	'CHECK MINE
	Dim tempcell As ShapePosition = Renderer.posGrid_MineZone(0, 0)
	Dim tempcell1 As ShapePosition = Renderer.posGrid_MineZone(BoardLogic.SelectedLevel.numRows - 1, BoardLogic.SelectedLevel.numColumns - 1)

	'Mouse on Mine Zones
	If mouseX > tempcell.Left And mouseX < tempcell1.Right And _
		mouseY > tempcell.Top And mouseY < tempcell1.Bottom Then

		If BoardLogic.State = BoardLogic.State_Lost Or BoardLogic.State = BoardLogic.State_Won Then Return

		Dim r As Int = Floor((mouseY - tempcell.Top) / 16)
		Dim c As Int = Floor((mouseX - tempcell.Left) / 16)

		Dim selMine As mine = BoardLogic.GameBoard(r, c)

		'Handling Left Click
		If EventData.PrimaryButtonPressed Then
			If selMine.Mark = BoardLogic.Mark_Flag Then Return
			If selMine.Mark = BoardLogic.Mark_Question Then Return

			'First click: Start game, enable timer and start background music
			If BoardLogic.State = BoardLogic.State_Idle Then
				gameTimer.Enabled = True
				BoardLogic.StartGame(selMine)
				Renderer.RenderTime(True)
				Media_GamePlaying.Stop
				Media_GamePlaying.Play
			End If

			BoardLogic.RevealCell(r, c)

			'Check lose
			If selMine.MineNumber = BoardLogic.Cell_Mine Then
				BoardLogic.Result_Lose
				gameTimer.Enabled = False
				Media_GamePlaying.Stop
				Media_Winning.Stop
				Media_BombExploded.Stop
				Media_BombExploded.Play
			Else If BoardLogic.SafeCellsLeft = 0 Then
				'Check win
				BoardLogic.Result_Win
				gameTimer.Enabled = False
				Media_GamePlaying.Stop
				Media_Winning.Stop
				Media_Winned.Stop
				Media_Winned.Play
				Dim besttime As Int = Floor((DateTime.Now - BoardLogic.StartTime) / 1000)
				BestTime_Write(BoardLogic.SelectedLevel.CurrentLevel, besttime)
			End If

			'Handling Right Click
		Else If EventData.SecondaryButtonPressed And BoardLogic.State = BoardLogic.State_Playing Then
			If selMine.Reveal = False Then
				BoardLogic.setMark(selMine)
				Renderer.RenderMineCount
			End If
		End If

		Dim curCell() As Int = Array As Int (r, c)
		Renderer.GetSpriteForMineZone(curCell)
		Renderer.RenderMineZone

		'Face sprite according to game state:
		If BoardLogic.State = BoardLogic.State_Lost Then
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Lose)
		Else If BoardLogic.State = BoardLogic.State_Won Then
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Win)
		Else
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Clicked)
		End If

		'Music transition near victory
		If BoardLogic.State = BoardLogic.State_Playing Then
			Dim winningrate As Double = BoardLogic.MinesLeft / BoardLogic.SelectedLevel.numMines
			If winningrate < 0.4 Then
				Media_GamePlaying.Pause
				Media_Winning.Play
			End If
		End If
	End If

	Renderer.Canvas.Invalidate
End Sub

Private Sub gamePane_MouseReleased (EventData As MouseEvent)
	Dim mouseX As Float = EventData.X
	Dim mouseY As Float = EventData.Y
	Dim GameFace As ShapePosition = Renderer.posFace

	'CLICK ON FACE: Reset and start a new game on mouse release
	If mouseX > GameFace.Left And mouseX < GameFace.Right And _
		mouseY > GameFace.Top And mouseY < GameFace.Bottom Then

		BoardLogic.NewGame
		gameTimer.Enabled = False
		Media_Winning.Stop
		Media_GamePlaying.Stop
		Media_BombExploded.Stop

		Renderer.LoadGameUI
		Renderer.RenderMineCount
		Renderer.RenderTime(False)
		Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Default)
		Renderer.Canvas.Invalidate
		Return
	End If

	'CHECK MINE ZONE BOUNDS
	Dim tempcell As ShapePosition = Renderer.posGrid_MineZone(0, 0)
	Dim tempcell1 As ShapePosition = Renderer.posGrid_MineZone(BoardLogic.SelectedLevel.numRows - 1, BoardLogic.SelectedLevel.numColumns - 1)

	'Only handle release inside mine grid area
	If mouseX > tempcell.Left And mouseX < tempcell1.Right And _
		mouseY > tempcell.Top And mouseY < tempcell1.Bottom Then

		'If Idle or Playing -> restore default smiley face (Face_Default)
		'If Lost -> keep dead face (Face_Lose)
		'If Won -> keep cool face (Face_Win)
		If BoardLogic.State = BoardLogic.State_Idle Or BoardLogic.State = BoardLogic.State_Playing Then
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Default)
		Else If BoardLogic.State = BoardLogic.State_Lost Then
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Lose)
		Else If BoardLogic.State = BoardLogic.State_Won Then
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Win)
		End If

		If BoardLogic.State <> BoardLogic.State_Lost Then
			Media_Clicked.Stop
			Media_Clicked.Play
		End If
		Renderer.Canvas.Invalidate
	Else
		'If released outside mine grid (and outside face), restore face state
		If BoardLogic.State = BoardLogic.State_Idle Or BoardLogic.State = BoardLogic.State_Playing Then
			Renderer.drawSprite(GameFace, Renderer.Assets_Faces, Renderer.Face_Default)
			Renderer.Canvas.Invalidate
		End If
	End If
End Sub

Private Sub Timer1_Tick
	Renderer.RenderTime(True)
	Renderer.Canvas.Invalidate

	If BoardLogic.State = BoardLogic.State_Lost Or BoardLogic.State = BoardLogic.State_Won Then
		gameTimer.Enabled = False
	End If
End Sub

Sub MainMenu_Action
	Dim mi As MenuItem = Sender
	Select mi.Text
		Case "_New"
			BoardLogic.NewGame
			Media_Winning.Stop
			Media_GamePlaying.Stop
			Renderer.LoadGameUI
			Renderer.RenderMineCount
			Renderer.RenderTime(False)
			gameTimer.Enabled = False
			Renderer.Canvas.Invalidate

		Case "_Beginner", "_Intermediate", "_Expert"
			Dim levelName As String = mi.Text.Replace("_", "")
			BoardLogic.ApplyLevel(levelName)
			BoardLogic.NewGame
			Media_Winning.Stop
			Media_GamePlaying.Stop
			Renderer.LoadGameUI
			Renderer.RenderMineCount
			Renderer.RenderTime(False)
			gameTimer.Enabled = False
			Renderer.Canvas.Invalidate

		Case "_Best Time"
			Dim Best As Map = BestTime_Load
			xui.MsgboxAsync( _
			"Beginner: " & NumberFormat(Best.Get("Beginner"), 3, 0) & " Seconds" & CRLF & _
			"Intermediate: " & NumberFormat(Best.Get("Intermediate"), 3, 0) & " Seconds" & CRLF & _
			"Expert: " & NumberFormat(Best.Get("Expert"), 3, 0) & " Seconds", _
			"Best Times")

		Case "Exit"
			Dim frm As Form = B4XPages.GetNativeParent(Me)
			frm.Close
	End Select
End Sub

Private Sub Mark_SelectedChange(Selected As Boolean)
	BoardLogic.QuestionEnable = Selected
End Sub

Private Sub Sound_SelectedChange(Selected As Boolean)
	isSound = Selected
	If isSound Then
		Media_GamePlaying.Volume = 0.5
		Media_Winning.Volume = 0.5
		Media_Clicked.Volume = 0.5
		Media_BombExploded.Volume = 0.5
		Media_Winned.Volume = 0.5
	Else
		Media_GamePlaying.Volume = 0
		Media_Winning.Volume = 0
		Media_Clicked.Volume = 0
		Media_BombExploded.Volume = 0
		Media_Winned.Volume = 0
	End If
End Sub

Private Sub Color_SelectedChange(Selected As Boolean)
	Renderer.loadAssets(Selected)
	BoardLogic.NewGame
	Renderer.LoadGameUI
	Renderer.Canvas.Invalidate
End Sub


#Region Helpers

	Private Sub BestTime_Write(Level As String, Seconds As Int)
		Dim Best As Map = BestTime_Load
		Dim OldTime As Int = Best.GetDefault(Level, 0)

		If OldTime = 0 Or Seconds < OldTime Then
			Best.Put(Level, Seconds)
			File.WriteMap(File.DirApp, File_BestTimes, Best)
		End If
	End Sub

	Private Sub BestTime_Load As Map
		Dim Best As Map = CreateMap("Beginner": 0, "Intermediate": 0, "Expert": 0)
		If File.Exists(File.DirApp, File_BestTimes) Then
			Dim loaded As Map = File.ReadMap(File.DirApp, File_BestTimes)
			For Each k As String In loaded.Keys
				Best.Put(k, Floor(loaded.Get(k)))
			Next
		End If
		Return Best
	End Sub

#End Region