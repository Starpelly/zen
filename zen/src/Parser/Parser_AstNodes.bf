using System;
using System.Collections;
using System.Diagnostics;

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

	AstNode.Expression.NamedType parseNamedType()
	{
		let token = consume(.Identifier, "Expected identifier.");
		if (match(.DoubleColon))
		{
			let name = consume(.Identifier, "Expected identifier.");
			let range =  SourceRange(token.SourceRange.Start, name.SourceRange.End);
			let qualified = new AstNode.Expression.QualifiedName(token, past(2), new AstNode.Expression.Variable(name, name.SourceRange), range);
			return new .(.Qualified(qualified), range);
		}

		return new .(.Simple(token), token.SourceRange);
	}

	private AstNode.Expression.NamedType consumeType()
	{
		var baseType = parseNamedType();

		while (check(.LeftBracket) || check(.Star))
		{
			// Parse array type
			if (match(.LeftBracket))
			{
				// let lbrack = previous();

				// @TODO
				// For now, we'll expect an expression, until we have dynamic arrays at least.
				AstNode.Expression count = null;
				// if (!check(.RightBracket))
					count = getExprAddition();

				let rbrack = consume(.RightBracket, "Expected ']'");

				let range = SourceRange(baseType.Range.Start, rbrack.SourceRange.End); // Starts at the identifier, ends at the closing bracket
				baseType = new .(.Array(baseType, count), range);
			}
			if (match(.Star))
			{
				let star = previous();
				let range = SourceRange(baseType.Range.Start, star.SourceRange.End); // Starts at the identifier, ends at the star(s)
				baseType = new .(.Pointer(baseType), range);
			}
		}

		return baseType;
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
		let oldFun = m_insideFunction;
		defer {
			m_insideFunction = oldFun;
		}

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

				parameters.Add(new .(accessor, pName, pType, null, null));
			}
			while (match(.Comma));
		}
		consume(.RightParen, "Expected ')'.");

		AstNode.Stmt.Block body = null;
		if (!isExtern)
		{
			m_insideFunction = true;

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

	private AstNode.Stmt.StructDeclaration getStructStmt(bool isExtern)
	{
		let name = consume(.Identifier, "Expected name.");

		// Body
		consume(.LeftBrace, "Expected '{'.");

		let fields = new List<AstNode.Stmt.VariableDeclaration>();
		while (!check(.RightBrace) && !isAtEnd())
		{
			let pType = consumeType();
			let pName = consume(.Identifier, "Expected parameter name.");

			AstNode.Expression initializer = null;
			Token? op = null;

			if (match(.Equal))
			{
				op = previous();
				initializer = getExpression();
			}

			consume(.Semicolon, "Semicolon expected.");

			fields.Add(new .(.Immutable, pName, pType, op, initializer));
			// list.Add(scanNextStmt());
			// fields.Add((AstNode.Stmt.VariableDeclaration)scanNextStmt());
		}

		consume(.RightBrace, "Expected '}'.");

		return new .(isExtern ? .Extern : .Normal, name, fields);
	}

	private AstNode.Stmt.EnumDeclaration getEnumStmt(bool isExtern)
	{
		let name = consume(.Identifier, "Expected name.");

		// Body
		consume(.LeftBrace, "Expected '{'.");

		let values = new List<AstNode.Stmt.EnumFieldValue>();
		int scopeDepth = 0;
		int valueIndex = 0;
		while (true && !isAtEnd())
		{
			mixin checkRightBrace()
			{
				if (check(.RightBrace))
				{
					if (scopeDepth <= 0)
					{
						break;
					}

					scopeDepth--;
				}
			}

			if (check(.LeftBrace))
			{
				scopeDepth++;
			}
			checkRightBrace!();

			if (valueIndex > 0)
			{
				consume(.Comma, "Expected comma.");

				// Supports trailing commas.
				checkRightBrace!();
			}

			let valueName = consume(.Identifier, "Member name expected.");

			// @FIX
			// To prevent infinite parsing loops, but eventually we'll want to store this.
			AstNode.Expression value = null;
			if (match(.Equal))
			{
				value = getExprPrimary();
			}
			else
			{
				let range = valueName.SourceRange;
				value = new AstNode.Expression.Literal(valueName, Variant.Create<int>(valueIndex), valueIndex.ToString(.. scope .()), range);
			}

			values.Add(new .(valueName, value));

			valueIndex++;
		}

		consume(.RightBrace, "Expected '}'.");

		return new .(isExtern ? .Extern : .Normal, name, values);
	}

	private AstNode.Stmt.NamespaceDeclaration getNamespaceStmt()
	{
		let token = previous();
		let name = consume(.Identifier, "Expected name.");

		consume(.Semicolon, "Semicolon expected.");

		List<AstNode.Stmt> list = new .();
		while (!check(.EOF) && !isAtEnd())
		{
			list.Add(scanNextStmt());
		}

		return new .(name, token, list);
	}

	private AstNode.Stmt.If getIfStmt()
	{
		consume(.LeftParen, "Expected '(' after 'if'.");
		let condition = getExpression();
		consume(.RightParen, "Expected ')' after condition.");

		AstNode.Stmt.Block thenBranch = null;
		AstNode.Stmt.Block elseBranch = null;

		// "Then" branch
		{
			let thenBlock = scanBlock(.. new .(), var open, var close);
			thenBranch = new AstNode.Stmt.Block(thenBlock, open, close);
		}

		// "Else" branch
		if (match(.Else))
		{
			let elseBlock = scanBlock(.. new .(), var open, var close);
			elseBranch = new AstNode.Stmt.Block(elseBlock, open, close);
		}

		Debug.Assert(thenBranch != null);
		return new .(condition, thenBranch, elseBranch);
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
		Token? op = null;

		AstNode.Expression initializer = null;

		if (match(.Equal))
		{
			op = previous();
			initializer = getExpression();
		}

		consume(.Semicolon, "Semicolon expected.");

		return new .(kind, name, type, op, initializer);
	}

	private AstNode.Stmt.ConstantDeclaration getConstStmt()
	{
		let type = consumeType();
		let name = consume(.Identifier, "Expected constant name.");

		AstNode.Expression initializer = null;
		Token? op = null;

		if (match(.Equal))
		{
			op = previous();
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

		return new .(name, type, initializer, op);
	}
}