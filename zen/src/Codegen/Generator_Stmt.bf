using System;
using System.Collections;

namespace Zen;

extension Generator
{
	private void writeStmt_ConstDecl(Entity.Constant constant, StringCodeBuilder code, Scope _scope)
	{
		Runtime.Assert(constant.Decl case .Normal(let decl));

		let namespaceStr = buildNamespaceString(constant, .. scope .(), true);

		code.AppendLine("#define ");
		// code.AppendLine("const ");
		bool isStructType = false;

		if (constant.ResolvedType case .Structure)
		{
			isStructType = true;
		}

		// Write type
		// code.Append(writeResolvedType(constant.ResolvedType, .. scope .()));

		// The space between type and name
		// code.Append(' ');

		// Write namespace
		code.Append(namespaceStr);
		code.Append("_");

		// Write name
		code.Append(decl.Name.Lexeme);

		if (constant.ResolvedType case .Array(let element, let count))
		{
			code.Append(scope $"[{count}]");
		}

		if (decl.Initializer != null)
		{
			code.Append(' ');

			// We'll begin a macro here so we can get '\' for any new lines the expression may generate.
			code.BeginMacro();
			defer code.EndMacro();

			emitExpr(decl.Initializer, code, _scope, true, .()
			{
				FromConst = true
			});
		}
		else
		{
			if (isStructType)
			{
				// Because C doesn't initialize structs automatically without an initializer (but we want to),
				// we'll have to tell it to do so manually.

				// @TODO - pelly, 11/2/25
				// Actually, we want initializers in the future, and we want to throw errors when we try to use uninitialized variables.
				// So this needs to be removed or changed in the future!
				Console.ForegroundColor = .Yellow;
				Console.WriteLine("please fix this implicit initializer");
				Console.ResetColor();
				code.Append(scope $" = \{\}");
			}
		}
		// code.Append(';');
	}

	private void writeStmt_VarDecl(AstNode.Stmt.VariableDeclaration v, StringCodeBuilder code, Scope _scope, bool writeType, bool writeInitializer, bool writeSemicolon)
	{
		code.AppendNewLine();
		code.AppendTabs();

		let entity = _scope.LookupStmtAs<Entity.Variable>(v).Value;

		if (writeType)
		{
			// Write type
			code.Append(writeResolvedType(entity.ResolvedType, .. scope .()));

			// Space between type and name
			code.Append(' ');
		}

		// Write namespace
		let ns = buildNamespaceString(entity, .. scope .(), true);
		code.Append(ns);
		code.Append('_');

		// Write name
		code.Append(v.Name.Lexeme);

		if (entity.ResolvedType case .Array(let element, let count))
		{
			code.Append(scope $"[{count}]");
		}

		if (writeInitializer)
		{
			if (v.Initializer != null)
			{
				code.Append(scope $" = ");
				emitExpr(v.Initializer, code, _scope);
			}
			else
			{
				if (entity.ResolvedType case .Structure(let _struct))
				{
					// Because C doesn't initialize structs automatically without an initializer (but we want to),
					// we'll have to tell it to do so manually.

					// @TODO - pelly, 11/2/25
					// Actually, we want initializers in the future, and we want to throw errors when we try to use uninitialized variables.
					// So this needs to be removed or changed in the future!
					Console.ForegroundColor = .Yellow;
					Console.WriteLine("please fix this implicit initializer");
					Console.ResetColor();
					code.Append(scope $" = ");

					let type = writeResolvedType(entity.ResolvedType, .. scope .());
					code.Append(scope $"CLITERAL({type})");

					int initFieldsCount = 0;
					for (let field in _struct.Fields)
					{
						if (field.Initializer == null)
							continue;
						initFieldsCount++;
					}

					if (initFieldsCount == 0)
					{
						code.Append("{ 0 }");
					}
					else
					{
						code.Append("{ ");
						for (let field in _struct.Fields)
						{
							if (field.Initializer == null)
								continue;

							code.Append(scope $".{field.Name.Lexeme} = ");
							emitExpr(field.Initializer, code, _scope);

							if (field != _struct.Fields.Back)
								code.Append(", ");
						}

						code.Append(" }");
					}
				}
			}
		}
		if (writeSemicolon)
		code.Append(';');
	}
}