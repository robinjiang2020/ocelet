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
package fr.ocelet.lang.validation

import fr.ocelet.lang.ocelet.Datafacer
import fr.ocelet.lang.ocelet.Entity
import fr.ocelet.lang.ocelet.Match
import fr.ocelet.lang.ocelet.Mdef
import fr.ocelet.lang.ocelet.OceletPackage
import fr.ocelet.lang.ocelet.Paramdefa
import fr.ocelet.lang.ocelet.Parameter
import fr.ocelet.lang.ocelet.PropertyDef
import fr.ocelet.lang.ocelet.Rangevals
import fr.ocelet.lang.ocelet.RelPropertyDef
import fr.ocelet.lang.ocelet.Strucdef
import fr.ocelet.lang.ocelet.StrucVarDef
import org.eclipse.xtext.validation.Check

/**
 * Custom validation rules of the editor
 * 
 * @author Pascal Degenne - Initial contribution
 */
class OceletValidator extends AbstractOceletValidator {

val static ldn = new java.util.ArrayList<String>


/**
 * Make sure the given datafacer type does exist
 */
@Check
def checkDatafacerType(Datafacer df) {
  if (ldn.size == 0) {
    ldn.add("Csvfile")
    ldn.add("KmlExport")
    ldn.add("Postgis")
    ldn.add("RasterFile")
    ldn.add("Shapefile")
    ldn.add("TemporalSeriesFile")
  }
  if (!ldn.contains(df.storetype)) {
  	error("Unknown datafacer type.",OceletPackage.Literals.DATAFACER__STORETYPE)
  }
}

/**
 * Property names must not begin with an uppercase letter
 */
 @Check
 def checkPropertyNameLowercase(PropertyDef pdef){
 	if (Character.isUpperCase((pdef.name.charAt(0))))
 	  error('The name of a property must not begin with an upper case character. Thank you.',OceletPackage.Literals.ENTITY_ELEMENTS__NAME)
 }

/**
 * Property names must not begin with an uppercase letter
 */
 @Check
 def checkRelPropertyNameLowercase(RelPropertyDef rpdef){
 	if (Character.isUpperCase((rpdef.name.charAt(0))))
 	  error('The name of a property must not begin with an upper case character. Thank you.',OceletPackage.Literals.REL_ELEMENTS__NAME)
 }

/**
 * Structure variable  names must not begin with an uppercase letter
 */
 @Check
 def checkStrucVarNameLowercase(StrucVarDef svd){
 	if (Character.isUpperCase((svd.name.charAt(0))))
 	  error('The variable name of a structure must not begin with an upper case character. Thank you.',OceletPackage.Literals.STRUC_ELN__NAME)
 }


 /**
  * Makes sure that every datafacer match definition is defined in the
  * corresponding entity (or structure)
  */
 @Check
 def checkMatchElements(Mdef mdef){
   val match = mdef.eContainer as Match
   val mt = match.mtype
   var propfound = false
   switch(mt) {
     Entity: {
       for (eln:mt.entelns)
       switch(eln) {
         PropertyDef: {
           if (eln.name.compareTo(mdef.prop) == 0) propfound=true
         }
       }
       if (!propfound) error('The entity '+mt.name+' has no property named '+mdef.prop,OceletPackage.Literals.MDEF__PROP)
     }
     Strucdef: {
       for (eln:mt.strucelns)
       switch(eln){
         StrucVarDef: {
            if (eln.name.compareTo(mdef.prop) == 0) propfound=true
         }
       }
       if (!propfound) error('The structure '+mt.name+' has no field named '+mdef.prop,OceletPackage.Literals.MDEF__PROP)
     }
   }
}


	@Check
	def checkParamDefaultWithinRange(Parameter parameter) {
		if (parameter.paramparts != null) {
			var sdef = ""
			var rgmin = 0.0
			var rgmax = 0.0
			var rangeDef = false
			for (pp : parameter.paramparts) {
				switch (pp) {
					Paramdefa: {
						sdef = pp.pardefa
					}
					Rangevals: {
						try {
						  rgmin = new Double(pp.parmin)
						  rgmax = new Double(pp.parmax)
						  rangeDef = true
						} catch (NumberFormatException nfe) {
							warning('Parameter range values must be valid numeric values',OceletPackage.Literals.PARAMETER__NAME)
						}
					}
				}
			}
			if (rangeDef) {
				try {
					val ddef = new Double(sdef)
					if ((ddef < rgmin) || (ddef > rgmax))
						warning('The default value of parameter ' + parameter.name + ' is not within the defined range',
							OceletPackage.Literals.PARAMETER__NAME)
				} catch (NumberFormatException e) {
					warning(
						'The parameter Range can only be used for numeric values and ' + sdef +
							' is not a valid numeric value.', OceletPackage.Literals.PARAMETER__NAME)
				}

			}
		}
	}
}

