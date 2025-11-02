using System;

namespace Zen;

struct BuiltinFunction
{
	public readonly String Name;
	public readonly uint ArgCount;
	public readonly bool Variadic;

	public this(String name, uint argCount, bool variadic)
	{
		this.Name = name;
		this.ArgCount = argCount;
		this.Variadic = variadic;
	}
}

static
{
	public const BuiltinFunction[?] BuiltinFunctions = .(
		.("print", 1, true),
		.("println", 1, true)
	);
}