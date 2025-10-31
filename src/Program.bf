using System;
using System.IO;
using System.Globalization;

namespace Zen;

class Program
{
	struct CLIArguments
	{
		public String MainFile;
		public bool RunAfterBuild = false;
		public bool KeepOpen = false;
	}

	public static int Main(String[] args)
	{
		CLIArguments cliArgs = default;

		if (args.IsEmpty)
		{
			Console.WriteLine("Set an input file.");
			return 0;
		}

		cliArgs.MainFile = args[0];
		for (let arg in args)
		{
			switch (arg)
			{
			case "-run":
				cliArgs.RunAfterBuild = true;
				break;
			case "-wait":
				cliArgs.KeepOpen = true;
				break;
			}
		}

		run_compiler(cliArgs);
		
		return 0;
	}

	private static void run_compiler(CLIArguments args)
	{
		let builder = scope Builder();
		// @TEMP
		let mainFileDirectory = Path.GetDirectoryPath(args.MainFile, .. scope .());
		let outputDirectory = Path.Combine(.. scope .(), mainFileDirectory, "output");
		builder.Run(args.MainFile, outputDirectory, scope => finishCompile);

		Console.ResetColor();
		if (!builder.HadErrors)
		{
			Console.ForegroundColor = .Green;
			Console.WriteLine("Done!");
			Console.ResetColor();
		}

		if (args.KeepOpen)
			Console.ReadLine("");
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