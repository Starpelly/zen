using System;
using System.Collections;

namespace Zen;

class OLD_Generator
{
	private readonly Ast m_ast;
	private readonly List<StringView> m_namespaceStack = new .() ~ delete _;

	public this(Ast ast)
	{
		this.m_ast = ast;
	}

	public void Run(String str)
	{
		let code = scope StringCodeBuilder();

		const String BOILERPLATE_TOP =
		"""
		#include <stdio.h>
		#include <stdlib.h>
		#include <stdbool.h>

		typedef char* string;

		typedef unsigned long long 	uint64;
		typedef unsigned int 		uint32;
		typedef unsigned short		uint16;
		typedef unsigned char		uint8;
		typedef			 long long	int64;
		typedef			 int		int32;
		typedef			 short		int16;
		typedef			 char		int8;
		typedef			 float		float32;
		typedef			 double		float64;

		#if defined(_WIN32)
		#define ZEN_PLATFORM_WINDOWS
			#ifdef _WIN64
				#define ZEN_X64
			#endif
		#elif defined(__linux__)
			#define ZEN_PLATFORM_LINUX
		#else
			#error "Unknown platform!"
		#endif

		#ifdef ZEN_PLATFORM_WINDOWS
		#include <windows.h>

			/*
			void message_box(string text)
			{
				MessageBox(
					NULL,
					text,
					"Title",
					MB_OK | MB_ICONINFORMATION
				);
			}
			*/
		#endif

		// #include <raylib.h>
		""";

		code.AppendLine(BOILERPLATE_TOP);
		code.AppendEmptyLine();

		void checkNamespaces(AstNode.Stmt node)
		{
			if (let namespc = node as AstNode.Stmt.NamespaceDeclaration)
			{
				m_namespaceStack.Add(namespc.Name.Lexeme);
			}
			if (node is AstNode.Stmt.EOF)
			{
				m_namespaceStack.Clear();
			}
		}

		code.AppendBanner("Enums");
		m_namespaceStack.Clear();
		for (let node in m_ast)
		{
			checkNamespaces(node);

			if (let e = node as AstNode.Stmt.EnumDeclaration)
			{
				let nsStr = buildNamespaceStr(m_namespaceStack, .. scope .());

				code.AppendLine("typedef enum {");
				code.IncreaseTab();
				for (let val in e.Values)
				{
					code.AppendLine(scope $"{nsStr}{e.Name.Lexeme}_{val.Name.Lexeme}");
					if (val != e.Values.Back)
						code.Append(",");
				}
				code.DecreaseTab();
				code.AppendLine(scope $"\} {nsStr}{e.Name.Lexeme};");
			}
		}

		code.AppendBanner("Structs");
		for (let node in m_ast)
		{
			if (let s = node as AstNode.Stmt.StructDeclaration)
			{
				code.AppendLine("typedef struct {");
				code.IncreaseTab();
				for (let field in s.Fields)
				{
					code.AppendLine(scope $"{field.Type.Lexeme} {field.Name.Lexeme};");
				}
				code.DecreaseTab();
				code.AppendLine(scope $"\} {s.Name.Lexeme};");
			}
		}

		code.AppendBanner("Constants");
		for (let node in m_ast)
		{
			if (let c = node as AstNode.Stmt.ConstantDeclaration)
			{
				code.AppendLine(scope $"#define {c.Name.Lexeme} {emitExpr(c.Initializer, .. scope .())}");
			}
		}

		code.AppendBanner("Forward Declarations");
		for (let node in m_ast)
		{
			if (let fun = node as AstNode.Stmt.FunctionDeclaration)
			{
				if (fun.Kind == .Extern)
				{
					// I guess we'll trust that it exists?
					continue;
				}

				emitFunctionHead(fun, code);
				code.Append(';');
			}
		}

		code.AppendBanner("Functions");

		// main fun
		{
			code.AppendLine("void main()");
			code.AppendLine("{");
			code.IncreaseTab();
			{
				code.AppendLine("CZEN_main();");
			}
			code.DecreaseTab();
			code.AppendLine("}");
		}

		for (let node in m_ast)
		{


			emitNode(node, code, true);
		}

		/*
		code.AppendLine("for (;;) {}");

		code.DecreaseTab();
		code.AppendLine("}");
		*/

		str.Append(code.Code);
	}

	private void emitNode(AstNode node, StringCodeBuilder code, bool semicolon = true)
	{
		mixin addSemicolon()
		{
			if (semicolon)
			{
				code.Append(";");
			}
		}

		if (let b = node as AstNode.Stmt.Block)
		{
			code.AppendLine("{");
			code.IncreaseTab();
			for (let n in b.List)
			{
				emitNode(n, code);
			}
			code.DecreaseTab();
			code.AppendLine("}");
		}

		if (let fun = node as AstNode.Stmt.FunctionDeclaration)
		{
			if (fun.Kind == .Extern)
			{
				return;
			}

			emitFunctionHead(fun, code);
			emitNode(fun.Body, code);
		}

		if (let n = node as AstNode.Stmt.VariableDeclaration)
		{
			code.AppendLine(scope $"{n.Type.Lexeme} {n.Name.Lexeme}");
			if (n.Initializer != null)
			{
				code.Append(scope $" = {emitExpr(n.Initializer, .. scope .())}");
			}
			addSemicolon!();
		}

		if (let r = node as AstNode.Stmt.Return)
		{
			code.AppendLine(scope $"return {emitExpr(r.Value, .. scope .())}");
			addSemicolon!();
		}

		if (let _if = node as AstNode.Stmt.If)
		{
			code.AppendLine(scope $"if ({emitExpr(_if.Condition, .. scope .())})");
			emitNode(_if.ThenBranch, code);
		}

		if (let _for = node as AstNode.Stmt.For)
		{
			let body = scope StringCodeBuilder();
			// Init
			// body.Append(emitExpr(_for.Initialization, .. scope .()));
			emitNode(_for.Initialization, body, false);
			body.Append(';');
			// Condition
			if (_for.Condition != null) body.Append(' ');
			body.Append(emitExpr(_for.Condition, .. scope .()));
			body.Append(';');
			// Update
			if (_for.Updation != null) body.Append(' ');
			body.Append(emitExpr(_for.Updation, .. scope .()));

			code.AppendLine(scope $"for ({body.Code})");
			emitNode(_for.Body, code);
		}

		if (let _while = node as AstNode.Stmt.While)
		{
			code.AppendLine(scope $"while ({emitExpr(_while.Condition, .. scope .())})");
			emitNode(_while.Body, code);
		}

		if (let expr = node as AstNode.Stmt.ExpressionStmt)
		{
			code.AppendLine(emitExpr(expr.InnerExpr, .. scope .()));
			addSemicolon!();
		}
	}

	private void emitExpr(AstNode.Expression expr, String outStr, bool applyQualifiedNameHack = true)
	{
		switch (expr.GetKind())
		{
		case .Binary(let bin):
			emitExpr(bin.Left, outStr);
			outStr.Append(scope $" {bin.Op.Lexeme} ");
			emitExpr(bin.Right, outStr);
			break;

		case .Variable(let _var):
			outStr.Append(_var.Name.Lexeme);
			break;

		case .Call(let call):
			let arguments = scope StringCodeBuilder();
			for (let arg in call.Arguments)
			{
				arguments.Append(scope $"{emitExpr(arg, .. scope .())}");
				if (arg != call.Arguments.Back)
					arguments.Append(", ");
			}

			// @TODO
			// I don't like that this is here...
			// But it might be okay... for now...
			Result<BuiltinFunction> builtinFunc = .Err;
			for (let builtin in BuiltinFunctions)
			{
				if (builtin.Name == call.Callee.Name.Lexeme)
				{
					builtinFunc = .Ok(builtin);
				}
			}

			if (builtinFunc != .Err)
			{
				let builtinName = builtinFunc.Value.Name;
				switch (builtinName)
				{
				case "print",
					 "println":
					String format = scope .();
					String extra = scope .();

					let argType = call.Arguments[0].Type;
					if (argType.IsTypeInteger())
					{
						format.Set("%i");
					}
					else if (argType.IsTypeFloat())
					{
						format.Set("%f");
					}
					else if (argType.IsTypeBoolean())
					{
						format.Set("%s");
						extra.Set(" ? \"true\" : \"false\"");
					}
					else if (argType.IsTypeString())
					{
						// No format
						format.Set("%s");
					}
					else
					{
						Runtime.FatalError("Can't convert this type! :(");
					}

					if (builtinName == "println")
						format.Append("\\n");

					outStr.Append("printf");
					outStr.Append("(");
					if (!format.IsEmpty)
					{
						outStr.Append(scope $"\"{format}\", ");
					}
					outStr.Append(arguments.Code);
					if (!extra.IsEmpty)
					{
						outStr.Append(scope $" {extra}");
					}
					outStr.Append(")");
					break;
				}
			}
			else
			{
				outStr.Append(scope $"{emitExpr(call.Callee, .. scope .())}({arguments.Code})");
			}
			break;

		case .Logical(let logical):
			break;

		case .Literal(let literal):
			outStr.Append(literal.Token.Lexeme);
			if (literal.Type.IsTypeFloat())
			{
				// C appends the "f" at the end of floats...
				// Not technically required, I don't think?
				// But better to be safe than sorry.
				outStr.Append("f");
			}
			break;

		case .Unary(let unary):
			break;

		case .Get(let get):
			outStr.Append(scope $"{emitExpr(get.Object, .. scope .())}.{get.Name.Lexeme}");
			// outStr.Append(scope $"{emitExpr(set.Object, .. scope .())}.{set.Name}");
			break;

		case .Set(let set):
			break;

		case .This(let _this):
			break;

		case .Grouping(let grouping):
			break;

		case .Assign(let assign):
			outStr.Append(scope $"{emitExpr(assign.Assignee, .. scope .())} {assign.Op.Lexeme} {emitExpr(assign.Value, .. scope .())}");
			break;

		case .QualifiedName(let qn):
			outStr.Append(scope $"CZEN_{qn.Left.Lexeme}_{emitExpr(qn.Right, .. scope .(), false)}");
			break;
		}
	}

	private void emitFunctionHead(AstNode.Stmt.FunctionDeclaration fun, StringCodeBuilder code)
	{
		let parameters = scope StringCodeBuilder();
		for (let param in fun.Parameters)
		{
			parameters.Append(scope $"{param.Type.Lexeme} {param.Name.Lexeme}");
			if (param != fun.Parameters.Back)
				parameters.Append(", ");
		}

		let namespaceStr = buildNamespaceStr(fun.Scope.BuildScopeNamespaces(.. scope .()), .. scope .());
		code.AppendLine(scope $"{fun.Type.Lexeme} {namespaceStr}{fun.Name.Lexeme}({parameters.Code})");
	}

	private void buildNamespaceStr(List<Entity.Namespace> namespaces, String outStr)
	{
		outStr.Append("CZEN_");

		for (let ns in namespaces)
		{
			outStr.Append(ns.Decl.Name.Lexeme);
			outStr.Append("_");
		}
	}

	private void buildNamespaceStr(List<StringView> namespaces, String outStr)
	{
		outStr.Append("CZEN_");

		for (let ns in namespaces)
		{
			outStr.Append(ns);
			outStr.Append("_");
		}
	}

	private void emitType(ZenType type, String outStr)
	{
		/*
		if (let b = type as ZenType.Basic)
		{
			outStr.Append(scope $"{b.Basic.Name}");
		}
		*/
	}
}