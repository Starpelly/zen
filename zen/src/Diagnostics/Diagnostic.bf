using System;
using System.Collections;

namespace Zen;

class Diagnostic
{
	public enum Severity { Info, Warning, Error }

	public readonly Severity Level;
	public readonly String Message = new .() ~ delete _;
	public readonly List<DiagnosticSpan> Spans = new .() ~ DeleteContainerAndItems!(_);

	public this(Severity level, String msg, params DiagnosticSpan[] spans)
	{
		this.Level = level;
		this.Message.Set(msg);
		this.Spans.AddRange(spans);
	}

	public this(Severity level, String msg, DiagnosticSpan span)
	{
		this.Level = level;
		this.Message.Set(msg);
		this.Spans.Add(span);
	}
}

class DiagnosticSpan
{
	public SourceRange Range;

	/// Optional annotation text
	public String Label = new .() ~ delete _;

	/// Optional terminal color
	public ConsoleColor? ColorHint;
}