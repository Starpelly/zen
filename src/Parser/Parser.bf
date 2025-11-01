using System;
using System.Collections;

namespace Zen;

class Parser
{
	private const int MAX_ERRORS = 1000;

	private readonly Ast m_ast = new .() ~ DeleteContainerAndItems!(_);
	private readonly List<Token> m_tokens;

	private int m_current = 0;
	private bool m_hadErrors = false;
	private List<CompilerError> m_errors;

	public this(List<Token> tokens, List<CompilerError> errors)
	{
		this.m_tokens = tokens;
		this.m_errors = errors;
	}

	public Result<Ast> Run()
	{
		m_ast.ClearAndDeleteItems();

		while (!isAtEnd() && !m_hadErrors)
		{
			let decl = scanNextStmt();
			if (decl != null)
			{
				m_ast.Add(decl);
			}
		}

		m_ast.Add(new AstNode.Stmt.EOF());
		return .Ok(m_ast);
	}

	private AstNode.Stmt scanNextStmt()
	{
		if (match(.Extern))
		{
			if (match(.Function))
				return getFunctionStmt(true);
			else if (match(.Struct))
				return getStructStmt(true);
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
			return getEnumStmt();
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
		if (match(.Hash))
		{
			let token = peek(); advance();
			let name = peek(); advance();
			consume(.Semicolon, "Semicolon expected.");
			return new AstNode.Stmt.BasicDirective(token, name);
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

	private void reportError(Token token, String message)
	{
		// Log error here.
		m_hadErrors = true;
		m_errors.Add(new .(token, message));
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