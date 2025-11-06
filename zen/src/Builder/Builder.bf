using System;
using System.IO;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class Builder
{
	private const ConsoleColor CONSOLE_CODE_COLOR = .Gray;

	private DiagnosticManager m_errorManager = new .(CONSOLE_CODE_COLOR) ~ delete _;
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
			for (let err in visitor.Diagnostics)
			{
				writeDiagnostic(err);
			}

			if (m_hadErrors)
				return .Err;
		}

		// Scope builder

		StopwatchChecker.Start();

		let scoper = scope Binder(finalAst);
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
		resolver.Run();

		StopwatchChecker.Stop();

		checkAddErrorsAndReturn!(resolver);

		// Checker

		StopwatchChecker.Start();

		let checker = scope Checker(finalAst, globalScope);
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

		// Tokenize file
		StopwatchLexer.Start();

		let tokenizer = new Tokenizer(text, fileID);
		let tokens = tokenizer.Run();

		StopwatchLexer.Stop();

		// Parse file

		StopwatchParser.Start();

		let parser = new Parser(tokens);
		Ast retAst = ?;
		switch (parser.Run())
		{
		case .Ok(let ast):
			retAst = ast;
			break;
		case .Err:
			break;
		}

		StopwatchParser.Stop();

		let comp = new CompFile(filePath, Path.GetFileName(filePath, .. scope .()), text, tokenizer, parser, tokens, retAst);
		return comp;
	}

	private CompFile pleaseDoFile(String path, Dictionary<Guid, CompFile> list)
	{
		let fileID = Guid.Create();
		let comp = compFile(Path.GetActualPathName(path, .. scope .()), fileID);
		list.Add(fileID, comp);

		for (let err in comp.Parser.Diagnostics)
		{
			writeDiagnostic(err);
		}

		searchForLoads(comp, comp.Ast, list);

		return comp;
	}

	// @TEMP?
	private void searchForLoads(CompFile currentFile, Ast ast, Dictionary<Guid, CompFile> list)
	{
		for (let stmt in ast)
		{
			if (let directive = stmt as AstNode.Stmt.BasicDirective)
			{
				if (directive.Token.Lexeme == "load")
				{
					// let directiveCompFile = m_compFiles[directive.Token.File];
					let directiveFilePath = m_compFiles[directive.Token.File].Path;
					let directiveFileDirectory = Path.GetDirectoryPath(directiveFilePath, .. scope .());

					// Trim the surrounding quotes
					bool isMultiline = false;
					let offset = (isMultiline) ? 3 : 1;

					let loadFileName = directive.Name.Lexeme.Substring(offset, directive.Name.Lexeme.Length - 1 - offset);
					let loadFilePath = Path.GetActualPathName(Path.Combine(.. scope .(), directiveFileDirectory, loadFileName), .. scope .());

					if (currentFile.Path == loadFilePath)
					{
						let span = new DiagnosticSpan()
						{
							Range = directive.Name.SourceRange
						};
						writeDiagnostic(new .(.Error, "File is attempting to load itself", span));
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
							pleaseDoFile(loadFilePath, list);
						}
						else
						{
							let span = new DiagnosticSpan()
							{
								Range = directive.Name.SourceRange
							};
							writeDiagnostic(new .(.Error, "File not found", span));
						}
					}
				}
				else
				{
					// @TEMP
					Runtime.FatalError("bruh");
				}
			}
		}
	}

	private void writeDiagnostic(Diagnostic diagnostic)
	{
		m_errorManager.WriteError(m_compFiles, diagnostic);

		++m_errorCount;
		m_hadErrors = true;
	}
}