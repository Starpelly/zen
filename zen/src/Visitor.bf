using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

abstract class Visitor
{
	private const int MAX_ERRORS = 1000;

	public bool HadErrors { public get; private set; }
	public Event<delegate void(Diagnostic)> OnReport = default;

	protected void reportError(Token token, String message)
	{
		Debug.Assert(OnReport != default);

		let diag = new Diagnostic(.Error, message, new DiagnosticSpan() { Range = token.SourceRange });
		OnReport(diag);

		HadErrors = true;
	}

	protected void reportError(AstNode.Expression expr, String message)
	{
		Debug.Assert(OnReport != default);

		let diag = new Diagnostic(.Error, message, new DiagnosticSpan() { Range = expr.Range });
		OnReport(diag);

		HadErrors = true;
	}
}