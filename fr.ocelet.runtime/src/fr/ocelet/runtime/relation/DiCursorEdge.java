/*
*  Ocelet spatial modelling language.   www.ocelet.org
*  Copyright Cirad 2010-2016
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
package fr.ocelet.runtime.relation;

import com.vividsolutions.jts.geom.Coordinate;

import fr.ocelet.runtime.entity.AbstractEntity;
import fr.ocelet.runtime.geom.ocltypes.Cell;
import fr.ocelet.runtime.ocltypes.KeyMap;
import fr.ocelet.runtime.ocltypes.List;
import fr.ocelet.runtime.raster.CellAggregOperator;
import fr.ocelet.runtime.raster.Grid;
import fr.ocelet.runtime.raster.GridManager;
import fr.ocelet.runtime.raster.MultiResolutionManager;
import fr.ocelet.runtime.relation.regularedges.DiRegularCellsEdgeManager;

import java.util.*;
import java.util.concurrent.TimeUnit;

// Referenced classes of package fr.ocelet.runtime.relation:
//            OcltEdge, OcltRole, AggregOperator



public abstract class DiCursorEdge extends OcltEdge{

	private Grid globalGrid; // grid of same or lower resolution
	private Grid grid; // grid of same or higher resolution

	protected int x; // x cell value for globalGrid
	protected int y; // y cell value for globalGrid
	protected int x2; // x cell value for grid
	protected int y2; // y cell value for grid

	protected int startX; 
	protected int startY;

	protected int startX2;
	protected int startY2;

	protected int endX;
	protected int endY;

	protected int endX2;
	protected int endY2;

	protected int globalWidth;

	private int colCount = 0;
	private int currentY;

	private int mode;
	private double r1XRes;
	private double r1YRes;
	private double xRes;
	private double yRes;
	private int rXRes;
	private int rYRes;
	private OcltRole r1;
	private OcltRole r2;
	private HashMap<String, CellAggregOperator> aggregMap = new HashMap<String, CellAggregOperator>();
	private boolean equalGrid = false;
	private MultiResolutionManager mrm;
	private DiRegularCellsEdgeManager edges = new DiRegularCellsEdgeManager();

	public abstract KeyMap<String, String> getEdgeProperties();

	public void setIntegerPropertySize(int size){
		edges.setIntegerPropertySize(size, grid, globalGrid);
	}
	public void setBooleanPropertySize(int size){
		edges.setBooleanPropertySize(size, grid, globalGrid);
	}
	public void setDoublePropertySize(int size){
		edges.setDoublePropertySize(size, grid, globalGrid);
	}

	public void setDoubleProperty(int property, Double value){
		edges.setDoubleValue(x2, y2, property, value);
	}
	public void setIntegerProperty(int property, Integer value){
		edges.setIntegerValue(x2, y2, property, value);
	}
	public void setBooleanProperty(int property, Boolean value){
		edges.setBooleanValue(x2, y2, property, value);
	}

	public Double getDoubleProperty(int property){
		return edges.getDoubleValue(x2, y2, property);
	}

	public Integer getIntegerProperty(int property){
		return edges.getIntegerValue(x2, y2, property);
	}
	public Boolean getBooleanProperty(int property){
		return edges.getBooleanValue(x2, y2, property);
	}

	private void initEdgeProperty(){

		KeyMap<String, String> properties = getEdgeProperties();
		int doubleIndex = 0;
		int integerIndex = 0;
		int booleanIndex = 0;		
		for(String name : properties.keySet()){

			if(properties.get(name).equals("Double")){
				doubleIndex++;
			}
			if(properties.get(name).equals("Integer")){
				integerIndex++;
			}
			if(properties.get(name).equals("Boolean")){
				booleanIndex++;
			}
		}

		setIntegerPropertySize(integerIndex);
		setBooleanPropertySize(booleanIndex);
		setDoublePropertySize(doubleIndex);
	}
	
	private GraphBounds getGraphBounds(Grid grid1, Grid grid2){
		
				
		
		GraphBounds gBounds = new GraphBounds();
	
			Coordinate leftCornerGrid1 = grid1.gridCoordinate(0, grid1.getHeight());
			Coordinate rightCornerGrid1 = grid1.gridCoordinate(grid1.getWidth(), 0);
			Coordinate leftCornerGrid2 = grid2.gridCoordinate(0, grid2.getHeight());
			Coordinate rightCornerGrid2 = grid2.gridCoordinate(grid2.getWidth(), 0);

		
		if(grid1.getWidth() * grid1.getHeight() > grid2.getWidth() * grid2.getHeight()){ // gri1 has the finest resolution
			
			int[] grid2Temp1 = grid2.gridCoordinate(leftCornerGrid1.x, leftCornerGrid1.y);
			int[] grid2Temp2 = grid2.gridCoordinate(rightCornerGrid1.x, rightCornerGrid1.y);
			int index = 0;
			
			while(grid2Temp1 == null){
				if(index % 2 == 0){
					grid2Temp1 = grid2.gridCoordinate(leftCornerGrid1.x, leftCornerGrid1.y);
 
				}
				//grid2
			}
		}else{ //gri2 has the finest resolution
			
		}
		
		return gBounds;
		
	}
	/*public DiCursorEdge(List<? extends AbstractEntity> r1List, List<? extends AbstractEntity> r2List){
		
		AbstractEntity ae1 = (AbstractEntity)r1List.get(0);
		Cell cell1 = (Cell)ae1.getSpatialType();

		AbstractEntity ae2 = (AbstractEntity)r2List.get(0);
		Cell cell2 = (Cell)ae2.getSpatialType();

		Grid grid1 = GridManager.getInstance().get(cell1.getNumGrid());
		Grid grid2 = GridManager.getInstance().get(cell2.getNumGrid());

		
		
		
		
	}*/
	public DiCursorEdge(List<? extends AbstractEntity> r1List, List<? extends AbstractEntity> r2List){   //Grid grid1, Grid grid2){

		AbstractEntity ae1 = (AbstractEntity)r1List.get(0);
		Cell cell1 = (Cell)ae1.getSpatialType();

		AbstractEntity ae2 = (AbstractEntity)r2List.get(0);
		Cell cell2 = (Cell)ae2.getSpatialType();

		Grid grid1 = GridManager.getInstance().get(cell1.getNumGrid());
		Grid grid2 = GridManager.getInstance().get(cell2.getNumGrid());
		scalingGrids(grid1, grid2);
		
		/*Double[] grid1Bounds = grid1.getWorldBounds();
		Double[] grid2Bounds =  grid2.getWorldBounds();
		
		int[] grid1CoordMin = new int[]{0, 0};
		int[] grid1CoordMax = new int[]{grid1.getWidth() - 1, grid1.getHeight() - 1};
		int[] grid2CoordMin = new int[]{0, 0};
		int[] grid2CoordMax = new int[]{grid2.getWidth() - 1, grid2.getHeight() - 1};


		 Coordinate c1Min = grid1.gridCoordinate(grid1CoordMin[0], grid1CoordMin[1]);
		 Coordinate c1Max = grid1.gridCoordinate(grid1CoordMax[0], grid1CoordMax[1]);
		 
		 Coordinate c2Min = grid2.gridCoordinate(grid2CoordMin[0], grid2CoordMin[1]);
		 Coordinate c2Max = grid2.gridCoordinate(grid2CoordMax[0], grid2CoordMax[1]);

		 grid1Bounds = new Double[]{c1Min.x,c1Max.y, c1Max.x, c1Min.y};
		 grid2Bounds = new Double[]{c2Min.x,c2Max.y, c2Max.x, c2Min.y};
		 
		double[] scaled = scalingdouble(grid1Bounds, grid2Bounds);

		int[] grid1Min = grid1.gridCoordinate(scaled[0],scaled[3]);
		int[] grid1Max = grid1.gridCoordinate(scaled[2],scaled[1]);

		int[] grid2Min = grid2.gridCoordinate(scaled[0],scaled[3]);
		int[] grid2Max = grid2.gridCoordinate(scaled[2],scaled[1]);

		if(grid1Min[0] < 0)
			grid1Min[0] = 0;
		if(grid1Min[1] < 0)
			grid1Min[1] = 0;

		if(grid2Min[0] < 0)
			grid2Min[0] = 0;
		if(grid2Min[1] < 0)
			grid2Min[1] = 0;

		c1Min = grid1.gridCoordinate(grid1Min[0], grid1Min[1]);
		c1Max = grid1.gridCoordinate(grid1Max[0], grid1Max[1]);

		c2Min = grid2.gridCoordinate(grid2Min[0], grid2Min[1]);
		c2Max = grid2.gridCoordinate(grid2Max[0], grid2Max[1]);

		Double[] newgrid1Bounds = new Double[]{c1Min.x, c1Max.y, c1Max.x, c1Min.y};
		Double[] newgrid2Bounds = new Double[]{c2Min.x, c2Max.y, c2Max.x, c2Min.y};
		scaled = scalingdouble(newgrid1Bounds, newgrid2Bounds);

		grid1Min = grid1.gridCoordinate(scaled[0],scaled[3]);
		grid1Max = grid1.gridCoordinate(scaled[2],scaled[1]);

		grid2Min = grid2.gridCoordinate(scaled[0],scaled[3]);
		grid2Max = grid2.gridCoordinate(scaled[2],scaled[1]);



		//if(grid1.getWidth() == grid2.getWidth() && grid1.getHeight() == grid2.getHeight() ) {
		if(1 > 2 ) {
			globalGrid = grid1;
			startX = 0;
			startY = 0;
			endX = grid1.getWidth();
			endY = grid1.getHeight();
			grid = grid2;
			startX2 = 0;
			startY2 = 0;
			endX2 = grid2.getWidth();
			endY2 = grid2.getHeight();

			equalGrid = true;
			x = startX;
			y = startY;
			x2 = startX2;
			y2 = startY2;       


		}else{
			
			//if(grid1.getWidth() < grid2.getWidth()){        
			if(grid1.getWidth() * grid1.getHeight() < grid2.getWidth() * grid2.getHeight()){  
				globalGrid = grid1;
				grid = grid2;

				if(grid1Min == null){
					startX = 0;
					startY = 0;
				}else{
					startX = grid1Min[0];
					startY = grid1Min[1];

				}
				if(grid1Max == null){
					endX = grid1.getWidth()-1;
					endY = grid1.getHeight()-1;
				}else{
					endX = grid1Max[0];
					endY = grid1Max[1];

				}
				if(grid2Min == null){
					startX2 = 0;
					startY2 = 0;
				}else{
					startX2 = grid2Min[0];
					startY2 = grid2Min[1];
				}
				if(grid2Max == null){
					endX2 = grid2.getWidth()-1;
					endY2 = grid2.getHeight()-1;
				}else{
					endX2 = grid2Max[0];
					endY2 = grid2Max[1];
				}

			} else {


				globalGrid = grid2;

				grid = grid1;

				if(grid2Min == null){
					startX = 0;
					startY = 0;
				}else{
					startX = grid2Min[0];
					startY = grid2Min[1];

				}
				if(grid2Max == null){
					endX = grid2.getWidth()- 1;
					endY = grid2.getHeight() - 1;
				}else{
					endX = grid2Max[0];
					endY = grid2Max[1];

				}
				if(grid1Min == null){
					startX2 = 0;
					startY2 = 0;
				}else{
					startX2 = grid1Min[0];
					startY2 = grid1Min[1];
				}
				if(grid1Max == null){
					endX2 = grid1.getWidth() - 1;
					endY2 = grid1.getHeight() - 1;
				}else{
					endX2 = grid1Max[0];
					endY2 = grid1Max[1];


				}

			}


		}
		 //rescale();

		equalGrid = false;
		x = startX;
		y = startY;
		x2 = -1;
		y2 = -1;
		currentY = startY;
		colCount = startX2;
		initEdgeProperty();*/

	}

	private void rescale(){
		if(startX < 0){
			startX = 0;
		}
		if(startY < 0){
			startY = 0;
		}
		if(startY2 < 0){
			startY2 = 0;
		}
		if(startX2 < 0){
			startX2 = 0;
		}
		if(endX > globalGrid.getWidth()){
			endX = globalGrid.getWidth();
		}
		if(endY > globalGrid.getHeight()){
			endY = globalGrid.getHeight();
		}

		if(endX2 > grid.getWidth()){
			endX2 = grid.getWidth();
		}

		if(endY2 > grid.getHeight()){
			endY2 = grid.getHeight();
		}
	}
	protected String getCellType(){
		return null;
	}
	public void updateRoleInfo(){	

		Cell cell1 = (Cell)getRole(new Integer(0)).getSpatialType();
		int numGrid = ((Cell)getRole(new Integer(0)).getSpatialType()).getNumGrid();
		cell1.setType(GridManager.getInstance().get(numGrid).getCellShapeType());

		Cell cell2 = (Cell)getRole(new Integer(1)).getSpatialType();
		int numGrid2 = ((Cell)getRole(new Integer(1)).getSpatialType()).getNumGrid();
		cell2.setType(GridManager.getInstance().get(numGrid2).getCellShapeType());


		if ( GridManager.getInstance().get(numGrid).equals(globalGrid)){
			r1 = getRole(new Integer(0));
			r2 = getRole(new Integer(1));

		}else{
			r1 = getRole(new Integer(1));
			r2 = getRole(new Integer(0));

		}
	}

	public void updateGrid(){

		if(equalGrid){
			globalGrid.setMode(1);
			grid.setMode(1);
		} else {

			globalGrid.setMode(4);
			grid.setMode(1);
		}


	}





	public abstract OcltRole getRole(Integer i);



	public OcltRole getRole(int i){
		return null;
	}

	public boolean hasNext(){

		if(equalGrid){
			if(x == endX - 1 && y == endY){

				x = startX;
				y = startY;
				x2 = -1;
				y2 = -1;

				return false;
			} else {            
				return true;
			}
		}
		if((x2 == endX2 && y2 == endY2)){// || (x == endX && y == endY)){

			//globalSynchronisation();
			finalSynchronisation();
			clearAggregMap();
			//System.out.println("END CURSOR");
			currentY = startY;
			x2 = -1;
			y2 = -1;
			x = startX;
			y = startY;
			//	globalGrid.cleanOperator();
			return false;
		}

		return true; 
	}



	public void next(){
		/*System.out.println("TYPE "+equalGrid);
		System.out.println(globalGrid.getWidth()+" "+globalGrid.getHeight());
		System.out.println("GLOBAL "+startX+" "+startY+" "+endX+" "+endY);
		System.out.println(grid.getWidth()+" "+grid.getHeight());
		System.out.println("LESSER "+startX2+" "+startY2+" "+endX2+" "+endY2);*/

		//System.out.println(grid.getWidth()+" "+grid.getHeight()+"  "+globalGrid.getWidth()+"   "+globalGrid.getHeight());
		//System.out.println(x+"  "+y+"  "+x2+" "+y2);
		if(equalGrid){

			if(x2 == -1 && y2 == -1){

				x2 = startX2;
				y2 = startY2;

			} else  if(x == endX - 1){        
				x = startX;
				y++;
				x2 = startX2;
				y2++;

			} else {

				x++;
				x2++;
			}

		}else{

			if(x2 == -1 && y2 == -1){
				globalGrid.initMrm(startX, endX, currentY);
				mrm = globalGrid.getMrm();
				x2 = startX2;
				y2 = startY2;
				x = startX;
				y = startY;
				currentY = startY;
			}else{

				if(x2 == endX2){

					x2 = startX2;
					y2++;

					//Coordinate c = grid.gridCoordinate(x2, y2);
					//int[] c2 = globalGrid.gridCoordinate(c.x, c.y);
					//System.out.println(colCount);
					if(colCount == endX2){
						
						globalSynchronisation();
						//y = c2[1];
						y = currentY + 1;
						mrm.switchLine();
						currentY ++;
						x = startX;
						colCount = startX2;
						
						Coordinate c = null;
						int[] c2 = null;
						try{
							c = grid.gridCoordinate(x2, y2);
							c2 = globalGrid.gridCoordinate(c.x, c.y);
						}catch(Exception e) {
							
						}
						//colCount++;

						//System.out.println(x+" "+y+" "+x2+" "+y2+" " +colCount);

						if(c2 != null){
							x = c2[0];
							y = c2[1];
						
							if(y == currentY + 1 || y == currentY + 2){
								colCount++;

								//System.out.print("  "+colCount);
							}


							//System.out.println(x + " "+y);
						}else{
							/*if(y != currentY + 1 && y != currentY + 2){

							colCount++;
						}*/
							if(y == currentY + 1 || y == currentY + 2){

								colCount++;

								//System.out.print("  "+colCount);
							}
							if(hasNext()){
								next();
							}else{
								x2 = endX2;
								y2 = endY2;
							}
						}
						//System.out.println("Sync "+currentY+" "+y);

					}else{
						Coordinate c = null;
						int[] c2 = null;
						try{
							c = grid.gridCoordinate(x2, y2);
							c2 = globalGrid.gridCoordinate(c.x, c.y);
						}catch(Exception e) {
							
						}
						//colCount++;

						//System.out.println(x+" "+y+" "+x2+" "+y2+" " +colCount);

						if(c2 != null){
							x = c2[0];
							y = c2[1];
						
							if(y == currentY + 1 || y == currentY + 2){
								colCount++;

								//System.out.print("  "+colCount);
							}


							//System.out.println(x + " "+y);
						}else{
							/*if(y != currentY + 1 && y != currentY + 2){

							colCount++;
						}*/
							if(y == currentY + 1 || y == currentY + 2){

								colCount++;

								//System.out.print("  "+colCount);
							}
							if(hasNext()){
								next();
							}else{
								x2 = endX2;
								y2 = endY2;
							}
						}
					}
					/*if(c2 != null){
						if(c2[1] > y + 0.75){
						globalSynchronisation();
						//y = c2[1];
						y = y + 1;
						mrm.switchLine();
					}
					}*/

					colCount = startX2;

					//x = startX;

				}else{
					x2++;
					//System.out.println("coord px "+x2 + " "+y2);
					Coordinate c = null;
					int[] c2 = null;
					try{
						c = grid.gridCoordinate(x2, y2);
						c2 = globalGrid.gridCoordinate(c.x, c.y);
					}catch(Exception e) {
						
					}
					//System.out.println(c);
					
					//colCount++;

					//System.out.println(x+" "+y+" "+x2+" "+y2+" " +colCount);

					if(c2 != null){
						x = c2[0];
						y = c2[1];
						
						if(y == currentY + 1 || y ==currentY + 2){

							colCount++;
						}
						//System.out.println(x + " "+y);
					}else{
						/*if(y != currentY + 1 && y != currentY + 2){

							colCount++;
						}*/
						if(y == currentY + 1 || y == currentY + 2){

							colCount++;
						}
						if(hasNext()){
							next();
						}else{
							x2 = endX2;
							y2 = endY2;
						}
					}
				}
			}
			/*try {
				TimeUnit.MILLISECONDS.sleep(20);
				System.out.println(x+" "+y+" "+x2+" "+y2);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}*/
			//System.out.println(x2+" "+y2+" "+x+" "+y);


		}
		//System.out.println(x+" "+y+" "+x2+" "+y2+" moving "+currentY+" "+colCount);
		updateBis();
	}




	private double[] scalingdouble(Double[] bounds1, Double[] bounds2){

		double[] scaled = new double[4];

		if(bounds1[0] - (grid.getXRes() / 2) < bounds2[0] - (globalGrid.getXRes() / 2) ){
			scaled[0]  = bounds2[0] - (globalGrid.getXRes() / 2);
		}else{
			scaled[0] = bounds1[0] - (grid.getXRes() / 2);

		}
		if(bounds1[1] - (grid.getYRes() / 2) < bounds2[1] - (globalGrid.getYRes() / 2)){
			scaled[1] = bounds2[1] - (globalGrid.getYRes() / 2);
		}else{
			scaled[1] = bounds1[1] - (grid.getYRes() / 2);

		}

		if(bounds1[2] + (grid.getXRes() / 2) > bounds2[2] + (globalGrid.getXRes() / 2)){
			scaled[2] = bounds2[2] + (globalGrid.getXRes() / 2);
		}else{
			scaled[2] = bounds1[2] + (grid.getXRes() / 2);

		}
		if(bounds1[3] + (grid.getYRes() / 2) > bounds2[3] + (globalGrid.getYRes() / 2)){
			scaled[3] = bounds2[3] + (globalGrid.getYRes() / 2);
		}else{
			scaled[3] = bounds1[3] + (grid.getYRes() / 2);

		}
		
		
		
		return scaled;
	}


	public abstract void update();

	public void updateBis(){


		((Cell)r1.getSpatialType()).setX(x);
		((Cell)r1.getSpatialType()).setY(y);
		((Cell)r2.getSpatialType()).setX(x2);
		((Cell)r2.getSpatialType()).setY(y2);

	}

	public void clearAggregMap(){    
		aggregMap.clear();
	}

	public void addOperator(String name, CellAggregOperator operator){    
		aggregMap.put(name, operator);
	}

	public void setCellOperator(String name, AggregOperator operator, KeyMap<String, String> typeProps)
	{
		CellAggregOperator cao = new CellAggregOperator();
		if(typeProps.get(name).equals("Double")){
			setAggregOpDouble(name, operator, false);
		}else if(typeProps.get(name).equals("Integer")){
			setAggregOpInteger(name, operator, false);

		}else if(typeProps.get(name).equals("Float")){
			setAggregOpFloat(name, operator, false);

		}else if(typeProps.get(name).equals("Byte")){
			setAggregOpByte(name, operator, false);

		}else if(typeProps.get(name).equals("Boolean")){
			setAggregOpBoolean(name, operator, false);

		}
	}
	public void setAggregOpDouble(String name, AggregOperator<Double, List<Double>> agg, boolean val){
		CellAggregOperator cao = new CellAggregOperator();
		cao.setOperatorDouble(agg);
		aggregMap.put(name, cao);

	}
	public void setAggregOpInteger(String name, AggregOperator<Integer, List<Integer>> agg, boolean val){
		CellAggregOperator cao = new CellAggregOperator();
		cao.setOperatorInteger(agg);
		aggregMap.put(name, cao);

	}

	public void setAggregOpFloat(String name, AggregOperator<Float, List<Float>> agg, boolean val){
		CellAggregOperator cao = new CellAggregOperator();
		cao.setOperatorFloat(agg);
		aggregMap.put(name, cao);
	}

	public void setAggregOpByte(String name, AggregOperator<Byte, List<Byte>> agg, boolean val){
		CellAggregOperator cao = new CellAggregOperator();
		cao.setOperatorByte(agg);
		aggregMap.put(name, cao);
	}

	public void setAggregOpBoolean(String name, AggregOperator<Boolean, List<Boolean>> agg, boolean val){
		CellAggregOperator cao = new CellAggregOperator();
		cao.setOperatorBoolean(agg);
		aggregMap.put(name, cao);
	}
	public void globalSynchronisation(){
		try{
			for(int i = startX; i < endX; i ++){

				CellValues cv = mrm.getFirstLineValue(i); 
				for(String name : mrm.getProperties()){

					List<Double> values  =cv.getValues(name);
					if(!values.isEmpty()){

						if(aggregMap.keySet().contains(name)){

							CellAggregOperator cao = aggregMap.get(name);   
							Double d;
							if(cao.preval() == false){
								d = cao.apply(values, null);
							}else{
								d = cao.apply(values, globalGrid.getDoubleValue(name, i, currentY));
							}
							globalGrid.setCellValue(name, i, currentY, d);

						} else{

							globalGrid.setCellValue(name, i, currentY, values.get((int)(Math.random() * values.size())));
						}
					}
					cv.clear(name);
				}

			}
		}catch(Exception e){
			e.printStackTrace();
		}
	}

	public void finalSynchronisation(){
		try{
			for(int i = startX; i < endX; i ++){

				CellValues cv = mrm.getFirstLineValue(i); 
				for(String name : mrm.getProperties()){

					List<Double> values  =cv.getValues(name);
					if(!values.isEmpty()){

						// .println("Size "+i+" "+y+" "+ values.size() +" "+name);
						if(aggregMap.keySet().contains(name)){

							CellAggregOperator cao = aggregMap.get(name);   
							Double d;
							if(cao.preval() == false){
								d = cao.apply(values, null);
							}else{
								d = cao.apply(values, globalGrid.getDoubleValue(name, i, currentY));
							}
							globalGrid.setCellValue(name, i, currentY, d);
							//   globalGrid.cleanOperator();

						} else{

							globalGrid.setCellValue(name, i, currentY, values.get((int)(Math.random() * values.size())));
							//globalGrid.clearGeomTempVal();
						}
					}
					cv.clear(name);
					//  CellValues v = mrm.get(globalGrid.getWidth());
					// v.clear(name);
				}

				cv = mrm.getSecondLineValue(i); 
				for(String name : mrm.getProperties()){

					List<Double> values  =cv.getValues(name);
					if(!values.isEmpty()){

						// .println("Size "+i+" "+y+" "+ values.size() +" "+name);
						if(aggregMap.keySet().contains(name)){

							CellAggregOperator cao = aggregMap.get(name);   
							Double d;
							if(cao.preval() == false){
								d = cao.apply(values, null);
							}else{
								d = cao.apply(values, globalGrid.getDoubleValue(name, i, currentY + 1));
							}
							globalGrid.setCellValue(name, i, currentY + 1, d);
							//   globalGrid.cleanOperator();

						} else{

							globalGrid.setCellValue(name, i, currentY + 1, values.get((int)(Math.random() * values.size())));
							//globalGrid.clearGeomTempVal();
						}
					}
					cv.clear(name);
					//  CellValues v = mrm.get(globalGrid.getWidth());
					// v.clear(name);
				}

				cv = mrm.getThirdLineValue(i); 
				for(String name : mrm.getProperties()){

					List<Double> values  =cv.getValues(name);
					if(!values.isEmpty()){

						// .println("Size "+i+" "+y+" "+ values.size() +" "+name);
						if(aggregMap.keySet().contains(name)){

							CellAggregOperator cao = aggregMap.get(name);   
							Double d;
							if(cao.preval() == false){
								d = cao.apply(values, null);
							}else{
								d = cao.apply(values, globalGrid.getDoubleValue(name, i, currentY + 2));
							}
							globalGrid.setCellValue(name, i, currentY + 2, d);
							//   globalGrid.cleanOperator();

						} else{

							globalGrid.setCellValue(name, i, currentY + 2, values.get((int)(Math.random() * values.size())));
							//globalGrid.clearGeomTempVal();
						}
					}
					cv.clear(name);
					//  CellValues v = mrm.get(globalGrid.getWidth());
					// v.clear(name);
				}

			}
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	public class GraphBounds{
		
		
		public int startX;
		public int startX2;
		public int startY;
		public int startY2;
		public int endX;
		public int endX2;
		public int endY;
		public int endY2;
		
		
		public GraphBounds(){
			
		}
		public void setBounds(int startX, int startY, int endX, int endY, int startX2, int startY2, int endX2, int endY2){
			
			this.startX = startX;
			this.startY = startY;
			this.endX = endX;
			this.endY = endY;
			
			this.startX2 = startX2;
			this.startY2 = startY2;
			this.endX2 = endX2;
			this.endY2 = endY2;
		}

		
		public GraphBounds(int startX, int startY, int endX, int endY, int startX2, int startY2, int endX2, int endY2){
			
			this.startX = startX;
			this.startY = startY;
			this.endX = endX;
			this.endY = endY;
			
			this.startX2 = startX2;
			this.startY2 = startY2;
			this.endX2 = endX2;
			this.endY2 = endY2;
		}
		
		@Override
		public String toString(){
			return startX+" "+endX+" "+startY+" "+endY+" "+startX2+" "+endX2+" "+startY+" "+startY2;
		
	}
}

	/*
	 * Return cells grids first and last grids coordinates that can spatially match
	 * Set the grid with the finest resolution as grid and the lowest as globalGrid
	 */
	private void scalingGrids(Grid grid1, Grid grid2) {
	
		
		if(grid1.getWidth() * grid1.getHeight() < grid2.getWidth() * grid2.getHeight()){ 
			globalGrid = grid1;
			grid = grid2;

	
		}else {
			globalGrid = grid2;
			grid = grid1;
		}
		
		
		
		int minGridX = 0;
		int minGridY = 0;
		int minGlobalX = 0;
		int minGlobalY = 0;
		int maxGridX = grid.getWidth() - 1;
		int maxGridY = grid.getHeight() - 1;
		int maxGlobalX = globalGrid.getWidth() - 1;
		int maxGlobalY = globalGrid.getHeight() - 1;
		
 		Coordinate upperLeftGrid = grid.gridCoordinate(minGridX, minGridY);
		Coordinate downRightGrid = grid.gridCoordinate(maxGridX, maxGridY);
		
		Coordinate upperLeftGlobal = globalGrid.gridCoordinate(minGlobalX, minGlobalY);
		Coordinate downRightGlobal = globalGrid.gridCoordinate(maxGlobalX, maxGlobalY);
		
		int[] minUpper = grid.gridCoordinate(upperLeftGrid.x, upperLeftGrid.y);
	
		
		/*int[] globalToGridUpperLeft = globalGrid.gridCoordinate(upperLeftGrid.x, upperLeftGrid.y);
		int[] globalToGridDownRight = globalGrid.gridCoordinate(downRightGrid.x, downRightGrid.y);
		
		int[] gridToGlobalUpperLeft = grid.gridCoordinate(upperLeftGlobal.x, upperLeftGlobal.y);
		int[] gridToGlobalDownRight = grid.gridCoordinate(downRightGlobal.x, downRightGlobal.y);*/
		
		Double[] gridBounds = new Double[]{upperLeftGrid.x, downRightGrid.y, downRightGrid.x, upperLeftGrid.y};
		Double[] globalBounds = new Double[]{upperLeftGlobal.x, downRightGlobal.y, downRightGlobal.x, upperLeftGlobal.y};
		 
		double[] scaled = scalingdouble(gridBounds, globalBounds);
		
		double xResFactor = 0.0;
		double yResFactor = 0.0;
		double precision = 1.0;
		if(grid.getXRes() == globalGrid.getXRes()) {
			xResFactor = (grid.getXRes() * precision) / 2;
			
		}else {
			if(grid.getXRes() < globalGrid.getXRes()) {
				xResFactor = (grid.getXRes() * precision) / 2; 
			}else {
				xResFactor = (globalGrid.getXRes() * precision) / 2;
 			}
		}
		
		if(grid.getYRes() == globalGrid.getYRes()) {
			yResFactor = (grid.getYRes() * precision) / 2;
			
		}else {
			if(grid.getYRes() < globalGrid.getYRes()) {
				yResFactor = (grid.getYRes() * precision) / 2; 
			}else {
				yResFactor = (globalGrid.getYRes() * precision) / 2;
 			}
		}
		
		
		
		
		double factorX = xResFactor;
		double factorY = yResFactor;
		
		int[] gridMin = grid.gridCoordinate(scaled[0] + factorX, scaled[3] - factorY);
		while(gridMin == null) {
			factorX = factorX + xResFactor;
			factorY = factorY + yResFactor;
			gridMin = grid.gridCoordinate(scaled[0] + factorX, scaled[3] - factorY);
		}
		 factorX = xResFactor;
		 factorY = yResFactor;
		int[] gridMax = grid.gridCoordinate(scaled[2] - factorX, scaled[1] + factorY);
		while(gridMax == null) {
			factorX = factorX + xResFactor;
			factorY = factorY + yResFactor;
			gridMax = grid.gridCoordinate(scaled[2] - factorX, scaled[1] + factorY);
		}
		factorX = xResFactor;
		 factorY = yResFactor;
		int[] globalMin = globalGrid.gridCoordinate(scaled[0] +factorX, scaled[3] - factorY);
		while(gridMax == null) {
			factorX = factorX + xResFactor;
			factorY = factorY + yResFactor;
			globalMin = globalGrid.gridCoordinate(scaled[0] + factorX, scaled[3] - factorY);
		}
		factorX = xResFactor;
		 factorY = yResFactor;
		int[] globalMax = globalGrid.gridCoordinate(scaled[2] - factorX, scaled[1] + factorY);
		while(gridMax == null) {
			factorX = factorX + xResFactor;
			factorY = factorY + yResFactor;
			globalMax = globalGrid.gridCoordinate(scaled[2] - factorX, scaled[1] + factorY);
		}
		
		if(globalMin == null){
			startX = 0;
			startY = 0;
		}else{
			startX = globalMin[0];
			startY = globalMin[1];

		}
		if(globalMax == null){
			endX = globalGrid.getWidth()-1;
			endY = globalGrid.getHeight()-1;
		}else{
			endX = globalMax[0];
			endY = globalMax[1];

		}
		if(gridMin == null){
			startX2 = 0;
			startY2 = 0;
		}else{
			startX2 = gridMin[0];
			startY2 = gridMin[1];
		}
		if(gridMax == null){
			endX2 = grid.getWidth()-1;
			endY2 = grid.getHeight()-1;
		}else{
			endX2 = gridMax[0];
			endY2 = gridMax[1];
		}
		
		equalGrid = false;
		x = startX;
		y = startY;
		x2 = -1;
		y2 = -1;
		currentY = startY;
		colCount = startX2;
		initEdgeProperty();
	}

}
	