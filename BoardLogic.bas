B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=10.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	'Levels
	Public Const Level_Beginner As String = "Beginner"
	Public Const Level_Intermediate As String = "Intermediate"
	Public Const Level_Expert As String = "Expert"

	'Cell Values
	Public Const Cell_Mine As Int = -1

	'Cell Marks
	Public Const Mark_None As Int = 0
	Public Const Mark_Flag As Int = 1
	Public Const Mark_Question As Int = 2

	'Game States
	Public Const State_Idle As Int = 0
	Public Const State_Playing As Int = 1
	Public Const State_Won As Int = 2
	Public Const State_Lost As Int = 3

	'Type definitions
	Type Level (CurrentLevel As String, numRows As Int, numColumns As Int, numMines As Int)
	Type mine (MineNumber As Int, Reveal As Boolean, Mark As Int)
	
	'GAME STATE
	Public State As Int = State_Idle
	Public StartTime As Long = 0
	Public SelectedLevel As Level

	'BOARD & COUNTERS
	Public GameBoard(, ) As mine  '(row, column)
	Public MinesLeft As Int
	Public SafeCellsLeft As Int

	'SETTINGS
	Public QuestionEnable As Boolean = True
End Sub

#Region Lifecycle

'Initialize board dimensions and cell array by difficulty
Public Sub ApplyLevel(GameLevel As String)
	SelectedLevel.Initialize
	Select GameLevel
		Case Level_Beginner
			SelectedLevel.numRows = 9
			SelectedLevel.numColumns = 9
			SelectedLevel.numMines = 10
		Case Level_Intermediate
			SelectedLevel.numRows = 16
			SelectedLevel.numColumns = 16
			SelectedLevel.numMines = 40
		Case Level_Expert
			SelectedLevel.numRows = 16
			SelectedLevel.numColumns = 30
			SelectedLevel.numMines = 99
	End Select

	SelectedLevel.CurrentLevel = GameLevel
	MinesLeft = SelectedLevel.numMines
	SafeCellsLeft = (SelectedLevel.numRows * SelectedLevel.numColumns) - SelectedLevel.numMines

	Dim newBoard(SelectedLevel.numRows, SelectedLevel.numColumns) As mine
	GameBoard = newBoard
End Sub

'Reset game to Idle state
Public Sub NewGame
	ApplyLevel(SelectedLevel.CurrentLevel)
	State = State_Idle
End Sub

'Place mines and compute neighboring mine counts on first click
Public Sub StartGame(startCell As mine)
	State = State_Playing
	StartTime = DateTime.Now

	Dim maxRows As Int = SelectedLevel.numRows
	Dim maxCols As Int = SelectedLevel.numColumns
	Dim totalMines As Int = SelectedLevel.numMines

	'1. Randomly place mines (avoid the player's first-click cell)
	Dim placedCount As Int = 0
	Do Until placedCount = totalMines
		Dim randR As Int = Rnd(0, maxRows)
		Dim randC As Int = Rnd(0, maxCols)
		Dim targetCell As mine = GameBoard(randR, randC)

		If targetCell.MineNumber <> Cell_Mine And targetCell <> startCell Then
			targetCell.MineNumber = Cell_Mine
			placedCount = placedCount + 1
		End If
	Loop

	'2. Calculate neighboring mine counts for non-mine cells
	For r = 0 To maxRows - 1
		For c = 0 To maxCols - 1
			If GameBoard(r, c).MineNumber = Cell_Mine Then Continue

			For check_r = r - 1 To r + 1
				For check_c = c - 1 To c + 1
					If check_r < 0 Or check_r > maxRows - 1 Then Continue
					If check_c < 0 Or check_c > maxCols - 1 Then Continue
					If check_r = r And check_c = c Then Continue

					If GameBoard(check_r, check_c).MineNumber = Cell_Mine Then
						GameBoard(r, c).MineNumber = GameBoard(r, c).MineNumber + 1
					End If
				Next
			Next
		Next
	Next
End Sub

#End Region

#Region User Actions

'Cycle cell mark state (None -> Flag -> Question -> None)
Public Sub setMark(selectedMine As mine)
	Dim oldMark As Int = selectedMine.Mark
	Dim maxStates As Int = 3
	If QuestionEnable = False Then maxStates = 2

	'If no flags left and current state is None, do not allow placing more flags
	If MinesLeft = 0 And oldMark = Mark_None Then
		Return
	End If

	selectedMine.Mark = (selectedMine.Mark + 1) Mod maxStates

	'Update remaining mine counter
	If selectedMine.Mark = Mark_Flag Then
		MinesLeft = MinesLeft - 1
	Else If oldMark = Mark_Flag And selectedMine.Mark <> Mark_Flag Then
		MinesLeft = MinesLeft + 1
	End If
End Sub

'Reveal cell and flood fill neighbors if empty
Public Sub RevealCell(startR As Int, startC As Int)
	Dim maxRows As Int = SelectedLevel.numRows
	Dim maxCols As Int = SelectedLevel.numColumns

	Dim queue As List
	queue.Initialize
	queue.Add(Array As Int(startR, startC))

	Do While queue.Size > 0
		Dim current() As Int = queue.Get(0)
		queue.RemoveAt(0)

		Dim r As Int = current(0)
		Dim c As Int = current(1)

		If r < 0 Or r > maxRows - 1 Or c < 0 Or c > maxCols - 1 Then Continue
		If GameBoard(r, c).Reveal = True Then Continue
		If GameBoard(r, c).Mark = Mark_Flag Then Continue

		GameBoard(r, c).Reveal = True
		SafeCellsLeft = SafeCellsLeft - 1

		'If empty cell (MineNumber = 0), reveal 8 neighbors
		If GameBoard(r, c).MineNumber = 0 Then
			For check_r = r - 1 To r + 1
				If check_r < 0 Or check_r > maxRows - 1 Then Continue
				For check_c = c - 1 To c + 1
					If check_c < 0 Or check_c > maxCols - 1 Then Continue
					If GameBoard(check_r, check_c).Reveal = False Then
						queue.Add(Array As Int(check_r, check_c))
					End If
				Next
			Next
		End If
	Loop
End Sub

#End Region

#Region End Game

'Reveal all mines on game lost
Public Sub Result_Lose
	State = State_Lost
	Dim maxRows As Int = SelectedLevel.numRows
	Dim maxCols As Int = SelectedLevel.numColumns

	For r = 0 To maxRows - 1
		For c = 0 To maxCols - 1
			If GameBoard(r, c).MineNumber = Cell_Mine Then
				GameBoard(r, c).Reveal = True
			End If
		Next
	Next
End Sub

'Reveal all cells on game won
Public Sub Result_Win
	State = State_Won
	Dim maxRows As Int = SelectedLevel.numRows
	Dim maxCols As Int = SelectedLevel.numColumns

	For r = 0 To maxRows - 1
		For c = 0 To maxCols - 1
			If GameBoard(r, c).MineNumber = Cell_Mine Then
				GameBoard(r, c).Mark = Mark_Flag
			Else
				GameBoard(r, c).Reveal = True
			End If
		Next
	Next
	MinesLeft = 0
End Sub

#End Region
