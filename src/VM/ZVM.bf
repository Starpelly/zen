using System;
using System.Collections;

namespace Zen.VM;

enum InstrKind
{
	case HALT;
	case PUSH;
	case POP;
	case ADD;
	case SUB;
	case MUL;
	case DIV;
	case AND;
	case OR;
	case NOT;
	case DUP;
	case ISEQ;
	case ISGE;
	case ISGT;
	case JMP;
	case JIF;
	case LOAD;
	case STORE;
	case CALL;
	case RET;
	case CONST;
	case PRINT;
}

struct Instr
{
	public readonly InstrKind Kind;
	public int Operand;

	public this(InstrKind kind, int operand = 0)
	{
		this.Kind = kind;
		this.Operand = operand;
	}
}

/// Zen virtual machine
class ZVM
{
	private readonly List<Instr> m_program = new .() ~ delete _;
	private readonly List<int> m_stack = new .() ~ delete _;

	private readonly int[] m_variables = new .[256] ~ delete _;

	private int m_instrPtr;
	private int m_stackPtr;

	private bool m_halted = false;

	public this()
	{
		m_program.Add(.(.PUSH, 1));
		m_program.Add(.(.PUSH, 1));
		m_program.Add(.(.ADD));
		m_program.Add(.(.STORE, 0));
		m_program.Add(.(.LOAD, 0));
		m_program.Add(.(.PRINT));
		m_program.Add(.(.HALT));
	}

	public void Run()
	{
		while (!m_halted)
		{
			step();
		}

		Console.Read();
	}

	private void step()
	{
		Instr getNextInstr()
		{
			let nextWord = m_program[m_instrPtr];
			m_instrPtr++;
			return nextWord;
		}

		let nextInstr = getNextInstr();
		doInstr(nextInstr);
	}

	private void doInstr(Instr instr)
	{
		switch (instr.Kind)
		{
		case .HALT:
			m_halted = true;
			break;

		case .PUSH:
			m_stack.Add(instr.Operand);
			break;

		case .POP:
			m_stack.PopFront();
			break;

		case .ADD:
			let x = m_stack.PopBack();
			let y = m_stack.PopBack();
			m_stack.Add(x + y);
			break;
		case .SUB:
			let x = m_stack.PopBack();
			let y = m_stack.PopBack();
			m_stack.Add(x - y);
			break;
		case .MUL:
			let x = m_stack.PopBack();
			let y = m_stack.PopBack();
			m_stack.Add(x * y);
			break;
		case .DIV:
			let x = m_stack.PopBack();
			let y = m_stack.PopBack();
			m_stack.Add(x / y);
			break;

		case .STORE:
			m_variables[instr.Operand] = m_stack.PopBack();
			break;

		case .LOAD:
			m_stack.Add(m_variables[instr.Operand]);
			break;

		case .PRINT:
			Console.WriteLine(m_stack.PopBack());
			break;

		default:
		}
	}

	private int doBinaryOp(InstrKind int, int n1, int n2)
	{
		bool toBool(int n) => n != 0;
		int toInt(bool b) => b ? 1 : 0;

		switch (int)
		{
		case .ADD:
			return n1 + n2;
		case .STORE:
			return n1 - n2;
		case .MUL:
			return n1 * n2;
		case .DIV:
			return n1 / n2;
		case .AND:
			return toInt(toBool(n1) && toBool(n2));
		case .OR:
			return toInt(toBool(n1) || toBool(n2));
		case .ISEQ:
			return toInt(n1 == n2);
		case .ISGE:
			return toInt(n1 >= n2);
		case .ISGT:
			return toInt(n1 > n2);
		default:
			Runtime.FatalError(scope $"Not a valid binary operator: ({int})");
		}
	}
}