using System;
using System.IO;
using System.Collections;
using System.Globalization;

namespace Zen;

class Program
{
	struct CLIArguments
	{
		public String MainFile;
		public bool RunAfterBuild = false;
		public bool KeepOpen = false;
		public bool DontBuild = false;
		public bool PrintScopes = false;
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
			case "-nobuild":
				cliArgs.DontBuild = true;
				break;
			case "-printscopes":
				cliArgs.PrintScopes = true;
				break;
			}
		}

		run_compiler(cliArgs);
		
		return 0;
	}

	private static let outputFiles = new List<CFile>() ~ DeleteContainerAndItems!(_);

	private static void run_compiler(CLIArguments args)
	{
		// @TEMP
		let mainFileDirectory = Path.GetDirectoryPath(args.MainFile, .. scope .());
		let outputDirectory = Path.Combine(.. scope .(), mainFileDirectory, "output", "src");

		if (args.DontBuild)
		{
			if (args.RunAfterBuild)
			{
				let path = Path.Combine(.. scope .(), outputDirectory, "main.c");
				execute_c_code(File.ReadAllText(path, .. scope .()), outputDirectory);
			}

			return;
		}

		let builder = scope Builder();
		let buildResult = builder.Run(args.MainFile, outputDirectory, outputFiles, args.PrintScopes);

		Console.ResetColor();

		builder.RenderDiagnostics();

		Console.WriteLine(scope $"Errors: {builder.ErrorCount}. Warnings: {builder.WarningCount}.");

		if (buildResult case .Ok)
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
			let checkerTime = builder.StopwatchChecker.Elapsed.TotalSeconds;
			let codegenTime = builder.StopwatchCodegen.Elapsed.TotalSeconds;

			/*
			writeTimeOutput("Lexing    time:", lexerTime);
			writeTimeOutput("Parsing   time:", parserTime);
			writeTimeOutput("Compiling time:", compilerTime);
			writeTimeOutput("Codegen   time:", codegenTime);
			writeTimeOutput("Total     time:", lexerTime + parserTime + compilerTime + codegenTime);
			*/

			writeTimeOutput("Frontend time:", lexerTime + parserTime + checkerTime);
			writeTimeOutput("Backend  time:", codegenTime);
			writeTimeOutput("Total    time:", lexerTime + parserTime + checkerTime + codegenTime);

			Console.ResetColor();

			Console.ForegroundColor = .Green;
			Console.Write("SUCCESS");
			Console.ResetColor();
			Console.WriteLine(": Build completed with no errors.");

			for (let file in buildResult.Value.Files)
			{
				let outputDir = Path.Combine(.. scope .(), outputDirectory, scope $"{file.Name}");
				File.WriteAllText(outputDir, file.Text);
			}

			if (args.RunAfterBuild)
			{
				execute_c_code(buildResult.Value.MainFile.Text, outputDirectory);
			}
		}
		else
		{
			Console.ForegroundColor = .Red;
			Console.WriteLine("Compile failed.");
		}

		if (args.KeepOpen)
		{
			Console.ReadLine("");
		}
	}

	private static void execute_c_code(String code, String includePath)
	{
		mixin fail(String msg)
		{
			Console.ForegroundColor = .DarkRed;
			Console.WriteLine(msg);
			Console.ResetColor();
			return;
		}

		let tccPath = Path.Combine(.. scope .(), Directory.GetCurrentDirectory(.. scope .()), "vendor", "libtcc", "vendor", "tcc");

		let compiler = scope libtcc.TCCCompiler(tccPath);

		compiler.AddIncludePath(includePath);
		c_raylib_add(compiler);

		if (compiler.CompileString(code) == -1)
		{
			fail!("TinyCC compilation failed");
		}
		if (compiler.Relocate(libtcc.Bindings.TccRealocateConst.TCC_RELOCATE_AUTO) < 0)
		{
			fail!("Relocation failed");
		}

		// let addSymbol = compiler.GetSymbol("add");
		// let mulSymbol = compiler.GetSymbol("mul");
		// let messageSymbol = compiler.GetSymbol("message");
		let mainSymbol = compiler.GetSymbol("main");

		if (mainSymbol == null)
		{
			fail!("The main symbol couldn't be found, so we can't run the program!");
		}

		// function int(int a, int b) add_func = (.)addSymbol;
		// function int(int a, int b) mul_func = (.)mulSymbol;
		// char8* msg_func = *(char8**)messageSymbol;
		function void() main_func = (.)mainSymbol;

		main_func();
		// Console.WriteLine(add_func(4, 2));
		// Console.WriteLine(mul_func(4, 2));
		// Console.WriteLine(scope String(msg_func));
	}
}