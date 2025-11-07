using System;
using System.Collections;

namespace Zen;

public enum DirectiveKind
{
	Load,
	C,
	If,
	Else,
	EndIf,
	Unknown
}

public class Directive
{
	public readonly DirectiveKind Kind;
	public readonly SourceRange Range;
	public readonly List<Token> Arguments ~ delete _;
	public readonly String Payload;
}