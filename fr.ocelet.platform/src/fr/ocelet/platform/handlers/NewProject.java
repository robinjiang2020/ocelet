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

package fr.ocelet.platform.handlers;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.jface.window.Window;
import org.eclipse.jface.wizard.WizardDialog;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.PlatformUI;

import fr.ocelet.platform.wizards.NewProjectWizard;
import fr.ocelet.platform.wizards.models.ProjectModel;
/**
 * Creates a new Ocelet project
 * @author Pascal Degenne - Initial contribution
 *
 */
public class NewProject extends AbstractHandler {

	NewProjectWizard npw;

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {

		Shell shell = PlatformUI.getWorkbench().getDisplay().getActiveShell();
		npw = new NewProjectWizard();

		WizardDialog refWizard1Dialog = new WizardDialog(shell, npw);
		refWizard1Dialog.create();

		if (refWizard1Dialog.open() == Window.OK) {
			ProjectModel pm = npw.getProjectModel();
			if (pm != null)
				pm.createModel();
		}
	  return null;
	}

}
