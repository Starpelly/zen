using System;
using System.Collections;

namespace Zen;

extension Parser
{
	private List<AstNode.Stmt> scanBlock(List<AstNode.Stmt> list, out Token open, out Token close)
	{
		open = consume(.LeftBrace, "Expected '{'.");

		while (!check(.RightBrace) && !isAtEnd())
		{
			list.Add(scanNextStmt());
		}

		close = consume(.RightBrace, "Expected '}'.");

		return list;
	}

	private Token consumeType()
	{
		let token = consume(.Identifier, "Expected type.");
		return token;
	}

	private AstNode.Stmt.Return getReturnStmt()
	{
		AstNode.Expression value = null;
		let token = previous();

		if (!check(.Semicolon))
		{
			value = getExpression();
		}

		consume(.Semicolon, "Semicolon expected.");

		return new .(token, value);
	}

	private AstNode.Stmt.FunctionDeclaration getFunctionStmt(bool isExtern)
	{
		let type = consumeType();

		let name = consume(.Identifier, "Expected name.");

		// Parameters
		let parameters = new List<AstNode.Stmt.VariableDeclaration>();
		consume(.LeftParen, "Expected '('.");
		if (!check(.RightParen))
		{
			repeat
			{
				DeclarationKind accessor = .Invalid;
				if (peek().Kind == .Let || peek().Kind == .Var)
				{
					accessor = peek().Kind == .Let ? .Immutable : .Mutable;
					advance();
				}
				else
				{
					// We'll just assume the variable is immutable for now.
					accessor = .Immutable;
				}

				let pType = consumeType();
				let pName = consume(.Identifier, "Expected parameter name.");

				parameters.Add(new .(accessor, pName, pType, null));
			}
			while (match(.Comma));
		}
		consume(.RightParen, "Expected ')'.");

		AstNode.Stmt.Block body = null;
		if (!isExtern)
		{
			// Body
			let bodyList = scanBlock(.. new .(), var open, var close);
			body = new AstNode.Stmt.Block(bodyList, open, close);
		}
		else
		{
			consume(.Semicolon, "Semicolon expected.");
		}

		return new .(isExtern ? .Extern : .Normal, name, type, body, parameters);
	}

	private AstNode.Stmt.If getIfStmt()
	{
		consume(.LeftParen, "Expected '(' after 'if'.");
		let condition = getExpression();
		consume(.RightParen, "Expected ')' after condition.");

		let thenBranch = node();

		return new .(condition, thenBranch, null);
	}

	private AstNode.Stmt.For getForStmt()
	{
		consume(.LeftParen, "Expected '('.");

		AstNode.Stmt initializer = null;
		if (match(.Semicolon))
		{
			initializer = null;
		}
		else if (match(.Var) || match(.Let))
		{
			initializer = getVariableStmt(past(2), previous().Kind == .Var ? .Mutable : .Immutable);
		}
		else
		{
			initializer = getExpressionStmt();
		}

		AstNode.Expression condition = null;
		if (!check(.Semicolon))
		{
			condition = getExpression();
		}
		consume(.Semicolon, "Expected ';' after for condition.");

		AstNode.Expression update = null;
		if (!check(.RightParen))
		{
			update = getExpression();
		}

		consume(.RightParen, "Expected ')'.");

		let body = node();

		return new .(initializer, condition, update, body);
	}

	private AstNode.Stmt.While getWhileStmt()
	{
		consume(.LeftParen, "Expected '('.");
		AstNode.Expression condition = getExpression();

		if (condition == null)
		{
			// @HACK
			// getExpression() eats the right parenthesis token for some reason, so we need to retreat to prevent another bullshit error.
			// I'm thinking this should be prevented somehow?
			retreat();
		}
		consume(.RightParen, "Expected ')'.");

		let body = node();

		return new .(condition, body);
	}

	private AstNode.Stmt node()
	{
		if (check(.LeftBrace))
		{
			let list = new List<AstNode.Stmt>();
			let blockNodes = scanBlock(list, var open, var close);
			return new AstNode.Stmt.Block(blockNodes, open, close);
		}

		return getExpressionStmt();
	}

	private AstNode.Stmt.VariableDeclaration getVariableStmt(Token accessor, DeclarationKind kind)
	{
		let type = consumeType();
		let name = consume(.Identifier, "Expected variable name.");

		AstNode.Expression initializer = null;

		if (match(.Equal))
		{
			initializer = getExpression();
		}

		consume(.Semicolon, "Semicolon expected.");

		return new .(kind, name, type, initializer);
	}

	private AstNode.Stmt.ConstantDeclaration getConstStmt()
	{
		let type = consumeType();
		let name = consume(.Identifier, "Expected constant name.");

		AstNode.Expression initializer = null;

		if (match(.Equal))
		{
			initializer = getExpression();
		}
		else if (check(.Semicolon))
		{
			reportError(name, "Constants require an initializer.");
		}
		else
		{
			reportError(peek(), "Unexpected token.");
		}

		consume(.Semicolon, "Semicolon expected.");

		return new .(name, type, initializer);
	}
}