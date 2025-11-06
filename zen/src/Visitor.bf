using System;
using System.Collections;

namespace Zen;

abstract class Visitor
{
	public readonly List<Diagnostic> Diagnostics = new .() ~ DeleteContainerAndItems!(_);
	public bool HadErrors { public get; private set; }

	protected void reportError(Token token, String message)
	{
		let diag = new Diagnostic(.Error, message, new DiagnosticSpan() { Range = token.SourceRange });
		Diagnostics.Add(diag);
	}

	protected void reportError(AstNode.Expression expr, String message)
	{
		let diag = new Diagnostic(.Error, message, new DiagnosticSpan() { Range = expr.Range });
		Diagnostics.Add(diag);
	}
}