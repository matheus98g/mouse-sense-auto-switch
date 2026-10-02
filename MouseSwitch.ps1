# MouseSwitch.ps1 - troca a velocidade do ponteiro automaticamente entre Mouse e Trackpad
# Detecta qual dispositivo voce esta usando (Raw Input) e ajusta na hora.
# Clique esquerdo no icone = alterna manualmente (pausa o automatico)
# Clique direito = menu (Automatico, Mouse, Trackpad, Ver ultimo dispositivo, Sair)

# ===== Configuracao =====
$MouseSpeed    = 12   # velocidade no mouse (1-20)
$TrackpadSpeed = 20   # velocidade no trackpad (1-20)
# Regex aplicada ao nome do dispositivo: se casar, e considerado MOUSE.
# "VID_" = dispositivos USB (inclui receptores sem fio), "VID&" = Bluetooth.
# Use "Ver ultimo dispositivo" no menu para ver o nome e ajustar se precisar.
$MouseNameMatch = 'VID_|VID&'
# ========================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;

public static class MouseSpeed {
    [DllImport("user32.dll", EntryPoint="SystemParametersInfo")]
    static extern bool SpiGet(uint action, uint param, ref int value, uint ini);
    [DllImport("user32.dll", EntryPoint="SystemParametersInfo")]
    static extern bool SpiSet(uint action, uint param, IntPtr value, uint ini);
    [DllImport("user32.dll")]
    public static extern bool DestroyIcon(IntPtr handle);

    public static int Get() { int v = 0; SpiGet(0x0070, 0, ref v, 0); return v; }
    // 0x03 = salva no registro e avisa o sistema
    public static void Set(int v) { SpiSet(0x0071, 0, new IntPtr(v), 0x03); }
}

public class RawInputWatcher : NativeWindow {
    [StructLayout(LayoutKind.Sequential)]
    struct RAWINPUTDEVICE { public ushort UsagePage; public ushort Usage; public uint Flags; public IntPtr Target; }
    [StructLayout(LayoutKind.Sequential)]
    struct RAWINPUTHEADER { public uint Type; public uint Size; public IntPtr Device; public IntPtr WParam; }

    [DllImport("user32.dll", SetLastError=true)]
    static extern bool RegisterRawInputDevices(RAWINPUTDEVICE[] devices, uint count, uint size);
    [DllImport("user32.dll")]
    static extern uint GetRawInputData(IntPtr hRawInput, uint command, out RAWINPUTHEADER data, ref uint size, uint headerSize);
    [DllImport("user32.dll", CharSet=CharSet.Unicode, EntryPoint="GetRawInputDeviceInfoW")]
    static extern uint GetRawInputDeviceInfo(IntPtr device, uint command, StringBuilder data, ref uint size);

    const int  WM_INPUT        = 0x00FF;
    const uint RID_HEADER      = 0x10000005;
    const uint RIDI_DEVICENAME = 0x20000007;
    const uint RIDEV_INPUTSINK = 0x00000100;
    const uint RIM_TYPEHID     = 2;

    public event Action<string> DeviceChanged;   // "mouse" ou "trackpad"
    public string LastDeviceName = "";
    public string LastKind = "";
    string current = "";
    Regex mouseRegex;
    Dictionary<IntPtr, string> names = new Dictionary<IntPtr, string>();

    public RawInputWatcher(string mousePattern) {
        mouseRegex = new Regex(mousePattern, RegexOptions.IgnoreCase);
        CreateHandle(new CreateParams());
        uint sz = (uint)Marshal.SizeOf(typeof(RAWINPUTDEVICE));
        RAWINPUTDEVICE[] devs = new RAWINPUTDEVICE[2];
        // Mouse generico (inclui o movimento gerado pelo touchpad)
        devs[0].UsagePage = 0x01; devs[0].Usage = 0x02; devs[0].Flags = RIDEV_INPUTSINK; devs[0].Target = Handle;
        // Touchpad de precisao (HID Digitizer / Touch Pad)
        devs[1].UsagePage = 0x0D; devs[1].Usage = 0x05; devs[1].Flags = RIDEV_INPUTSINK; devs[1].Target = Handle;
        if (!RegisterRawInputDevices(devs, 2, sz)) {
            RegisterRawInputDevices(new RAWINPUTDEVICE[] { devs[0] }, 1, sz);
        }
    }

    // Faz o proximo uso disparar o evento mesmo que o tipo nao tenha mudado
    public void Reset() { current = ""; }

    string GetName(IntPtr dev) {
        if (dev == IntPtr.Zero) return "";
        string n;
        if (names.TryGetValue(dev, out n)) return n;
        uint size = 0;
        GetRawInputDeviceInfo(dev, RIDI_DEVICENAME, null, ref size);
        StringBuilder sb = new StringBuilder((int)size + 1);
        GetRawInputDeviceInfo(dev, RIDI_DEVICENAME, sb, ref size);
        n = sb.ToString();
        names[dev] = n;
        return n;
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_INPUT) {
            RAWINPUTHEADER h;
            uint size = (uint)Marshal.SizeOf(typeof(RAWINPUTHEADER));
            if (GetRawInputData(m.LParam, RID_HEADER, out h, ref size, size) != unchecked((uint)-1)) {
                string name = GetName(h.Device);
                string kind;
                if (h.Type == RIM_TYPEHID)          kind = "trackpad"; // toque no touchpad de precisao
                else if (h.Device == IntPtr.Zero)   kind = "trackpad"; // movimento sintetizado pelo touchpad
                else if (mouseRegex.IsMatch(name))  kind = "mouse";
                else                                kind = "trackpad";

                LastDeviceName = (name == "") ? "(sem identificacao - gerado pelo touchpad de precisao)" : name;
                LastKind = kind;
                if (kind != current) {
                    current = kind;
                    if (DeviceChanged != null) DeviceChanged(kind);
                }
            }
        }
        base.WndProc(ref m);
    }
}
"@

# Evita abrir duas instancias
$created = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\MouseSwitchTray", [ref]$created)
if (-not $created) {
    [System.Windows.Forms.MessageBox]::Show("O MouseSwitch ja esta rodando. Feche o icone antigo na bandeja antes.", "MouseSwitch") | Out-Null
    exit
}

# Icone: circulo = automatico, quadrado = manual
function New-TrayIcon([string]$text, [System.Drawing.Color]$color, [bool]$round) {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $color
    if ($round) { $g.FillEllipse($brush, 0, 0, 31, 31) } else { $g.FillRectangle($brush, 1, 1, 30, 30) }
    $font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString($text, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, 1, 32, 32), $fmt)
    $g.Dispose()
    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon).Clone()
    [MouseSpeed]::DestroyIcon($hIcon) | Out-Null
    $bmp.Dispose()
    return $icon
}

$blue  = [System.Drawing.Color]::FromArgb(0, 120, 212)
$green = [System.Drawing.Color]::FromArgb(16, 137, 62)
$icons = @{
    'mouse-auto'      = New-TrayIcon "$MouseSpeed"    $blue  $true
    'trackpad-auto'   = New-TrayIcon "$TrackpadSpeed" $green $true
    'mouse-manual'    = New-TrayIcon "$MouseSpeed"    $blue  $false
    'trackpad-manual' = New-TrayIcon "$TrackpadSpeed" $green $false
}

$tray = New-Object System.Windows.Forms.NotifyIcon
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemAuto     = $menu.Items.Add("Automatico")
[void]$menu.Items.Add("-")
$itemMouse    = $menu.Items.Add("Mouse ($MouseSpeed)")
$itemTrackpad = $menu.Items.Add("Trackpad ($TrackpadSpeed)")
[void]$menu.Items.Add("-")
$itemInfo     = $menu.Items.Add("Ver ultimo dispositivo")
$itemExit     = $menu.Items.Add("Sair")
$tray.ContextMenuStrip = $menu

$script:auto = $true
$script:currentMode = ''

function Update-Ui {
    $suffix = if ($script:auto) { 'auto' } else { 'manual' }
    $tray.Icon = $icons["$($script:currentMode)-$suffix"]
    $label = if ($script:currentMode -eq 'trackpad') { "Trackpad - $TrackpadSpeed" } else { "Mouse - $MouseSpeed" }
    $tray.Text = if ($script:auto) { "$label (automatico)" } else { "$label (manual)" }
    $itemAuto.Checked     = $script:auto
    $itemMouse.Checked    = ($script:currentMode -eq 'mouse')
    $itemTrackpad.Checked = ($script:currentMode -eq 'trackpad')
}

function Set-Mode([string]$mode) {
    if ($mode -ne $script:currentMode) {
        if ($mode -eq 'trackpad') { [MouseSpeed]::Set($TrackpadSpeed) } else { [MouseSpeed]::Set($MouseSpeed) }
        $script:currentMode = $mode
    }
    Update-Ui
}

function Set-Auto([bool]$on) {
    $script:auto = $on
    if ($on) {
        $watcher.Reset()
        if ($watcher.LastKind) { Set-Mode $watcher.LastKind } else { Update-Ui }
    } else { Update-Ui }
}

# Estado inicial pela velocidade atual
if ([MouseSpeed]::Get() -eq $TrackpadSpeed) { $script:currentMode = 'trackpad' } else { $script:currentMode = 'mouse' }

$watcher = New-Object RawInputWatcher $MouseNameMatch
$watcher.add_DeviceChanged({
    param($kind)
    if ($script:auto) { Set-Mode $kind }
})

$tray.add_MouseClick({
    param($s, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:auto = $false
        if ($script:currentMode -eq 'mouse') { Set-Mode 'trackpad' } else { Set-Mode 'mouse' }
    }
})
$itemAuto.add_Click({ Set-Auto (-not $script:auto) })
$itemMouse.add_Click({ $script:auto = $false; Set-Mode 'mouse' })
$itemTrackpad.add_Click({ $script:auto = $false; Set-Mode 'trackpad' })
$itemInfo.add_Click({
    $tipo = if ($watcher.LastKind -eq 'mouse') { 'MOUSE' } else { 'TRACKPAD' }
    [System.Windows.Forms.MessageBox]::Show(
        "Ultimo dispositivo usado (o que clicou neste menu):`n`n$($watcher.LastDeviceName)`n`nClassificado como: $tipo",
        "MouseSwitch") | Out-Null
})
$itemExit.add_Click({
    $tray.Visible = $false
    $tray.Dispose()
    $watcher.DestroyHandle()
    [System.Windows.Forms.Application]::Exit()
})

Update-Ui
$tray.Visible = $true
[System.Windows.Forms.Application]::Run()
$mutex.ReleaseMutex()
