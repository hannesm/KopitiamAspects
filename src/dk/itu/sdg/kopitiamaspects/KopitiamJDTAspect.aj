/* (c) 2011 Hannes Mehnert */

package dk.itu.sdg.kopitiamaspects;

import org.eclipse.jdt.core.compiler.CharOperation;
import org.eclipse.jdt.core.compiler.InvalidInputException;
import org.eclipse.jdt.internal.compiler.parser.Parser;
import org.eclipse.jdt.internal.compiler.parser.Scanner;
import org.eclipse.jdt.internal.compiler.ast.AbstractMethodDeclaration;
import org.eclipse.jdt.internal.compiler.ast.ASTNode;
import org.eclipse.jdt.internal.compiler.ast.FieldDeclaration;
import org.eclipse.jdt.internal.compiler.ast.Statement;
import org.eclipse.jdt.internal.compiler.ast.TypeDeclaration;
import org.eclipse.jdt.internal.compiler.parser.TerminalTokens;
import org.eclipse.jdt.internal.compiler.problem.ProblemReporter;

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
	//private boolean enabled = false;
	
    int around(Scanner t) : //cflowbelow(execution(void Parser.parse()))\
    		target(t) && call(int Scanner.getNextToken() throws InvalidInputException) {
    	int token = proceed(t);
    	if (token == TerminalTokens.TokenNameLESS) {
    		char[] source = t.getSource();
    		int pos = t.currentPosition;
    		if (source[pos++] == '%') {
	    		//t.startPosition = pos;
    			int start = pos;
    			//System.out.println("bla at " + start);
    			try { while (source[pos++] != '%' || source[pos++] != '>') ; }
    			catch (ArrayIndexOutOfBoundsException i) { return token; }
				//System.out.println("boo at " + pos);
    			t.currentPosition = pos;
    			//t.lastCommentLinePosition = t.currentPosition;
    			int end = pos - 2;
    			char[] coq = CharOperation.subarray(source, start, end);
    			c = new CoqTxt(start, end, coq);
    			//enabled = true;
    			System.out.println("created inner " + new String(c.content));
    			//t.recordComment(TerminalTokens.TokenNameCOMMENT_LINE);
    			return TerminalTokens.TokenNameSEMICOLON;
    		}
    	}
    	return token;
    }

    private boolean hasParsedSpec = false;

    void around (Parser p, int type) : target(p) && call(protected void consumeToken(int)) && args(type) {
        System.out.println("blaaaa");
    	if (type == TerminalTokens.TokenNameSEMICOLON) {
    		if (c != null && c.start - 2 == p.scanner.startPosition) {
    			System.out.println("consumetoken: from " + (c.start - 2) + " to " + (c.end + 1) + ": " + new String(c.content));
                ASTNode currentNode = p.astPtr > -1 ? p.astStack[p.astPtr] : null ;
    			CoqExpression ce = new CoqExpression(c.content, c.start - 2, c.end + 1);
				if (currentNode instanceof TypeDeclaration || currentNode instanceof FieldDeclaration || currentNode instanceof AbstractMethodDeclaration) {
					hasParsedSpec = true;
					p.pushOnAstStack(new TypeSpec(ce, c.start - 2 , c.end + 1));
					return;
				} else if (currentNode instanceof Statement) {
					System.out.println("pushed statement onto aststack");
					hasParsedSpec = true;
					p.pushOnAstStack(new StatementSpec(ce, c.start - 2, c.end + 1));
					return;
				}
    		}
    	}
	    if (c == null)
	  		System.out.println("consumetoken: got null, but c is null as well :/ ");
    	else
	     	System.out.println("consumetoken: got null, but c is null as well :/ " + c.start + " scanner " +  p.scanner.startPosition);
    	proceed(p, type);
    }
    
    void around (Parser p) : target(p) && call(void consumeEmptyTypeDeclaration()) {
    	if (hasParsedSpec) {
    	  System.out.println("called around consumeemptytypedeclaration");
    	  hasParsedSpec = false;
    	  p.flushCommentsDefinedPriorTo(p.endStatementPosition);
    	} else
    	  proceed(p);
    }
	
    void around (Parser p) : target(p) && call(void consumeEmptyStatement()) {
    	if (hasParsedSpec) {
    	  System.out.println("called around consumeemptystatement");
    	  hasParsedSpec = false;
    	  p.flushCommentsDefinedPriorTo(p.endStatementPosition);
    	} else
    	  proceed(p);
    }

    void around (Parser p) : target(p) && call(void parse()) {
      proceed(p);
      if (hasParsedSpec)
        System.out.println("set enabled to false in after parse");
      hasParsedSpec = false;
    }
    
    void around (ProblemReporter pr, char[] sourceName, FieldDeclaration fieldDecl) : target(pr) && call(void interfaceCannotHaveInitializers(char[], FieldDeclaration)) && args(sourceName, fieldDecl) {
    	if (!(fieldDecl instanceof TypeSpec))
    	  proceed(pr, sourceName, fieldDecl);
    }

/*	void around (Parser p) : target(p) && call(protected void consumeExitVariableWithInitialization()) {
	  if (p.astStack[p.astPtr] instanceof CoqExpression) {
	    //p.expressionLengthPtr--;
	    //p.expressionPtr--;
	    //p.intPtr--;
	    p.astPtr--;
	    System.out.println("wuff! consumeexitvariablebla");
	  } else
	    proceed(p);
	}

	void around (Parser p) : target(p) && call(protected void consumeAssignment()) {
	  if (p.astStack[p.astPtr] instanceof CoqExpression) {
//	    p.intPtr--;
//	    p.expressionPtr--;
//	    p.expressionLengthPtr--;
	    System.out.println("barffff consumeAssignment");
	  } else
	    proceed(p);
	} */
/*	
	void around (Parser p) : target(p) && call(protected void consumeFieldDeclaration()) {
	  if (p.astStack[p.astPtr] instanceof CoqExpression) {
	    System.out.println("wuffff consumefielddeclaration");
	  } else
	    proceed(p);
	}
	
    before() : cflowbelow(execution(void BundleActivator.start(BundleContext))) 
    	&& call(void PrintStream.println(String))
    	&& !within(KopitiamJDTAspect) {
    	System.out.println("Hi from Aspect ;-)");
    } */
}
