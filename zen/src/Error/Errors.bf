using System;
using System.Collections;

namespace Zen;

public class CompilerError
{
	public readonly String Message = new .() ~ delete _;
	public readonly List<Token> Tokens = new .() ~ delete _;

	public int StartLine => FirstToken.Line;
	public int EndLine => LastToken.Line;

	public int StartChar => FirstToken.Column;
	public int EndChar => LastToken.Column + LastToken.Lexeme.Length;

	public Token FirstToken
	{
		get
		{
			return Tokens[0];
		}
	}

	public Token LastToken
	{
		get
		{
			return Tokens[^1];
		}
	}

	public this(Token token, String msg)
	{
		this.Tokens.Add(token);
		this.Message.Set(msg);
	}

	public this(List<Token> tokens, String msg)
	{

	}
}
