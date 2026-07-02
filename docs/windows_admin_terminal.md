# Windows Admin and Terminal Notes

TestDeck requests Windows administrator rights in `windows/runner/runner.exe.manifest`.

The elevated manifest is intentional for packaged tester builds because the app includes a real PTY terminal plus local networking and serial tooling. On some Windows machines, binding local ports, opening COM devices, or launching diagnostic shell tools is less error-prone when the app is elevated.

For local development, change:

```xml
<requestedExecutionLevel level="requireAdministrator" uiAccess="false"/>
```

to:

```xml
<requestedExecutionLevel level="asInvoker" uiAccess="false"/>
```

Switch it back before producing tester builds that should request UAC elevation.

## PowerShell Fallback

The terminal defaults to Command Prompt on Windows because it is the most reliable PTY target.

Windows PowerShell is detected through:

- `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
- `powershell.exe` as a fallback command

PowerShell Core is shown only when `pwsh` is found through a common install path or `where.exe pwsh`.

If direct PowerShell initialization fails in the PTY, TestDeck prints a readable terminal message and tries the CMD wrapper mode. This avoids crashes and helps with Windows PowerShell failures such as managed runtime initialization error `8009001d`.
