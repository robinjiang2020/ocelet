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
package fr.ocelet.lang.jvmmodel

import com.google.inject.Inject
import fr.ocelet.lang.ocelet.Agregdef
import fr.ocelet.lang.ocelet.ConstructorDef
import fr.ocelet.lang.ocelet.Datafacer
import fr.ocelet.lang.ocelet.Entity
import fr.ocelet.lang.ocelet.Filterdef
import fr.ocelet.lang.ocelet.InteractionDef
import fr.ocelet.lang.ocelet.Metadata
import fr.ocelet.lang.ocelet.Model
import fr.ocelet.lang.ocelet.Paradesc
import fr.ocelet.lang.ocelet.Paramdefa
import fr.ocelet.lang.ocelet.Paramunit
import fr.ocelet.lang.ocelet.Paraopt
import fr.ocelet.lang.ocelet.PropertyDef
import fr.ocelet.lang.ocelet.Rangevals
import fr.ocelet.lang.ocelet.RelPropertyDef
import fr.ocelet.lang.ocelet.Relation
import fr.ocelet.lang.ocelet.Scenario
import fr.ocelet.lang.ocelet.ServiceDef
import fr.ocelet.lang.ocelet.StrucFuncDef
import fr.ocelet.lang.ocelet.StrucVarDef
import fr.ocelet.lang.ocelet.Strucdef
import java.util.HashMap
import java.util.List
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.common.types.JvmTypeParameter
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.TypesFactory
import org.eclipse.xtext.common.types.util.Primitives
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XAssignment
import java.util.ArrayList
import org.eclipse.xtext.xbase.XMemberFeatureCall
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.impl.XMemberFeatureCallImplCustom
import org.eclipse.xtext.xbase.jvmmodel.JvmAnnotationReferenceBuilder

/**
 * Java code inferrer of the Ocelet language
 * 
 * @author Pascal Degenne - Initial contribution
 * @author Mathieu Castets - Raster related code generator
 */
class OceletJvmModelInferrer extends AbstractModelInferrer {

  @Inject extension JvmTypesBuilder
  @Inject extension JvmAnnotationReferenceBuilder

  @Inject extension IQualifiedNameProvider
  @Inject OceletCompiler ocltCompiler
  // Used to wrap primtive types to their corresponding java classes when needed.
  @Inject extension Primitives
  
  def dispatch void infer(Model modl, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
    val List<Scenario> scens = newArrayList()
    val Metadatastuff md = new Metadatastuff();
    var boolean mainScen = false

    // ---- Récupération du nom du modèle ----
    val Resource res = modl.eResource();
    val modlName = res.getURI.segment(1)
    if(modl.getName() === null) modl.setName("fr.ocelet.model."+ modlName.toLowerCase());
    val packg = modl.getName()+"."
  
    // ---- Remplissage de la liste des scenarios et repérage du main ----
    for(meln:modl.modelns) {
  	  try {
        switch(meln) {
          Scenario : { 
              if (meln.name.compareTo(modlName) == 0) mainScen = true
     	      scens.add(meln)
            }
            
      // ---- Metadata ------------------------------------
          Metadata : {
            if (meln.paramdefs !== null) {          	
          	  md.setModeldesc(meln.desc)
          	  md.setWebpage(meln.webp)
          	  for (paramdef:meln.paramdefs) {
          	    val pst = new Parameterstuff(paramdef.name,paramdef.ptype)
          	    for(ppart:paramdef.paramparts) {
          		  switch(ppart) {
          		    Paramunit : {pst.setUnit(ppart.parunit)}
          		    Paramdefa : {pst.setDefvalue(ppart.pardefa)}
          		    Rangevals : {pst.setMin(ppart.parmin); pst.setMax(ppart.parmax)}
          		    Paradesc : {pst.setDescription(ppart.pardesc)}
          		    Paraopt : {pst.setOptionnal((ppart.paropt.compareToIgnoreCase("true") == 0))}
          	      }
          	    }
                md.params.add(pst)
              }
            }
          }
          
// ---- Datafacer ----------------------------------
          Datafacer : {
          	acceptor.accept(modl.toClass(meln.fullyQualifiedName)) [
          	  superTypes += typeRef('fr.ocelet.datafacer.ocltypes.'+meln.storetype)
          	  members+= meln.toConstructor[
                body = [
                  append('''super(''')
                  var int carg=0
                  for (arg:meln.arguments) {
                	if (carg > 0) append(''',''')
                	ocltCompiler.compileDatafacerParamExpression(arg,it)
//                	  append('''«arg»''')
                	carg = carg+1
                  }
                append(''');''')
              ]
     		]
     		
     		// Generates a set of functions for every match definition
     		// We have to add .simpleName to every type we need to generate
     		// don't know why so far ! ... but it works.
          	var isFirst = true
          	for(matchdef:meln.matchbox){
     		  val mt = matchdef.mtype
     		  if (mt !== null) switch (mt) {
     		    Entity : {
     		  	  val entype = typeRef(mt.fullyQualifiedName.toString)
                  val entname = mt.name.toFirstUpper
                  val listype = typeRef('fr.ocelet.runtime.ocltypes.List',entype)
                  val propmap = new HashMap<String,String>()
                  val propmapf = new HashMap<String,String>()
                  for(eprop:mt.entelns) {
                  	switch(eprop) {
                  	  PropertyDef : {
                  		if (eprop.type !== null) {
                  		  propmap.put(eprop.name,eprop.type.simpleName) 
                  		  propmapf.put(eprop.name,eprop.type.qualifiedName)
                  		}	
                  	  }
                  	}
                  }

  				  if ('RasterFile'.equals(''+meln.storetype)) { 
                    // if (Class::forName('fr.ocelet.datafacer.RasterFile').isAssignableFrom(Class::forName('fr.ocelet.datafacer.ocltypes.'+meln.storetype))) {
				    //val tabType = typeRef('fr.ocelet.runtime.ocltypes.List','fr.ocelet.runtime.raster.Grid')
                 	
                 	val tabType = typeRef('fr.ocelet.runtime.ocltypes.List',entype)
                  	members += meln.toMethod('readAll'+entname,tabType)[
                  	  body='''
						«entname» entity = new «entname»();
						«FOR mp:matchdef.matchprops»
						«val eproptype = propmap.get(mp.prop)»
						«IF eproptype !== null»
						«IF mp.colname !== null»
						addProperty("«mp.prop»",«mp.colname»);
						«ENDIF»
						«ENDIF»
                  	  	«ENDFOR»
						this.grid = createGrid(entity.getProps(), "«entname»");
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						List<«entname»> entityList = new List<«entname»>();
						entityList.cellCut();
						entityList.add(entity);
						
						return entityList;
                  	  '''
                  	]                  	
                  	
                   	members += meln.toMethod('readAll'+entname,tabType)[
                  	  parameters += meln.toParameter('shp', typeRef('fr.ocelet.datafacer.ocltypes.Shapefile'))
                  	  body='''
                  	    «entname» entity = new «entname»();
						«FOR mp:matchdef.matchprops»
						«val eproptype = propmap.get(mp.prop)»
						«IF eproptype !== null»
						«IF mp.colname !== null»
						addProperty("«mp.prop»",«mp.colname»);
						«ENDIF»
						«ENDIF»
                  	    «ENDFOR»
						this.grid = createGrid(entity.getProps(), shp, 	"«entname»");
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						List<«entname»> entityList = new List<«entname»>();
						entityList.cellCut();
						entityList.add(entity);
						return entityList;
                      '''
                    ]
                    
                    members += meln.toMethod('readAll'+entname,tabType)[
                  	parameters += meln.toParameter('geometry',  typeRef('com.vividsolutions.jts.geom.Geometry'))
                  	body='''
						«entname» entity = new «entname»();
						«FOR mp:matchdef.matchprops»
						«val eproptype = propmap.get(mp.prop)»
						«IF eproptype !== null»
						«IF mp.colname !== null»
						addProperty("«mp.prop»",«mp.colname»);
						«ENDIF»
						«ENDIF»
						«ENDFOR»
						this.grid = createGrid(entity.getProps(), geometry, 	"«entname»");
						entity.updateCellInfo("QUADRILATERAL");
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						List<«entname»> entityList = new List<«entname»>();
						entityList.cellCut();
						entityList.add(entity);
						return entityList;
                    '''
                  ]
                } else {
                  // InputDatafacer functions
                  if (Class::forName('fr.ocelet.datafacer.InputDatafacer').isAssignableFrom(Class::forName('fr.ocelet.datafacer.ocltypes.'+meln.storetype))) {
                  	val inputRecordType = typeRef('fr.ocelet.datafacer.InputDataRecord')
                  	members += meln.toMethod('readAll'+entname,listype) [
                  	  body='''
                  	    List<«entname»> _elist = new List<«entname»>();
                  	    for («inputRecordType» _record : this) {
                  	      _elist.add(create«entname»FromRecord(_record));
                  	     }
                  	    resetIterator();
                  	    return _elist;
                  	  '''
                  	]
                  	
                  	if (isFirst) {
                  	  members += meln.toMethod('readAll',listype)[
                  	    body = '''return readAll«entname»();'''
                  	  ]
                  	}
                  	
                  	members += meln.toMethod('create'+entname+'FromRecord',entype) [
                  	  parameters += meln.toParameter('_rec', typeRef('fr.ocelet.datafacer.InputDataRecord'))
                  	  body = '''
                  	    «entname» _entity = new «entname»();
                  	  	«FOR mp:matchdef.matchprops»
                  	  	  «val eproptype = propmap.get(mp.prop)»
                  	  	  «IF eproptype !== null»
                  	  	    «IF mp.colname !== null»_entity.setProperty("«mp.prop»",read«eproptype»("«mp.colname»"));«ENDIF»
                  	  	  «ENDIF»
                  	  	«ENDFOR»
                  	  	return _entity;
                  	  '''
                  	]
                  	
                  	val hmtype = typeRef('java.util.LinkedHashMap',typeRef('java.lang.String'),typeRef('java.lang.String'))
                  	members += meln.toMethod('getMatchdef',hmtype) [
                  	  body = '''
                  	    «hmtype.simpleName» hm = new «hmtype»();
                 	  	«FOR mp:matchdef.matchprops»
                  	  	  «val epropftype = propmapf.get(mp.prop)»
                 	  	  «IF epropftype !== null»
                  	  	    «IF mp.colname !== null»hm.put("«mp.colname»","«epropftype»");«ENDIF»
                  	  	  «ENDIF»
                  	  	«ENDFOR»
                  	    return hm;
                  	  '''
                  	]
                  }

                  if (Class::forName('fr.ocelet.datafacer.FiltrableDatafacer').isAssignableFrom(Class::forName('fr.ocelet.datafacer.ocltypes.'+meln.storetype))) {
                    members += meln.toMethod('readFiltered'+entname,listype)[
                    parameters += meln.toParameter('_filt', typeRef('java.lang.String'))
                    body = '''
                 	  setFilter(_filt);
                 	  return readAll«entname»();
                 	'''
                  ]
                }

                 // OutputDatafacer functions
                if (Class::forName('fr.ocelet.datafacer.OutputDatafacer').isAssignableFrom(Class::forName('fr.ocelet.datafacer.ocltypes.'+meln.storetype))) {
                  members += meln.toMethod('createRecord',typeRef('fr.ocelet.datafacer.OutputDataRecord')) [
                    parameters += meln.toParameter('ety',typeRef('fr.ocelet.runtime.entity.Entity'))
                    exceptions += typeRef('java.lang.IllegalArgumentException')
                    body = '''
						«val odrtype = typeRef('fr.ocelet.datafacer.OutputDataRecord')»
						«odrtype» odr = createOutputDataRec();
						if (odr != null) {
						«FOR mp:matchdef.matchprops»
							odr.setAttribute("«mp.colname»",((«entname») ety).get«mp.prop.toFirstUpper»());
						«ENDFOR»
						}
						return odr;
                    '''
                  ]
                }
                 
                if (Class::forName('fr.ocelet.datafacer.ocltypes.Csvfile').isAssignableFrom(Class::forName('fr.ocelet.datafacer.ocltypes.'+meln.storetype))) {
                  members += meln.toMethod('headerString',typeRef('java.lang.String')) [
                    body = '''
                      StringBuffer sb = new StringBuffer();
                      «var coma = 0»
                      «FOR mp:matchdef.matchprops»
                        «IF coma++ > 0»sb.append(separator);«ENDIF»                     
                        sb.append("«mp.colname»");
                      «ENDFOR»
                      return sb.toString();
                    '''  
                  ]
                   
                  members += meln.toMethod('propsString',typeRef('java.lang.String')) [
                    parameters += meln.toParameter('_entity', typeRef('fr.ocelet.runtime.entity.Entity'))
                    body='''
                      StringBuffer sb = new StringBuffer();
                      «var coma = 0»
                      «FOR mp:matchdef.matchprops»
                        «IF coma++ > 0»sb.append(separator);«ENDIF»                     
                        sb.append(_entity.getProperty("«mp.prop»").toString());
                      «ENDFOR»
                      return sb.toString();
                    '''
                  ]
                }
              }
            }
          }
          isFirst = false
        }
      ]
    }     
          
      // ---- Entity --------------------------------------
          Entity : {
            // Generation d'une classe par entity
            acceptor.accept(modl.toClass(meln.fullyQualifiedName)) [
      		  documentation = meln.documentation
     		  superTypes += typeRef('fr.ocelet.runtime.entity.AbstractEntity')
     		  val List<PropertyDef> lpropdefs = <PropertyDef>newArrayList()
     		  val List<String> cellProps = <String>newArrayList() 
     		  val HashMap<String, String> typeProps = <String, String>newHashMap()
     		  var boolean isCell = false
     		  var String cellNameTemp = ""
     		  var index = 0
     		  for(enteln:meln.entelns) {
      		  	switch(enteln) {
      		  		PropertyDef: {
      		  			if (enteln.name !== null) {
      		  				if(enteln.type.simpleName.equals("Cell")){
      		  					isCell = true;
      		  					cellNameTemp = enteln.name
      		  				}
      		  			}
      		  		}
      		  	}
      		  }
     		  val cellName = cellNameTemp
      		  for(enteln:meln.entelns) {
      		  	switch(enteln) {
      		  		
      		  		PropertyDef: {
                      if (enteln.name !== null) {
      		  			lpropdefs.add(enteln)
      		  			
      		  			if(!enteln.type.simpleName.equals("Cell")){
      		  			cellProps.add(enteln.name)
      		  			typeProps.put(enteln.name, enteln.type.simpleName)
      		  			}
      		  			
      		  			val fIndex = index
      		  			if(isCell){
      		  				if(!enteln.type.simpleName.equals('Cell')){
      		  					members += enteln.toMethod('set'+enteln.name.toFirstUpper,typeRef(Void::TYPE))[
      		  				documentation = enteln.documentation
      		  				val parName = enteln.name
      		  				parameters += enteln.toParameter(parName, enteln.type)
      		  				if(enteln.type.simpleName.equals('Double')){
      		  				body= '''
      		  					«cellName».getGrid().setValue(«fIndex»,getX(), getY(),«enteln.name»);
      		  					 
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Integer')){
      		  				body= '''
      		  					«cellName».getGrid().setValue(«fIndex»,getX(), getY(),«enteln.name».doubleValue());
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Float')){
      		  				body= '''
      		  					«cellName».getGrid().setValue(«fIndex»,getX(), getY(),«enteln.name».doubleValue());
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Boolean')){
      		  				body= '''
								if(«enteln.name» == true){
									«cellName».getGrid().setValue(«fIndex»,getX(), getY(),1.0);
								}else{
									«cellName».getGrid().setValue(«fIndex»,getX(), getY(),0.0);
								}
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Byte')){
      		  				body= '''
								«cellName».getGrid().setValue(«fIndex»,getX(), getY(),«enteln.name».doubleValue());
      		  				'''
      		  				}else{
							body= '''
								System.out.println("«enteln.type.simpleName» type is not allowed for a cell entity");
      		  				'''
      		  				}
      		  				
      		  			]
      		  			members += enteln.toMethod('get'+enteln.name.toFirstUpper,enteln.type)[
      		  				documentation = enteln.documentation      		  				
      		  				if(enteln.type.simpleName.equals('Double')){
      		  				body= '''
      		  					return «cellName».getGrid().getValue(«fIndex»,getX(), getY());
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Integer')){
      		  				body= '''
      		  					return «cellName».getGrid().getValue(«fIndex»,getX(), getY()).intValue();
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Float')){
      		  				body= '''
      		  					return «cellName».getGrid().getValue(«fIndex»,getX(), getY()).floatValue();
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Byte')){
      		  				body= '''
      		  					return «cellName».getGrid().getValue(«fIndex»,getX(), getY()).byteValue();
      		  				'''
      		  				}else if(enteln.type.simpleName.equals('Boolean')){
      		  				body= '''
      		  					Double val =«cellName».getGrid().getValue(«fIndex»,getX(), getY());
      		  					if(val == 1.0){
      		  						return true;
      		  					} 
      		  					return false;
      		  				'''
      		  				}else{
      		  				body= '''
      		  					System.out.println("«enteln.type.simpleName» type is not allowed for a cell entity");
      		  					return null;
      		  				'''

      		  				}
      		  			]
      		  			index = index + 1
      		  			}
      		  		
      		  			}else{
      		  				// Add special setter and getter
      		  				// We can't use the toSetter and toGetter methods because we do not create a real field.
      		  				members += enteln.toMethod('set'+enteln.name.toFirstUpper,typeRef(Void::TYPE))[
      		  					documentation = enteln.documentation
      		  					val parName = enteln.name
      		  					parameters += enteln.toParameter(parName, enteln.type)
      		  					body='''setProperty("«enteln.name»",«parName»);'''
      		  				]
      		  				members += enteln.toMethod('get'+enteln.name.toFirstUpper,enteln.type)[
      		  					documentation = enteln.documentation
      		  					body='''return getProperty("«enteln.name»");'''
      		  					]
      		  		  		}
      		  			}
      		  		}
      		  		ServiceDef: {
      		  			var rtype = enteln.type
      		  			if (rtype === null) rtype = typeRef(Void::TYPE)
      		  			members+= enteln.toMethod(enteln.name, rtype)[
      		  				documentation = enteln.documentation
      		  				for (p: enteln.params) {
      		  					parameters += p.toParameter(p.name, p.parameterType)
      		  				}
      		  				body = enteln.body
      		  			]
      		  		}
      		  		ConstructorDef: {
      		  			members+= enteln.toMethod(enteln.name, typeRef(meln.fullyQualifiedName.toString))[
      		  				setStatic(true)
      		  				documentation = enteln.documentation
      		  				for (p: enteln.params) {
      		  					parameters += p.toParameter(p.name, p.parameterType)
      		  				}
      		  				body =	enteln.body
      		  			]
      		  		}
      		  	}
      		  }
      		  if(!isCell){
      	      // Ajout d'un constructeur avec déclaration de toutes les properties
      	      members+= meln.toConstructor[
      	      	body = '''
      	      	  super();
      	      	  «FOR hprop : lpropdefs»
      	      	    «val hhtype = typeRef('fr.ocelet.runtime.entity.Hproperty',asWrapperTypeIfPrimitive(hprop.type))»
      	      	    defProperty("«hprop.name»",new «hhtype»());
      	      	    «val vtyp = asWrapperTypeIfPrimitive(hprop.type)»
      	      	    set«hprop.name.toFirstUpper»(new «vtyp»«IF (vtyp.isNumberType)»("0"));«ELSEIF (vtyp.qualifiedName.equals("java.lang.Boolean"))»(false));«ELSE»());
                    «ENDIF»
      	      	  «ENDFOR»
      	      	'''
      	       ]
      	       
      	 	} else{
      	    	
      	      		members+= meln.toConstructor[
      	        	body = '''
               			this.«cellName» = new fr.ocelet.runtime.geom.ocltypes.Cell();
               			this.setSpatialType(«cellName»);
                		'''
      	      		]  
      	      	members += meln.toMethod('getProps',typeRef('fr.ocelet.runtime.ocltypes.List',typeRef('java.lang.String')))[    	      	
      	            		  				
      		  			body='''
      		  				List<String> names = new List<String>();
      		  				«FOR name : cellProps»
      		  					names.add("«name»");
      		  				«ENDFOR»
      		  				return names;
      		  			'''
      		  		]
      		  		members += meln.toMethod('getTypeProps',typeRef('fr.ocelet.runtime.ocltypes.KeyMap',typeRef('java.lang.String'), typeRef('java.lang.String')))[    	      	
      	            		  				
      		  			body='''
      		  				KeyMap<String, String> names = new KeyMap<String, String>();
      		  				«FOR name : cellProps»
      		  					names.put("«name»","«typeProps.get(name)»");
      		  				«ENDFOR»
      		  				return names;
      		  			'''
      		  		]	
					members += meln.toMethod('updateCellInfo',typeRef(Void::TYPE))[    	      	
					parameters += meln.toParameter('type', typeRef('java.lang.String'))
					body='''
						this.«cellName».setType(type);
					'''
					]
      		  
      
				var jvmFieldCell = meln.toField(cellName, typeRef("fr.ocelet.runtime.geom.ocltypes.Cell"))
				if (jvmFieldCell !== null) {
          	      jvmFieldCell.setFinal(false) 
          		  members+= jvmFieldCell
          		
          		 }
      		  	
          	  var jvmFieldX = meln.toField("x", typeRef("java.lang.Integer"))
          	    if (jvmFieldX !== null) {
          	      jvmFieldX.setFinal(false) 
          		  members+= jvmFieldX
          		
          		 }
          		  var jvmFieldY = meln.toField("y", typeRef("java.lang.Integer"))
          	    if (jvmFieldY !== null) {
          	      jvmFieldY.setFinal(false) 
          		  members+= jvmFieldY
          		
          		 }
          		 
          		var jvmFieldNum = meln.toField("numGrid", typeRef("java.lang.Integer"))
          	    if (jvmFieldNum !== null) {
          	      jvmFieldNum.setFinal(false) 
          	      jvmFieldNum.setStatic(true)
          		  members+= jvmFieldNum
				}		
				members += meln.toMethod('setX', typeRef(Void::TYPE))[    	      	
				parameters += meln.toParameter('x', typeRef('java.lang.Integer'))
				body='''
					this.«cellName».setX(x); 
				'''
      		  	]
				members += meln.toMethod('setY', typeRef(Void::TYPE))[    	      	
				parameters += meln.toParameter('y', typeRef('java.lang.Integer'))
				body= '''
					this.«cellName».setY(y); 
				'''
				]
				members += meln.toMethod('getX',typeRef('java.lang.Integer'))[    	      	
				body= '''
					return this.«cellName».getX(); 
				'''
				]
				members += meln.toMethod('get'+cellName.toFirstUpper, typeRef("fr.ocelet.runtime.geom.ocltypes.Cell"))[    	      	
				body= '''
					return «cellName»;
				'''
				]
				members += meln.toMethod('getY', typeRef('java.lang.Integer'))[    	      	
				body= '''
					return this.«cellName».getY();
				'''
				]		
			
      	       	
		}
	]
}

// ---- Agregdef --------------------------------------
          Agregdef : {
            // Generates one class for every agregation function
            if (meln.type !== null) {
            acceptor.accept(modl.toClass(meln.fullyQualifiedName)) [
              superTypes += typeRef('fr.ocelet.runtime.relation.AggregOperator',meln.type,typeRef('fr.ocelet.runtime.ocltypes.List',meln.type))
              members += meln.toMethod('compute',meln.type)[
                parameters += meln.toParameter('values', typeRef('fr.ocelet.runtime.ocltypes.List',meln.type))
                parameters += meln.toParameter('preval',meln.type)
                body  = meln.body
              ]
            ]
          }
        }
        
        
// ---- Relation ------------------------------------
          Relation : {
          	val graphcname = meln.fullyQualifiedName
          	val edgecname = graphcname+"_Edge"
            if (meln.roles.size > 2) println("Sorry, only graphs with two roles are supported by this version. The two first roles will be used and the others will be ignored.")
    
            val aggregType = typeRef('fr.ocelet.runtime.raster.CellAggregOperator')
            val listype = typeRef('fr.ocelet.runtime.ocltypes.List',aggregType)
           	//val gridType = typeRef('fr.ocelet.runtime.raster.Grid')
     
	 			// Generate the edge class
        	acceptor.accept(modl.toClass(edgecname))[
          			
          	val isAutoGraph = (meln.roles.get(0).type.equals(meln.roles.get(1).type))
            var isCellGraph = false
            var isCellGeomGraph = false
            var testCell1 = false
            var testCell2 = false
            var testGeom1 = false
            var testGeom2 = false
            val rol1 = meln.roles.get(0).type
            val rol2 = meln.roles.get(1).type
           
            for(e : rol1.eContents) {
              switch (e){
           	  	PropertyDef : {
           		  if (e.type.simpleName.equals('Cell')) {
           			testCell1 = true
           		  }
           		  if (e.type.simpleName.equals('Line') || e.type.simpleName.equals('MultiLine') ||
           					e.type.simpleName.equals('Polygon') || e.type.simpleName.equals('MultiPolygon') ||
           					e.type.simpleName.equals('Point') || e.type.simpleName.equals('MultiPoint') ||
           					e.type.simpleName.equals('Ring')
           			 ) {
       					testGeom1 = true
           			   }
           	    }
           	  }
            }
            for (e : rol2.eContents) {
           	  switch (e) {
           		PropertyDef : {
           		  if (e.type.simpleName.equals('Cell')) {
           		    testCell2 = true
           		  }
           		  if (e.type.simpleName.equals('Line') || e.type.simpleName.equals('MultiLine') ||
           					e.type.simpleName.equals('Polygon') || e.type.simpleName.equals('MultiPolygon') ||
           					e.type.simpleName.equals('Point') || e.type.simpleName.equals('MultiPoint') ||
           					e.type.simpleName.equals('Ring')
           			  ) {
           					testGeom2 = true
           				}
           		}
           	  }
            }
     
            if (testCell1 && testCell2) {
              isCellGraph = true
            }
            if (testGeom1 && testCell2 || testGeom2 && testCell1){
              isCellGeomGraph = true
            }
            
            /*var graphname = 'fr.ocelet.runtime.relation.impl.AutoGraph'
            
            if (!isAutoGraph) {
              graphname = 'fr.ocelet.runtime.relation.impl.DiGraph'
            }
            if (isCellGraph) {
              if (isAutoGraph) {
            	graphname = 'fr.ocelet.runtime.relation.impl.CellGraph'
              } else {
           		graphname = 'fr.ocelet.runtime.relation.impl.DiCellGraph'
           	  }
            }
			if(isCellGeomGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.GeometryCellGraph'
            }*/
            
//        	val graphTypeName = graphname 
          			
          	if (isCellGeomGraph) {	
          	  val firstRole = meln.roles.get(0)                                 
              val secondRole = meln.roles.get(1)     
               
              var tempcellType = typeRef(firstRole.type.fullyQualifiedName.toString)
              var tempgeomType = typeRef(secondRole.type.fullyQualifiedName.toString)
              
              var tempCellName = firstRole.name
              var tempGeomName = secondRole.name
              
              if (testCell2) {
              	tempcellType = typeRef(secondRole.type.fullyQualifiedName.toString)
              	tempCellName = secondRole.name
            	tempgeomType = typeRef(firstRole.type.fullyQualifiedName.toString)
              	tempGeomName = firstRole.name
              }
              val cellType = tempcellType
              val geomType = tempgeomType
              val cellName = tempCellName
              val geomName = tempGeomName
              	
              val cellList1 = typeRef('fr.ocelet.runtime.ocltypes.List', cellType)

			  val cellListName = cellName+"s"
			  val geomNames = geomName+"s"
              	
          	  superTypes += typeRef('fr.ocelet.runtime.relation.GeomCellEdge', cellType, geomType)            
          	  if ((meln.roles.size >= 2) &&
                (meln.roles.get(0)!==null) && (meln.roles.get(1)!==null) &&
            	(meln.roles.get(0).type !== null) && (meln.roles.get(1).type !== null) &&
               	(meln.roles.get(0).type.fullyQualifiedName !== null) &&
               	(meln.roles.get(1).type.fullyQualifiedName !== null) &&
            	(meln.roles.get(0).name !== null) && (meln.roles.get(1).name !== null)
                ) {	
          	 		var jvmField = meln.toField(cellName, cellType)
          	    	if (jvmField !== null) {
          	      		jvmField.setFinal(false) 
          		  		members+= jvmField
          		  		members+= meln.toSetter(cellName, cellType)
          		  		members+= meln.toGetter(cellName, cellType)
          		  	}
          			jvmField = meln.toField(geomName, geomType)
          	  		if (jvmField !== null) {
          	  	  		jvmField.setFinal(false) 
          		  		members+= jvmField
          		  		members+= meln.toSetter(geomName, geomType)
          		  		members+= meln.toGetter(geomName, geomType)
          			}          		
          		
          			members+= meln.toConstructor[
          			parameters += meln.toParameter(cellListName, cellList1)
          			parameters += meln.toParameter(geomNames, typeRef("fr.ocelet.runtime.ocltypes.List", geomType))
          			body = '''
          			  super(«cellListName», «geomNames»);  
          			  this.«cellName» = new «cellType»();
          			  
          			  ((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)this.«cellName».getSpatialType()).setGrid(grid);
					'''
					]
          		
          			members+= meln.toConstructor[
          			parameters += meln.toParameter(cellListName, cellList1)
          			parameters += meln.toParameter(geomNames, typeRef("fr.ocelet.runtime.ocltypes.List", geomType))
          			parameters += meln.toParameter("distance", typeRef(Double::TYPE))
          			body = '''
          			  super(«cellListName», «geomNames», distance);  
          			  this.«cellName» = new «cellType»();
          			 ((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)this.«cellName».getSpatialType()).setGrid(grid);
					'''
					]
					members += meln.toMethod("getRole", typeRef("fr.ocelet.runtime.relation.OcltRole"))[
          			parameters += meln.toParameter("i",typeRef("int"))
					body = '''
						if (i==0) return «cellName»;
						else if (i==1) return «geomName»;
						else return null;
					'''
					]
          		
					members += meln.toMethod("update", typeRef(Void::TYPE))[
          			
          			body = '''
						this.«cellName».setX(getX());
						this.«cellName».setY(getY());
						this. «geomName» = getGeomEntity();
          			'''
          			]
          		}
     		  // Generate Properties and Interactions on the edge level
     		  
     		  val HashMap<String, JvmTypeReference> typeProps = <String, JvmTypeReference>newHashMap()

    		  for (reln:meln.relelns){
    		  	switch(reln) {
          		  RelPropertyDef : {
          		  	typeProps.put(reln.name, reln.type)
        	  	  	
          	  	  }

          	  	  InteractionDef : {
          	  	  	members+= reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  }
          	  	  	  body = reln.body
          	  	  
          	  	  	]
          	  	    if (reln.comitexpressions.size() > 0) {          	  	    	
          	  	    	
          	  	        members += reln.toMethod("get_agr_"+reln.name,listype)[
          	  	      	body = '''
							«var index = 0»
							«listype» cvtList = new «listype»();
							«FOR ce : reln.comitexpressions»
							«IF ce.rol.type.fullyQualifiedName.toString.equals(cellType.qualifiedName.toString)»
							«aggregType» cvt«index» = new «aggregType»();
							cvt«index».setName("«ce.prop»"); 
							cvt«index».setCellOperator(new  «ce.agrfunc»(), «cellName».getTypeProps(), «ce.usepreval»);
							cvtList.add(cvt«index»);
							«{index = index + 1; null}»
							«ENDIF»
							«ENDFOR »
							return cvtList;
							'''
						]          	  	    	
						members += reln.toMethod("_agr_"+reln.name,typeRef(Void::TYPE))[
          	  	      	body = '''	
          	  	      		«FOR ce:reln.comitexpressions»
          	  	      		«val t1 = ce.rol.type.fullyQualifiedName.toString»
          	  	      		«val t2 = cellType.qualifiedName.toString»
          	  	      			«IF !t1.equals(t2)»
          	  	      				this.«ce.rol.getName()».setAgregOp("«ce.prop»",new «ce.agrfunc»(),«ce.usepreval»);
								«ENDIF»
							«ENDFOR»          	  	      		
          	  	      	'''
          	  	      ]
          	  	    }else{
          	  	    	   members += reln.toMethod("get_agr_"+reln.name,listype)[
          	  	      	body = ''' 
          	  	      		return null;
          	  	      	'''
          	  	      	]
          	  	    }
          	  	 }
          	  }
  		    }
  		    var indexDouble = 0
  		     	var indexInteger = 0
  		     	var indexBoolean = 0

  		     for(String name : typeProps.keySet){
  		     	
  		     		if(typeProps.get(name).simpleName.equals("Double")){
  		     				
  		     		val index = indexDouble
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setDoubleProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Double'))[
							
          	  	      	body = '''
          	  	      		return getDoubleProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexDouble = indexDouble + 1;
  		     	}
  		     	if(typeProps.get(name).simpleName.equals("Integer")){	
  		     	  val index = indexInteger
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setIntegerProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Integer'))[
							
          	  	      	body = '''
          	  	      		return getIntegerProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexInteger = indexInteger + 1; 
          	  	}
  		     	if(typeProps.get(name).simpleName.equals("Boolean")){	
  		     	  val index = indexBoolean
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setBooleanProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Boolean'))[
							
          	  	      	body = '''
          	  	      		return getBooleanProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexBoolean = indexBoolean + 1;  	
          	  	   }


  		     }
  		      
  		      members += meln.toMethod("getEdgeProperties",typeRef('fr.ocelet.runtime.ocltypes.KeyMap',
  		      	typeRef('java.lang.String'), typeRef('java.lang.String')))[
				body = '''
					KeyMap<String, String> properties = new KeyMap<String, String>();	
					«FOR name : typeProps.keySet»
					properties.put("«name»","«typeProps.get(name).simpleName»");
					«ENDFOR» 
					return properties;         	  	      		
				'''
				]
          	  	      	//typeProps.clear();
  		    
  		    } else if (isCellGraph) {
  		    	
  		    	
  		    	if(!isAutoGraph){
  		    		 superTypes += typeRef('fr.ocelet.runtime.relation.DiCursorEdge')
              /*  if ((meln.roles.size >= 2) &&
            	(meln.roles.get(0)!=null) && (meln.roles.get(1)!=null) &&
            	(meln.roles.get(0).type != null) && (meln.roles.get(1).type != null) &&
               	(meln.roles.get(0).type.fullyQualifiedName != null) &&
               	(meln.roles.get(1).type.fullyQualifiedName != null) &&
            	(meln.roles.get(0).name != null) && (meln.roles.get(1).name != null)
                ) {*/ 
                	
 			  val firstRole = meln.roles.get(0)
       		  val secondRole = meln.roles.get(1)      
              val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
              val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
              val cellList1 = typeRef('fr.ocelet.runtime.ocltypes.List', firstRoleType)
              val cellList2 = typeRef('fr.ocelet.runtime.ocltypes.List', secondRoleType)

				val firstName = firstRole.name+"s"
				val secondName = secondRole.name+"s"
          		
          	  var jvmField = meln.toField(firstRole.name, firstRoleType)
          	    if (jvmField !== null) {
          	      jvmField.setFinal(false) 
          		  members+= jvmField
          		
          		 }
          		jvmField = meln.toField(secondRole.name, secondRoleType)
          	  	if (jvmField !== null) {
          	  	  jvmField.setFinal(false) 
          		  members+= jvmField
          	
          		}          		
          		
          		members+= meln.toConstructor[
          			parameters += meln.toParameter(firstName,cellList1)
          			parameters += meln.toParameter(secondName,cellList2)
          			
          			body = ''' 
          			  super(«firstName», «secondName»);
          			  «firstRole.name» = new «firstRoleType»();
          			  «secondRole.name» = new «secondRoleType»();
          			  ((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«firstRole.name».getSpatialType()).setGrid(grid1);
          			  ((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«secondRole.name».getSpatialType()).setGrid(grid2);
          			  updateRoleInfo();
          		  '''
          		]
          		
          	
          		members += meln.toMethod("getRole",typeRef("fr.ocelet.runtime.relation.OcltRole"))[
          			parameters += meln.toParameter("i",typeRef('java.lang.Integer'))
          						body = '''
          				if (i==0) return «firstRole.name»;
          				else if (i==1) return «secondRole.name»;
          				else return null;
          			'''
          		]
          		members += meln.toMethod("getNearest",secondRoleType)[
          			parameters += meln.toParameter(firstRole.name,firstRoleType)
          						body = '''
          							Cell «firstRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«firstRole.name».getSpatialType();
          							double[] «firstRole.name»Coordinate = «firstRole.name»Cell.getGrid().gridDoubleCoordinate(«firstRole.name»Cell.getX(), «firstRole.name»Cell.getY());
          							Cell «secondRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«secondRole.name».getSpatialType();
          							int[] newCoords = «secondRole.name»Cell.getGrid().gridCoordinate(«firstRole.name»Coordinate[0], «firstRole.name»Coordinate[1]);
          							«secondRole.name»Cell.setX(newCoords[0]);
          							«secondRole.name»Cell.setY(newCoords[1]);
          							return «secondRole.name»;
          			'''
          			
          		]
          		
          		members += meln.toMethod("getNearest",firstRoleType)[
          			parameters += meln.toParameter(secondRole.name,secondRoleType)
          						body = '''
          							Cell «secondRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«secondRole.name».getSpatialType();
          							double[] «secondRole.name»Coordinate = «secondRole.name»Cell.getGrid().gridDoubleCoordinate(«secondRole.name»Cell.getX(), «secondRole.name»Cell.getY());
          							Cell «firstRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«firstRole.name».getSpatialType();
          							int[] newCoords = «firstRole.name»Cell.getGrid().gridCoordinate(«secondRole.name»Coordinate[0], «secondRole.name»Coordinate[1]);
          							«firstRole.name»Cell.setX(newCoords[0]);
          							«firstRole.name»Cell.setY(newCoords[1]);
          							return «firstRole.name»;
          			'''
          			
          		]
          		
          			members += meln.toMethod("hasNearest",typeRef(Boolean::TYPE))[
          			parameters += meln.toParameter(firstRole.name,firstRoleType)
          						body = '''
          							Cell «firstRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«firstRole.name».getSpatialType();
          							double[] «firstRole.name»Coordinate = «firstRole.name»Cell.getGrid().gridDoubleCoordinate(«firstRole.name»Cell.getX(), «firstRole.name»Cell.getY());
          							Cell «secondRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«secondRole.name».getSpatialType();
          							int[] newCoords = «secondRole.name»Cell.getGrid().gridCoordinate(«firstRole.name»Coordinate[0], «firstRole.name»Coordinate[1]);
          							if(newCoords == null){
          							   	return false;
          							}
          							return true;
          			'''
          			
          		]
          		
          		members += meln.toMethod("hasNearest",typeRef(Boolean::TYPE))[
          			parameters += meln.toParameter(secondRole.name,secondRoleType)
          						body = '''
          							Cell «secondRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«secondRole.name».getSpatialType();
          							double[] «secondRole.name»Coordinate = «secondRole.name»Cell.getGrid().gridDoubleCoordinate(«secondRole.name»Cell.getX(), «secondRole.name»Cell.getY());
          							Cell «firstRole.name»Cell = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«firstRole.name».getSpatialType();
          							int[] newCoords = «firstRole.name»Cell.getGrid().gridCoordinate(«secondRole.name»Coordinate[0], «secondRole.name»Coordinate[1]);
          							if(newCoords == null){
          								return false;
          							}          							
          							return true;
          			'''
          			
          		]
          		          		
          		members += meln.toMethod("update",typeRef(Void::TYPE))[
          			
          			body = '''
          				this. «firstRole.name».setX(x);
          				this. «firstRole.name».setY(y);
          				this. «secondRole.name».setX(x2);
          				this. «secondRole.name».setY(y2);
          				// this.e1.setX(x);
          				//this.e1.setY(y);
          				//this.e2.setX(x2);
          				//this.e2.setY(y2);

          			'''
          		]
          		//}
     		  // Generate Properties and Interactions on the edge level
     		  val HashMap<String, JvmTypeReference> typeProps = <String, JvmTypeReference>newHashMap()

    		  for (reln:meln.relelns){
    		  	switch(reln) {
    		  		
    		  		RelPropertyDef : {
            	    typeProps.put(reln.name, reln.type)

        	  	  	
          	  	  }

          	  	  InteractionDef : {
          	  	  	
 	
          	  	  	members+= reln.toMethod(reln.name, typeRef(Void::TYPE))[
          	  	  	var params =""
          	  	  		
          	  	  
          	  	  	var index = 0;
          	  	  	 for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  	
          	  	  	  	if(index == reln.params.size){
          	  	  	  		params = params + p.name
          	  	  	  	}else{
          	  	  	  		params = params + p.name+","
          	  	  	 	}
          	  	  	}
          	  	  	
          	  	  	
          	  	  	body = reln.body
          	  	  	  //val finalParams = params
          	  	  
          	  	 
          	  	 
          	  	 /*
          	  	  * «IF ec instanceof XAssignment»
          	  	  	 			«ec.actualReceiver»
          	  	  	 			//assignable
          	  	  	 			«ec.assignable»
          	  	  	 			//feature
          	  	  	 			«ec.feature»
          	  	  	 			//value
          	  	  	 			«ec.value»
          	  	  	 			//Meh
          	  	  	 		
          	  	  	 		«IF ec instanceof XMemberFeatureCall»
          	  	  	 		
          	  	  	 			«ec.value»
          	  	  	 			«ec.fullyQualifiedName»
          	  	  	 			       	  	  	 	    
          	  	  	 		«ENDIF»
          	  	  	 			
          	  	  	 	«ENDIF»
          	  	  */
          	  	  	//reln.body.
          	  	  	
          	  	  	/*val ArrayList<XExpression> xList = <XExpression>newArrayList()
          	  	  	val ArrayList<String> sList = <String>newArrayList()
          	  	  	
          	  	  val fbo = reln.body
 					switch(fbo) {
 						
					  XBlockExpression: {
					  	
					   for (ee:fbo.expressions)  {
							
						    switch(ee) {
								
						     XAssignment: {
						     	xList.add(ee.actualReceiver)
						     	xList.add(ee.assignable)
						     	
						     	xList.add(ee.value)
						     	 switch(ee.value) {
						     	 	  XMemberFeatureCallImplCustom:{
						     			xList.add(ee.actualReceiver)
						     			sList.add(ee.concreteSyntaxFeatureName)
						     	
						     }
						     	 }
						     }
						     
						   
						    }
						   }
						  }
					}
          	  	  		body = '''
          	  	  			«FOR exp : xList»
          	  	  		         «exp»          	  	  		       
          	  	  		          	  	  	 	
          	  	  		    «ENDFOR »
          	  	  		  //sList  
          	  	  		    «FOR exp : sList»
          	  	  		         «exp»
          	  	  		  
          	  	  		              	  	  		          	  	  	 	
          	  	  		   «ENDFOR »
          	  	  	 	
          	  	  	 '''*/
          	  	  	]
          	  	    if (reln.comitexpressions.size() > 0) {
          	  	      members += reln.toMethod("get_agr_"+reln.name,listype)[
          	  	      	
          	  	      	/*	body = '''«FOR ce:reln.comitexpressions»
          	  	      	    this.«ce.rol.getName()».setAgregOp("«ce.prop»",new «ce.agrfunc»(),«ce.usepreval»);
           	  	      	  «ENDFOR»
          	  	      	''' */
          	  	      	body = '''
          	  	      		«var index = 0»
          	  	      		«listype» cvtList = new «listype»();	
          	  	      		«FOR ce : reln.comitexpressions»
								«aggregType» cvt«index» = new «aggregType»();	
								cvt«index».setName("«ce.prop»"); 
							
								«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")» cellIndex«index» = («typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«ce.rol.getName()».getSpatialType();
								cvt«index».setCellOperator(new «ce.agrfunc»(), «ce.rol.getName()».getTypeProps(), «ce.usepreval», cellIndex«index».getGrid());
								cvtList.add(cvt«index»);
          	  	      	  	 	«{index = index + 1; null}»
							«ENDFOR»
							return cvtList;
          	  	      	'''
          	  	      ]
          	  	    }else{
          	  	    	   members += reln.toMethod("get_agr_"+reln.name,listype)[
          	  	      	body = '''
          	  	      		return null;
          	  	      	'''
          	  	      	]
          	  	    }
          	  	  }
          	  	}
  		      }
  		    var indexDouble = 0
  		    var indexInteger = 0
  		    var indexBoolean = 0

  		    for(String name : typeProps.keySet){
  		     	
  		     		if(typeProps.get(name).simpleName.equals("Double")){
  		     				
  		     		val index = indexDouble
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setDoubleProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Double'))[
							
          	  	      	body = '''
          	  	      		return getDoubleProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexDouble = indexDouble + 1;
  		     	}
  		     	if(typeProps.get(name).simpleName.equals("Integer")){	
  		     	  val index = indexInteger
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setIntegerProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Integer'))[
							
          	  	      	body = '''
          	  	      		return getIntegerProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexInteger = indexInteger + 1; 
          	  	}
  		     	if(typeProps.get(name).simpleName.equals("Boolean")){	
  		     	  val index = indexBoolean
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setBooleanProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Boolean'))[
							
          	  	      	body = '''
          	  	      		return getBooleanProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexBoolean = indexBoolean + 1;  		     	}


  		     }
  		      
  		      members += meln.toMethod("getEdgeProperties",typeRef('fr.ocelet.runtime.ocltypes.KeyMap',
  		      typeRef('java.lang.String'), typeRef('java.lang.String')))[
				body = '''
					KeyMap<String, String> properties = new KeyMap<String, String>();	
					«FOR name : typeProps.keySet»
					properties.put("«name»","«typeProps.get(name).simpleName»");
					«ENDFOR» 
					return properties;         	  	      		
				'''
				]
          	  	//	typeProps.clear();

				}else{
  		    			
  		    	superTypes += typeRef('fr.ocelet.runtime.relation.CursorEdge')
              /*   if ((meln.roles.size >= 2) &&
            	(meln.roles.get(0)!=null) && (meln.roles.get(1)!=null) &&
            	(meln.roles.get(0).type != null) && (meln.roles.get(1).type != null) &&
               	(meln.roles.get(0).type.fullyQualifiedName != null) &&
               	(meln.roles.get(1).type.fullyQualifiedName != null) &&
            	(meln.roles.get(0).name != null) && (meln.roles.get(1).name != null)
                ) {*/
              	val firstRole = meln.roles.get(0)
              	val secondRole = meln.roles.get(1)
              	val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
              	val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
              	val cellList = typeRef('fr.ocelet.runtime.ocltypes.List', firstRoleType)
				val firstName = firstRole.name+"s"
				//val secondName = secondRole.name+"s"
          		
          	  	var jvmField = meln.toField(firstRole.name, firstRoleType)
          	    if (jvmField !== null) {
          	    	
          	      jvmField.setFinal(false) 
          		  members+= jvmField
          		}
          		 
          		jvmField = meln.toField(secondRole.name, secondRoleType)
          	  	if (jvmField !== null) {
          	  	  jvmField.setFinal(false) 
          		  members+= jvmField
          	
          		}          		
          		
          		members+= meln.toConstructor[
          		parameters += meln.toParameter(firstName,cellList)
					body = '''
						super(«firstName»);
						«firstRole.name» = new «firstRoleType»();
						«secondRole.name» = new «secondRoleType»();
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«firstRole.name».getSpatialType()).setGrid(grid);
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)«secondRole.name».getSpatialType()).setGrid(grid);           			    
					'''
          		]
          		members += meln.toMethod("getRole",typeRef("fr.ocelet.runtime.relation.OcltRole"))[
          		parameters += meln.toParameter("i",typeRef('java.lang.Integer'))
					body = '''
						if (i==0) return «firstRole.name»;
						else if (i==1) return «secondRole.name»;
						else return null;
					'''
          		]
          		members += meln.toMethod("updateCellType",typeRef(Void::TYPE))[          			
					body = '''
						«firstRole.name».updateCellInfo(getCellType());
						«secondRole.name».updateCellInfo(getCellType());
						'''
          		]
          		          		
          		members += meln.toMethod("update",typeRef(Void::TYPE))[          			
          			body = '''
						this. «firstRole.name».setX(x);
						this. «firstRole.name».setY(y);
						this. «secondRole.name».setX(x2);
						this. «secondRole.name».setY(y2);
          			'''
          		]
          		//}
     		  // Generate Properties and Interactions on the edge level
     		  val HashMap<String, JvmTypeReference> typeProps = <String, JvmTypeReference>newHashMap()

    		  for (reln:meln.relelns){
    		  	switch(reln) {
    		  		
    		  		RelPropertyDef : {
            	    typeProps.put(reln.name, reln.type)

        	  	  	
          	  	  }
          	  	  InteractionDef : {          	  	  	          	  	  	
          	  	  	
          	  	  	members+= reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  		var params =""          	  	  		
          	  	  
          	  	  	var index = 0;
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  	
          	  	  	  	if(index == reln.params.size){
          	  	  	  		params = params + p.name
          	  	  	  	}else{
          	  	  	  		params = params + p.name+","
          	  	  	  	}
          	  	  	  }
          	  	  	  body = reln.body
          	  	  	]
          	  	  	 
          	  	    if (reln.comitexpressions.size() > 0) {
          	  	      members += reln.toMethod("get_agr_"+reln.name,listype)[
          	  	      	body = '''
          	  	      		«var index = 0»
          	  	      	«listype» cvtList = new «listype»();
          	  	      	«FOR ce : reln.comitexpressions»
							«aggregType» cvt«index» = new «aggregType»();
							cvt«index».setName("«ce.prop»"); 
							
							cvt«index».setCellOperator(new «ce.agrfunc»(), «firstRole.name».getTypeProps(), «ce.usepreval»);
							cvtList.add(cvt«index»);
          	  	      	  	«{index = index + 1; null}»
           	  	      	  «ENDFOR»
						return cvtList;
          	  	      	'''
          	  	      ]
          	  	    }else{
          	  	    	   members += reln.toMethod("get_agr_"+reln.name,listype)[
          	  	      	body = '''
          	  	      		return null;
          	  	      	 '''         	  	      	
          	  	      	]
          	  	    }
          	  	  }
          	  	}
  		      }
  		     	var indexDouble = 0
  		     	var indexInteger = 0
  		     	var indexBoolean = 0

  		     for(String name : typeProps.keySet){
  		     	
  		     		if(typeProps.get(name).simpleName.equals("Double")){
  		     				
  		     		val index = indexDouble
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setDoubleProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Double'))[
							
          	  	      	body = '''
          	  	      		return getDoubleProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexDouble = indexDouble + 1;
  		     	}
  		     	if(typeProps.get(name).simpleName.equals("Integer")){	
  		     	  val index = indexInteger
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setIntegerProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Integer'))[
							
          	  	      	body = '''
          	  	      		return getIntegerProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexInteger = indexInteger + 1; 
          	  	}
  		     	if(typeProps.get(name).simpleName.equals("Boolean")){	
  		     	  val index = indexBoolean
  		     	 	members += meln.toMethod('set'+name.toFirstUpper,typeRef(Void::TYPE))[
  		     	  	parameters += meln.toParameter('value', typeProps.get(name))
							
          	  	      	body = '''
          	  	      		setBooleanProperty(«index», value);
          	  	      	'''
          	  	      	]
          	  	    members += meln.toMethod('get'+name.toFirstUpper,typeRef('java.lang.Boolean'))[
							
          	  	      	body = '''
          	  	      		return getBooleanProperty(«index»);
          	  	      	'''
          	  	      	]
          	  	      	indexBoolean = indexBoolean + 1;  		     	}


  		     }
  		      
  		      members += meln.toMethod("getEdgeProperties",typeRef('fr.ocelet.runtime.ocltypes.KeyMap',
  		      typeRef('java.lang.String'), typeRef('java.lang.String')))[
				body = '''
					KeyMap<String, String> properties = new KeyMap<String, String>();	
					«FOR name : typeProps.keySet»
					properties.put("«name»","«typeProps.get(name).simpleName»");
					«ENDFOR» 
					return properties;         	  	      		
				'''
			]

  		    }
  		  } else {
  		    // Not cell related graphs	
  		    superTypes += typeRef('fr.ocelet.runtime.relation.OcltEdge')

             if ((meln.roles.size >= 2) &&
            	(meln.roles.get(0)!==null) && (meln.roles.get(1)!==null) &&
            	(meln.roles.get(0).type !== null) && (meln.roles.get(1).type !== null) &&
       	        (meln.roles.get(0).type.fullyQualifiedName !== null) &&
            	(meln.roles.get(1).type.fullyQualifiedName !== null) &&
            	(meln.roles.get(0).name !== null) && (meln.roles.get(1).name !== null)
                ) {

              val firstRole = meln.roles.get(0)
              val secondRole = meln.roles.get(1)
              val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
              val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
          		
          		
          		
          	  var jvmField = meln.toField(firstRole.name, firstRoleType)
          	    if (jvmField !== null) {
          	      jvmField.setFinal(false) 
          		  members+= jvmField
          		  members+= meln.toSetter(firstRole.name, firstRoleType)
          		  members+= meln.toGetter(firstRole.name, firstRoleType)
          		 }
          		jvmField = meln.toField(secondRole.name, secondRoleType)
          	  	if (jvmField !== null) {
          	  	  jvmField.setFinal(false) 
          		  members+= jvmField
          		  members+= meln.toSetter(secondRole.name, secondRoleType)
          		  members+= meln.toGetter(secondRole.name, secondRoleType)
          		}          		
          		
          		members+= meln.toConstructor[
          			parameters += meln.toParameter("igr",typeRef("fr.ocelet.runtime.relation.InteractionGraph"))
          			parameters += meln.toParameter("first",firstRoleType)
          			parameters += meln.toParameter("second",secondRoleType)
          			body = '''
          			  super(igr);
          			  «firstRole.name»=first;
          			  «secondRole.name»=second;
          			'''
          		]
          		
          		members += meln.toMethod("getRole",typeRef("fr.ocelet.runtime.relation.OcltRole"))[
          			parameters += meln.toParameter("i",typeRef("int"))
          			body = '''
          			  if (i==0) return «firstRole.name»;
          			  else if (i==1) return «secondRole.name»;
          			  else return null;
          	       '''
          		]
             } // if roles are well defined
                	
                		    		
     		  // Generate Properties and Interactions on the edge level
    		  for (reln:meln.relelns){
    		  	switch(reln) {
          	  	  RelPropertyDef : {
            	    val rField = reln.toField(reln.name, reln.type)
          	  	    if (rField !== null) {
          	  	      rField.setFinal(false) 
          		      members+= rField
          		      members+= reln.toSetter(reln.name, reln.type)
          		      members+= reln.toGetter(reln.name, reln.type)
          		     }
        	  	  	
          	  	  }
          	  	  InteractionDef : {
          	  	  	members+= reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  }
          	  	  	  body = reln.body
          	  	  	]
          	  	    if (reln.comitexpressions.size() > 0) {
          	  	      members += reln.toMethod("_agr_"+reln.name,typeRef(Void::TYPE))[
          	  	      	body = '''«FOR ce:reln.comitexpressions»
          	  	      	    this.«ce.rol.getName()».setAgregOp("«ce.prop»",new «ce.agrfunc»(),«ce.usepreval»);
           	  	      	  «ENDFOR»
          	  	      	'''
          	  	      ]
          	  	    }
          	  	  }
          	  	}
  		      }		    	
  		    }
         ]
          	
          	// -- Generate filters classes --
          	for (reln:meln.relelns){
    		  	switch(reln) {
          	  	  Filterdef : {
          	  	  	val filterfqn = graphcname+"_"+reln.name
          	  	  	acceptor.accept(modl.toClass(filterfqn))[
          	  	  		
          	  	  		val isAutoGraph = (meln.roles.get(0).type.equals(meln.roles.get(1).type))
            var isCellGraph = false
            var isCellGeomGraph = false
            var testCell1 = false
            var testCell2 = false
            var testGeom1 = false
            var testGeom2 = false
            val rol1 = meln.roles.get(0).type
            val rol2 = meln.roles.get(1).type
          // var graphType = 0 
            for(e : rol1.eContents){
            	switch (e){
           	  	PropertyDef : {
           			if(e.type.simpleName.equals('Cell')){
           				testCell1 = true
           			}
           			if(e.type.simpleName.equals('Line') || e.type.simpleName.equals('MultiLine') ||
           				e.type.simpleName.equals('Polygon') || e.type.simpleName.equals('MultiPolygon') ||
           				e.type.simpleName.equals('Point') || e.type.simpleName.equals('MultiPoint') ||
           				e.type.simpleName.equals('Ring')
           			){
           				testGeom1 = true
           			}
           		}
           	}
           	
           }
            for(e : rol2.eContents){
           	switch (e){
           		PropertyDef : {
           			if(e.type.simpleName.equals('Cell')){
           				testCell2 = true
           			}
           				if(e.type.simpleName.equals('Line') || e.type.simpleName.equals('MultiLine') ||
           				e.type.simpleName.equals('Polygon') || e.type.simpleName.equals('MultiPolygon') ||
           				e.type.simpleName.equals('Point') || e.type.simpleName.equals('MultiPoint') ||
           				e.type.simpleName.equals('Ring')
           			){
           				testGeom2 = true
           			}
           		}
           	}
           	
           }
               
     
            if(testCell1 && testCell2){
            	isCellGraph = true
            }
            if(testGeom1 && testCell2 || testGeom2 && testCell1){
            	isCellGeomGraph = true
            }
            /*var graphname = 'fr.ocelet.runtime.relation.impl.AutoGraph'
            
            if(!isAutoGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.DiGraph'
            }
            if(isCellGraph){
            	if(isAutoGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.CellGraph'
            	}else{
            		graphname = 'fr.ocelet.runtime.relation.impl.DiCellGraph'
            	}
            }




			 if(isCellGeomGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.GeometryCellGraph'
            }*/
     
          			
          			
          		if(isCellGeomGraph){	
          			       	val firstRole = meln.roles.get(0)                                 
              	val secondRole = meln.roles.get(1)     
               
              	/*var tempcellType = typeRef(firstRole.type.fullyQualifiedName.toString)
              	var tempgeomType = typeRef(secondRole.type.fullyQualifiedName.toString)
              
             	var tempCellName = firstRole.name
              	var tempGeomName = secondRole.name
              
             	if(testCell2){
              	
              		tempcellType = typeRef(secondRole.type.fullyQualifiedName.toString)
              		tempCellName = secondRole.name
            		tempgeomType = typeRef(firstRole.type.fullyQualifiedName.toString)
              		tempGeomName = firstRole.name
              	}*/
                      val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
                      val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
                      superTypes += typeRef("fr.ocelet.runtime.relation.EdgeFilter",firstRoleType,secondRoleType)
                      for(p:reln.params){
                      	val pfield = reln.toField(p.name,p.parameterType)
                      	if (pfield !== null) {
          	  	          pfield.setFinal(false)
          	  	          members += pfield
          	  	        }
                      }
                      members += reln.toConstructor()[
                      for(p:reln.params) {
                      	  parameters += reln.toParameter(p.name,p.parameterType)
                      }
						body = '''
							« FOR p : reln.params»
							this.«p.name» = «p.name»;
							« ENDFOR»
						'''
                      ]                      
          	  	  	  members += reln.toMethod("filter",typeRef("java.lang.Boolean"))[
          	  	  		parameters += reln.toParameter(firstRole.name,firstRoleType)
          	  	  		parameters += reln.toParameter(secondRole.name,secondRoleType)
          	  	  		body = reln.body
          	  	  	  ]
          	  	  	  
          	  	  	  }else if (isCellGraph){
  		    				if(!isAutoGraph){
  		    		
  		    		
  		    		val firstRole = meln.roles.get(0)
       				val secondRole = meln.roles.get(1)      
                    val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
                    val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
                    superTypes += typeRef("fr.ocelet.runtime.relation.EdgeFilter",firstRoleType,secondRoleType)
                    for(p:reln.params){
                     	val pfield = reln.toField(p.name,p.parameterType)
                      	if (pfield !== null) {
          	  	          pfield.setFinal(false)
          	  	          members += pfield
          	  	        }
                      }
                      members += reln.toConstructor()[
                      	for(p:reln.params) {
                      	  parameters += reln.toParameter(p.name,p.parameterType)
                        }
                        body = '''
							«FOR p : reln.params»
							this.«p.name» = «p.name»;
                         	«ENDFOR»
                        '''
                      ]                      
          	  	  	  members += reln.toMethod("filter",typeRef("java.lang.Boolean"))[
          	  	  		parameters += reln.toParameter(firstRole.name,firstRoleType)
          	  	  		parameters += reln.toParameter(secondRole.name,secondRoleType)
          	  	  		body = reln.body
          	  	  	  ]
  		    		
  		    }else{
  		    			
  		    		  val firstRole = meln.roles.get(0)
       				  val secondRole = meln.roles.get(1)      

                      val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
                      val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
                      superTypes += typeRef("fr.ocelet.runtime.relation.EdgeFilter",firstRoleType,secondRoleType)
                      
                      for(p:reln.params){
                      	
                      	val pfield = reln.toField(p.name,p.parameterType)
                      	
                      	if (pfield !== null) {
          	  	          pfield.setFinal(false)
          	  	          members += pfield
          	  	        }
                      }
                      members += reln.toConstructor()[
                      	for(p:reln.params) {
                      	  parameters += reln.toParameter(p.name,p.parameterType)
                        }
                        body = '''
							«FOR p : reln.params»
								this.«p.name» = «p.name»;
                        	«ENDFOR»
                        '''
                      ]                      
          	  	  	  members += reln.toMethod("filter", typeRef("java.lang.Boolean"))[
          	  	  		parameters += reln.toParameter(firstRole.name,firstRoleType)
          	  	  		parameters += reln.toParameter(secondRole.name,secondRoleType)
          	  	  		body = reln.body
          	  	  	  ]
  		    			
  		    	}
  		    	
  		    	
  		    }else{
  		    	
  		    	if ((meln.roles.size >= 2) &&
            	    (meln.roles.get(0)!== null) && (meln.roles.get(1)!== null) &&
            	    (meln.roles.get(0).type !== null) && (meln.roles.get(1).type !== null) &&
       	            (meln.roles.get(0).type.fullyQualifiedName !== null) &&
            	    (meln.roles.get(1).type.fullyQualifiedName !== null) &&
            	    (meln.roles.get(0).name !== null) && (meln.roles.get(1).name !== null)
                    ) {
                      val firstRole = meln.roles.get(0)
                      val secondRole = meln.roles.get(1)
                      val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
                      val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
                      superTypes += typeRef("fr.ocelet.runtime.relation.EdgeFilter",firstRoleType,secondRoleType)
                      for(p:reln.params){
                      	val pfield = reln.toField(p.name,p.parameterType)
                      	if (pfield !== null) {
          	  	          pfield.setFinal(false)
          	  	          members += pfield
          	  	        }
                      }
                      members += reln.toConstructor()[
                      	for(p:reln.params) {
                      	  parameters += reln.toParameter(p.name,p.parameterType)
                        }
                        body = '''
                        	«FOR p:reln.params»
                        	 this.«p.name» = «p.name»;
                        	 «ENDFOR»
                        '''
                      ]                      
          	  	  	  members += reln.toMethod("filter",typeRef("java.lang.Boolean"))[
          	  	  		parameters += reln.toParameter(firstRole.name,firstRoleType)
          	  	  		parameters += reln.toParameter(secondRole.name,secondRoleType)
          	  	  		body = reln.body
          	  	  	  ]
          	  	  	} // if roles are well defined
  		    	}
          	  	  	  
          	  	  	]
          	  
          	  	  }
           	  	}
          	 }
          	
          	// -- Generate the interaction graph class --
          	if	(typeRef(edgecname) !== null) {
          	acceptor.accept(modl.toClass(graphcname))[
      		  documentation = meln.documentation        
                              		 
                              		 
                    val isAutoGraph = (meln.roles.get(0).type.equals(meln.roles.get(1).type))
            var isCellGraph = false
            var isCellGeomGraph = false
            var testCell1 = false
            var testCell2 = false
            var testGeom1 = false
            var testGeom2 = false
            val rol1 = meln.roles.get(0).type
            val rol2 = meln.roles.get(1).type
           
            for(e : rol1.eContents){
            	switch (e){
           	  	PropertyDef : {
           			if(e.type.simpleName.equals('Cell')){
           				testCell1 = true
           			}
           			if(e.type.simpleName.equals('Line') || e.type.simpleName.equals('MultiLine') ||
           				e.type.simpleName.equals('Polygon') || e.type.simpleName.equals('MultiPolygon') ||
           				e.type.simpleName.equals('Point') || e.type.simpleName.equals('MultiPoint') ||
           				e.type.simpleName.equals('Ring')
           			){
           				testGeom1 = true
           			}
           		}
           	}
           	
           }
            for(e : rol2.eContents){
           	switch (e){
           		PropertyDef : {
           			if(e.type.simpleName.equals('Cell')){
           				testCell2 = true
           			}
           				if(e.type.simpleName.equals('Line') || e.type.simpleName.equals('MultiLine') ||
           				e.type.simpleName.equals('Polygon') || e.type.simpleName.equals('MultiPolygon') ||
           				e.type.simpleName.equals('Point') || e.type.simpleName.equals('MultiPoint') ||
           				e.type.simpleName.equals('Ring')
           			){
           				testGeom2 = true
           			}
           		}
           	}
           	
           }
               
     
            if(testCell1 && testCell2){
            	isCellGraph = true
            }
            if(testGeom1 && testCell2 || testGeom2 && testCell1){
            	isCellGeomGraph = true
            }
                        var graphname = 'fr.ocelet.runtime.relation.impl.AutoGraph'
            
            if(!isAutoGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.DiGraph'
            }
            if(isCellGraph){
            	if(isAutoGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.CellGraph'
            	}else{
            		graphname = 'fr.ocelet.runtime.relation.impl.DiCellGraph'
            	}
            }




			 if(isCellGeomGraph){
            	graphname = 'fr.ocelet.runtime.relation.impl.GeometryCellGraph'
            }
        val graphTypeName = graphname 
          			
          			
          		if(isCellGeomGraph){	
          		val firstRole = meln.roles.get(0)                                 
              	val secondRole = meln.roles.get(1)                    
              	var tempcellType = typeRef(firstRole.type.fullyQualifiedName.toString)
              	var tempgeomType = typeRef(secondRole.type.fullyQualifiedName.toString)              
             	var tempCellName = firstRole.name
              	var tempGeomName = secondRole.name
              
             	if(testCell2){
              	
              		tempcellType = typeRef(secondRole.type.fullyQualifiedName.toString)
              		tempCellName = secondRole.name
            		tempgeomType = typeRef(firstRole.type.fullyQualifiedName.toString)
              		tempGeomName = firstRole.name
              	}
              	val cellType = tempcellType
              	val geomType = tempgeomType
              	val cellName = tempCellName
              	val geomName = tempGeomName          		 
                              		 
                                		 
              superTypes += typeRef(graphTypeName, typeRef(edgecname), cellType, geomType)
           //  else superTypes += typeRef(graphTypeName, typeRef(edgecname), firstRoleType, secondRoleType)

              // Generate an empty constructor
     		  members+= meln.toConstructor[	
     		  	body = '''
     		  	 super();
     		    ''' 
     		  ]

             
              val geomList = typeRef('fr.ocelet.runtime.ocltypes.List', geomType)
              val cellList = typeRef('fr.ocelet.runtime.ocltypes.List', cellType)
				val firstName = cellName+"s"
				val secondName = geomName+"s"
              // Generate DiGraph overridden methods : connect, getLeftSet, getRightSet
              if(testGeom1 == true){
              	   members+= meln.toMethod("connect",typeRef(Void::TYPE))[              	
                parameters += meln.toParameter(secondName,geomList)
                parameters += meln.toParameter(firstName,cellList)
              	body = ''' 
					«typeRef(edgecname)» _gen_edge = new «meln.name+"_Edge"»(«firstName», «secondName»);
					setCompleteIteratorGeomCell(_gen_edge);
              	'''
              ]
              members+= meln.toMethod("connect",typeRef(Void::TYPE))[              	
                parameters += meln.toParameter(secondName,geomList)
                parameters += meln.toParameter(firstName,cellList)
                  parameters += meln.toParameter("distance",typeRef(Double::TYPE))
                
              	body = ''' 
					«typeRef(edgecname)» _gen_edge = new «meln.name+"_Edge"»(«firstName», «secondName», distance);
					setCompleteIteratorGeomCell(_gen_edge);
              	'''
              ]

              }else{
              members+= meln.toMethod("connect",typeRef(Void::TYPE))[
              	parameters += meln.toParameter(firstName,cellList)
                parameters += meln.toParameter(secondName,geomList)
              	body = ''' 
					«typeRef(edgecname)» _gen_edge = new «meln.name+"_Edge"»(«firstName», «secondName»);
					setCompleteIteratorGeomCell(_gen_edge);
              	'''
              ]
              
                  members+= meln.toMethod("connect",typeRef(Void::TYPE))[              	
                parameters += meln.toParameter(firstName,cellList)
                parameters += meln.toParameter(secondName,geomList)               
                 parameters += meln.toParameter("distance",typeRef(Double::TYPE))
                
              	body = ''' 
					«typeRef(edgecname)» _gen_edge = new «meln.name+"_Edge"»(«firstName», «secondName», distance);
					setCompleteIteratorGeomCell(_gen_edge);
              	'''
              ]
              }
           
     		  
     		  // Generate Properties, Interactions and Filters code on the graph level
    		  for (reln:meln.relelns){
    		  	switch(reln) {
          	       	  	  InteractionDef : {
                    members+=reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  }
                      body=''' 
                      	setMode(2);
                      	cleanOperator();
                      	«listype» cvtList = ((«typeRef(edgecname)»)getEdge()).get_agr_«reln.name»();
                      	 		if(cvtList != null){
                      	 			for(«aggregType» cvt : cvtList) {
                      	 				setCellOperator(cvt);
                      	 			}
                      	 		}
                      	beginTransaction();
                      	initInteraction();
                      	for(«typeRef(edgecname)» _edg_ : this){
                      		_edg_.«reln.name»(«var ci = 0»«FOR p : reln.params»«IF ci > 0»,«ENDIF»«p.name»«{ci = 1; null}»«ENDFOR»);
                      	   	«IF (reln.comitexpressions.size() > 0)»
                      	 	«var test = false»
                      	 	«FOR ce:reln.comitexpressions»
							«IF !ce.rol.type.equals(cellType)»
							«{test = true; null}»
							«ENDIF»
							«ENDFOR»
							«IF test = true»
							_edg_._agr_«reln.name»();
							«ENDIF»
							«ENDIF»
                      	}
                      	endTransaction();
                      	endInteraction();
                      '''
                    ]
          	  	  }
          	  	  Filterdef : {
          	  	  	members += reln.toMethod(reln.name,typeRef(graphcname.toString))[
          	  	  	  for(p:reln.params) {
                        parameters += reln.toParameter(p.name,p.parameterType)
                      }
                      
                      body = '''
                        «meln.name+"_"+reln.name» _filter = new «meln.name+"_"+reln.name»(
                        «IF reln.params.size() > 0»
                        	«FOR i:0..reln.params.size()-1»
                        		«reln.params.get(i).name»
                        		«IF i < (reln.params.size()-1)»
                        			,
                        		«ENDIF»
                        	«ENDFOR»
                        «ENDIF»
                        );
                        super.addFilter(_filter);
                        return this;
                      '''
          	  	  	]
          	  	  }
 		        }
  		      }
  		      
  		      
  		      }else if (isCellGraph){
  		    	
  		    	if(!isAutoGraph){
  		    		
  		    	val firstRole = meln.roles.get(0)
        		val secondRole = meln.roles.get(1)      
              	val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
              	val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
              val firstCellList = typeRef('fr.ocelet.runtime.ocltypes.List', firstRoleType)
              val secondCellList = typeRef('fr.ocelet.runtime.ocltypes.List', secondRoleType)
				val firstName = firstRole.name+"s"
				val secondName = secondRole.name+"s"
              superTypes += typeRef(graphTypeName, typeRef(edgecname), firstRoleType, secondRoleType)

              // Generate an empty constructor
     		  members+= meln.toConstructor[	
     		  	body =  '''
     		  		super();
     		     '''
     		  ]
     		  
              members += meln.toMethod("getNearest",secondRoleType)[
          			parameters += meln.toParameter(firstRole.name,firstRoleType)
          						body = '''
          						
          							return ((«typeRef(edgecname)»)getEdge()).getNearest(«firstRole.name»);
          			'''
          			
          		]
          		
          		members += meln.toMethod("getNearest",firstRoleType)[
          			parameters += meln.toParameter(secondRole.name,secondRoleType)
          						body = '''
          							return ((«typeRef(edgecname)»)getEdge()).getNearest(«secondRole.name»);
          			'''
          			
          		]
          		
          		 members += meln.toMethod("hasNearest",typeRef(Boolean::TYPE))[
          			parameters += meln.toParameter(firstRole.name,firstRoleType)
          						body = '''
          						
          							return ((«typeRef(edgecname)»)getEdge()).hasNearest(«firstRole.name»);
          			'''
          			
          		]
          		
          		members += meln.toMethod("hasNearest",typeRef(Boolean::TYPE))[
          			parameters += meln.toParameter(secondRole.name,secondRoleType)
          						body = '''
          							return ((«typeRef(edgecname)»)getEdge()).hasNearest(«secondRole.name»);
          			'''
          			
          		]
     		  
     		  
     		  
              // Generate DiGraph overridden methods : connect, getLeftSet, getRightSet
              members+= meln.toMethod("connect",typeRef(Void::TYPE))[
            
              parameters += meln.toParameter(firstName,firstCellList)
              parameters += meln.toParameter(secondName, secondCellList)
				body = '''              		
					super.setGrid(«firstName», «secondName»);
					«typeRef(edgecname)» _gen_edge_ = new «meln.name+"_Edge"»(«firstName», «secondName»);
					setCompleteIteratorDiCell(_gen_edge_ );
				'''
              ]
     		  
     		  // Generate Properties, Interactions and Filters code on the graph level
    		  for (reln:meln.relelns){
    		  	switch(reln) {
          	  	  RelPropertyDef : {
                    members+=reln.toMethod("set"+reln.name.toFirstUpper,typeRef(Void::TYPE))[
                      parameters+= reln.toParameter(reln.name,reln.type)	
                      body= '''
                      	for( «typeRef(edgecname)» _edg_ : this )
                      	_edg_.set«reln.name.toFirstUpper»(«reln.name»);
                      '''
                    ]
          	  	  }
          	  	  InteractionDef : {
                    members+=reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  }
					body= '''
						updateGrid();
						cleanOperator();
						«listype» cvtList = ((«typeRef(edgecname)»)getEdge()).get_agr_«reln.name»();
						if(cvtList != null){
							for(«aggregType» cvt : cvtList){
								setCellOperator(cvt);
							}
						}
						initInteraction();
						for(«typeRef(edgecname)» _edg_ : this) {
							_edg_.«reln.name»(«var ci = 0»«FOR p : reln.params»«IF ci > 0»,«ENDIF»«p.name»«{ci = 1; null}»«ENDFOR»);
						}
						endInteraction();
                      '''
                    ]
          	  	  }
          	  	  Filterdef : {
          	  	   	members += reln.toMethod(reln.name,typeRef(graphcname.toString))[
          	  	  	  for(p:reln.params) {
                        parameters += reln.toParameter(p.name,p.parameterType)
                      }
                      
                      body = '''
                        «meln.name+"_"+reln.name» _filter = new «meln.name+"_"+reln.name»(
                        «IF reln.params.size() > 0»
                        	«FOR i:0..reln.params.size()-1»
                        		«reln.params.get(i).name»
                        		«IF i < (reln.params.size()-1)»
                        			,
                        		«ENDIF»
                        	«ENDFOR»
                        «ENDIF»
                        );
                        super.addFilter(_filter);
                        return this;
                      '''
          	  	  	]
          	  	  }
 		        }
  		      }
  		    		
  		    		
  		    		}else{
  		    			
  		    			
  		    	val firstRole = meln.roles.get(0)
  		    	val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)

				val firstCellList = typeRef('fr.ocelet.runtime.ocltypes.List', firstRoleType)
				val firstName = firstRole.name
				val getEntity = "getAll"+firstRoleType.simpleName
                val getEntity_dep = "get"+firstRoleType.simpleName+"s"             
              
              superTypes += typeRef(graphTypeName, typeRef(edgecname), firstRoleType)

              // Generate an empty constructor
     		  members+= meln.toConstructor[	
     		  	body = '''
     		  		 super();
     		    '''
     		  ]
				members+= meln.toMethod(getEntity, firstCellList)[
              
              	body = '''
					«firstRoleType» entity = new «firstRoleType»();
					
					((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
					«firstCellList» array = new «firstCellList»();
					array.cellCut();
					array.add(entity);
					return array;
				'''
              ]
              
              // Deprecated getAll method
              members+= meln.toMethod(getEntity_dep, firstCellList)[
				annotations += annotationRef("java.lang.Deprecated");
				body = '''return «getEntity»();'''
              ]

              
              // Generate DiGraph overridden methods : connect, getLeftSet, getRightSet
              members+= meln.toMethod("connect",typeRef(Void::TYPE))[
              	parameters += meln.toParameter(firstName, firstCellList)
              
              	body = '''
					super.setGrid(«firstName»);
					«typeRef(edgecname)» _gen_edge_ = new «meln.name+"_Edge"»(«firstName»);
					setCompleteIteratorCell(_gen_edge_ );
				'''
              ]
              
              	/* Generate method for generation graphs */
              	 
          		members += meln.toMethod("createHexagons",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("shp",typeRef("fr.ocelet.datafacer.ocltypes.Shapefile"))
          		parameters += meln.toParameter("size",typeRef('java.lang.Double'))
				body = '''
					«firstRoleType» entity = new «firstRoleType»();
					grid = createHexagon("«firstRoleType»",entity.getProps(), shp.getBounds(), size);
					((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
					«firstCellList» array = new «firstCellList»();
					array.cellCut();
					array.add(entity);
					connect(array);
				'''
          		]
          		
          		members += meln.toMethod("createHexagons",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("geometry",typeRef("com.vividsolutions.jts.geom.Geometry"))
          		parameters += meln.toParameter("size",typeRef('java.lang.Double'))
          		body = '''
					«firstRoleType» entity = new «firstRoleType»();
					grid = createHexagon("«firstRoleType»",entity.getProps(), geometry, size);
					((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
					«firstCellList» array = new «firstCellList»();
					array.cellCut();
					array.add(entity);
					connect(array);
				'''
          		]
          		
          		members += meln.toMethod("createHexagons",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("size",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("minX",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("minY",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("maxX",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("maxY",typeRef('java.lang.Double'))
          			
          		body = '''
					«firstRoleType» entity = new «firstRoleType»();
					grid =  createHexagon("«firstRoleType»",entity.getProps(), minX, minY, maxX, maxY, size);
					((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
					«firstCellList» array = new «firstCellList»();
					array.cellCut();
					array.add(entity);
					connect(array);
				'''
          		]
          			members += meln.toMethod("createSquares",typeRef(Void::TYPE))[
          			parameters += meln.toParameter("shp",typeRef("fr.ocelet.datafacer.ocltypes.Shapefile"))
          			parameters += meln.toParameter("xRes",typeRef('java.lang.Double'))
          			parameters += meln.toParameter("yRes",typeRef('java.lang.Double'))
          			body = '''
						«firstRoleType» entity = new «firstRoleType»();
						grid = createSquare("«firstRoleType»",entity.getProps(), shp.getBounds(), xRes, yRes);
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						«firstCellList» array = new «firstCellList»();
						array.cellCut();
						array.add(entity);
						connect(array);
					'''
          		]
          		members += meln.toMethod("createSquares",typeRef(Void::TYPE))[
          			parameters += meln.toParameter("geometry",typeRef("com.vividsolutions.jts.geom.Geometry"))
          			parameters += meln.toParameter("xRes",typeRef('java.lang.Double'))
          			parameters += meln.toParameter("yRes",typeRef('java.lang.Double'))
          			body = '''
						«firstRoleType» entity = new «firstRoleType»();
						grid = createSquare("«firstRoleType»",entity.getProps(), geometry, xRes, yRes);
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						«firstCellList» array = new «firstCellList»();
						array.cellCut();
						array.add(entity);
						connect(array);
					'''
          		]
          		
          		members += meln.toMethod("createSquares",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("xRes",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("yRes",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("minX",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("minY",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("maxX",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("maxY",typeRef('java.lang.Double'))
          			
          		body = '''
					«firstRoleType» entity = new «firstRoleType»();
					grid = createSquare("«firstRoleType»",entity.getProps(), minX, minY, maxX, maxY, xRes, yRes);
					((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
					«firstCellList» array = new «firstCellList»();
					array.cellCut();
					array.add(entity);
					connect(array);
          			'''
          		]
          		members += meln.toMethod("createTriangles",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("geometry",typeRef("com.vividsolutions.jts.geom.Geometry"))
          		parameters += meln.toParameter("size",typeRef('java.lang.Double'))
          			body = '''
						«firstRoleType» entity = new «firstRoleType»();
						grid = createTriangle("«firstRoleType»",entity.getProps(), geometry, size);
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						«firstCellList» array = new «firstCellList»();
						array.cellCut();
						array.add(entity);
						connect(array);
						
          			'''
          		]
          		members += meln.toMethod("createTriangles",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("shp",typeRef("fr.ocelet.datafacer.ocltypes.Shapefile"))
          		parameters += meln.toParameter("size",typeRef('java.lang.Double'))
          			body = '''
						«firstRoleType» entity = new «firstRoleType»();
						grid = createTriangle("«firstRoleType»",entity.getProps(), shp.getBounds(), size);
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);
						«firstCellList» array = new «firstCellList»();
						array.cellCut();
						array.add(entity);
						connect(array);
						
          			'''
          		]
          		
          		members += meln.toMethod("createTriangles",typeRef(Void::TYPE))[
          		parameters += meln.toParameter("size",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("minX",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("minY",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("maxX",typeRef('java.lang.Double'))
          		parameters += meln.toParameter("maxY",typeRef('java.lang.Double'))	
          			body = '''
						«firstRoleType» entity = new «firstRoleType»();
						grid = createTriangle("«firstRoleType»",entity.getProps(), minX, minY, maxX, maxY, size);
						((«typeRef("fr.ocelet.runtime.geom.ocltypes.Cell")»)entity.getSpatialType()).setGrid(grid);						
						«firstCellList» array = new «firstCellList»();
						array.cellCut();
						array.add(entity);
						connect(array);
						
          			'''
          		]
              
              
     		  
     		  // Generate Properties, Interactions and Filters code on the graph level
    		  for (reln:meln.relelns){
    		  	switch(reln) {
          	  	  RelPropertyDef : {
                    members+=reln.toMethod("set"+reln.name.toFirstUpper,typeRef(Void::TYPE))[
                      parameters+= reln.toParameter(reln.name,reln.type)	
                      body='''
                      	
                      	for(«typeRef(edgecname)» _edg_ : this)
                      	_edg_.set«reln.name.toFirstUpper»(«reln.name»);
                      '''
                    ]
          	  	  }
          	  	  InteractionDef : {
                    members+=reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  }
                      body= '''
						setMode(0);
						cleanOperator();
						«listype» cvtList = ((«typeRef(edgecname)»)getEdge()).get_agr_«reln.name»();
						if(cvtList != null){
							for(«aggregType» cvt : cvtList){
								setCellOperator(cvt);
							} 
						}
						initInteraction();
						for(«typeRef(edgecname)» _edg_ : this) {
							_edg_.«reln.name»(«var ci = 0»«FOR p:reln.params» «IF ci > 0»,«ENDIF»«p.name»«{ci = 1; null}»«ENDFOR»);
						}
						endInteraction();
                      '''
                    ]
          	  	  }
          	  	  Filterdef : {
          	  	  	members += reln.toMethod(reln.name,typeRef(graphcname.toString))[
          	  	  	  for(p:reln.params) {
                        parameters += reln.toParameter(p.name,p.parameterType)
                      }
					body = '''
						«meln.name+"_"+reln.name» _filter = new «meln.name+"_"+reln.name»(
						«IF reln.params.size() > 0»
							«FOR i : 0..reln.params.size() - 1»	
								«reln.params.get(i).name»
								«IF i < (reln.params.size()-1)»	
									,
								«ENDIF»
							«ENDFOR»
						«ENDIF»
						);
						super.addFilter(_filter);
						return this;
                      '''
          	  	  	]
          	  	  }
 		        }
  		      }
  		    			}

  		    	
  		    	
  		    }else{
  		    	
  		    	 if ((meln.roles.size >= 2) &&
             (meln.roles.get(0)!==null) && (meln.roles.get(1)!==null) &&
             (meln.roles.get(0).type !== null) && (meln.roles.get(1).type !== null) &&
       	     (meln.roles.get(0).type.fullyQualifiedName !== null) &&
             (meln.roles.get(1).type.fullyQualifiedName !== null) &&
             (meln.roles.get(0).name !== null) && (meln.roles.get(1).name !== null)
             ) {
              val firstRole = meln.roles.get(0)
              val secondRole = meln.roles.get(1)
              val firstRoleType = typeRef(firstRole.type.fullyQualifiedName.toString)
              val secondRoleType = typeRef(secondRole.type.fullyQualifiedName.toString)
              val rolset1 = meln.roles.get(0).name+"Set"
              val rolset2 = meln.roles.get(1).name+"Set"
              //val isAutoGraph = (meln.roles.get(0).type.equals(meln.roles.get(1).type))
              //val graphTypeName = if(isAutoGraph) 'fr.ocelet.runtime.relation.impl.AutoGraph'
                //                           else 'fr.ocelet.runtime.relation.impl.DiGraph'               		  
             if (isAutoGraph) superTypes += typeRef(graphTypeName, typeRef(edgecname), firstRoleType)
             else superTypes += typeRef(graphTypeName, typeRef(edgecname), firstRoleType, secondRoleType)

              // Generate an empty constructor
     		  members+= meln.toConstructor[	body = '''super();''' ]

              // Generate DiGraph overridden methods : connect, getLeftSet, getRightSet
              members+= meln.toMethod("connect",typeRef(edgecname))[
              	parameters += meln.toParameter(firstRole.name,firstRoleType)
              	parameters += meln.toParameter(secondRole.name,secondRoleType)
                body = '''
                if ((this.«rolset1» == null) || (!this.«rolset1».contains(«firstRole.name»))) add(«firstRole.name»);
                «IF (!isAutoGraph)»
                if ((this.«rolset2» == null) || (!this.«rolset2».contains(«secondRole.name»))) add(«secondRole.name»);
                «ELSE»
                if ((this.«rolset1» == null) || (!this.«rolset1».contains(«secondRole.name»))) add(«secondRole.name»);
                «ENDIF»
                «val typ_edgecname = typeRef(edgecname)»
                «typ_edgecname» _gen_edge_ = new «meln.name+"_Edge"»(this,«firstRole.name»,«secondRole.name»);
                addEdge(_gen_edge_);
                return _gen_edge_;
                '''
              ]
              
              members+= meln.toMethod("getLeftSet", typeRef("fr.ocelet.runtime.relation.RoleSet",firstRoleType))[
              	body ='''return «rolset1»;'''
              ]
              
              members+= meln.toMethod("getRightSet", typeRef("fr.ocelet.runtime.relation.RoleSet",secondRoleType))[
              	body =''' 
              	 «IF (isAutoGraph)»return «rolset1»;
              	 «ELSE»return «rolset2»;
              	 «ENDIF»
              	'''
               ]

          	   members +=meln.toMethod("getComplete",typeRef(graphcname.toString)) [
          			body='''return («meln.name»)super.getComplete();'''
          	   ]

               members += meln.toMethod("createEdge",typeRef(edgecname))[
               	  parameters += firstRole.toParameter(firstRole.name,firstRoleType)
               	  parameters += secondRole.toParameter(secondRole.name,secondRoleType)
               	  body = ''' return new «meln.name+"_Edge"»(this,«firstRole.name»,«secondRole.name»);'''
               ]


              // -- Generate RoleSet fields, setters, getters and add+remove role functions --

     		    val rsetype =  typeRef("fr.ocelet.runtime.relation.RoleSet",firstRoleType)
     		  	val rsfield = meln.toField(rolset1,rsetype)
     		  	if (rsfield !== null) {
     		  	  members += rsfield
  		          members+= meln.toMethod('set'+rolset1.toFirstUpper, typeRef(Void::TYPE))[
   		            parameters += firstRole.toParameter("croles",typeRef('java.util.Collection',firstRoleType))
                    body='''
     		          «val rsimplt = typeRef("fr.ocelet.runtime.relation.impl.RoleSetImpl",firstRoleType)»
     		          this.«rolset1»=new «rsimplt»(croles);
     		  	    '''
   		  	      ]
   		  	      
   		  	      members+= meln.toMethod('get'+rolset1.toFirstUpper, rsetype)[
   		  	      	body ='''return «rolset1»;'''
   		  	      ]

                  if(!isAutoGraph) {
     		        val rsetype2 =  typeRef("fr.ocelet.runtime.relation.RoleSet",secondRoleType)
     		  	    val rsfield2 = meln.toField(rolset2,rsetype2)
     		  	    if (rsfield2 !== null) {
     		  	      members += rsfield2

   		              members+= meln.toMethod('set'+rolset2.toFirstUpper, typeRef(Void::TYPE))[
     		            parameters += secondRole.toParameter("croles",typeRef('java.util.Collection',secondRoleType))
                        body='''
                          «val rsimplt = typeRef("fr.ocelet.runtime.relation.impl.RoleSetImpl",secondRoleType)»
                          this.«rolset2»=new «rsimplt»(croles);
                        '''
   		  	          ]
   		  	      
   		  	          members+= meln.toMethod('get'+rolset2.toFirstUpper, rsetype2)[
   		  	      	    body ='''return «rolset2»;'''
   		  	          ]
                    }
                  }
   		  	      
   		  	      members += meln.toMethod('add',typeRef(Void::TYPE))[
   		  	      	parameters += meln.toParameter('role', firstRoleType)
   		  	      	body = '''add«firstRoleType»(role);'''
   		  	      ]

   		  	      members += meln.toMethod('remove',typeRef(Void::TYPE))[
   		  	      	parameters += meln.toParameter('role', firstRoleType)
   		  	      	body = '''remove«firstRoleType»(role);'''
   		  	      ]

                  members += meln.toMethod('add'+firstRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	parameters += meln.toParameter('role',firstRoleType)
   		  	      	body = '''
   		  	      	  «val ltype = typeRef('java.util.HashSet',firstRoleType)»
   		  	      	  if (this.«rolset1» == null) set«rolset1.toFirstUpper»( new «ltype»());
   		  	      	  this.«rolset1».addRole(role);
   		  	      	'''
   		  	      ]

   		  	      members += meln.toMethod('remove'+firstRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	parameters += meln.toParameter('role', firstRoleType)
   		  	      	body = '''if (this.«rolset1» != null) this.«rolset1».removeRole(role);'''
   		  	      ]
 		  	      
   		  	      members += meln.toMethod('addAll'+firstRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	parameters += meln.toParameter('roles',typeRef('java.lang.Iterable',firstRoleType))
   		  	      	body = '''
   		  	      	  «val ltype = typeRef('java.util.HashSet',firstRoleType)»
   		  	      	  if (this.«rolset1» == null) set«rolset1.toFirstUpper»( new «ltype»());
   		  	      	  this.«rolset1».addRoles(roles);
   		  	      	'''
   		  	      ]

                  members += meln.toMethod('removeAll'+firstRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	parameters += meln.toParameter('roles',typeRef('java.lang.Iterable',firstRoleType))
   		  	      	body = '''if (this.«rolset1» != null) this.«rolset1».removeRoles(roles);'''
   		  	      ]
   		  	      
   		  	      if (!isAutoGraph) {
                    members += meln.toMethod('add'+secondRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	  parameters += meln.toParameter('role',secondRoleType)
   		  	      	  body = '''
   		  	      		«val ltype = typeRef('java.util.HashSet',secondRoleType)»
   		  	      		if (this.«rolset2» == null) set«rolset2.toFirstUpper»( new «ltype»());
   		  	      		this.«rolset2».addRole(role);
   		  	      	  '''
   		  	        ]

   		  	        members += meln.toMethod('remove',typeRef(Void::TYPE))[
   		  	      	  parameters += meln.toParameter('role', secondRoleType)
   		  	      	  body = '''remove«secondRoleType»(role);'''
   		  	        ]

   		  	        members += meln.toMethod('add',typeRef(Void::TYPE))[
   		  	      	  parameters += meln.toParameter('role', secondRoleType)
   		  	      	  body = '''add«secondRoleType»(role);'''
   		  	        ]

   		  	        members += meln.toMethod('remove'+secondRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	  parameters += meln.toParameter('role', secondRoleType)
   		  	      	  body = '''if (this.«rolset2» != null) this.«rolset2».removeRole(role);'''
   		  	        ]

   		  	        members += meln.toMethod('addAll'+secondRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	  parameters += meln.toParameter('roles',typeRef('java.lang.Iterable',secondRoleType))
   		  	      	  body = '''
   		  	      		«val rtype = typeRef('java.util.HashSet',secondRoleType)»
   		  	      		if (this.«rolset2» == null) set«rolset2.toFirstUpper»( new «rtype»());
   		  	      		this.«rolset2».addRoles(roles);
   		  	      	  '''
   		  	        ]

                    members += meln.toMethod('removeAll'+secondRoleType.simpleName,typeRef(Void::TYPE))[
   		  	      	  parameters += meln.toParameter('roles',typeRef('java.lang.Iterable',secondRoleType))
   		  	      	  body = '''if (this.«rolset2» != null) this.«rolset2».removeRoles(roles);'''
   		  	        ]
   		  	      } // if roles are well defined
   		  	   }
   		     }
     		  
     		  // Generate Properties, Interactions and Filters code on the graph level
    		  for (reln:meln.relelns){
    		  	switch(reln) {
          	  	  RelPropertyDef : {
          	  	  	if (reln.name !== null) {
                    members+=reln.toMethod("set"+reln.name.toFirstUpper,typeRef(Void::TYPE))[
                      parameters+= reln.toParameter(reln.name,reln.type)	
                      body='''
                      	«val typ_edgecname = typeRef(edgecname)»
                      	beginTransaction();
                      	for(«typ_edgecname» _edg_ : this)
                      	  _edg_.set«reln.name.toFirstUpper»(«reln.name»);
                      	endTransaction();
                      '''
                    ]}
          	  	  }
          	  	  InteractionDef : {
          	  	  	if (reln.name !== null) {
                    members+=reln.toMethod(reln.name,typeRef(Void::TYPE))[
          	  	  	  for(p:reln.params){
          	  	  	  	parameters += reln.toParameter(p.name,p.parameterType)
          	  	  	  }
                      body='''
                      	«val typ_edgecname = typeRef(edgecname)»
                      	beginTransaction();
                      	«var ci=0»
                      	for(«typ_edgecname» _edg_ : this) {
                      	  _edg_.«reln.name»(«FOR p:reln.params»«IF (ci++ > 0)»,«ENDIF»«p.name»«ENDFOR»);
                      	 «IF (reln.comitexpressions.size() > 0)»
                      	 _edg_._agr_«reln.name»();«ENDIF»
                      	}
                      	endTransaction();
                      '''
                    ]}
          	  	  }
          	  	  Filterdef : {
          	  	  	if (reln.name !== null) {
          	  	  	members += reln.toMethod(reln.name,typeRef(graphcname.toString))[
          	  	  	  for(p:reln.params) {
                        parameters += reln.toParameter(p.name,p.parameterType)
                      }
                      body ='''
                        «meln.name+"_"+reln.name» _filter = new «meln.name+"_"+reln.name»(«IF (reln.params.size() > 0)»«FOR i:0..(reln.params.size()-1)»«reln.params.get(i).name»«IF i < (reln.params.size()-1)»,«ENDIF»«ENDFOR»«ENDIF»);
                        super.addFilter(_filter);
                        return this;
                      '''
          	  	  	]}
          	  	  }
 		        }
  		      }
    		    	
  		    	}
    		      
     		]
     	}
	}

                     
       // ---- Structure -----------------------------------
          Strucdef : {
          	acceptor.accept(modl.toClass(meln.fullyQualifiedName))[
              if (meln.typeArgument !== null) {
                val JvmTypeParameter param = TypesFactory::eINSTANCE.createJvmTypeParameter
                param.setName(meln.typeArgument)
                typeParameters += param
       		    if (meln.superType !== null)
       		      {
       		        superTypes += typeRef(meln.superType, typeRef(param))
                   }
       		    }
       		    else if (meln.superType !== null) superTypes += typeRef(meln.superType)
              val List<StrucVarDef> lvdefs = <StrucVarDef>newArrayList()
          	  for(steln:meln.strucelns) {
          	  	switch(steln) {
          	  	  StrucVarDef: {
          	  	   lvdefs.add(steln)
          	  	   var jvmField = steln.toField(steln.name, steln.type)
          	  	     if (jvmField !== null) {
          	  	       jvmField.setFinal(false) 
          		       members+= jvmField
          		       members+= steln.toSetter(steln.name, steln.type)
          		       members+= steln.toGetter(steln.name, steln.type)
          		     }
      		      }
      		      StrucFuncDef: {
          	  	    if (steln.type === null) steln.type = typeRef(Void::TYPE)
          	  	    members += steln.toMethod(steln.name,steln.type)[
          	  	      documentation = steln.documentation
      		  	      for (p: steln.params) {
      		  	        parameters += p.toParameter(p.name, p.parameterType)
      		  	      }
  		  		      body = steln.body
          	   	    ]
       		      }
      		    }  
          	  }
          	  members += meln.toConstructor[
          	  	body = '''
          	  	  super();«FOR vardef:lvdefs»
          	  	  «var vtyp = vardef.type»
          	  	  «IF !vtyp.primitive»«vardef.name» = new «vtyp»«IF vtyp.isNumberType»("0");«ELSEIF vtyp.qualifiedName.equals("java.lang.Boolean")»(false);«ELSE»();«ENDIF»
                   «ENDIF»
                  «ENDFOR»
                '''
          	  ]
          	]
          }
    
   	    }          // switch(meln)

      } catch (Exception e) {
	      println('''Exception caught : «e.getMessage()»''')
        }
    }

     
    // ---- Scenario -----------------------------------
    // Génération de la classe qui contient le main() et d'une methode par scenario
    if (mainScen) {
      acceptor.accept(modl.toClass(packg+modlName)) [
          documentation = modl.documentation
          superTypes += typeRef('fr.ocelet.runtime.model.AbstractModel')
          members+= modl.toConstructor[
          // Metadata related code generation
          body = '''
            super("«modlName»");
            «IF (md.getModeldesc !== null)»modDescription = "«md.getModeldesc»";«ENDIF»
            «IF (md.getWebpage !== null)»modelWebPage = "«md.getWebpage»";«ENDIF»
            «IF (md.hasParameters)»
            «FOR pstuff:md.params»
            «val genptype = typeRef('fr.ocelet.runtime.model.Parameter',pstuff.getType)»
            «IF(pstuff.numericType)»
              «val implptype = typeRef('fr.ocelet.runtime.model.NumericParameterImpl',pstuff.getType)»
              «genptype» par_«pstuff.getName» = new «implptype»("«pstuff.getName»","«pstuff.getDescription»",«pstuff.getOptionnal»,«pstuff.getDvalueString»«IF (pstuff.getMinvalue === null)»,null«ELSE»,«pstuff.getMinvalue»«ENDIF»«IF (pstuff.getMaxvalue === null)»,null«ELSE»,«pstuff.getMaxvalue»«ENDIF»«IF (pstuff.getUnit === null)»,null«ELSE»,«pstuff.getUnit»«ENDIF»);
            «ELSE»
              «val implptype = typeRef('fr.ocelet.runtime.model.ParameterImpl',pstuff.getType)»
              «genptype» par_«pstuff.getName» = new «implptype»("«pstuff.getName»","«pstuff.getDescription»",«pstuff.getOptionnal»,«pstuff.getDvalueString»«IF (pstuff.getUnit === null)»,null«ELSE»,"«pstuff.getUnit»"«ENDIF»);
            «ENDIF»
            addParameter(par_«pstuff.getName»);
            «IF (pstuff.getDvalue !== null)»
            «pstuff.name» = «pstuff.getDvalueString»;
            «ENDIF»
            «ENDFOR»
            «ENDIF»
          '''
          ]
                  
          for(scen:scens) {
   	  	    if (scen.name.compareTo(modlName) == 0) {
              members += modl.toMethod("main",typeRef(Void.TYPE)) [
              	 parameters += modl.toParameter('args', typeRef('java.lang.String').addArrayTypeDimension)
              	 setStatic(true)
                 body = '''
                 «modlName» model_«modlName» = new «modlName»();
                 model_«modlName».run_«modlName»();'''
              ]
              members += modl.toMethod("run_"+modlName,typeRef(Void.TYPE)) [
              	body = scen.body
              ]
              members += modl.toMethod("simulate",typeRef(Void.TYPE)) [
              parameters += modl.toParameter('in_params',typeRef('java.util.HashMap',typeRef('java.lang.String'),typeRef('java.lang.Object')))
              body = '''
              «IF (md.hasParameters)»
                «FOR pstuff:md.params»
                  «pstuff.getType.getSimpleName» val_«pstuff.getName» = («pstuff.getType.getSimpleName») in_params.get("«pstuff.getName»");
                  if (val_«pstuff.getName» != null) «pstuff.getName» = val_«pstuff.getName»;
                «ENDFOR»
              «ENDIF»
              run_«modlName»();
              ''']
   	  	    } else {
   	  	      var rtype = scen.type
      		  if (rtype === null) rtype = typeRef(Void::TYPE)
              members += scen.toMethod(scen.name,rtype) [
                for (p: scen.params) {
      		  	  parameters += p.toParameter(p.name, p.parameterType)
      		    }
      		  	body = scen.body
              ]
             }
           }
           // Produces a field for every declared parameter
           if (md.hasParameters) {
             for(pstuff:md.params) {
               var jvmField = modl.toField(pstuff.name, pstuff.type)
          	  	 if (jvmField !== null) {
          	  	  jvmField.setFinal(false)
          		  members+= jvmField
          		  members+= modl.toSetter(pstuff.name, pstuff.type)
          		  members+= modl.toGetter(pstuff.name, pstuff.type)
          		 }
          	   }
            }            
         ]
      }
  }
  
  private def boolean isNumberType(JvmTypeReference vtyp){
  	return vtyp.qualifiedName.equals("java.lang.Integer") ||
  	       vtyp.qualifiedName.equals("java.lang.Double") ||
           vtyp.qualifiedName.equals("java.lang.Float") ||
           vtyp.qualifiedName.equals("java.lang.Long") ||
           vtyp.qualifiedName.equals("java.lang.Byte") ||
           vtyp.qualifiedName.equals("java.lang.Short")
   }
}

