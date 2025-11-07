using System;
using System.Collections;

namespace Zen;

class Parser : Visitor
{
	private readonly Ast m_ast;
	private readonly List<Token> m_tokens;

	private int m_current = 0;

	public this(List<Token> tokens, Ast ast)
	{
		this.m_tokens = tokens;
		this.m_ast = ast;
	}

	public Result<Ast> Run()
	{
		m_ast.ClearAndDeleteItems();

		while (!isAtEnd() && !HadErrors)
		{
			let decl = scanNextStmt();
			if (decl != null)
			{
				m_ast.Add(decl);
			}
		}

		m_ast.Add(new AstNode.Stmt.EOF());
		return HadErrors ? .Err : .Ok(m_ast);
	}

	private AstNode.Stmt scanNextStmt()
	{
		if (match(.Extern))
		{
			if (match(.Function))
				return getFunctionStmt(true);
			else if (match(.Struct))
				return getStructStmt(true);
			else if (match(.Enum))
				return getEnumStmt(true);
			else
				reportError(previous(), "Only functions can be declared as 'extern'");
		}
		if (match(.Function))
		{
			return getFunctionStmt(false);
		}
		if (match(.Struct))
		{
			return getStructStmt(false);
		}
		if (match(.Enum))
		{
			return getEnumStmt(false);
		}
		if (match(.Namespace))
		{
			return getNamespaceStmt();
		}
		if (match(.Return))
		{
			return getReturnStmt();
		}
		if (match(.If))
		{
			return getIfStmt();
		}
		if (match(.For))
		{
			return getForStmt();
		}
		if (match(.While))
		{
			return getWhileStmt();
		}
		if (match(.Let))
		{
			return getVariableStmt(previous(), .Immutable);
		}
		if (match(.Var))
		{
			return getVariableStmt(previous(), .Mutable);
		}
		if (match(.Const))
		{
			return getConstStmt();
		}

		return getExpressionStmt();
	}

	private Token consume(TokenKind kind, String message)
	{
		if (check(kind))
		{
			advance();
			return previous();
		}

		reportError(previous(), message);
		return peek();
	}

	private bool match(params TokenKind[] types)
	{
		for (let type in types)
		{
			if (check(type))
			{
				advance();
				return true;
			}
		}
		return false;
	}

	/// Checks to see if the current token is the passed-in type.
	private bool check(TokenKind kind)
	{
		if (isAtEnd()) return false;
		return peek().Kind == kind;
	}

	private bool isAtEnd()
	{
		return peek().Kind == .EOF;
	}

	private void advance()
	{
		if (!isAtEnd()) m_current++;
	}

	private void retreat()
	{
		m_current--;
	}

	private Token peek()
	{
		return m_tokens[m_current];
	}

	private Token previous()
	{
		return m_tokens[m_current - 1];
	}

	private Token past(int count)
	{
		return m_tokens[m_current - count];
	}

	private Token next()
	{
		if (isAtEnd()) return peek();
		return m_tokens[m_current++];
	}
}