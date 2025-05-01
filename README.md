# mano_design

video link --> https://www.dropbox.com/scl/fi/7pkdhp0gljg4ls9zhs8sr/Project10.mp4?rlkey=1xnbdspvqb3cex02rmxj57stg&st=wox5awkn&dl=0

# Mano Basic Computer Implementation in Verilog & Proteus - Complete Documentation

## Project Overview
This project implements Mano's Basic Computer - a simplified computer architecture model - using Verilog HDL for digital design and Proteus for simulation. The implementation includes the complete instruction set as defined in Mano's original design.

## Complete Instruction Set Implementation

### Memory Reference Instructions
- AND (0x00): Performs bitwise AND operation between memory content and AC
- ADD (0x01): Adds memory content to AC with carry handling
- LDA (0x02): Loads data from memory into AC
- STA (0x03): Stores AC content into memory
- BUN (0x04): Unconditional branch to specified address
- BSA (0x05): Branch and save return address (subroutine call)
- ISZ (0x06): Increments memory content and skips next instruction if zero

### Register Reference Instructions (Opcode 0x7000-0x7FFF)
- CLA (0x7800): Clears Accumulator register
- CLE (0x7400): Clears Overflow flag (E)
- CMA (0x7200): Complements all bits in AC
- CME (0x7100): Toggles Overflow flag
- CIR (0x7080): Circular right shift through E flag
- CIL (0x7040): Circular left shift through E flag
- INC (0x7020): Increments AC value
- SPA (0x7010): Skips next instruction if AC is positive
- SNA (0x7008): Skips next instruction if AC is negative
- SZA (0x7004): Skips next instruction if AC is zero
- SZE (0x7002): Skips next instruction if E is zero
- HLT (0x7001): Stops program execution

### Input/Output Instructions (Opcode 0xF000-0xFFFF)
- INP (0xF800): Reads input character into AC
- OUT (0xF400): Writes AC content to output
- SKI (0xF200): Skips if input device is ready
- SKO (0xF100): Skips if output device is ready
- ION (0xF080): Enables interrupt system
- IOF (0xF040): Disables interrupt system
- PUSH (0xF008): Pushes AC onto stack
- POP (0xF004): Pops value from stack into AC

## Project Architecture

### Verilog Implementation
- Memory.v: 4Kx16-bit memory module with dual-port access
- ALU.v: Enhanced arithmetic logic unit supporting all operations
- ControlUnit.v: Finite state machine implementing complete instruction cycle
- Registers.v: Register file with special flags (E, I, F)
- IO_Module.v: Handles all input/output operations
- ManoComputer.v: Top-level integration module

### Key Features
1. Full 16-bit data path implementation
2. Complete instruction set execution
3. Interrupt handling capability
4. Stack operations support
5. Conditional branching logic
6. I/O device communication

## Testing Methodology

### Sample Test Programs

1. Arithmetic Test:
   LDA [0x100]   // Load first operand
   ADD [0x101]   // Add second operand
   CMA           // Logical NOT operation
   STA [0x102]   // Store result
   HLT           // End program

2. I/O Test Sequence:
   INP           // Read input character
   OUT           // Write to output
   SKI           // Check input status
   SKO           // Check output status
   HLT           // End program

3. Stack Test:
   LDA [0x100]   // Load initial value
   PUSH          // Save to stack
   POP           // Restore from stack
   STA [0x101]   // Store recovered value
   HLT           // End program

## Simulation Results
The implementation demonstrates:
- Correct timing for all instruction types
- Accurate flag handling (E, S, Z)
- Proper interrupt behavior
- Valid memory access patterns
- Correct I/O device communication

## Future Development Roadmap
- Floating-point unit integration
- Memory-mapped I/O expansion
- Assembler tool development
- FPGA porting with physical interfaces
- Cache memory implementation
- Pipeline optimization

## Implementation Notes
1. All instructions complete in 1-3 machine cycles
2. Memory access uses 12-bit addressing
3. I/O operations are synchronous
4. Stack grows downward in memory
5. Interrupts are maskable
6. Conditional skips affect PC increment

This documentation provides complete technical specifications for the Mano Basic Computer implementation, suitable for both development and educational purposes.
