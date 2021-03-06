/*
 * generated by Xtext 2.12.0
 */
package fr.ocelet.lang.ui;

import com.google.inject.Injector;
import fr.ocelet.ui.internal.OceletActivator;
import org.eclipse.xtext.ui.guice.AbstractGuiceAwareExecutableExtensionFactory;
import org.osgi.framework.Bundle;

/**
 * This class was generated. Customizations should only happen in a newly
 * introduced subclass. 
 */
public class OceletExecutableExtensionFactory extends AbstractGuiceAwareExecutableExtensionFactory {

	@Override
	protected Bundle getBundle() {
		return OceletActivator.getInstance().getBundle();
	}
	
	@Override
	protected Injector getInjector() {
		return OceletActivator.getInstance().getInjector(OceletActivator.FR_OCELET_LANG_OCELET);
	}
	
}
