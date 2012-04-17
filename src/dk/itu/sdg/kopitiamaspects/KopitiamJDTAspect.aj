/* (c) 2011 Hannes Mehnert */

package dk.itu.sdg.kopitiamaspects;

import org.eclipse.jdt.core.compiler.CharOperation;
import org.eclipse.jdt.core.compiler.InvalidInputException;
import org.eclipse.jdt.internal.compiler.parser.Parser;
import org.eclipse.jdt.internal.compiler.parser.Scanner;
import org.eclipse.jdt.internal.compiler.parser.TerminalTokens;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import java.io.PrintStream;

public privileged aspect KopitiamJDTAspect {
	class CoqTxt {
		int start;
		int end;
		char[] content;
		
		public CoqTxt (int s, int e, char[] c) {
			start = s;
			end = e;
			content = c;
		}
	}
	
	private CoqTxt c;
	
    int around(Scanner t) : //cflowbelow(execution(void Parser.parse()))\
    		target(t) && call(int Scanner.getNextToken() throws InvalidInputException) {
    	int token = proceed(t);
    	if (token == TerminalTokens.TokenNameLBRACE) {
    		char[] source = t.getSource();
    		int pos = t.currentPosition;
    		if (source[pos++] == '%') {
    			int start = pos;
    			try { while (source[pos++] != '%' || source[pos++] != '}') ; }
    			catch (ArrayIndexOutOfBoundsException i) { return token; }
    			t.currentPosition = pos;
    			int end = pos - 2;
    			char[] coq = CharOperation.subarray(source, start, end);
    			c = new CoqTxt(start, end, coq);
    			System.out.println("created coqtxt");
    			return TerminalTokens.TokenNamenull;
    		}
    	}
    	return token;
    }

    void around (Parser p, int type) : target(p) && call(protected void consumeToken(int)) && args(type) {
    	if (type == TerminalTokens.TokenNamenull) {
    		if (c != null) {
    			System.out.println("consumetoken: have !null, coq is from " + c.start + " to " + c.end + ": " + new String(c.content));
    			CoqExpression ce = new CoqExpression(c.content, c.start - 2, c.end + 2);
    			//p.pushOnIntStack(c.start - 2);
    			p.pushOnExpressionStack(ce);
    			//proceed(p, type);
    		} else {
    			System.out.println("consumetoken: got null, but c is null as well :/");
    			proceed(p, type);
    		}
    		c = null;
    	} else
    		proceed(p, type);
    }
	
    before() : cflowbelow(execution(void BundleActivator.start(BundleContext))) 
    	&& call(void PrintStream.println(String))
    	&& !within(KopitiamJDTAspect) {
    	System.out.println("Hi from Aspect ;-)");
    }
}
