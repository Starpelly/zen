using System;

namespace Zen;

struct BuiltinFunction
{
	public readonly String Name;
	public readonly uint ArgCount;
	public readonly bool Variadic;

	// @TEMP
	// This should be resolved on a case by case basis
	public readonly ZenType TempType;

	public this(String name, uint argCount, bool variadic, ZenType type)
	{
		this.Name = name;
		this.ArgCount = argCount;
		this.Variadic = variadic;
		this.TempType = type;
	}
}

static
{
	public static readonly BuiltinFunction[?] BuiltinFunctions = .(
		.("sizeof", 1, false, .Basic(.FromKind(.UntypedInteger))),

		.("print", 1, true, .Basic(.FromKind(.Void))),
		.("println", 1, true, .Basic(.FromKind(.Void)))
	);
}