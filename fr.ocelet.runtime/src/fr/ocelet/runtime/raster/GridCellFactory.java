/*
*  Ocelet spatial modelling language.   www.ocelet.org
*  Copyright Cirad 2010-2018
*
*  This software is a domain specific programming language dedicated to writing
*  spatially explicit models and performing spatial dynamics simulations.
*
*  This software is governed by the CeCILL license under French law and
*  abiding by the rules of distribution of free software.  You can  use,
*  modify and/ or redistribute the software under the terms of the CeCILL
*  license as circulated by CEA, CNRS and INRIA at the following URL
*  "http://www.cecill.info".
*  As a counterpart to the access to the source code and  rights to copy,
*  modify and redistribute granted by the license, users are provided only
*  with a limited warranty  and the software's author,  the holder of the
*  economic rights,  and the successive licensors  have only limited
*  liability.
*  The fact that you are presently reading this means that you have had
*  knowledge of the CeCILL license and that you accept its terms.
*/
package fr.ocelet.runtime.raster;

/**
 * @author Mathieu Castets - Initial contribution
 */
public class GridCellFactory {
	
	public static GridCellManager create(String cellType, Grid grid){
		
		if(cellType.equals("HEXAGONAL")){
				return new GridHexaCellManager(grid);
		}
		if(cellType.equals("QUADRILATERAL")){
			return new GridQuadriCellManager(grid);
		}
		if(cellType.equals("TRIANGULAR")){
			return new GridTriangularCellManager(grid);
		}
		return null;
		
		}
	
	
public static GridCellManager create(Grid grid){
		String cellType = grid.getCellShapeType();
		if(cellType.equals("HEXAGONAL")){
				return new GridHexaCellManager(grid);
		}
		if(cellType.equals("QUADRILATERAL")){
			return new GridQuadriCellManager(grid);
		}
		if(cellType.equals("TRIANGULAR")){
			return new GridTriangularCellManager(grid);
		}
		return null;
		
		}
}
