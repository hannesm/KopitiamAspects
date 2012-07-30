package dk.itu.sdg.kopitiamaspects;

import org.eclipse.jdt.internal.compiler.ASTVisitor;
import org.eclipse.jdt.internal.compiler.ast.SingleNameReference;
import org.eclipse.jdt.internal.compiler.codegen.CodeStream;
import org.eclipse.jdt.internal.compiler.flow.FlowContext;
import org.eclipse.jdt.internal.compiler.flow.FlowInfo;
import org.eclipse.jdt.internal.compiler.lookup.BlockScope;
import org.eclipse.jdt.internal.compiler.lookup.TypeBinding;

public class CoqExpression extends SingleNameReference {
	private String content;
	
	public CoqExpression(char[] source, int start, int end) {
		super(source, (((long) start) << 32) + end);
   		this.sourceStart = start;
		this.sourceEnd = end;

		content = new String(source);
	}
	
	public StringBuffer printExpression(int indent, StringBuffer output) {
		System.out.println("printing coqexpr");
		output.append("<%");
		output.append(content);
		output.append("%>");
		return output;
	}
	
	public TypeBinding resolveType (BlockScope scope) {
		System.out.println("resolvetype coqexpression " + content);
		return null;
	}
	
	public FlowInfo analyseCode (BlockScope currentScope, FlowContext flowContext, FlowInfo flowInfo) {
		System.out.println("analyzed coqexpr");
		return flowInfo;
	}
	
	public void generateCode (BlockScope currentScope, CodeStream codeStream) {
		System.out.println("generate coqexpr code");
	}
	
	public void traverse (ASTVisitor visitor, BlockScope scope) {
		System.out.println("visiting coqexpression " + content);
	}
}
