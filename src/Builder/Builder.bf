using System;
using System.IO;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class CompFile
{
	public readonly String Path = new .() ~ delete _;

	public readonly String Name = new .() ~ delete _;
	public readonly String Text ~ delete _;
	public readonly List<StringView> Lines = new .() ~ delete _;

	public readonly Tokenizer Tokenizer ~ delete _;
	public readonly Parser Parser ~ delete _;

	public readonly List<Token> Tokens;
	public readonly Ast Ast;

	public this(String path, String name, String text, Tokenizer tokenizer, Parser parser, List<Token> tokens, Ast ast)
	{
		this.Path.Set(path);
		this.Name.Set(name);
		this.Text = text;

		this.Tokenizer = tokenizer;
		this.Parser = parser;

		this.Tokens = tokens;
		this.Ast = ast;

		let split = text.Split('\n');
		for (let line in split)
		{
			this.Lines.Add(line);
		}
	}
}

class Builder
{
	private const ConsoleColor CONSOLE_CODE_COLOR = .Gray;

	private ErrorManager m_errorManager = new .(CONSOLE_CODE_COLOR) ~ delete _;
	private bool m_hadErrors = false;
	private int m_errorCount = 0;

	private Dictionary<Guid, CompFile> m_compFiles = new .() ~ DeleteDictionaryAndValues!(_);
	private List<CompilerError> m_errors = new .() ~ DeleteContainerAndItems!(_);

	// public int FilesWritten => m_writtenFiles.Count;
	// public List<String> WrittenFiles => m_writtenFiles;

	public readonly int ErrorCount => m_errorCount;
	public readonly bool HadErrors => m_hadErrors;

	public readonly Stopwatch StopwatchLexer = new .() ~ delete _;
	public readonly Stopwatch StopwatchParser = new .() ~ delete _;
	public readonly Stopwatch StopwatchCompiler = new .() ~ delete _;
	public readonly Stopwatch StopwatchCodegen = new .() ~ delete _;

	typealias FinishCompCallback = delegate void(Self builder, bool hadErros);

	public ~this()
	{
		Console.ResetColor();
	}

	public void Run(String mainFilePath, String outputDirectory, FinishCompCallback finishCompCallback, String outCCode)
	{
		// Load files
		let testFile = pleaseDoFile(mainFilePath, m_compFiles);
		searchForLoads(testFile.Ast, m_compFiles);

		if (m_hadErrors)
			return;

		let finalAst = scope Ast();
		for (let file in m_compFiles)
		{
			finalAst.AddRange(file.value.Ast);
		}

		// Checker

		let errors = scope List<CompilerError>();

		StopwatchCompiler.Start();

		let scoper = scope Scoper(finalAst, errors);
		let globalScope = scoper.Run();

		StopwatchCompiler.Stop();

		Scoper.PrintScopeTree(globalScope);

		// Checker

		StopwatchCompiler.Start();

		let checker = scope Checker(finalAst, globalScope, errors);
		checker.Run();

		StopwatchCompiler.Stop();

		for (let err in errors)
		{
			addError(m_compFiles[err.FirstToken.File], err);
		}

		if (m_hadErrors)
			return;

		// Code gen

		StopwatchCodegen.Start();

		let gen = scope Generator(finalAst);
		gen.Run(outCCode);

		StopwatchCodegen.Stop();

		finishCompCallback(this, m_hadErrors);
	}

	private CompFile compFile(String filePath, Guid fileID)
	{
		let text = File.ReadAllText(filePath, .. new .());
		let errors = scope List<CompilerError>();

		// Tokenize file
		StopwatchLexer.Start();

		let tokenizer = new Tokenizer(text, fileID);
		let tokens = tokenizer.Run();

		StopwatchLexer.Stop();

		// Parse file

		StopwatchParser.Start();

		let parser = new Parser(tokens, errors);
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
		for (let err in errors)
		{
			addError(comp, err);
		}

		return comp;
	}

	// @TEMP?
	private void searchForLoads(Ast ast, Dictionary<Guid, CompFile> list)
	{
		for (let stmt in ast)
		{
			if (let directive = stmt as AstNode.Stmt.BasicDirective)
			{
				if (directive.Token.Lexeme == "load")
				{
					let directiveCompFile = m_compFiles[directive.Token.File];
					let directiveFilePath = m_compFiles[directive.Token.File].Path;
					let directiveFileDirectory = Path.GetDirectoryPath(directiveFilePath, .. scope .());

					// Trim the surrounding quotes
					bool isMultiline = false;
					let offset = (isMultiline) ? 3 : 1;

					let loadFileName = directive.Name.Lexeme.Substring(offset, directive.Name.Lexeme.Length - 1 - offset);
					let loadFilePath = Path.Combine(.. scope .(), directiveFileDirectory, loadFileName);

					if (File.Exists(loadFilePath))
					{
						pleaseDoFile(loadFilePath, list);
					}
					else
					{
						addError(directiveCompFile, new .(directive.Name, "File not found"));
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

	private CompFile pleaseDoFile(String path, Dictionary<Guid, CompFile> list)
	{
		let fileID = Guid.Create();
		let comp = compFile(path, fileID);
		list.Add(fileID, comp);

		return comp;
	}

	private void addError(CompFile file, CompilerError err)
	{
		m_errors.Add(err);
		m_errorManager.WriteError(file, err);

		++m_errorCount;
		m_hadErrors = true;
	}
}