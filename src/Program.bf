using System;
using System.IO;
using System.Globalization;

namespace Zen;

class Program
{
	public static int Main(String[] args)
	{
		let builder = scope Builder();
		builder.Run(scope => finishCompile);

		Console.ResetColor();
		if (!builder.HadErrors)
		{
			Console.ForegroundColor = .Green;
			Console.WriteLine("Done!");
			Console.ResetColor();
		}

		Console.ReadLine("");

		/*

		if (parser.Run() case .Ok(let ast))
		{
			/*
			for (let node in ast)
			{
				Console.WriteLine(scope $"{node.GetType().GetName(..scope .())}");
				Console.WriteLine(printNode(node, .. scope .()));
			}
			*/

			let gen = scope Generator(ast);
			let c = gen.Run(.. scope .());

			File.WriteAllText(Path.Combine(.. scope .(), testPath, "main.c"), c);
		}
		else
		{
		}

		*/
		return 0;
	}

	private static void printNode(AstNode node, String outBuffer)
	{
		if (let v = node as AstNode.Stmt.VariableDeclaration)
		{
			outBuffer.Append(scope $"{v.Kind}, {v.Name.Lexeme}");
			printNode(v.Initializer, outBuffer);
		}

		if (let bin = node as AstNode.Expression.Binary)
		{
			outBuffer.Append(scope $"{bin.Left} {bin.Op.Lexeme}");
		}
	}

	private static void finishCompile(Builder builder, bool hadErrors)
	{
		if (!builder.HadErrors)
		{
			void writeTimeOutput(StringView title, double seconds)
			{
				let secondsFormat = "0.00000";

				Console.ForegroundColor = .White;

				Console.Write(title);

				Console.ForegroundColor = .DarkGray;

				Console.Write(scope $" {seconds.ToString(.. scope .(), secondsFormat, CultureInfo.InvariantCulture)}s \n");
			}

			Console.ForegroundColor = .DarkGray;
			// Console.WriteLine(scope $"{builder.FilesWritten} {(builder.FilesWritten == 1) ? "file" : "files" } written");

			let lexerTime = builder.StopwatchLexer.Elapsed.TotalSeconds;
			let parserTime = builder.StopwatchParser.Elapsed.TotalSeconds;
			let compilerTime = builder.StopwatchCompiler.Elapsed.TotalSeconds;
			let codegenTime = builder.StopwatchCodegen.Elapsed.TotalSeconds;

			/*
			writeTimeOutput("Lexing    time:", lexerTime);
			writeTimeOutput("Parsing   time:", parserTime);
			writeTimeOutput("Compiling time:", compilerTime);
			writeTimeOutput("Codegen   time:", codegenTime);
			writeTimeOutput("Total     time:", lexerTime + parserTime + compilerTime + codegenTime);
			*/

			writeTimeOutput("Frontend time:", lexerTime + parserTime);
			writeTimeOutput("Backend  time:", compilerTime + codegenTime);
			writeTimeOutput("Total    time:", lexerTime + parserTime + compilerTime + codegenTime);

			Console.ResetColor();
		}
		else
		{
			Console.ForegroundColor = .Red;
			Console.WriteLine(scope $"Errors: {builder.ErrorCount}");
			Console.WriteLine("Compilation failed.");
		}
	}
}