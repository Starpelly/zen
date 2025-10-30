using System;
using System.Collections;

namespace Zen;

enum BasicKind
{
	Invalid,
	Void,
	Bool,
	Int8,
	Int16,
	Int32,
	Int64,
	UInt8,
	UInt16,
	UInt32,
	UInt64,
	Float32,
	Float64,
	Int,
	UInt,
	RawPtr,
	String,
	Char8,
	Char16,
	Char32
}

[AllowDuplicates]
enum BasicFlag : uint32
{
	case Boolean = 0;
	case Integer = 1;
	case Unsigned = _*2;
	case Float = _*2;
	case Pointer = _*2;
	case String = _*2;
	case Char = _*2;
	case Void = _*2;

	case Numeric 		= Integer | Float;
	case Ordered 		= Void | Numeric | Char | String | Pointer;
	case ConstantType 	= Void | Boolean | Numeric | Char | String | Pointer;
}

struct BasicType
{
	public BasicKind Kind;
	public BasicFlag Flags;
	public StringView Name;

	public this(BasicKind kind, BasicFlag flags, StringView name)
	{
		this.Kind = kind;
		this.Flags = flags;
		this.Name = name;
	}

	public const BasicType[?] BasicTypes = .(
		.(.Void, .Void, "void"),

		.(.Int, .Integer, "int"),
		.(.Int8, .Integer, "int8"),
		.(.Int16, .Integer, "int16"),
		.(.Int32, .Integer, "int32"),
		.(.Int64, .Integer, "int64"),

		.(.UInt, .Integer | .Unsigned, "uint"),
		.(.UInt8, .Integer | .Unsigned, "uint8"),
		.(.UInt16, .Integer | .Unsigned, "uint16"),
		.(.UInt32, .Integer | .Unsigned, "uint32"),
		.(.UInt64, .Integer | .Unsigned, "uint64"),

		.(.Float32, .Float, "float"),
		.(.Float32, .Float, "float32"),
		.(.Float64, .Float, "float64"),

		.(.Bool, .Boolean, "bool"),

		.(.Char8, .Char, "char"),
		.(.Char8, .Char, "char8"),
		.(.Char16, .Char, "char16"),
		.(.Char32, .Char, "char32"),

		.(.String, .String, "string")
	);

	public static Result<BasicType> FromName(StringView name)
	{
		for (let type in BasicTypes)
		{
			if (name == type.Name)
			{
				return .Ok(type);
			}
		}

		return .Err;
	}

	public static Result<BasicType> FromKind(BasicKind kind)
	{
		for (let type in BasicTypes)
		{
			if (kind == type.Kind)
			{
				return .Ok(type);
			}
		}

		return .Err;
	}
}

enum TypeKind
{
	Invalid,

	Basic,
	Array,
	Struct,
	Pointer,
	Named,
	Tuple,
	Function,

	Count
}

public enum ZenType
{
	case Invalid;
	case Basic(BasicType basic);

	/*
	public class Basic : ZenType
	{
		public readonly BasicType Basic;

		public this(BasicType basic)
		{
			this.Basic = basic;
		}
	}
	*/

	public bool IsTypeVoid()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Void) != 0;
		return false;
	}

	public bool IsTypeBoolean()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Boolean) != 0;
		return false;
	}

	public bool IsTypeInteger()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Integer) != 0;
		return false;
	}

	public bool IsTypeUnsigned()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Unsigned) != 0;
		return false;
	}

	public bool IsTypeNumeric()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Numeric) != 0;
		return false;
	}

	public bool IsTypeString()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .String) != 0;
		return false;
	}

	public bool IsTypeFloat()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Float) != 0;
		return false;
	}

	public bool IsTypePointer()
	{
		if (this case .Basic(let basic))
			return (basic.Flags & .Pointer) != 0;
		return false;
	}

	public bool IsTypeIntOrUInt()
	{
		if (this case .Basic(let basic))
			return (basic.Kind == .Int) || (basic.Kind == .UInt);
		return false;
	}

	public bool IsTypeRawPtr()
	{
		if (this case .Basic(let basic))
			return (basic.Kind == .RawPtr);
		return false;
	}

	public bool IsTypeComparable()
	{
		if (this case .Basic(let basic))
			return true;
		return false;
	}

	public StringView GetName()
	{
		switch (this)
		{
		case .Invalid:
			return "Invalid type";
		case .Basic(let basic):
			return basic.Name;
		}
	}

	public static bool AreTypesIdentical(ZenType x, ZenType y)
	{
		if (x == y)
			return true;

		// if (let bx = x as Basic)
		if (x case .Basic(let bx))
		{
			if (y case .Basic(let by))
				return bx.Kind == by.Kind;
		}

		return false;
	}
}