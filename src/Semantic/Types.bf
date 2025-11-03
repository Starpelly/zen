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

	Float16,
	Float32,
	Float64,

	Int,
	UInt,
	UIntPtr,
	RawPtr,

	String,
	CString,

	Char8,
	Char16,
	Char32,

	TypeID,

	// Untyped types
	UntypedBool,
	UntypedInteger,
	UntypedFloat,
	UntypedString,
	UntypedNull
}

enum BasicFlag
{
	case Boolean = 1;
	case Integer = _*2;
	case Unsigned = _*2;
	case Float = _*2;
	case Pointer = _*2;
	case String = _*2;
	case Char = _*2;
	case Void = _*2;
	case Untyped = _*2;

	case Numeric 		= Integer | Float;
	case Ordered 		= Void | Numeric | Char | String | Pointer;
	case ConstantType 	= Void | Boolean | Numeric | Char | String | Pointer;

	[Inline]
	public bool HasFlagInclusive(Self flag)
	{
		return (this & flag) != 0;
	}
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

		.(.Int, 	.Integer, "int"),
		.(.Int8, 	.Integer, "int8"),
		.(.Int16, 	.Integer, "int16"),
		.(.Int32, 	.Integer, "int32"),
		.(.Int64, 	.Integer, "int64"),

		.(.UInt, 	.Integer | .Unsigned, "uint"),
		.(.UInt8, 	.Integer | .Unsigned, "uint8"),
		.(.UInt16, 	.Integer | .Unsigned, "uint16"),
		.(.UInt32, 	.Integer | .Unsigned, "uint32"),
		.(.UInt64, 	.Integer | .Unsigned, "uint64"),

		.(.Float32, .Float, "float"),
		.(.Float32, .Float, "float32"),
		.(.Float64, .Float, "float64"),

		.(.Bool, 	.Boolean, "bool"),

		.(.Char8, 	.Char, "char"),
		.(.Char8, 	.Char, "char8"),
		.(.Char16, 	.Char, "char16"),
		.(.Char32, 	.Char, "char32"),

		.(.String, 	.String, "string"),

		.(.UntypedBool, 	.Boolean | .Untyped, "untyped bool"),
		.(.UntypedInteger, 	.Integer | .Untyped, "untyped int"),
		.(.UntypedFloat, 	.Float   | .Untyped, "untyped float"),
		.(.UntypedString, 	.String  | .Untyped, "untyped string"),
		.(.UntypedNull, 	.Untyped, "untyped null"),
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

	public static BasicType FromKind(BasicKind kind)
	{
		for (let type in BasicTypes)
		{
			if (kind == type.Kind)
			{
				return type;
			}
		}

		Runtime.FatalError("This should never happen");
	}
}

public enum ZenType
{
	case Invalid;
	case Basic(BasicType basic);
	case SimpleNamed(Token token);
	case QualifiedNamed(AstNode.Expression.QualifiedName name);
	case Structure(AstNode.Stmt.StructDeclaration _struct);
	case Enum(AstNode.Stmt.EnumDeclaration _enum);
	case Namespace(AstNode.Stmt.NamespaceDeclaration _ns);
	case Pointer(ZenType* element);

	public bool IsTypeVoid()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Void);
		return false;
	}

	public bool IsTypeBoolean()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Boolean);
		return false;
	}

	public bool IsTypeInteger()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Integer);
		return false;
	}

	public bool IsTypeUnsigned()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Unsigned);
		return false;
	}

	public bool IsTypeNumeric()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Numeric);
		return false;
	}

	public bool IsTypeString()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.String);
		return false;
	}

	public bool IsTypeFloat()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Float);
		return false;
	}

	public bool IsTypePointer()
	{
		if (this case .Basic(let basic))
			return basic.Flags.HasFlagInclusive(.Pointer);
		return this case .Pointer;
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
		// @TODO
		// This should be dynamic (for pointers), so maybe this should take a string as a parameter.
		switch (this)
		{
		case .Invalid:
			return "Invalid type";
		case .Basic(let basic):
			return basic.Name;
		case .SimpleNamed:
			return "Simple named type";
		case .QualifiedNamed:
			return "Qualified named type";
		case .Structure:
			return "Struct";
		case .Enum:
			return "Enum";
		case .Namespace:
			return "Namespace";
		case .Pointer:
			return "Pointer";
		}
	}

	public static bool AreTypesIdentical(ZenType x, ZenType y)
	{
		if (x == y)
			return true;

		if (x case .Basic(let bx))
		{
			if (y case .Basic(let by))
				return bx.Kind == by.Kind;
		}

		return false;
	}

	// @HACK
	// I don't know how I feel about this...
	public static bool AreTypesIdenticalUntyped(ZenType x, ZenType y)
	{
		if (x == y)
			return true;

		if (x case .Basic(let bx))
		{
			if (y case .Basic(let by))
			{
				return bx.Flags.HasFlagInclusive(by.Flags);
			}
		}

		if (x case .Pointer(let px))
		{
			if (y case .Pointer(let py))
			{
				// In Zen, pointers are typically type safe, so while pointers are still technically just ints,
				// we'll still need to actually compare the pointer types
				return AreTypesIdenticalUntyped(*px, *py);
			}
		}

		return false;
	}
}