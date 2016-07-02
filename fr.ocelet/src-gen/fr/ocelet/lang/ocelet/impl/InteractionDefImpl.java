/**
 * generated by Xtext 2.10.0
 */
package fr.ocelet.lang.ocelet.impl;

import fr.ocelet.lang.ocelet.Comitexpr;
import fr.ocelet.lang.ocelet.InteractionDef;
import fr.ocelet.lang.ocelet.OceletPackage;

import java.util.Collection;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.impl.ENotificationImpl;

import org.eclipse.emf.ecore.util.EObjectContainmentEList;
import org.eclipse.emf.ecore.util.InternalEList;

import org.eclipse.xtext.common.types.JvmFormalParameter;

import org.eclipse.xtext.xbase.XExpression;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Interaction Def</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link fr.ocelet.lang.ocelet.impl.InteractionDefImpl#getParams <em>Params</em>}</li>
 *   <li>{@link fr.ocelet.lang.ocelet.impl.InteractionDefImpl#getBody <em>Body</em>}</li>
 *   <li>{@link fr.ocelet.lang.ocelet.impl.InteractionDefImpl#getComitexpressions <em>Comitexpressions</em>}</li>
 * </ul>
 *
 * @generated
 */
public class InteractionDefImpl extends RelElementsImpl implements InteractionDef
{
  /**
   * The cached value of the '{@link #getParams() <em>Params</em>}' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getParams()
   * @generated
   * @ordered
   */
  protected EList<JvmFormalParameter> params;

  /**
   * The cached value of the '{@link #getBody() <em>Body</em>}' containment reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getBody()
   * @generated
   * @ordered
   */
  protected XExpression body;

  /**
   * The cached value of the '{@link #getComitexpressions() <em>Comitexpressions</em>}' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getComitexpressions()
   * @generated
   * @ordered
   */
  protected EList<Comitexpr> comitexpressions;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected InteractionDefImpl()
  {
    super();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  protected EClass eStaticClass()
  {
    return OceletPackage.Literals.INTERACTION_DEF;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public EList<JvmFormalParameter> getParams()
  {
    if (params == null)
    {
      params = new EObjectContainmentEList<JvmFormalParameter>(JvmFormalParameter.class, this, OceletPackage.INTERACTION_DEF__PARAMS);
    }
    return params;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public XExpression getBody()
  {
    return body;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicSetBody(XExpression newBody, NotificationChain msgs)
  {
    XExpression oldBody = body;
    body = newBody;
    if (eNotificationRequired())
    {
      ENotificationImpl notification = new ENotificationImpl(this, Notification.SET, OceletPackage.INTERACTION_DEF__BODY, oldBody, newBody);
      if (msgs == null) msgs = notification; else msgs.add(notification);
    }
    return msgs;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void setBody(XExpression newBody)
  {
    if (newBody != body)
    {
      NotificationChain msgs = null;
      if (body != null)
        msgs = ((InternalEObject)body).eInverseRemove(this, EOPPOSITE_FEATURE_BASE - OceletPackage.INTERACTION_DEF__BODY, null, msgs);
      if (newBody != null)
        msgs = ((InternalEObject)newBody).eInverseAdd(this, EOPPOSITE_FEATURE_BASE - OceletPackage.INTERACTION_DEF__BODY, null, msgs);
      msgs = basicSetBody(newBody, msgs);
      if (msgs != null) msgs.dispatch();
    }
    else if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, OceletPackage.INTERACTION_DEF__BODY, newBody, newBody));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public EList<Comitexpr> getComitexpressions()
  {
    if (comitexpressions == null)
    {
      comitexpressions = new EObjectContainmentEList<Comitexpr>(Comitexpr.class, this, OceletPackage.INTERACTION_DEF__COMITEXPRESSIONS);
    }
    return comitexpressions;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs)
  {
    switch (featureID)
    {
      case OceletPackage.INTERACTION_DEF__PARAMS:
        return ((InternalEList<?>)getParams()).basicRemove(otherEnd, msgs);
      case OceletPackage.INTERACTION_DEF__BODY:
        return basicSetBody(null, msgs);
      case OceletPackage.INTERACTION_DEF__COMITEXPRESSIONS:
        return ((InternalEList<?>)getComitexpressions()).basicRemove(otherEnd, msgs);
    }
    return super.eInverseRemove(otherEnd, featureID, msgs);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Object eGet(int featureID, boolean resolve, boolean coreType)
  {
    switch (featureID)
    {
      case OceletPackage.INTERACTION_DEF__PARAMS:
        return getParams();
      case OceletPackage.INTERACTION_DEF__BODY:
        return getBody();
      case OceletPackage.INTERACTION_DEF__COMITEXPRESSIONS:
        return getComitexpressions();
    }
    return super.eGet(featureID, resolve, coreType);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @SuppressWarnings("unchecked")
  @Override
  public void eSet(int featureID, Object newValue)
  {
    switch (featureID)
    {
      case OceletPackage.INTERACTION_DEF__PARAMS:
        getParams().clear();
        getParams().addAll((Collection<? extends JvmFormalParameter>)newValue);
        return;
      case OceletPackage.INTERACTION_DEF__BODY:
        setBody((XExpression)newValue);
        return;
      case OceletPackage.INTERACTION_DEF__COMITEXPRESSIONS:
        getComitexpressions().clear();
        getComitexpressions().addAll((Collection<? extends Comitexpr>)newValue);
        return;
    }
    super.eSet(featureID, newValue);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void eUnset(int featureID)
  {
    switch (featureID)
    {
      case OceletPackage.INTERACTION_DEF__PARAMS:
        getParams().clear();
        return;
      case OceletPackage.INTERACTION_DEF__BODY:
        setBody((XExpression)null);
        return;
      case OceletPackage.INTERACTION_DEF__COMITEXPRESSIONS:
        getComitexpressions().clear();
        return;
    }
    super.eUnset(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean eIsSet(int featureID)
  {
    switch (featureID)
    {
      case OceletPackage.INTERACTION_DEF__PARAMS:
        return params != null && !params.isEmpty();
      case OceletPackage.INTERACTION_DEF__BODY:
        return body != null;
      case OceletPackage.INTERACTION_DEF__COMITEXPRESSIONS:
        return comitexpressions != null && !comitexpressions.isEmpty();
    }
    return super.eIsSet(featureID);
  }

} //InteractionDefImpl
