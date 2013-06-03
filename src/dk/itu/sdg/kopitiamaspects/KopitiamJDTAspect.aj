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

import org.eclipse.jdt.core.dom.EmptyStatement;

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
	
	EmptyStatement around(org.eclipse.jdt.core.dom.ASTConverter a,
			org.eclipse.jdt.internal.compiler.ast.EmptyStatement es) :
			target(a) && call(EmptyStatement convert(
					org.eclipse.jdt.internal.compiler.ast.EmptyStatement))
			&& args(es) {
		EmptyStatement domStatement = proceed(a, es);
		if (es instanceof StatementSpec) {
			StatementSpec ss = (StatementSpec)es;
			if (ss.expression instanceof CoqExpression)
				domStatement.setProperty("dk.itu.sdg.kopitiam.contentExpr",
						((CoqExpression)ss.expression).content);
		}
		return domStatement;
	}
	
    int around(Scanner t) : //cflowbelow(execution(void Parser.parse()))\
    		target(t) && call(int Scanner.getNextToken() throws InvalidInputException) {
    	int token = proceed(t);
    	if (token == TerminalTokens.TokenNameLESS) {
    		char[] source = t.getSource();
    		int pos = t.currentPosition;
    		if (source[pos++] == '%') {
    			int start = pos;
    			try { while (source[pos++] != '%' || source[pos++] != '>') ; }
    			catch (ArrayIndexOutOfBoundsException i) { return token; }
    			t.currentPosition = pos;
    			int end = pos - 2;
    			char[] coq = CharOperation.subarray(source, start, end);
    			c = new CoqTxt(start, end, coq);
    			return TerminalTokens.TokenNameSEMICOLON;
    		}
    	}
    	return token;
    }

    private boolean hasParsedSpec = false;

    void around (Parser p, int type) : target(p) && call(protected void consumeToken(int)) && args(type) {
    	if (type == TerminalTokens.TokenNameSEMICOLON) {
    		if (c != null && c.start - 2 == p.scanner.startPosition) {
                ASTNode currentNode = p.astPtr > -1 ? p.astStack[p.astPtr] : null ;
    			CoqExpression ce = new CoqExpression(c.content, c.start - 2, c.end + 1);
				if (currentNode instanceof TypeDeclaration || currentNode instanceof FieldDeclaration || currentNode instanceof AbstractMethodDeclaration) {
					hasParsedSpec = true;
					p.pushOnAstStack(new TypeSpec(ce, c.start - 2 , c.end + 1));
					return;
				} else if (currentNode instanceof Statement) {
					hasParsedSpec = true;
					p.pushOnAstStack(new StatementSpec(ce, c.start - 2, c.end + 1));
					return;
				}
    		}
    	}
    	proceed(p, type);
    }
    
    void around (Parser p) : target(p) && call(void consumeEmptyTypeDeclaration()) {
    	if (hasParsedSpec) {
    	  hasParsedSpec = false;
    	  p.flushCommentsDefinedPriorTo(p.endStatementPosition);
    	} else
    	  proceed(p);
    }
	
    void around (Parser p) : target(p) && call(void consumeEmptyStatement()) {
    	if (hasParsedSpec) {
    	  hasParsedSpec = false;
    	  p.flushCommentsDefinedPriorTo(p.endStatementPosition);
    	} else
    	  proceed(p);
    }

    void around (Parser p) : target(p) && call(void parse()) {
      proceed(p);
      hasParsedSpec = false;
    }
    
    void around (ProblemReporter pr, char[] sourceName, FieldDeclaration fieldDecl) : target(pr) && call(void interfaceCannotHaveInitializers(char[], FieldDeclaration)) && args(sourceName, fieldDecl) {
    	if (!(fieldDecl instanceof TypeSpec))
    	  proceed(pr, sourceName, fieldDecl);
    }
}
