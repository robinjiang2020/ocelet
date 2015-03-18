/**
 */
package fr.ocelet.lang.ocelet;

import org.eclipse.emf.ecore.EFactory;

/**
 * <!-- begin-user-doc -->
 * The <b>Factory</b> for the model.
 * It provides a create method for each non-abstract class of the model.
 * <!-- end-user-doc -->
 * @see fr.ocelet.lang.ocelet.OceletPackage
 * @generated
 */
public interface OceletFactory extends EFactory
{
  /**
   * The singleton instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  OceletFactory eINSTANCE = fr.ocelet.lang.ocelet.impl.OceletFactoryImpl.init();

  /**
   * Returns a new object of class '<em>Model</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Model</em>'.
   * @generated
   */
  Model createModel();

  /**
   * Returns a new object of class '<em>Mod Eln</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Mod Eln</em>'.
   * @generated
   */
  ModEln createModEln();

  /**
   * Returns a new object of class '<em>Metadata</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Metadata</em>'.
   * @generated
   */
  Metadata createMetadata();

  /**
   * Returns a new object of class '<em>Parameter</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Parameter</em>'.
   * @generated
   */
  Parameter createParameter();

  /**
   * Returns a new object of class '<em>Parampart</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Parampart</em>'.
   * @generated
   */
  Parampart createParampart();

  /**
   * Returns a new object of class '<em>Paramunit</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Paramunit</em>'.
   * @generated
   */
  Paramunit createParamunit();

  /**
   * Returns a new object of class '<em>Paramdefa</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Paramdefa</em>'.
   * @generated
   */
  Paramdefa createParamdefa();

  /**
   * Returns a new object of class '<em>Rangevals</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Rangevals</em>'.
   * @generated
   */
  Rangevals createRangevals();

  /**
   * Returns a new object of class '<em>Paradesc</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Paradesc</em>'.
   * @generated
   */
  Paradesc createParadesc();

  /**
   * Returns a new object of class '<em>Paraopt</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Paraopt</em>'.
   * @generated
   */
  Paraopt createParaopt();

  /**
   * Returns a new object of class '<em>Entity</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Entity</em>'.
   * @generated
   */
  Entity createEntity();

  /**
   * Returns a new object of class '<em>Entity Elements</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Entity Elements</em>'.
   * @generated
   */
  EntityElements createEntityElements();

  /**
   * Returns a new object of class '<em>Property Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Property Def</em>'.
   * @generated
   */
  PropertyDef createPropertyDef();

  /**
   * Returns a new object of class '<em>Service Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Service Def</em>'.
   * @generated
   */
  ServiceDef createServiceDef();

  /**
   * Returns a new object of class '<em>Constructor Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Constructor Def</em>'.
   * @generated
   */
  ConstructorDef createConstructorDef();

  /**
   * Returns a new object of class '<em>Relation</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Relation</em>'.
   * @generated
   */
  Relation createRelation();

  /**
   * Returns a new object of class '<em>Role</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Role</em>'.
   * @generated
   */
  Role createRole();

  /**
   * Returns a new object of class '<em>Rel Elements</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Rel Elements</em>'.
   * @generated
   */
  RelElements createRelElements();

  /**
   * Returns a new object of class '<em>Rel Property Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Rel Property Def</em>'.
   * @generated
   */
  RelPropertyDef createRelPropertyDef();

  /**
   * Returns a new object of class '<em>Interaction Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Interaction Def</em>'.
   * @generated
   */
  InteractionDef createInteractionDef();

  /**
   * Returns a new object of class '<em>Comitexpr</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Comitexpr</em>'.
   * @generated
   */
  Comitexpr createComitexpr();

  /**
   * Returns a new object of class '<em>Filterdef</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Filterdef</em>'.
   * @generated
   */
  Filterdef createFilterdef();

  /**
   * Returns a new object of class '<em>Strucdef</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Strucdef</em>'.
   * @generated
   */
  Strucdef createStrucdef();

  /**
   * Returns a new object of class '<em>Struc Eln</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Struc Eln</em>'.
   * @generated
   */
  StrucEln createStrucEln();

  /**
   * Returns a new object of class '<em>Struc Var Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Struc Var Def</em>'.
   * @generated
   */
  StrucVarDef createStrucVarDef();

  /**
   * Returns a new object of class '<em>Struc Func Def</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Struc Func Def</em>'.
   * @generated
   */
  StrucFuncDef createStrucFuncDef();

  /**
   * Returns a new object of class '<em>Datafacer</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Datafacer</em>'.
   * @generated
   */
  Datafacer createDatafacer();

  /**
   * Returns a new object of class '<em>Match</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Match</em>'.
   * @generated
   */
  Match createMatch();

  /**
   * Returns a new object of class '<em>Matchtype</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Matchtype</em>'.
   * @generated
   */
  Matchtype createMatchtype();

  /**
   * Returns a new object of class '<em>Mdef</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Mdef</em>'.
   * @generated
   */
  Mdef createMdef();

  /**
   * Returns a new object of class '<em>Agregdef</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Agregdef</em>'.
   * @generated
   */
  Agregdef createAgregdef();

  /**
   * Returns a new object of class '<em>Scenario</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Scenario</em>'.
   * @generated
   */
  Scenario createScenario();

  /**
   * Returns the package supported by this factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the package supported by this factory.
   * @generated
   */
  OceletPackage getOceletPackage();

} //OceletFactory
