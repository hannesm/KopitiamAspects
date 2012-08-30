package dk.itu.sdg.kopitiamaspects;

import org.eclipse.jface.text.rules.DefaultDamagerRepairer;
import org.eclipse.jface.text.rules.ITokenScanner;

public interface DamagerRepairerFactoryInterface {
	public DefaultDamagerRepairer newDamagerRepairer (ITokenScanner scanner);
}
