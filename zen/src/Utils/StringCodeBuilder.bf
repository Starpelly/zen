using System;

namespace Zen;

public class StringCodeBuilder
{
	private String m_code = new .() ~ delete _;
	private int m_tabCount;
	private int m_line = 0;

	private bool m_inMacro = false;

	public String Code => m_code;

	public void IncreaseTab()
	{
		m_tabCount++;
	}

	public void DecreaseTab()
	{
		m_tabCount--;
	}

	public void BeginMacro()
	{
		m_inMacro = true;
	}

	public void EndMacro()
	{
		m_inMacro = false;
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
		if (m_inMacro)
		{
			m_code.Append('\\');
		}

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
		AppendNewLine();
		AppendTabs();
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