# CageLab MATLAB and Shell Scripting Conventions

**Note:** CageLab builds on the [opticka framework](https://github.com/iandol/opticka). 
For opticka-specific conventions, see `~/Code/opticka/AGENTS.md`.

## MATLAB Coding Standards

### General Principles

- Write clear, readable code with descriptive variable names
- Use comments to explain **why** something is done, not what the code obviously does
- Keep functions focused on a single responsibility
- Prefer explicit over implicit behavior
- Use `arguments` blocks for input/output validation when available
- **Follow opticka's camelCase convention** for all variable/property/function/method names
- CageLab inherits opticka's handle-class architecture and stimulus API patterns

### File Organization

- One class or main function per file
- File name must match the primary function or class name
- Place related utility functions in package directories using `+packageName` convention
- Group related functionality into packages (e.g., `+clutil`, `+cltasks`)

### Naming Conventions

- **Functions**: Use camelCase (e.g., `startMatchToSample`, `checkInput`)
- **Classes**: Use CamelCase (e.g., `theConductor`, `screenManager`)
- **Variables**: Use camelCase (e.g., `sampleTime`, `objectSize`)
- **Constants**: Use UPPER_CASE with underscores (e.g., `MAX_TRIALS`)
- **Structs**: Use short, meaningful lowercase names (e.g., `in`, `r`, `dt`)
- **Managers/Objects**: Use abbreviated suffix convention (e.g., `sM` for screenManager, `aM` for audioManager, `rM` for rewardManager, `tM` for touchManager)

### Documentation

- **Follow Doxygen conventions**: Line comments start with `%>`
- Use MATLAB's built-in documentation format with `%>` for class-level documentation
- Include `@class`, `@brief` tags for classes
- Document function purpose, inputs, outputs, and usage examples at the top of each function
- Use `arguments` blocks for modern input/output validation instead of older `nargin` checks
- Include copyright and license information in header comments for main files

```matlab
function [sM, aM, rM, tM, r, dt, in] = initialise(in, bgName, prefix)
    % [sM, aM, rM, tM, r, dt, in] = initialise(in, bgName, prefix)
    % INITIALISE orchestrates the CageLab runtime by configuring hardware
    
    arguments (Input)
        in struct
        bgName (1,:) char {mustBeNonempty} % background image filename
        prefix (1,:) char = '' % prefix to add to save name
    end
    arguments (Output)
        sM (1,1) screenManager % screen manager object
        aM (1,1) audioManager % audio manager
        % ... additional outputs
    end
```

### Code Style

- **Indentation**: Use **tabs** for all MATLAB code (matches opticka convention)
  - **Exception:** YAML files (`*.yml`, `*.yaml`) must use **2 spaces** for indentation
- **Line Length**: Aim for ~80 characters when practical
- **Spacing**: 
  - Use blank lines to separate logical code blocks
  - Add space after commas in parameter lists
  - No space between function name and opening parenthesis
- **String Literals**: Prefer double quotes `"string"` over single quotes for modern MATLAB
- **Comments**:
  - Use `%` for single-line comments
  - Use `%%` for section headers within functions
  - Add inline comments with `%` preceded by space or tab

### Struct and Data Management

- Use descriptive struct field names
- Initialize structs with all expected fields for clarity
- Use `arguments` blocks to validate struct fields when possible
- Common struct conventions in this codebase:
  - `in` = input parameters from GUI or configuration
  - `r` = runtime state and status variables
  - `dt` = touch data

### Error Handling

- Use `try-catch` blocks for operations that may fail
- Always provide meaningful error messages
- Use `error()` for critical failures
- Use `warning()` for non-critical issues
- Clean up resources (close files, release hardware) in catch blocks or using cleanup objects

### Classes

- Use classdef with proper inheritance when appropriate
- **Most classes inherit from `optickaCore`** (handle-class base providing common paths, IDs, argument parsing)
- Group properties by access level:
  - Public properties first
  - Protected properties (`SetAccess = protected`)
  - Private properties last
- Document each property with inline comments using `%>` (Doxygen style)
- Use property validation when available
- Add new public options to the class's `allowedProperties` list (inherited from `optickaCore`)
- Follow property order: public → protected → private

```matlab
classdef theConductor < optickaCore
    properties
        %> run the zmq server immediately?
        runNow = false
        %> IP address
        address = '0.0.0.0'
    end
    
    properties (GetAccess = public, SetAccess = protected)
        %> is running
        isRunning = false
    end
    
    properties (Access = private)
        allowedProperties = {'runNow', 'address', 'port'}
    end
```

### Functions

- Use `function` keyword with explicit return values
- Validate inputs using `arguments` blocks in modern MATLAB
- Return multiple outputs when appropriate
- Keep functions short and focused (< 100 lines when practical)
- Use subfunctions for repeated logic within a file

### Best Practices

- **Avoid Magic Numbers**: Define constants at the top or in configuration structs
- **Use Logical Indexing**: Prefer `array(logical_index)` over loops when possible
- **Preallocate Arrays**: When building large arrays, preallocate with `zeros()`, `nan()`, etc.
- **Object Lifecycle**: Call `delete()` or cleanup methods explicitly for objects managing resources
- **Timing**: Use `tic`/`toc` sparingly, mainly for debugging and performance monitoring
- **File Paths**: Use `filesep` instead of hardcoded `/` or `\` for cross-platform compatibility
- **Conditional Logic**: Use `matches()`, `strcmp()`, `strcmpi()` for string comparisons
- **Modern Features**: Prefer string arrays over cell arrays of chars when available

### Psychtoolbox-Specific

- Always check screen availability with `Screen('Screens')`
- Use windowed mode for debugging: `kPsychGUIWindow` flag
- **Avoid `debug=true` in real experiments** as it reduces timing fidelity
- Clean up PTB resources with `Screen('CloseAll')` and `sca` in error handlers
- Use `GetSecs()` for high-precision timing
- Suppress PTB verbosity in production with appropriate flags
- Keep behavioural timing-sensitive code minimal
- **Avoid per-frame allocations/logging in display loops** to maintain timing precision

### Package Organization

- Use `+packageName` folders for namespaced code
- Reference package functions with dot notation: `clutil.checkInput()`
- Keep package-internal functions in the package directory
- Export only necessary functions; keep implementation details private

---

## ZSH Shell Scripting Standards

### File Header

- Always include shebang: `#!/usr/bin/env zsh`
- Add a brief comment describing the script's purpose
- Keep scripts focused on a single task or workflow

```zsh
#!/usr/bin/env zsh
# a script to start all cagelab services gracefully
```

### Style

- **Indentation**: Use tabs or 4 spaces consistently
- **Quoting**: Quote variables to prevent word splitting: `"$variable"`
- **Arrays**: Use zsh arrays for lists: `sl=(item1 item2 item3)`
- **Spacing**: Add spaces around operators and after semicolons

### Best Practices

- **Error Handling**: Check exit codes of critical commands
- **Paths**: Use absolute paths or make paths relative to known locations
- **User Feedback**: Echo progress messages for long-running operations
- **Parallelization**: Use `&` for background tasks when safe
- **Delays**: Add `sleep` between service restarts to avoid race conditions

```zsh
systemctl --user daemon-reload
sl=(toggleInput.service cogmoteGO.service theConductor.service)
for s in $sl; do
    echo "Restarting $s"
    systemctl --user restart $s &
    sleep 0.25s
done
```

### Systemd Integration

- Use `systemctl --user` for user services
- Always run `daemon-reload` before restarting services
- Start services in the correct dependency order
- Add appropriate delays between service starts

### Command Execution

- Prefer built-in commands over external utilities when possible
- Use command substitution with `$(command)` for modern zsh
- Chain related commands with `&&` for error propagation
- Background tasks that can run independently with `&`

### Script Organization

- Put configuration/variables at the top
- Keep main logic in the middle
- Add cleanup or status messages at the end
- Use functions for repeated operations

### Variables

- Use meaningful variable names
- Avoid single-letter variables except for loop counters
- Use `${variable}` syntax when disambiguation is needed
- Mark readonly variables with `readonly` or `typeset -r`

### Loops and Conditionals

- Use zsh's array syntax: `for item in $array; do`
- Prefer `[[ ]]` over `[ ]` for conditionals
- Use zsh-specific features when they improve readability

---

## Testing and Validation

### MATLAB Testing

- Test hardware initialization in debug mode before production
- Use try-catch blocks to validate graceful failure handling
- Verify resource cleanup (screens, files, hardware) after errors
- Test with both full screen and windowed modes

### Script Testing

- Test scripts in a safe environment before production
- Verify service dependencies are met
- Check that paths exist before using them
- Test error conditions and ensure graceful failures

---

## Version Control

- Commit working code frequently
- Use meaningful commit messages
- Keep generated files out of version control
- Include license information in main source files

---

## Project-Specific Notes

### Build Process

- Compilation uses MATLAB Compiler (`mcc`) with explicit dependencies
- Include all required toolbox paths with `-a` flags
- Package resources and custom packages explicitly
- Use `-R` flags for runtime messages

### Dependencies

- **opticka** (`~/Code/opticka`) - Core framework providing:
  - `optickaCore` base class for handle objects
  - `screenManager` for PTB screen management and degree↔pixel transforms
  - Stimulus classes (`imageStimulus`, `discStimulus`, etc.) with unified API
  - `stateMachine` for behavioural task control
  - `touchManager` for touchscreen interaction
  - `audioManager` for audio feedback
  - `communication/jzmqConnection` for ØMQ networking
- **Psychtoolbox-3** for visual stimuli and timing
- **PTBSimia** for hardware interfaces (reward pump management)
- **matlab-jzmq** for ØMQ communication
- Custom CageLab packages: `+clutil`, `+cltasks`

### Opticka Integration

- CageLab tasks use opticka's stimulus API: `setup(screenManager)`, `animate`, `draw`, `update`, `reset`
- Stimulus objects are configured via property setting before calling `setup()`
- Use `screenManager` for all PTB operations and coordinate transforms
- `touchManager` provides touchscreen input with exclusion zones and negation
- The `theConductor` class extends `optickaCore` and acts as ØMQ server for remote task control

### Architecture

- `theConductor` class runs as ØMQ REP server
- Task functions in `+cltasks` package start specific behavioral paradigms
- Utility functions in `+clutil` provide shared initialization and helper functions
- Shell scripts manage systemd services and system state

---

*Document Version: 1.0*
*Last Updated: 2026-01-23*
