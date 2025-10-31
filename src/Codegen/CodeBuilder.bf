using System;

namespace Zen;

public class CodeBuilder
{
	private String m_code = new .() ~ delete _;
	private int m_tabCount;
	private int m_line = 0;

	public String Code => m_code;

	public void IncreaseTab()
	{
		m_tabCount++;
	}

	public void DecreaseTab()
	{
		m_tabCount--;
	}

	public void Append(String text)
	{
		m_code.Append(text);
	}

	public void Append(StringView text)
	{
		m_code.Append(text);
	}

	public void Append(char8 char)
	{
		m_code.Append(char);
	}

	public void AppendLine(String text)
	{
		let lines = text.Split('\n');
		for (let line in lines)
		{
			AppendNewLine();
			AppendTabs();
			Append(line);
		}
	}

	public void AppendLine(StringView text)
	{
		let lines = text.Split('\n');
		for (let line in lines)
		{
			AppendNewLine();
			AppendTabs();
			Append(line);
		}
	}

	public void AppendLine(char8 char)
	{
		AppendNewLine();
		AppendTabs();
		Append(char);
	}

	public void AppendNewLine()
	{
		if (m_line > 0) m_code.Append('\n');
		m_line++;
	}

	public void AppendLineIgnoreTabs(StringView text)
	{
		if (m_line > 0) m_code.Append('\n');
		m_code.Append(text);
		m_line++;
	}

	public void AppendEmptyLine()
	{
		AppendLine("");
	}

	public void AppendTabs()
	{
		for (let i < m_tabCount)
		{
			m_code.Append('\t');
		}
	}

	public void AppendBanner(String text)
	{
		let separatorChar = '-';
		// let separatorLength = text.Length;
		let separatorLength = 62;

		mixin appendSeparator()
		{
			AppendNewLine();
			AppendTabs();
			Append("// ");
			for (let i < separatorLength)
			{
				Append(separatorChar);
			}
		}

		appendSeparator!();
		AppendLine(scope $"// {text}");
		appendSeparator!();
	}

	public void AppendBannerAutogen()
	{
		AppendBanner("Auto-generated. Do not modify!");
	}

	public void Clear()
	{
		m_code.Clear();
		m_line = 0;
	}
}