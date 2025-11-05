using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class Generator
{
	private readonly Ast m_ast;
	private readonly Scope m_globalScope;
	private readonly List<CFile> m_outputFilesList;

	public struct GeneratorResult
	{
		public readonly CFile MainFile;
		public readonly List<CFile> Files;
	}

	const String BOILERPLATE =
		"""
		#include <stdio.h>
		#include <stdlib.h>
		#include <stdbool.h>
		#include <math.h>

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
		// #include <windows.h>
		#endif

		#include <raylib.h>
		""";

	public this(Ast ast, Scope globalScope, List<CFile> cfilesList)
	{
		this.m_ast = ast;
		this.m_globalScope = globalScope;
		this.m_outputFilesList = cfilesList;
	}

	public GeneratorResult Generate()
	{
		createNewFile(new .("zen.h", BOILERPLATE));

		let headerCode = doAST(m_ast, .. scope .());

		let mainCode = scope StringCodeBuilder();
		mainCode.AppendLine("#include <zen.h>");
		mainCode.AppendEmptyLine();
		mainCode.AppendLine(headerCode.Code);
		mainCode.AppendEmptyLine();
		mainCode.AppendLine(
		"""
		void main()
		{
			zen_main();
		}
		""");
		let mainFile = createNewFile(new .("main.c", mainCode.Code));

		return .() {
			MainFile = mainFile,
			Files = m_outputFilesList
		};
	}

	private void doAST(Ast ast, StringCodeBuilder headerCode)
	{
		void doScopeRecursive(DoScopeKind kind, Scope _scope, StringCodeBuilder code)
		{
			doScope(kind, _scope, code);
			for (let entity in _scope.EntityMap)
			{
				if (let ns = entity.value as Entity.Namespace)
				{
					// namespaceStack.Append(scope $"_{ns.Decl.Name.Lexeme}");
					// doScope(.NamedTypeDeclares, ns.Decl.Scope, namespaceStackStr, headerCode);
					doScopeRecursive(kind, ns.Decl.Scope, code);
				}
			}
		}

		doScopeRecursive(.NamedTypeDeclares, m_globalScope, headerCode);
		doScopeRecursive(.FunctionDeclares, m_globalScope, headerCode);
		doScopeRecursive(.NamedTypeImpls, m_globalScope, headerCode);
		doScopeRecursive(.FunctionImpls, m_globalScope, headerCode);
	}

	enum DoScopeKind
	{
		NamedTypeDeclares,
		FunctionDeclares,
		NamedTypeImpls,
		FunctionImpls
	}

	private void buildNamespaceString(IEntityNamespaceParent entity, String outStr, bool zenPrefix)
	{
		buildNamespaceString(entity.NamespaceParent, outStr, zenPrefix);
	}

	private void buildNamespaceString(Entity.Namespace _namespace, String outStr, bool zenPrefix)
	{
		if (zenPrefix)
		{
			outStr.Append("zen");
		}
		if (_namespace != null)
		{
			outStr.Append("_");
			outStr.Append(_namespace.Token.Lexeme);
		}
	}

	private void doScope(DoScopeKind kind, Scope _scope, StringCodeBuilder code)
	{
		if (kind == .NamedTypeDeclares)
		{
			for (let entity in _scope.EntityMap)
			{
				switch (entity.value.GetKind())
				{
				case .TypeName(let typename):
					let namespaceStr = buildNamespaceString(typename, .. scope .(), true);
					switch (typename.Decl.GetKind())
					{
					case .StructDecl(let _struct):
						if (_struct.Kind == .Extern)
							break;

						let name = scope $"{namespaceStr}_{_struct.Name.Lexeme}";
						code.AppendLine(scope $"typedef struct {name} {name};");
						break;
					case .EnumDecl(let _enum):
						if (_enum.Kind == .Extern)
							break;

						let enumName = scope $"{namespaceStr}_{_enum.Name.Lexeme}";
						code.AppendLine(scope $"typedef enum \{");
						code.IncreaseTab();
						{
							for (let value in _enum.Values)
							{
								code.AppendLine(scope $"{enumName}_{value.Name.Lexeme}");
								if (value.Value != null)
								{
									code.Append(" = ");
									emitExpr(value.Value, code, _enum.Scope);
								}
								if (value != _enum.Values.Back)
									code.Append(',');
							}
						}
						code.DecreaseTab();
						code.AppendLine(scope $"\} {enumName};");
						break;
					default:
					}
					break;
				default:
				}
			}
		}

		if (kind == .FunctionDeclares)
		{
			for (let entity in _scope.EntityMap)
			{
				if (let funEnt = entity.value as Entity.Function)
				{
					let fun = funEnt.Decl;

					if (fun.Kind == .Extern)
						continue;

					let namespaceStr = buildNamespaceString(funEnt, .. scope .(), true);
					appendFunctionHead(fun, namespaceStr, code);
					code.Append(';');
				}
				if (let constant = entity.value as Entity.Constant)
				{
					// This means it's a built in constant, so like int32s and stuff. We can safely ignore those as they're defined in the zen.h header.
					if (constant.Decl case .Builtin)
						continue;

					Runtime.Assert(constant.Decl case .Normal(let basic));

					// @TODO
					// Macros are a bit wack, does c have constant expressions or something?
					// code.AppendLine(scope $"#define {basic.Name.Lexeme} ");
					code.AppendLine("const ");
					bool isStructType = false;

					if (constant.ResolvedType case .Structure)
					{
						isStructType = true;
					}
					code.Append(writeResolvedType(constant.ResolvedType, .. scope .()));

					// emitExpr(v.Type, code, _scope);
					code.Append(scope $" {basic.Name.Lexeme}");

					if (constant.ResolvedType case .Array(let element, let count))
					{
						code.Append(scope $"[{count}]");
					}

					if (basic.Initializer != null)
					{
						code.Append(scope $" = ");
						emitExpr(basic.Initializer, code, _scope);
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
					code.Append(';');
				}
			}
		}

		if (kind == .NamedTypeImpls)
		{
			for (let entity in _scope.EntityMap)
			{
				switch (entity.value.GetKind())
				{
				case .TypeName(let typename):
					let namespaceStr = buildNamespaceString(typename, .. scope .(), true);
					switch (typename.Decl.GetKind())
					{
					case .StructDecl(let _struct):
						if (_struct.Kind == .Extern)
							break;

						let name = scope $"{namespaceStr}_{_struct.Name.Lexeme}";
						code.AppendLine(scope $"struct {name} \{");
						code.IncreaseTab();
						{
							for (let field in _struct.Fields)
							{
								code.AppendNewLine();
								code.AppendTabs();

								let lookup = _struct.Scope.LookupStmtAs<Entity.Variable>(field);
								if (lookup case .Ok(let val))
								{
									bool writeNamespace = true;
									if (val.ResolvedType case .Structure(let foundStruct))
									{
										if (foundStruct.Kind == .Extern)
										{
											writeNamespace = false;
										}

									}

									/*
									if (writeNamespace)
									if (let ns = val.ResolvedType as IEntityNamespaceParent)
									{
										code.Append(buildNamespaceString(ns, .. scope .()));
										code.Append("_");
									}
									*/

									// emitExpr( )
									// code.Append(val.ResolvedType);
									code.Append(writeResolvedType(val.ResolvedType, .. scope .()));
									code.Append(scope $" {field.Name.Lexeme};");
								}
								else
								{
									Runtime.FatalError("This should've been declared. SOMEONE didn't do their job correctly!");
								}

								// emitExpr(field.Type, code, _struct.Scope);
								// code.Append(scope $" {field.Name.Lexeme};");
							}
						}
						code.DecreaseTab();
						code.AppendLine("};"); // <- Yah, struct implementations need semicolons for TinyCC:
											   // https://lists.gnu.org/archive/html/tinycc-devel/2008-09/msg00033.html
						break;
					default:
					}
					break;
				default:
				}
			}
		}

		if (kind == .FunctionImpls)
		{
			for (let entity in _scope.EntityMap)
			{
				switch (entity.value.GetKind())
				{
				case .Function(let entity):

					let fun = entity.Decl;

					if (fun.Kind == .Extern)
						break;

					let namespaceStr = buildNamespaceString(entity, .. scope .(), true);
					appendFunctionHead(fun, namespaceStr, code);
					code.AppendLine("{");
					code.IncreaseTab();
					{
						for (let stmt in fun.Body.List)
						{
							emitFunctionStmt(stmt, code, fun.Scope);
						}
					}
					code.DecreaseTab();
					code.AppendLine("}");
					break;
				case .Variable(let ent):
					// It might be okay to do this here?
					// For variables at the global (or non functional) scope at least...?
					emitFunctionStmt(ent.Decl, code, _scope);
					break;
				default:
				}
			}
		}
	}

	private void appendFunctionHead(AstNode.Stmt.FunctionDeclaration func, String namespaceStack, StringCodeBuilder code)
	{
		let parameters = scope StringCodeBuilder();
		for (let param in func.Parameters)
		{
			let entity = func.Scope.LookupStmtAs<Entity.Variable>(param);
			parameters.Append(writeResolvedType(entity.Value.ResolvedType, .. scope .()));
			// emitExpr(param.Type, parameters, func.Scope);
			parameters.Append(scope $" {param.Name.Lexeme}");
			if (param != func.Parameters.Back)
				parameters.Append(", ");
		}

		code.AppendEmptyLine();

		emitExpr(func.Type, code, func.Scope);
		code.Append(scope $" {namespaceStack}_{func.Name.Lexeme}({parameters.Code})");
	}

	private void emitFunctionStmt(AstNode.Stmt stmt, StringCodeBuilder code, Scope _scope, bool emitSemicolon = true)
	{
		mixin addSemicolon()
		{
			if (emitSemicolon)
			{
				code.Append(';');
			}
		}

		switch (stmt.GetKind())
		{
		case .Block(let block):
			code.AppendLine("{");
			code.IncreaseTab();
			for (let n in block.List)
			{
				emitFunctionStmt(n, code, _scope);
			}
			code.DecreaseTab();
			code.AppendLine("}");
			break;

		case .VarDecl(let v):
			code.AppendNewLine();
			code.AppendTabs();

			bool isStructType = false;

			let entity = _scope.LookupStmtAs<Entity.Variable>(v).Value;
			if (entity.ResolvedType case .Structure)
			{
				isStructType = true;
			}
			code.Append(writeResolvedType(entity.ResolvedType, .. scope .()));

			// emitExpr(v.Type, code, _scope);
			code.Append(scope $" {v.Name.Lexeme}");

			if (entity.ResolvedType case .Array(let element, let count))
			{
				code.Append(scope $"[{count}]");
			}

			if (v.Initializer != null)
			{
				code.Append(scope $" = ");
				emitExpr(v.Initializer, code, _scope);
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
			addSemicolon!();
			break;

		case .Return(let ret):
			code.AppendLine(scope $"return ");
			emitExpr(ret.Value, code, _scope);
			addSemicolon!();
			break;

		case .If(let _if):
			let condition = emitExpr(_if.Condition, .. scope .(), _if.ThenBranch.Scope);
			code.AppendLine(scope $"if ({condition.Code})");
			emitFunctionStmt(_if.ThenBranch, code, _if.ThenBranch.Scope);

			if (_if.ElseBranch case .Ok(let _else))
			{
				code.AppendLine("else");
				emitFunctionStmt(_else, code, _else.Scope);
			}

			break;

		case .For(let _for):
			let body = scope StringCodeBuilder();
			// Init
			// body.Append(emitExpr(_for.Initialization, .. scope .()));
			emitFunctionStmt(_for.Initialization, body, _for.Scope, false);
			body.Append(';');
			// Condition
			if (_for.Condition != null) body.Append(' ');
			emitExpr(_for.Condition, body, _for.Scope);
			body.Append(';');
			// Update
			if (_for.Updation != null) body.Append(' ');
			emitExpr(_for.Updation, body, _for.Scope);

			code.AppendLine(scope $"for ({body.Code})");
			emitFunctionStmt(_for.Body, code, _for.Scope);
			break;

		case .While(let _while):
			let condition = emitExpr(_while.Condition, .. scope .(), _while.Scope);
			code.AppendLine(scope $"while ({condition.Code})");
			emitFunctionStmt(_while.Body, code, _while.Scope);
			break;

		case .Expression(let expr):
			code.AppendNewLine();
			code.AppendTabs();
			emitExpr(expr.InnerExpr, code, _scope);
			addSemicolon!();
			break;

		default:
		}
	}

	private void writeResolvedType(ZenType type, String outStr)
	{
		switch (type)
		{
		case .Basic(let basic):
			outStr.Append(basic.Name);
			break;
		case .Structure(let _struct):
			bool writeNamespace = true;
			if (_struct.Kind == .Extern)
			{
				writeNamespace = false;
			}
			if (writeNamespace )
			{
				outStr.Append("zen");
				if (_struct.Scope.NamespaceParent case .Ok(let ns))
				{
					buildNamespaceString(ns, outStr, false);
					outStr.Append('_');
				}
			}

			outStr.Append(_struct.Name.Lexeme);
			break;
		case .Enum(let _enum):
			bool writeNamespace = true;
			if (writeNamespace )
			{
				// outStr.Append("zen_");
				if (_enum.Scope.NamespaceParent case .Ok(let ns))
				{
					buildNamespaceString(ns, outStr, true);
					outStr.Append('_');
				}
			}

			outStr.Append(_enum.Name.Lexeme);
			break;
		case .Pointer(let elem):
			writeResolvedType(*elem, outStr);

			// @TODO
			// Pointers in C are next to the name and not the type...
			// In Zen they're on the type....
			// I'll have to look into this
			outStr.Append('*');
			break;
		case .Array(let element, let count):
			// Arrays are next to the name and not the type.
			// So we can just ignore this.
			writeResolvedType(*element, outStr);
			break;
		default:
			Runtime.Assert(false);
		}
	}

	private void emitExpr(AstNode.Expression expr, StringCodeBuilder code, Scope _scope, bool zenNamespacePrefix = true)
	{
		switch (expr.GetKind())
		{
		case .Binary(let bin):
			emitExpr(bin.Left, code, _scope);
			code.Append(scope $" {bin.Op.Lexeme} ");
			emitExpr(bin.Right, code, _scope);
			break;

		case .Variable(let _var):
			code.Append(_var.Name.Lexeme);
			break;

		case .Call(let call):
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

			let arguments = scope StringCodeBuilder();
			for (let arg in call.Arguments)
			{
				/*
				let entity = _scope.Lookup(call.Callee.Name.Lexeme);
				if (entity case .Ok(let found))
				{
					if (let fun = found as Entity.Function)
					{
						if (fun.Decl.Kind == .Extern)
						{
							arguments.Append("*(Color*)&");
						}
					}
				}
				*/
				if (builtinFunc case .Ok(let name))
				{
					if (name.Name == "sizeof")
					{
						let a = 0;
					}
				}

				emitExpr(arg, arguments, _scope);
				if (arg != call.Arguments.Back)
					arguments.Append(", ");
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

					// @TODO
					// Support non-primitive types.
					let printArg = call.Arguments[0];
					ZenType argType = ?;
					if (printArg.GetKind() case .Literal(let lit))
					{
						argType = lit.GetLiteralType();
					}
					else if (printArg.GetKind() case .Variable(let _var))
					{
						let entity = _scope.LookupName(_var.Name.Lexeme).Value as Entity.Variable;
						argType = entity.ResolvedType;
					}
					else
					{
						Runtime.FatalError("Can't convert this type! :(");
					}

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

					code.Append("printf");
					code.Append("(");
					if (!format.IsEmpty)
					{
						code.Append(scope $"\"{format}\", ");
					}
					code.Append(arguments.Code);
					if (!extra.IsEmpty)
					{
						code.Append(scope $" {extra}");
					}
					code.Append(")");
					break;
				case "sizeof":
					code.Append("sizeof(");
					code.Append(arguments.Code);
					code.Append(")");
					break;
				default:
					Runtime.FatalError(scope $"Unhandled builtin: {builtinName}");
				}
			}
			else
			{
				// @FIX
				// I don't think the codegen should have to do this
				let entity = _scope.LookupName(call.Callee.Name.Lexeme);
				if (entity case .Ok(let found))
				{
					if (let t = found as IEntityNamespaceParent)
					{
						bool writeNamespace = true;

						if (let fun = t as Entity.Function)
						{
							if (fun.Decl.Kind == .Extern)
								writeNamespace = false;
						}

						if (writeNamespace)
						{
							code.Append(buildNamespaceString(t, .. scope .(), true));
							code.Append("_");
						}
					}
				}

				emitExpr(call.Callee, code, _scope);
				code.Append(scope $"({arguments.Code})");
			}
			break;

		case .Logical(let logical):
			break;

		case .Literal(let literal):
			code.Append(literal.ValueString);
			if (literal.GetLiteralType().IsTypeFloat())
			{
				// C appends the "f" at the end of floats...
				// Not technically required, I don't think?
				// But better to be safe than sorry.
				code.Append("f");
			}
			break;

		case .Unary(let unary):
			code.Append(unary.Operator.Lexeme);
			emitExpr(unary.Right, code, _scope);
			break;

		case .Get(let get):
			emitExpr(get.Object, code, _scope);

			bool isPointer = get.IsPointer;
			if (isPointer)
				code.Append("->");
			else
				code.Append('.');
			code.Append(get.Name.Lexeme);
			break;

		case .Set(let set):
			emitExpr(set.Object, code, _scope);
			code.Append(scope $".{set.Name}");
			break;

		case .This(let _this):
			break;

		case .Grouping(let grouping):
			code.Append('(');
			emitExpr(grouping.Expression, code, _scope);
			code.Append(')');
			break;

		case .Assign(let assign):
			emitExpr(assign.Assignee, code, _scope);
			code.Append(scope $" {assign.Op.Lexeme} ");
			emitExpr(assign.Value, code, _scope);
			break;

		case .QualifiedName(let qn):
			bool writeNamespace = true;

			// @FIX @FIX @FIX
			// This sucks fucking dick
			// The checker should resolve all this, I'm tired of looking back up scopes to find this data...
			if (let call = qn.Right as AstNode.Expression.Call)
			{
				let lookForScopeResult = _scope.LookupName(qn.Left.Lexeme);

				if (lookForScopeResult case .Ok(let leftFound))
				{
					if (let foundScope = leftFound as Entity.Namespace)
					{
						let callRes = foundScope.Decl.Scope.LookupName(call.Callee.Name.Lexeme);
						if (callRes case .Ok(let found))
						{
							if (let fun = found as Entity.Function)
							{
								if (fun.Decl.Kind == .Extern)
								{
									writeNamespace = false;
								}
							}
						}
					}
				}
			}

			if (writeNamespace)
			{
				if (zenNamespacePrefix)
				code.Append("zen_");

				// @FIX
				// I don't think the codegen should have to do this
				let entity = _scope.LookupName(qn.Left.Lexeme);
				if (entity case .Ok(let found))
				{
					if (let typename = found as Entity.TypeName)
					{
						code.Append(typename.NamespaceParent.Token.Lexeme);
						code.Append("_");
					}
				}

				code.Append(scope $"{qn.Left.Lexeme}_");
			}

			emitExpr(qn.Right, code, _scope, false);
			break;

		case .NamedType(let type):
			switch (type.Kind)
			{
			case .Simple(let name):
				code.Append(name.Lexeme);
				break;
			case .Qualified(let qualified):
				emitExpr(qualified, code, _scope);
				break;
			case .Array(let inner, let countExpr):
				Debug.Assert(false);
				break;
			case .Pointer(let inner):
				Debug.Assert(false);
				break;
			}
			break;

		case .Cast(let cast):
			code.Append('(');
			emitExpr(cast.TargetType, code, _scope);
			code.Append(')');
			emitExpr(cast.Value, code, _scope);
			break;

		case .Index(let index):
			emitExpr(index.Array, code, _scope);
			code.Append('[');
			emitExpr(index.Index, code, _scope);
			code.Append(']');
			break;
		}
	}

	private CFile createNewFile(CFile file)
	{
		m_outputFilesList.Add(file);

		return file;
	}
}