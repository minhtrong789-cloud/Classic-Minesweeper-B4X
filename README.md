# Classic Minesweeper

A Windows-style Minesweeper clone built with B4X / B4J.

The game uses a custom canvas-based interface. The board, counters, face button, frames, and cell states are drawn from code instead of using one UI control for each cell.

## Features

- Beginner, Intermediate, and Expert difficulty levels
- First-click-safe mine generation
- Left-click reveal and right-click marking
- Optional question-mark state
- Timer and remaining-mine counter
- Win, loss, click, and background audio
- Best-time saving for each difficulty
- Color and black-and-white sprite sets
- Window and board layout resized for the selected difficulty

## How the code is organized

The code is split into three main modules.

### `BoardLogic`

Owns the board and the game rules.

It handles:

- Difficulty settings and board creation
- Mine placement after the first valid click
- Adjacent-mine number calculation
- Cell marks: none, flag, and question mark
- Cell reveal and empty-area expansion
- Remaining mine and safe-cell counters
- Idle, playing, won, and lost states

`BoardLogic` is the source of truth for the current game state.

### `RenderUI`

Draws the game interface with `B4XCanvas`.

It handles:

- Loading and cutting sprite sheets into face, cell, and digit images
- Calculating the position and size of each visual element
- Drawing the board, counters, face button, and 3D-style frames
- Reading the current state from `BoardLogic`
- Mapping each cell state to the correct sprite
- Resizing the canvas, input area, and window for each board size

The renderer reads the board state directly from `BoardLogic`. This is intentional: `BoardLogic` owns the data, and `RenderUI` needs that data to draw the current frame.

### `B4XMainPage`

Connects input, game logic, rendering, and application features.

It handles:

- Mouse input and hit testing
- Converting mouse coordinates to board row and column
- Starting and resetting a game
- Calling `BoardLogic` for game actions
- Asking `RenderUI` to redraw the interface
- Timer, audio, menu settings, and best-time files

## Input and rendering flow

```text
Mouse input
    -> B4XMainPage checks the clicked area
    -> pixel position is converted to board coordinates
    -> BoardLogic updates the game state
    -> RenderUI reads the new state
    -> the canvas is redrawn
```

The minefield uses one input surface over the canvas. It does not create a separate button or view for every cell.

## Game logic details

### First-click-safe board generation

Mines are not placed when a new board is created. They are placed after the first valid click, and the clicked cell is excluded from mine placement. The timer and game audio also start at this point.

### Empty-area reveal

Empty areas are revealed with an iterative queue. When a cell has no adjacent mines, its neighboring cells are added to the queue. This continues until the empty area and its numbered border have been revealed.

### Win check

The game keeps a count of unrevealed safe cells. The count is reduced when a safe cell is opened. When it reaches zero, the game is won without scanning the full board again after every click.

### Cell state to sprite mapping

The renderer maps board state to sprites in one place. It handles normal cells, flags, question marks, numbers, mines, correctly flagged mines, and the mine that caused the loss.

## UI implementation

The interface is built from small sprite sheets and drawing code.

At startup, the sprite sheets are cut into named images such as face states, mine states, numbers, and digital digits. The rest of the renderer uses these names instead of working with sprite-sheet coordinates directly.

The layout is calculated from the selected board size. Changing the difficulty updates the board dimensions, visual frames, canvas, input surface, and application window. The same rendering code is used for all three difficulty levels.

The full grid is redrawn after an accepted board action. The largest board contains 480 cells, so a full redraw keeps the code simple and is enough for this project.

## Project files

```text
B4XMainPage.bas  Input and application coordination
BoardLogic.bas   Board state and Minesweeper rules
RenderUI.bas     Layout, sprites, and canvas rendering
```

## Download

[Releases](https://github.com/minhtrong789-cloud/Classic-Minesweeper-B4X/releases).
