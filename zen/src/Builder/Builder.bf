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

	private bool m_hadErrors = false;
	private int m_errorCount = 0;

	private Dictionary<Guid, CompFile> m_compFiles = new .() ~ DeleteDictionaryAndValues!(_);

	// public int FilesWritten => m_writtenFiles.Count;
	// public List<String> WrittenFiles => m_writtenFiles;

	public readonly int ErrorCount => m_errorCount;
	public readonly bool HadErrors => m_hadErrors;

	public readonly Stopwatch StopwatchLexer = new .() ~ delete _;
	public readonly Stopwatch StopwatchParser = new .() ~ delete _;
	public readonly Stopwatch StopwatchChecker = new .() ~ delete _;
	public readonly Stopwatch StopwatchCodegen = new .() ~ delete _;

	typealias FinishCompCallback = delegate void(Self builder, bool hadErros);

	public ~this()
	{
		Console.ResetColor();
	}

	public Result<Generator.GeneratorResult> Run(String mainFilePath, String outputDirectory, FinishCompCallback finishCompCallback, List<CFile> outCFiles, bool printScopes)
	{
		// Load files
		pleaseDoFile(mainFilePath, m_compFiles);

		if (m_hadErrors)
			return .Err;

		let finalAst = scope Ast();
		for (let file in m_compFiles)
		{
			finalAst.AddRange(file.value.Ast);
		}

		mixin checkAddErrorsAndReturn(Visitor visitor)
		{
			renderDiagnostics();

			if (m_hadErrors)
				return .Err;
		}

		// Scope builder

		StopwatchChecker.Start();

		let scoper = scope Binder(finalAst);
		addOnVisitorReport!(scoper);
		let globalScope = scoper.Run();

		StopwatchChecker.Stop();

		if (printScopes)
		{
			Binder.PrintScopeTree(globalScope);
		}

		checkAddErrorsAndReturn!(scoper);

		StopwatchChecker.Start();

		// Type resolver

		let resolver = scope Resolver(finalAst, globalScope);
		addOnVisitorReport!(resolver);
		resolver.Run();

		StopwatchChecker.Stop();

		checkAddErrorsAndReturn!(resolver);

		// Checker

		StopwatchChecker.Start();

		let checker = scope Checker(finalAst, globalScope);
		addOnVisitorReport!(checker);
		checker.Run();

		StopwatchChecker.Stop();

		checkAddErrorsAndReturn!(checker);

		// Code gen

		StopwatchCodegen.Start();

		let gen = scope Generator(finalAst, globalScope, outCFiles);
		let c = gen.Generate();

		StopwatchCodegen.Stop();

		finishCompCallback(this, m_hadErrors);

		return .Ok(c);
	}

	private CompFile compFile(String filePath, Guid fileID)
	{
		let text = File.ReadAllText(filePath, .. new .());
		let outTokens = new List<Token>();
		let ast = new Ast();
		let pp = new PreprocessingResult();

		// ----------------------------------------------
		// Tokenize file
		// ----------------------------------------------
		StopwatchLexer.Start();

		let tokenizer = scope Tokenizer(text, fileID);
		let inTokens = tokenizer.Run();

		StopwatchLexer.Stop();

		// ----------------------------------------------
		// Preprocessor
		// ----------------------------------------------
		let preprocessor = scope DirectivePreprocessor();
		addOnVisitorReport!(preprocessor);
		preprocessor.Process(inTokens, outTokens, pp);

		// ----------------------------------------------
		// Parse file
		// ----------------------------------------------
		StopwatchParser.Start();

		let parser = scope Parser(outTokens, ast);
		addOnVisitorReport!(parser);
		parser.Run().IgnoreError();

		StopwatchParser.Stop();

		let comp = new CompFile(filePath, Path.GetFileName(filePath, .. scope .()), text, outTokens, ast, pp);
		return comp;
	}

	private CompFile pleaseDoFile(String path, Dictionary<Guid, CompFile> list)
	{
		let fileID = Guid.Create();
		let comp = compFile(Path.GetActualPathName(path, .. scope .()), fileID);
		list.Add(fileID, comp);

		evaluatePP(comp.PreprocessingResult);

		renderDiagnostics();

		return comp;
	}

	private void evaluatePP(PreprocessingResult result)
	{
		for (let file in result.FilesToLoad)
		{
			let originFilePath = m_compFiles[file.Origin].Path;
			let originFileDirectory = Path.GetDirectoryPath(originFilePath, .. scope .());

			let loadFileName = file.Path;
			let loadFilePath = Path.GetActualPathName(Path.Combine(.. scope .(), originFileDirectory, loadFileName), .. scope .());

			if (originFilePath == loadFilePath)
			{
				let span = new DiagnosticSpan()
				{
					Range = file.PathToken.SourceRange
				};
				addDiagnostic(new .(.Error, "File is attempting to load itself", span));
			}

			bool tryLoadFile = true;
			for (let file in m_compFiles)
			{
				// This file is already loaded, we can safely ignore it.
				if (file.value.Path == loadFilePath)
				{
					tryLoadFile = false;
					break;
				}
			}

			if (tryLoadFile)
			{
				if (File.Exists(loadFilePath))
				{
					pleaseDoFile(loadFilePath, m_compFiles);
				}
				else
				{
					let span = new DiagnosticSpan()
					{
						Range = file.PathToken.SourceRange
					};
					addDiagnostic(new .(.Error, "File not found", span));
				}
			}
		}
	}

	private mixin addOnVisitorReport(Visitor visitor)
	{
		visitor.OnReport.Add(scope:mixin => addDiagnostic);
	}

	private void addDiagnostic(Diagnostic diag)
	{
		m_diagnostics.Add(diag);
	}

	private void renderDiagnostics()
	{
		for (let diagnostic in m_diagnostics)
		{
			m_diagnosticsRenderer.WriteError(m_compFiles, diagnostic);

			++m_errorCount;
			m_hadErrors = true;
		}
	}
}