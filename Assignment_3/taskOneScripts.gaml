/**
* Name: taskOneScripts
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/


model taskOneScripts

/* Insert your model definition here */
global{
    int numberOfQueens <- 15 min: 4 max: 20; 
    list<int> rowList <- [];
    
    init{
        create Queen number: numberOfQueens{location <- {-2.5, -2.5};}
        loop counter from: 0 to: numberOfQueens - 1{
        	rowList <+ counter;	
        }
    }
    list<Queen> queens;
    list<Chessboard> ChessboardCells;
    
}

grid Chessboard skills:[fipa] width: numberOfQueens height: numberOfQueens neighbors: numberOfQueens{
   rgb color <- rgb("white");
   bool occupied <- false;
   init{
   		if ((grid_x + grid_y) mod 2 = 1){
			color <- rgb("black");
		}
		add self to: ChessboardCells;
   }
 
}

species Queen skills: [fipa]{
	int id;
	/* The row which the queen has been placed */
	int placedRow <- -1;
	/* The cell that the queen has been placed */
	Chessboard placedCell <- nil;
	/* Rows which are available to place */
	list<int> availableRowsToPlace <- [];
	/* Contain rows will make the following queen cannot place */
	list<int> rowsHaveBeenPlaced <- [];
	/* The status of the queen, has not yet to place, placed or has failed to place and start to find cells to place */
	bool placed <- false;
	bool findCellToPlace <- false;
	
	init{
		queens <+ self;
		id <- length(queens) - 1;
		if (length(queens) = numberOfQueens){
			/* Initialize complete, ready to conduct by sending the message to the first queen */
			do start_conversation to: list(queens[0]) protocol: 'fipa-contract-net' performative: 'inform' contents: ['Find your place'];
			write 'Start! ----------------------------';
		}
	}
	
	int getCell(int curId, int curRow){
		/* Get the occupied status of the cell */
		return (numberOfQueens * curRow) + curId;
	}
	
	bool checkDiagnolAvailable(int row, int col){
		/* Check left upper diagnol */
		int x <- col - 1;
		int y <- row - 1;
		loop while: (x >= 0 and y >= 0){
			Chessboard cell <- Chessboard[getCell(x, y)];
			if (cell.occupied){
				return false;
			}
			x <- x - 1;
			y <- y - 1;
		}
		
		/* Check left lower diagnol */
		x <- col - 1;
		y <- row + 1;
		loop while: (x >= 0 and y >= 0 and y < numberOfQueens) {
    		Chessboard cell <- ChessboardCells[getCell(x, y)];
    		if(cell.occupied) {
        		return false;
        	}
        	x <- x - 1;
        	y <- y + 1;
    	}
    	return true;
	}
	
	list<int> getAvailableRows{
		list<int> availableRows <- [];
		loop row over: rowList{
			availableRows <+ row;
		}
		list<int> occupiedRows <- [];
		if (id = 0)
		{
			return availableRows;
		} else{
			loop counter from:0 to: id - 1{
				if queens[counter].placedRow in availableRows{
					occupiedRows <+ queens[counter].placedRow;
				}
			}
			/* Remove occupied rows */
			loop row over: occupiedRows{
				remove item: row from: availableRows;
			}
		}
		
		list<int> notDiagnolAvailableRows <- [];
		if length(availableRows) != 0{
			loop row over: availableRows{
				/* Reomove rows whose cell is occupied in diagnol */
				if (!checkDiagnolAvailable(row, id)){
					notDiagnolAvailableRows <+ row;
				}
			}
			loop row over: notDiagnolAvailableRows{
				remove item: row from: availableRows;
			}	
		}
		return availableRows;
	}
	
	reflex conductByRecievingInforms when: !empty(informs){
		message informMsg <- informs[0];
		if (informMsg.contents[0] = 'Find your place'){
			findCellToPlace <- true;
		} else if(informMsg.contents[0] = 'I cannot find any places, please replace yourself'){
			/* Reset status of the cell just been placed */
			placedCell.occupied <- false;
			placedCell <- nil;
			/* Set the status of the queen */
			placed <- false;
			findCellToPlace <- true;
			rowsHaveBeenPlaced <+ placedRow;
			placedRow <- -1;
		}
	} 
	
	reflex placeTheQueen when: findCellToPlace{
		availableRowsToPlace <- getAvailableRows();
		/* Have never been asked to replace */
		if !empty(rowsHaveBeenPlaced){
			loop haveBeenPlacedRows over: rowsHaveBeenPlaced{
				if haveBeenPlacedRows in availableRowsToPlace{
					remove item: haveBeenPlacedRows from: availableRowsToPlace;
				}
			}	
		}
		if !empty(availableRowsToPlace){
			/* There is place can be placed */
			placedRow <- availableRowsToPlace[0];
			placedCell <- Chessboard[getCell(id, placedRow)];
			placedCell.occupied <- true;
			placed <- true;
			findCellToPlace <- false;
			location <- placedCell.location;
			if (id != numberOfQueens - 1){
				do start_conversation to: list(queens[id + 1]) protocol: 'fipa-contract-net' performative: 'inform' contents: ['Find your place'];	
			}
		} else{
			if (id != 0){
				do start_conversation to: list(queens[id - 1]) protocol: 'fipa-contract-net' performative: 'inform' contents: ['I cannot find any places, please replace yourself'];
			}
			/* All places are not available */
			findCellToPlace <- false;
			placed <- false;
			placedRow <- -1;
			location <- {-2.5, -2.5};
			/* Reset the list of rows that having been placed */
			rowsHaveBeenPlaced <- [];
		}
	}
	
	aspect base{
		draw square(5) at: location color: rgb('red');
	}
}

experiment assignment_3_1 type: gui {
	output{
		display map type: opengl{
			grid Chessboard border: rgb("black");
			species Queen aspect: base;
		}
	}
}