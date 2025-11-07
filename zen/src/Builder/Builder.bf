using System;
using System.IO;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class Builder
{
	private const ConsoleColor CONSOLE_CODE_COLOR = .Gray;

	private readonly List<Diagnostic> m_diagnostics = new .() ~ DeleteContainerAndItems!(_);
	private readonly DiagnosticRenderer m_diagnosticsRenderer = new .(CONSOLE_CODE_COLOR) ~ delete _;

	private int m_errorCount = 0;
	private int m_warningCount = 0;

	private SourceFileID m_currentFileID = 0;

	private Dictionary<SourceFileID, SourceFile> m_knownFiles = new .() ~ DeleteDictionaryAndValues!(_);
	private Dictionary<SourceFileID, CompFile> m_compFiles = new .() ~ DeleteDictionaryAndValues!(_);

	// public int FilesWritten => m_writtenFiles.Count;
	// public List<String> WrittenFiles => m_writtenFiles;

	public readonly int ErrorCount => m_errorCount;
	public readonly int WarningCount => m_warningCount;

	public readonly Stopwatch StopwatchLexer = new .() ~ delete _;
	public readonly Stopwatch StopwatchParser = new .() ~ delete _;
	public readonly Stopwatch StopwatchChecker = new .() ~ delete _;
	public readonly Stopwatch StopwatchCodegen = new .() ~ delete _;

	public ~this()
	{
		Console.ResetColor();
	}

	public Result<Generator.GeneratorResult> Run(String mainFilePath, String outputDirectory, List<CFile> outCFiles, bool printScopes)
	{
		// ----------------------------------------------
		// Load files (starting from the main file)
		// ----------------------------------------------
		Try!(parseFile(loadSourceFile(mainFilePath)));

		let finalAst = scope Ast();
		for (let file in m_compFiles)
		{
			finalAst.AddRange(file.value.Ast);
		}

		// ----------------------------------------------
		// Scope builder
		// ----------------------------------------------

		StopwatchChecker.Start();

		let scoper = scope Binder(finalAst);
		addOnVisitorReport!(scoper);
		let globalScope = Try!(scoper.Run());

		StopwatchChecker.Stop();

		if (printScopes)
		{
			Binder.PrintScopeTree(globalScope);
		}

		StopwatchChecker.Start();

		// ----------------------------------------------
		// Type resolver
		// ----------------------------------------------

		let resolver = scope Resolver(finalAst, globalScope);
		addOnVisitorReport!(resolver);
		Try!(resolver.Run());

		StopwatchChecker.Stop();

		// ----------------------------------------------
		// Checker
		// ----------------------------------------------

		StopwatchChecker.Start();

		let checker = scope Checker(finalAst, globalScope);
		addOnVisitorReport!(checker);
		Try!(checker.Run());

		StopwatchChecker.Stop();

		// ----------------------------------------------
		// Code gen
		// ----------------------------------------------

		StopwatchCodegen.Start();

		let gen = scope Generator(finalAst, globalScope, outCFiles);
		let c = gen.Generate();

		StopwatchCodegen.Stop();

		return .Ok(c);
	}

	private Result<CompFile> parseFile(SourceFile source)
	{
		let comp = Try!(parseFileWithID(source, source.ID));
		m_compFiles.Add(source.ID, comp);

		// Load files from the preprocessor
		for (let fileLoad in comp.PreprocessingResult.FilesToLoad)
		{
			let originFilePath = m_compFiles[fileLoad.Origin].Source.Path;
			let originFileDirectory = Path.GetDirectoryPath(originFilePath, .. scope .());

			let loadFileName = fileLoad.Path;
			let loadFilePath = Path.GetActualPathName(Path.Combine(.. scope .(), originFileDirectory, loadFileName), .. scope .());

			if (originFilePath == loadFilePath)
			{
				let span = new DiagnosticSpan()
				{
					Range = fileLoad.PathToken.SourceRange
				};
				addDiagnostic(new .(.Error, "File is attempting to load itself", span));
				return .Err;
			}

			bool tryLoadFile = true;
			for (let file in m_compFiles)
			{
				// This file is already loaded, we can safely ignore it.
				if (file.value.Source.Path == loadFilePath)
				{
					tryLoadFile = false;
					break;
				}
			}

			if (tryLoadFile)
			{
				if (File.Exists(loadFilePath))
				{
					Try!(parseFile(loadSourceFile(loadFilePath)));
				}
				else
				{
					let span = new DiagnosticSpan()
					{
						Range = fileLoad.PathToken.SourceRange
					};
					addDiagnostic(new .(.Error, "File not found", span));
				}
			}
		}

		return comp;
	}

	private Result<CompFile> parseFileWithID(SourceFile source, SourceFileID fileID)
	{
		let outTokens = new List<Token>();
		let ast = new Ast();
		let pp = new PreprocessingResult();

		mixin TryCleanup(var result)
		{
			if (result case .Err(var err))
			{
				delete outTokens;
				DeleteContainerAndItems!(ast);
				delete pp;

				return .Err((.)err);
			}
			result.Get()
		}

		// ----------------------------------------------
		// Tokenize file
		// ----------------------------------------------
		StopwatchLexer.Start();

		let tokenizer = scope Tokenizer(source.Content, fileID);
		let inTokens = tokenizer.Run();

		StopwatchLexer.Stop();

		// ----------------------------------------------
		// Preprocessor
		// ----------------------------------------------
		let preprocessor = scope DirectivePreprocessor(inTokens);
		addOnVisitorReport!(preprocessor);
		TryCleanup!(preprocessor.Process(source, outTokens, pp));

		// ----------------------------------------------
		// Parse file
		// ----------------------------------------------
		StopwatchParser.Start();

		let parser = scope Parser(outTokens, ast);
		addOnVisitorReport!(parser);
		TryCleanup!(parser.Run());

		StopwatchParser.Stop();

		return .Ok(new CompFile(source, outTokens, ast, pp));
	}

	private SourceFile loadSourceFile(String path)
	{
		let actualPath = Path.GetActualPathName(path, .. scope .());
		let id = ++m_currentFileID;
		let source = new SourceFile(id, actualPath);
 		m_knownFiles.Add(id, source);

		return source;
	}

	private mixin addOnVisitorReport(Visitor visitor)
	{
		visitor.OnReport.Add(scope:mixin => addDiagnostic);
	}

	private void addDiagnostic(Diagnostic diag)
	{
		m_diagnostics.Add(diag);

		if (diag.Level == .Error)
		{
			m_errorCount++;
		}
	}

	public void RenderDiagnostics()
	{
		for (let diagnostic in m_diagnostics)
		{
			m_diagnosticsRenderer.WriteError(m_knownFiles, diagnostic);
		}
	}
}