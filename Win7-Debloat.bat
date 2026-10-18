@echo off
rem ============================================================
rem  Windows 7 Debloater - graphical version (English)
rem  Double-click this file. It asks for Administrator rights
rem  by itself. The window code is embedded below the marker.
rem ============================================================
set "SELF=%~f0"
set "ELEV="
if /i "%~1"=="elevated" set "ELEV=1"
fltmc >nul 2>&1 && goto admin
if defined ELEV (
    echo Could not get Administrator rights. Right-click the file and choose Run as administrator.
    pause
    exit /b 1
)
powershell -NoProfile -Command "Start-Process -FilePath $env:SELF -ArgumentList 'elevated' -Verb RunAs"
exit /b

:admin
start "" powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { $t=[IO.File]::ReadAllText($env:SELF,[Text.Encoding]::UTF8); Invoke-Expression $t.Substring($t.IndexOf('#'+'PS-BEGIN')) } catch { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(),'Debloater error') }"
exit /b

#PS-BEGIN
$ErrorActionPreference = 'Continue'
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
[System.Windows.Forms.Application]::EnableVisualStyles()

$global:Busy = $false
$global:groups = New-Object System.Collections.ArrayList
$global:BaseFamily = [System.Drawing.SystemFonts]::MessageBoxFont.FontFamily

# ============================================================
#  All texts in one place (key=value, one per line)
# ============================================================
function Parse-Lang([string]$block) {
    $h = @{}
    foreach ($line in ($block -split "`r?`n")) {
        $i = $line.IndexOf('=')
        if ($i -gt 0) {
            $h[$line.Substring(0, $i).Trim()] = $line.Substring($i + 1).Trim()
        }
    }
    return $h
}

$global:Langs = @{}

$global:Langs['en'] = Parse-Lang @'
app_sub=Tick what you want to remove, then press "Run"
btn_rec=Recommended
btn_none=Clear all
chk_rp=Create a restore point (recommended)
btn_run=Run
btn_exit=Exit
st_ready=Ready
st_rp=Creating restore point...
st_done=Done
msg_nothing=Nothing is selected.
msg_confirm_head=The following will be done:
msg_confirm_q=Continue?
msg_rp_fail=Could not create a restore point. Continue without it?
msg_reboot=Done. Restart to apply all changes. Restart now?
log_rp_ok=Restore point created
log_rp_fail=Could not create a restore point
log_freed=Freed on disk: {0} MB
log_hide=After restarting, hide these updates in Windows Update so they do not return.
log_notwin7=This is not Windows 7 (version {0})
g1t=Remove spying updates
g1d=Telemetry and forced upgrade to Windows 10 (KB2952664, KB3035583 and others)
g2t=Turn off data collection
g2d=CEIP, error reporting, application telemetry, Windows 10 upgrade offer
g3t=Disable unneeded services
g3d=Fax, RemoteRegistry, HomeGroup, UPnP, DiagTrack and others
g4t=Disable telemetry tasks
g4d=Scheduled tasks: Application Experience, CEIP, GWX and others
g5t=Remove unneeded Windows features
g5d=Games, Media Center, Tablet PC, gadgets, Fax and Scan, DVD Maker. Slow, needs restart
g6t=Clean temporary files
g6d=Temp, Windows Update cache, crash dumps
g7t=Turn off hibernation
g7d=Frees disk space equal to your RAM (hiberfil.sys)
g8t=SSD optimization (SSD only!)
g8d=Disables Superfetch, Prefetch and scheduled defrag. Do NOT use on a regular HDD
g9t=Turn off Remote Desktop (RDP)
g9d=Disables the Remote Desktop services
g10t=Remove Service Pack 1 backup files (irreversible)
g10d=Frees space, but SP1 can no longer be uninstalled. Takes several minutes
'@


$global:Strings = $global:Langs['en']
$global:LangEn = $global:Langs['en']

function T([string]$key) {
    $s = $null
    if ($global:Strings.ContainsKey($key)) { $s = $global:Strings[$key] }
    elseif ($global:LangEn.ContainsKey($key)) { $s = $global:LangEn[$key] }
    else { $s = $key }
    if ($args.Count -gt 0) { $s = [string]::Format($s, [object[]]$args) }
    return $s
}

# ============================================================
#  Small UI helpers (fonts come from the Windows UI font of the
#  current language, so every script renders correctly)
# ============================================================
function Pt([int]$x, [int]$y) { return (New-Object System.Drawing.Point($x, $y)) }
function Sz([int]$w, [int]$h) { return (New-Object System.Drawing.Size($w, $h)) }
function Rgb([int]$r, [int]$g, [int]$b) { return [System.Drawing.Color]::FromArgb($r, $g, $b) }
function New-Font([double]$size, [bool]$bold) {
    $style = [System.Drawing.FontStyle]::Regular
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold }
    try { return (New-Object System.Drawing.Font($global:BaseFamily, [single]$size, $style)) }
    catch { return (New-Object System.Drawing.Font($global:BaseFamily, [single]$size)) }
}
function Fit-Width([string]$text, [int]$min) {
    $w = [System.Windows.Forms.TextRenderer]::MeasureText($text, $global:form.Font).Width + 30
    if ($w -lt $min) { $w = $min }
    return [int]$w
}

# Window / taskbar icon: the same artwork as Win7-Debloat.ico, embedded as base64
# (multi-size ICO: 16/24/32/48 px, so the title bar gets a crisp 16 px version)
function New-AppIcon {
    $raw = @'
AAABAAQAEBAAAAAAIAAoBAAARgAAABgYAAAAACAAKAkAAG4EAAAgIAAAAAAgACgQAACWDQAAMDAAAAAAIAAoJAAAvh0AACgAAAAQ
AAAAIAAAAAEAIAAAAAAAAAQAAMQOAADEDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABJmW1YyhHZyR4N0bUhnXlU2
AAAAFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAEBAQEAOTQ0LJaLhp/FvLjf0srG+c3CvP/Dt7D/t6uj/LGloOWWjYeoQjw3
LgEBAQD//wABAAAAAAAAAAD///8DAAAAAJyPh57u4tv/7OXi/+bf3P/UycT+yLy2/sS4sf/Nw77/7+jk/5+WkZgAAAAA////AwAA
AAAAAAAA//+qAwAAAACzpp6v4tfR/OPd2vri2tf+z8fC/8S7tf++ta7/w7q0+uXf3Py/trGlAAAAAL+/vwQAAAAAAAAAAP///wEA
AAAAtKafxuTZ1P/o4dz85N/b/97Kwv/OtKz/x62m/8i8tfzk39z/w7u3vQAAAAD///8CAAAAAAAAAAEAAQEAAAAAA7iqo9rc0sz/
3tzl/eDV1P+FtMD/PsfZ/1LJzv+1srD95t7a/8jBv9EAAAAAAgICAAAAAAD///8BAAAAAEQiEQ+8s7Pr0bOL/9i1Pf7Pgir/NYKM
/wDT//8F+f//er/N/evY0v/MycbjAAAACQAAAAAAAAABf39/AgAAAABzWkofv7Wx+dTArv/zuwD++JMA/45vPP8sqbr/Isei/1u9
tP7m0tL/0c/M81hCNxcAAAAA////AapVVQMAAAAAiXpwMsS2r//g1dL+iZOR/4aAcP9ZWn//G5sy/wDNN/8d1WH+zMvD/9zW1f55
bGYoAAAAAH9/fwKqqqoDAAAAAJOEfUfJvbj/8N/R/VyR3f8AaP//ADTU/wp2TP8YukH/ENln/5vKpf3x4ub/jIh7PAAAAACqqqoD
v39/BAAAAACcjoZd0cS+/+ne1vvBxtP/OJPf/yldyP90gZj/vbOk/7a1rf/Jz8X88ezr/6Oak1EAAAAAv39/BL+/vwQAAAAAo5SN
ddnLxP/f2NT78uzn/+fc1P/Qxbv/zLyz/8K1sP/Kvbj/3dTS+/bz8f+wpqFoAAAAAL+/vwS/v78EAAAAAKaXkI3bzcb/4NjU++vn
5v/j3dr/0MXA/8G2sP/BtK7/xby2/9jSz/v69/b/uK6ofwAAAAD//78Ev7+/BAAAAACtn5eo39LM/ePc1/js6Ob84drX/M3CvfzB
ta/8v7Os/MS6tPzX0s/4/////cO7t5oAAAAA////BP//qgMAAAAArZ+Ytc2/uP/Et7H/z8S+/9fMx//d083/29HL/9XKxf/Rxb//
yLy2/93Tzf+1qqWpAAAAAL+/vwQAAAABAAAAAJB/dx6fjoZbqJmTebGjm4u+sq2TyL65l8zCvZfHvbiUvrGsjq+hm4CbjIRkg3Nq
HwAAAAD///8BKAAAABgAAAAwAAAAAQAgAAAAAAAACQAAxA4AAMQOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAAMD
AwAAAAAAAAAAAAAAAAAAAAAAAAAABgAAAAYAAAABAAAAAAAAAAAAAAAAAgICAP///wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAABMyKydHfXNtfp+VkKmtopzErKCb0qeblNOfk4zJkYV+sXptaIlJPDlQAAAAFQAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQAVFRUMPTcxU5iLhcnGu7b/6uLe//Lq5//o39r/3NHL/9XIwf/RxL3/zcG5
/87CvP+9s63/mY6J1kY+OFoZAAAK////AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIBAgAAAAAOoJOM2Ojb1P/g19P95N3b/OLb
2PzZ0Mz8zsS+/ce7tf3Dt7H9v7Ot/Ma8t/zRysX77+nm/6CVkdMAAAAJAgICAAAAAAEAAAAAAAAAAAAAAAAAAAAA/wAAAQAAAAAq
FRUMs6Se6NnOyP3b0s795d7b/+Te2//a0c3/0MXA/8i8tf/EuLH/v7Os/8a7tv/Kwr3949/c/bmxrd0AAAAEAQEBAAAAAAEAAAAA
AAAAAAAAAAAAAAAAf39/AgAAAABgT0Ydtqeh9tnOyP/d1dD+5uDd/+Xf3P/a0s3/0MXA/8a7tf/CuLH/vrKr/8a7tv/Kwr7+4t7b
/8C4te4oDQ0TAAAAAP///wEAAAAAAAAAAAAAAAAAAAAAf39/AgAAAAB0ZF8wvK6n/9jNyP/e1tL/5+Lf/+Xf3P/Z0cz/zsXB/8q7
tP/KubL/v7Os/8S7tf/Lwr7+4NvZ/8jBvftcRj8kAAAAAH9/fwIAAAAAAAAAAAAAAAAAAAAAqqpVAwAAAACBcmtFxbew/9nPyv3j
29b/6ePd/+fh3P/g1tL/2MO7/7Kyr/+iraz/tKei/8m7tP/Lw7//3tnW/tPNyv9zZlw3AAAAAFVVVQMAAAAAAAAAAAAAAAAAAAAA
f39/BAAAAACMfnVbzr+4/9XLxfvSzdH/5ePu/+Pg5P+4tbH/P67L/xTH6P8X5/L/L9Hg/6Gqr//Sxr//3NjW/N/Z1v+GdW5MAAAA
AKqqqgMAAAAAAAAAAAAAAAAAAAAAv39/BAAAAACSgnlz1cjD/8q4qfvHljj/1rpn/8qTTP+eYx7/BqLS/wHD8v8Q6vj/C/3//2S1
xP/Uvrf/29nW++jj4f+Sg3tjAAAAAH9/fwQAAAAAAAAAAAAAAAAAAAAAv39/BAAAAACaiYKL18rC/9HFxPvcoBr/99EA/9qMA//D
XAD/OYaU/wC9/v8W0fP/Ffb//0DT7v/Jubj/3NjU++/r6f+ckIl6AAAAAL+/vwQAAAAAAAAAAAAAAAAAAAAAv39/BAAAAACfj4mj
18i+/9jT2fvNn1P//sUA/++qCv/XagD/gHBI/z2jtP9GoHP/JLyA/zO4nv+6tbb/3tfU+/Pw7v+lmZSSAAAAAL+/vwQAAAAAAAAA
AAAAAAAAAAAA////AgAAAACjlY261sjB/9/X0/zGu7P/mopP/8SaOv+idUT/Y2B4/yGiNv8AtCj/CdlQ/wviWv+Asof/49TY+/T0
8f+sop2qAAAAAP///wMAAAAAAAAAAAAAAAAAAAAAAQEBAAAAAACpmpPO1cjC/9/Vzf3Qy9L/DmTk/xNy8v8KUdn/BzO+/xqMRv8A
qyT/AspJ/wD2bf9DxG3/3MrN/Pf49f+0q6bAAAAAAP///wIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAetnpfh1cjC/9rSz/3r3tP/
PXbH/wSG+/8OYN//By/B/xtlcv8Fox3/Jq5P/xzabv8ezGD/wsK4/f35+v+7tK/TAAAAAQICAgAAAAAAAAAAAAAAAAD///8BAAAA
AEg8MBWxo5zw1MfB/9fQzf706t//ipzH/wKC6f8Gc+//ADTF/zZTkf+hrpH/v6qr/7yxrf+svqz/zMzF/fn29f/EvbnkAAAACgAB
AQAAAAABAAAAAAAAAAB/f38CAAAAAHJdVya1qKH908fA/9zTz/7n4d7/7efk/7rH0f+Uq8b/m6C2/7qtqf/OvLn/vbOr/8W6s//Z
y8r/2NHP/vTy8f/MxcLzMx4UGQAAAAD///8BAAAAAAAAAABVVVUDAAAAAH1vZjm/sar/0cW//t3U0P/m4N3/7uro//Dm4P/k1Mn/
2su//8O2r//DuLD/v7Kr/8K4sf/PycT/19HN/vLx7//Tzcr+XUo+KQAAAAB/f38CAAAAAAAAAACqqqoDAAAAAIR3bU/IurL/08fB
/N7V0f/m4d7/7uno/+Tf3v/Vzcr/zMK+/8G1rv/EubL/wLOs/8O4sf/SysX/2NLP//Hv7v3h3Nn/dWBXPQAAAACqVVUDAAAAAAAA
AAB/f38EAAAAAI5/eGbOwLj/0sbA+93V0P/l39z/7enn/+bg3f/Xzsn/zsO+/8G1rv/EuLL/wLOs/8K3sf/SysX/2NLP/+7s6/zs
6OX/hHRrUwAAAACqqqoDAAAAAAAAAAC/f38EAAAAAJSEfH3Txb3918rE+uLa1v/p5OH/7+zq/+fh3v/Xzsn/zsO+/8K2r//EubL/
wLWu/8K3sf/Ty8f/29XS//Px8Pr49fT9j4B5aQAAAAB/f38EAAAAAAAAAAC/f38EAAAAAJyOhqXf0Mn/wrWu/8O3sv/DuLP/xbu2
/si+uf3LwLv9zcK8/ci+uf3FurX9wbax/b+0rv3Ata/+wrex/8zDv/727+z/moyGjgAAAAC/v38EAAAAAAAAAAB/f38CAAAAAJSF
f1avopnOpZeQ7a6fmPy5q6X/xbix/9HFv//b0Mr/4tjS/+Ta1f/h19L/3NLN/9XKxP/Kvrf/uq2n/6yemPOvoJjWjoF3SwAAAACq
VVUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAk4l/GpqKhDCcjYVBnpGLTaaXkVSqn5lYraKcW62inFutopxYqJyWVaGUjk+TiIFH
jX96OIp7dCMAAAAFAAAAAAAAAAAAAAAAAAAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAMQOAADEDgAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAACAgIAAwMDAAECAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAACAgIA////Af//AAEAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB
AQEAAQEBAAAAAAAAAAAMAAAAJC4mHkJcUUtecWZfc3ltZ4B5bWaCcGNdeGRXUGZHPTZLCwUFKwAAAA4AAAAAAAAAAAEBAQAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJCQABwAAABEAAAA2TkM/fIh9eL2vpaDoxr25
/9bMx//Zzsj/1snD/9DDvf/Lvbb/wbOs/7Cjm/+fkYvzhnlyzV5RSo0MBAA+AAAADyoAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAB8fHwgAAAAeSUA8cp6RiuDQxL7/6uDc/+/o5f/p4+D/4NnV/djOyfzRxcD7y764+8e8tvzF
urP8w7iy/s3Dvf/SyMP/yb+5/6CUje9WSkZ/AAAAHSQkJAcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8B
AAAABC8mIjuqm5T84dTO/9vRzPze1tL84dvY/uLc2P7d1dH/1szH/8/Dvv/IvLb/xrq0/8K2r/+/s6z/xLmz/snAu/3Tzcn76ubk
/6ablvsUDwozAAAAAwEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFVVVQMAAAAAbFpSRL6wqf/TyML8183I/+DY
1P/l3tv/5N7b/97W0v/Wzcj/z8S+/8i8tv/GurT/wraw/7+zrP/Fu7X/ysG8/83Gwv/g3Nr+vLSw/lZCODIAAAAAf39/AgAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/BAAAAACCc2pWxbev/tXKxPzZ0Mv/4dnV/+bg3f/m4N3/3tbS/9bNyP/PxL7/
yLy2/8W6s//Ctq//vrKr/8W7tf/Kwbz/z8jD/+Hd2/3Lw7//dGFWRAAAAACqVVUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAB/f38EAAAAAIh4b3DMvrb/1crE+9vSzf/h2tb/5+He/+bg3f/e1tL/183J/8/Evv/IvLX/xbmz/8G2r/++sqv/xbq1/8rB
vP/PyMT/4Nza/NjRzf98bGNcAAAAAH9/fwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH9/fwQAAAAAj353idHDu//V
ysT73NLO/+Lb1//o4+D/5+He/97W0//Xzcn/zsS+/8S6tP/CurP/v7aw/7uwqv/FurT/ysG8/8/IxP/f29n74tzY/4h4cHQAAAAA
f39/BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/BAAAAACUhX2g1Ma+/9XKxfvc08//4tvY/+nj4f/n4t//3dXR
/9bNyP/TxsD/0bmw/861rP/Lsar/w7Kp/8a7tv/Kwr3/z8jE/97a1/vo4+H/kYF6jAAAAAB/f38EAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAD///8CAAAAAJmJgrfVx8D/1crE/OPZ1P/m3tn/6ePe/+jh3P/i29f/3c7I/7q4tf+Csbj/aLG7/2+0uP+W
oKL/wrSu/8zDvv/PyMT/3djW++3p5/+YioSkAAAAAKqqqgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP///wEAAAAA
no+IzNXIwf/TyML9y8bG/9nW3f/q6e//5Obs/8/Bu/97oaj/DbHe/wDK8f8J6f7/D/r//x/c8P+En6v/08S8/83IxP/c19T88O3r
/6CUjroAAAAA////AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAaik4vf18nC/8zDwP26jEn/xKBX/82y
hP/BoXX/vWwc/2RzW/8AtfP/CLro/w3Z8/8Z7/n/Evz//1Gyyf/KtrD/0MvH/9rV0v3y7+3/qJ2XzgAAAAACAgIAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAP///wEAAAAATDMmFKeZke/Uxr3/0s3Q/s+TQf/2vgD/8skH/92KAP/JaAD/ml4c/wyg0/8Euez/
A9Hy/w3v/v8S////MdHn/7avsP/UzMb/2dTS/fLw7/+wpaDgAAAABwABAQAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/
AgAAAABnUkslrJ2W/NHDu//Y1NX+w6B7/+WrAv/02Bb/5JsN/8l3Cv+3WAT/L4qc/wC4+f8hueL/Kcfi/x7n9P8j4v7/mrHA/9fK
wf/X09H+8vDv/7euqvAkDAwVAAAAAP///wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABVVVUDAAAAAHRiWTm1p6D/z8K7/tzTz//L
vbP/3JQC//7PB//tqwn/2YUH/8VZAP95c1b/TZyt/1+YaP82nlP/JrNj/yazgv+Iop7/2crH/9bT0P7x7+7/v7ez/FA8LiYAAAAA
f39/AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKqqVQMAAAAAfGtlTr+wqf/QxL382c7I/9/a2v+yl2r/x6Aj/+KlGP/Xjhf/n2o1
/3Jrdv8npDv/ALAl/wDEPf8G5Fr/CvFk/z61XP/KvLz/29fT/+/t7P7MxcH/ZlBHOQAAAABVVVUDAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAf39/BAAAAACDdGxlxriw/9DDvPvVzMn/8ubZ/4GXyv8MXNv/PnbK/0Nuwf8USsL/FTy0/x+ZQ/8BpiL/CLM6/wvRU/8L
8HX/FtVf/6OwnP/i2Nj/7u3r/NnT0P91YlhOAAAAAKqqVQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38EAAAAAIp6cn3Mvrb/
0MO8+9fOyv/u5Nv/qa3C/wFg4P8KhP7/Alrs/wJEyP8HKLj/J3Vm/wOlG/8Bri//AMxD/wbwa/8F6WX/dLN9/+XU2v/s7er75d/c
/35vZ2UAAAAAf39/BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH9/fwQAAAAAkIF6lNDCuv/Pw7z72dDL/+fg3P/Vzcr/HF/H/xOX
+v8ScOz/DFPT/wMuuf8pVJH/BqEg/w+aMf8xrlf/Jspo/wrjbP9GtmP/3M3Q/+3t6vvu6ef/iHhyfQAAAAB/f38EAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAqqqqAwAAAACVhn+s0sS9/87Cu/za0s3/4NrZ//Xr3f9Rcrv/AH/0/wmM/P8AVeb/ADDC/xIynf9ulnP/
sa2k/8Koqv+/rKv/sLmu/6G4ov/Y09D/7Orp+/Tx7/+SgnyUAAAAAH9/fwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8BAAAA
AJuMhMLUxr//z8O9/NzTz//i29j/7ujj/9LP1v9wocz/R5fS/z11zf9Oa7D/h4eb/8u2s//Kvbj/urCn/8K3sP/Wycb/28zM/9rV
0//r6Ob7+vf2/5uNh6sAAAAAqqqqAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQABAQAAAAACoJKJ1dPGv//Owrz93NTP/+Td2f/o
4+D/9O/r//jp4P/j0cf/282//9rKuv/MvbH/wLWu/8W6s/+8sKn/wLSu/83Gwf/QysX/2tXS/+nm5Pz9+/r/o5eSwAAAAAD///8C
AAAAAAAAAAAAAAAAAAAAAAAAAAD/AAABAAAAACoVFQyllpDm08a//87CvP7d1M//5N3Z/+nk4f/t6ef/5eLh/9nT0f/Sysf/y8K+
/7+zrv/Bta7/xru0/72wqf/AtK7/z8fC/9LLx//b1dL/5+Tj/f/+/f+qn5nUAAAAAQECAgAAAAABAAAAAAAAAAAAAAAAAAAAAH9/
fwIAAAAAVUI4G6mbk/XSxb7/z8O9/t7V0P/j3dn/6eTi/+7q6P/o4+H/3NPP/9TLxv/Nw73/wrWv/8K1r//GurT/vrGq/8C0rv/P
xsL/08zH/9vW0//m4+H+//7+/7Opo+UAAAALAAEBAAAAAAEAAAAAAAAAAAAAAAAAAAAAf39/AgAAAABmVU8tr6Ga/9DDvf/Qxb7/
3tXQ/+Pc2f/p5OL/7uro/+jj4P/c08//1MrF/83Cvf/Cta//wbWu/8a6tP++sav/wLSu/8/Gwf/TzMj/29bT/+bj4f7+/v3/urGt
9CcTCRoAAAAA////AQAAAAAAAAAAAAAAAAAAAACqVVUDAAAAAHNkWEK6rKX/0MO8/dHFv//d1M//4tvY/+jj4P/t6ef/5+Lf/9vS
zv/TycT/zcG8/8K1rv/BtK3/xbqz/76xqv++sqz/zsXA/9TMyP/b1dL/5uLg/vz8/P/DvLj+UTkuLAAAAAB/f38CAAAAAAAAAAAA
AAAAAAAAAH9/fwQAAAAAe2pkWcO1rf/Qw7381MnC/+HZ1f/o4d7/7unn//Lu7P/r5uT/3tbS/9bMx//Pxb//xbmz/8W4sv/Jvrf/
wrav/8K3sP/RyMT/19DM/9/Z1//r5+b//////dPMyP9hTEQ/AAAAAFVVVQMAAAAAAAAAAAAAAAAAAAAAf39/BAAAAACDdGx4z8G6
/M/Du/fJvLb8yL24/ca8t/3Fu7b+xry3/sW7tv7Fu7X+xry2/sW7tv7Bt7H+vrOt/ryxq/65rqj+uK2n/ruvqv69sqz+wriz/czE
wPzs6ef44NrX/HRhWFwAAAAAf39/BAAAAAAAAAAAAAAAAAAAAAB/f38EAAAAAIJza3fNvrb/u62l/7Gim/+0pp//uauk/7+yq//G
ubP/z8O9/9fLxv/d0s3/4tjS/+LY0//g1tH/3dPO/9nPyv/Wy8X/0ca//8y/uP/FuLH/u62m/8a5sf/Ju7X/eWhfWAAAAAB/f38E
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABf1VVBoV2b1KgkIiSp5mQt62gmc+zpZ7et6qj6Lywqu7Bt7HyyL239MzAvPbPxcD30MfC
98/FwPbOxL/1ysC688W7tfC/tK3st6yl5K+jnNmmmpPFnI6Go4Nyalt/Pz8EAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlDKCgTW0c9GWpaUh90Zl4jfGdgJXxoYid8b2InfGdgJXRmXiNnV08gW0g/HEIsIRcR
AAAPAAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKAAAADAAAABgAAAAAQAgAAAAAAAAJAAAxA4AAMQOAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAAAAA
AP///wH///8B////Af///wEDAgIAAgICAAICAgACAgIA////Af///wH///8B////Af///wEAAAABAAAAAQAAAAEAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEBAAICAQD///8BAQEBAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAABQAAAAUAAAAD
AAAAAQAAAAAAAAAAAAAAAAAAAAABAQEAAgICAAEBAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH9/fwI4ODgJAAAADQAA
ABMAAAAfAAAANh4VElRFOjVyX1NNjXFkXqJ5bGawfnFqun5wabx5bGW1cmReqmlbVZlVSUOAQTYxYhsXE0EAAAAkAAAAEAAAAAgA
AAAGqlVVAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGGBgYFQAAAB8AAAAwDggFWEk+OY54bGXBm4+J57OppP7Lwbz/18zG/9rOyf/Yzcf/1cjC
/9HEvf/Owbn/yby1/8K0rP+2qKD/pZeP/5KDfPZ7bWbYXlFLqDgvKmwAAAA1AAAAGg0NDRMAAAAGAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAABAHAAAkAAAAMSojHm1x
ZF2/o5WP9M3BvP/m3dj/7ufj/+zl4v/l39v939fT/NnQy/zTycT8zsO9/Mu/ufzIvbb8x7y1/Ma6s/zFubP8xLiy/srAuv/Jvrj/
u6+o/5yOh/95amPaSj03hQAAADQAAAAhAAAADwAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADQcHByIEAAA4aFpVq6mblP3WysP/4dfS/+HZ1P3h2db94tvX/uLb2P/g2NX/3NPP/9fN
yf/Sx8P/zsK8/8q+uP/Hu7T/xrqz/8K2r//AtK3/v7St/8S6tP7Jv7r9z8fC/NLLyP7Px8P/raGa/3BjW8MZFBQ9BwcHIAAAAAwA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHx8fEAAAABdqXVac
x7ev/9fLxf3Vy8X8187I/tzU0P/h2tb/5N3a/+Te2//h2tb/3dTQ/9fOyf/SyMP/zsK8/8m+t//Hu7T/xrq0/8O3sP/AtK3/wLSt
/8W6tP/Ivrn/ycC7/87Gwv/X0s/95+Ti+8K3sf9hUkuVAAAAEyIiIg8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAqlVVAwAAAAiFdnDK0cS9/c/DvPzUycP/2tHL/97W0v/i29j/5d7b/+Xf2//h
2tb/3dTQ/9fOyf/SyMP/zsK8/8m9t//Gu7T/x7u0/8O3sf/AtK3/v7Os/8W6tP/Ivrn/ysK9/8/Iw//Tzcr/4d3b/NfPy/12Zl+x
AAAABH9/fwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAA
AAAAAAONfnfW0MO8/9DEvv3Vy8X/29LN/9/X0//j3Nn/5d/c/+Xf3P/i29f/3dTQ/9fOyf/TycT/zcK8/8m9t//GurT/xrqz/8O3
sP/AtK3/v7Os/8S6tP/Ivrn/ysK9/8/Iw//Vz8v/4Nza/NzW0/+EdW2/AAAAAP///wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//wABAAAAAF9PPxCWh3/o0sW+/8/Dvf7Wy8b/29LO/9/X0//k3dn/
5uDd/+fg3v/i29f/3dTQ/9jOyf/TycT/zsK8/8m9t//GurT/xbqz/8O3sP/AtK3/vrKr/8S6s//Iv7n/ysG9/8/Hw//Vz8z/3trY
/eLe3P+MfXXVAAAAAwAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAB/f38CAAAAAGlaUiKaioP40cW+/8/Dvf7XzMf/3NPO/+DY1P/k3tr/5+He/+fh3v/i29j/3dTQ/9jOyv/TycT/zcK8/8m9t//G
urP/xbqz/8O3sP+/s6z/vrKr/8S5s//Iv7r/y8K9/8/Hw//Vz8z/3djV/ufj4v+UhX7lTicnDQAAAAD/AAABAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38CAAAAAHNfWjOik4v/0cW//8/Dvf/Xzcj/3dTP
/+DZ1f/l3tv/6OLf/+fi3//i3Nn/3dXR/9jOyv/UysT/zcK8/8m9tv/GurP/xbmz/8K3sP+/sqv/vrGq/8S5s//Jv7r/ysG8/8/H
w//Vz8z/3NfV/unm5f+bjoj1Wko5HwAAAAB/f38CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAACqVVUDAAAAAHdmW0usnZX/0sa//dDEvf/Yzsn/3dTQ/+HZ1v/l39z/6OPg/+ji3//j3Nn/3dXR/9jOyv/UysX/
zcK8/8i8tf/FubL/xbmz/8K3sP++sqv/vbGq/8O5s//Jv7r/ysG9/8/Hw//Vz8z/3NfU/+vo5/+lmZP/YVFGLwAAAAB/f38CAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38EAAAAAHdnX2C1pp7/0sa//NDF
vv/Zz8r/3tXQ/+Ha1v/m39z/6OTh/+jj4P/j3Nn/3NXQ/9jOyv/UysT/zcK8/8e7tf/Ct7H/wriy/8C1sP+9sav/vLCp/8O5sv/J
wLr/ysK9/8/Hw//Vz8v/3NfU/+3q6f2yp6L/bFpORAAAAACqVVUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAB/f38EAAAAAH5tZXm8rqb/08bA+9HFv//a0Mv/3tbS/+Ha1//m4N3/6eTh/+jj4P/j3Nn/3NTQ
/9fOyf/RycT/ysK9/8q+t//Mu7L/z7yz/8u6sf/Dtq3/vbOs/8K3sf/KwLv/ysK9/87Hw//Vz8v/3NfV/+3r6vy/tbD/cVpSWgAA
AAB/f38EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38EAAAAAH5uZ5HD
tKz/0sW++9HGwP/Z0Mv/3tbR/+La1//m4N3/6eTi/+nj4f/j3Nn/29LO/9jPyv/fzsj/1r20/7mtqP+Vn6L/hJqg/4ydnv+jnZv/
uaOb/8i8tP/JwLv/ysK9/87Hwv/Vz8v/3NfV/+3r6vvKwb3/dWNacQAAAAB/f38EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACqVVUDAAAAAIZ1bafHubH/0MO9/NLGwP/e1M//593Y/+Xd2f/m4Nz/6OPg/+ji
3//l3tn/49vY/9TJxf+Vqq3/S6vA/yC82v8V0+7/H9/z/xbn8/8w1uL/U5+0/5aWl//QxL7/ycG9/87Gwv/Vz8v/3NjV/+3q6fvU
zMn/eGdgigAAAAB/f38EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38C
AAAAAIh4cL7KvLX/zsK8/NXJw//NxsP/vru//9nW2P/r6en/8O3s/+7r6//W1tn/t62n/4WKif8Artf/ALzx/wLF8f8L2/f/Dun7
/xf3//8U+///Jvb//0+Ur//Itq//y8XA/87Gwv/Vz8v/3djV/+vp6Pvc1tL/gHBmnwAAAACqqlUDAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAYx9ddLMv7j/zcC4/dfOzP+0oo3/soJA/6mRcf+z
opL/w7i0/8Czp/+liWr/vXEe/4NkOv8Mq9r/BbPq/wa15v8IzPD/DuD3/xXw/P8Y8/r/Ffj+/0C41/+mnJ3/0srD/83Fwf/Vzsv/
3djW/+rn5vzj3dv/hHVstwAAAAB/f38CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAEAAAAARS4uC5GBeeTOwbn/y763/tnPzf/BsZ7/24cF//W2Fv/ovRX/3qMb/9mOE//LdQf/wWMA/6xcC/8miKP/Abbx/wWx
5f8Gx+//Ctfz/xLr+/8Z9v3/FPb+/yrb9P9+k6H/1ca+/8zGwv/Uzsv/3tnW/+nm5fzp5OL/jHx1ygAAAAD///8BAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH9/fwIAAAAAa1hOGpaGfvPPwrv/y764/tjMx//PyMX/
yIAY/+6uBf/36BD/9ccL/+eaCP/OfAf/vGYI/7xcAP9Pbmr/ALLv/wat5P8IxO3/CtDw/xDk+P8Z8/v/FfP5/yLs/v9op8H/zr62
/83IxP/Uzsv/3tnW/+fk4/3t6uj/kYN83SoAAAYAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
5P8KTc3/BzS1/wQos/9KbXz/RJVT/6ahnP/GrbD/xKiq/8Cmqf++sbD/oK6j/32qiP+1vbD/49va/+Xi4P/x7+798O7s/4t9dNAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/AgAAAABwYVIimIqC98/Cu//Kvbb+
0MS+/9nQy//h2tb/49zZ/+fi4f/w6N7/WHKr/wBn4P8JqPr/A4L4/wBf7/8ASdn/ADW+/woqmf92eI3/zraz/8y/u/++taz/ua+m
/7y0q//Nw77/2szJ/9zJzP/a0c//29jU/+fj4v/w7u399fPy/5KEfeJVKioMAAAAAP8AAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAVVVVAwAAAABvXFg3oJGJ/8/CvP7Kvbf/0MW//9rQzP/h2tb/5N3Z/+fh3//t6ef/7Obg/7K6xv90
nbf/W5LA/1WCwP9adq7/e4aj/6qinv/Ft6v/wbev/8W7tP/Ata7/u66n/72xqv/JwLr/zsjC/87Iwv/Uz8v/3djV/+fj4f/u7Ov+
+Pf2/5qMhvFbPTMZAAAAAP///wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAqlVVAwAAAAB2ZVpJqpuU
/9DDvP3Kvbb/0MW//9vRzP/h2tb/5N3a/+nj4P/r5uT/7uvq//bu6P/v39f/5tTI/+HPwP/g0MH/2Mi7/8m8tP+/sq3/wrav/8e8
tv/Bta7/vK+o/72xqv/Jv7r/0cnE/9HJxf/Vz8z/3djV/+fj4f/t6+r++/r6/6KWkftnTkgqAAAAAH9/fwIAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/BAAAAAB7aWFhs6Sc/9DDvfzLvrf/0cW//9vRzP/h2tb/5N3a/+jj4P/s5+X/
7ero/+fk4v/f2tj/19DO/9HJxv/QyMX/yL66/8K1r//As6z/wrWv/8i8tv/Bta//vK+o/72xqv/Jv7r/0cnE/9HJxf/Vz8z/3djV
/+fj4f/t6+r//Pz8/q+knv9kU0c9AAAAAFVVVQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/BAAA
AAB6a2J3u6yl/9HEvPvMv7j/0sbA/9vSzf/h2tb/5N3a/+nj4P/s5+X/7uro/+vm4//i29j/2tHN/9TKxf/TycT/y8C6/8O2sP/A
s6z/wrav/8i8tv/Ctq//vK+o/72xqv/Jv7n/0cnE/9HJxf/Wz8z/3djW/+bj4f/t6+n//////Lyyrf9nVUtRAAAAAKqqVQMAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/BAAAAAB8bGWPwbOr/9DDvPvMv7n/08fB/9zTzv/h2tb/5N3a
/+nj4P/s6Ob/7uro/+rl4//i29j/2tLN/9XLxf/TycT/y8C6/8O3sf/As63/wrav/8e8tv/CtrD/vbCp/76xqv/Ivrn/0cnE/9LK
xv/W0Mz/3djW/+bj4f/t6+n/////+8m/u/9tXFBpAAAAAH9/fwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAqqpVAwAAAACBcGmnxrmx/8/Cu/vNwLr/08fB/9zTzv/h2tb/5N3a/+nj4P/s6Ob/7uro/+rl4//i29j/2tLN/9XKxf/SyMP/
y8C6/8O3sP/As63/wrWv/8e7tf/CtrD/vbCp/72xqv/Ivrj/0cnE/9LKxv/W0Mz/3dnW/+bj4f/t6+n/////+9XNyf9yYlh/AAAA
AH9/fwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf39/AgAAAACGdm28yry2/83AuvzOwbr/08jC/9zT
z//h2tb/5N3a/+nj4f/s6OX/7uro/+rl4//i29j/2tLN/9TKxf/SyMP/y8C6/8S3sf/As63/wbWu/8e7tf/DtrD/vbCp/72xqv/I
vbj/0cnE/9PLx//W0Mz/3dnW/+bj4f/t6+r//f/9+93X1P93Zl2YAAAAAH9/fwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAACJeXLSzcC5/8y/uP3Nwbr/08jC/9zTz//h2tb/5N3a/+jj4P/s5+X/7uro/+rl4//i29f/2tHN
/9TKxf/SyMP/y8C6/8S3sf/AtK3/wbWu/8e7tf/Dt7H/vbCq/72xqv/Ivbj/0cnE/9PLx//X0Mz/3dnW/+bj4f/u7Or/+/v7/Ofi
4P9+bWWuAAAAAKpVVQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAD8qKgyPf3fkz8K7/8y+uP3O
wbv/1MnD/9zTz//h2dX/5N3Z/+fi3//r5uT/7enn/+nj4f/h2tb/2dDM/9PJxP/Rx8H/yr+5/8O2sP/As6z/wbSu/8a6tP/DtrD/
vLCp/72xqv/Hvbj/0cjD/9PMyP/X0M3/3tnW/+bi4P/t6+r/+vr5/O7q6P+Dc2rEAAAAAP///wEAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAB/f38CAAAAAF5LQhuThH300MS9/8q9tv7Owbr/1MjC/9zTzv/i2tf/59/c/+zn5P/w7Or/8+/t/+/q
6P/n4N3/39bS/9nPyv/Xzcj/0MbA/8m+t//HurT/x7y1/8vAuv/Ivbb/wrWu/8C0rf/Jv7r/0srF/9XOyv/Y0s7/39vY/+jl5P/x
7u3/+fj4/fTx8P+KenLYAAAAAwAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38CAAAAAGhWUSyYioL+
z8O8/87Buv7VycL/2c3I/9zTzf/a0c3/18/K/9bNyf/UzMj/0cnE/83EwP/Jwbz/x765/8W8t//Fu7b/w7m0/8C2sP++s67/vbOt
/76zrv+9s63/vbKs/72yrf/AtrD/xbu2/8i/uv/Mw73/0snF/9rU0f/o4+H/9PPz/vr5+f+RgnvoTz8vEAAAAAD/AAABAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACqVVUDAAAAAGxbVUupmpL/3M/I+byvqf2vopv+qZuU/6WXkP+ll5D/ppiS/6mblf+u
oZr/tKag/7qtpv/AtK3/xrm0/8q+uf/Ow73/z8S+/87Dvf/Kv7n/yLy3/8O4sv/AtK//vLGr/7qup/+2qqP/sqWf/7Cim/+toJn/
rJ6Y/62fmP+xpZ7+yL24/enj4PyWiYL7XE0/JAAAAAB/f38CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38CAAAA
AHNgVjWYiYH508W9/7Gim/+rnpj/rKCZ/7OmoP25rKX8vbGr+8O2r/vHurT7zMC5+9HGwPvWy8X72c/K+93Szfvg1tD749nU++PZ
1Pvi2NT749nU++HX0vvf1tH73dPO+9zRzPvZz8n718zG+9PHwvvOwrv7x7u1/MC0rv22qqP/wbWu/9LFvv+Le3Pqa1BQEwAAAAH/
/wABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAABzZF8ziHZulJ+QiM6ml5DvrJ6X/7qrpP/CtK3/
yLqz/83Auf/Sxr//1srE/9rPyP/f1M7/49nT/+fc1//p39n/7OPd/+3j3//s497/6+Ld/+rh3P/o3tn/5dvW/+LX0v/e087/2M3H
/9HFv//Jvbf/v7Os/7Klnv+jlo/8mIqC4Id2baZ/b2QwAAAAAP///wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAABIPDAVblxWLH9sZUSCcWhYiHlyaYx9dHiQg3uEl4iBjJyOh5OekYqZopWOnaSXkqCn
m5Shp52WpKmdmKSom5eip5yVoKWak52ilpCan5GKlZeKg5GQgnqLiXtzgoNybHZ+b2VndmdeVnViWkFgUkQlTDMZCgAAAAAAAAAA
AAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/f38Cf39/BAEBAQAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKpVVQN/f38CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==
'@
    $bytes = [Convert]::FromBase64String(($raw -replace '\s', ''))
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    return (New-Object System.Drawing.Icon($ms))
}

function Show-Msg([string]$text, [string]$buttons, [string]$icon) {
    $opt = [System.Windows.Forms.MessageBoxOptions]0
    return [System.Windows.Forms.MessageBox]::Show($global:form, $text, 'Windows 7 Debloater', [System.Windows.Forms.MessageBoxButtons]$buttons, [System.Windows.Forms.MessageBoxIcon]$icon, [System.Windows.Forms.MessageBoxDefaultButton]'Button1', $opt)
}

# ============================================================
#  Logging and process helpers
#  Tags: [ OK ] done   [ -- ] skipped   [ !! ] warning   [FAIL] error
# ============================================================
function Write-Log([string]$msg, [string]$kind = 'info') {
    switch ($kind) {
        'ok'    { $tag = '[ OK ] ' }
        'skip'  { $tag = '[ -- ] ' }
        'warn'  { $tag = '[ !! ] ' }
        'err'   { $tag = '[FAIL] ' }
        default { $tag = '       ' }
    }
    $line = $tag + $msg
    $global:txtLog.AppendText($line + "`r`n")
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-Proc([string]$file, [string]$arguments) {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $file
        $psi.Arguments = $arguments
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        while (-not $p.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 80
        }
        return [int]$p.ExitCode
    } catch {
        Write-Log ($file + ' - ' + $_.Exception.Message) 'err'
        return -1
    }
}

# ============================================================
#  Worker functions
# ============================================================
function Set-Reg([string]$key, [string]$name, [int]$value) {
    try {
        [Microsoft.Win32.Registry]::SetValue($key, $name, $value, [Microsoft.Win32.RegistryValueKind]::DWord)
        Write-Log ($name + ' = ' + $value) 'ok'
    } catch {
        Write-Log ($name + ' - ' + $_.Exception.Message) 'err'
    }
}

function Disable-Svc([string]$name) {
    $svc = Get-WmiObject -Class Win32_Service -Filter ("Name='" + $name + "'") -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Log $name 'skip'; return }
    $old = $svc.StartMode
    if ($old -eq 'Disabled') { Write-Log $name 'skip'; return }
    try {
        if ($svc.State -eq 'Running') { [void]$svc.StopService() }
        $r = $svc.ChangeStartMode('Disabled')
        if ($r.ReturnValue -eq 0) {
            Write-Log ($name + ': ' + $old + ' -> Disabled') 'ok'
        } else {
            Write-Log ($name + ' [' + $r.ReturnValue + ']') 'err'
        }
    } catch {
        Write-Log ($name + ' - ' + $_.Exception.Message) 'err'
    }
}

function Disable-Task([string]$path) {
    $leaf = $path.Substring($path.LastIndexOf('\') + 1)
    $q = Run-Proc 'schtasks.exe' ('/query /tn "' + $path + '"')
    if ($q -ne 0) { Write-Log $leaf 'skip'; return }
    $c = Run-Proc 'schtasks.exe' ('/change /tn "' + $path + '" /disable')
    if ($c -eq 0) { Write-Log $leaf 'ok' } else { Write-Log ($leaf + ' [' + $c + ']') 'err' }
}

function Remove-Updates {
    $kbs = 2952664, 2977759, 2990214, 3021917, 3022345, 3035583, 3068708, 3075249, 3080149, 3123862, 3150513
    $ids = @()
    try { $ids = @(Get-HotFix | ForEach-Object { $_.HotFixID }) } catch { }
    foreach ($kb in $kbs) {
        if ($ids -contains "KB$kb") {
            Write-Log ("KB$kb ...")
            $rc = Run-Proc 'wusa.exe' "/uninstall /kb:$kb /quiet /norestart"
            if ($rc -eq 0 -or $rc -eq 3010) {
                Write-Log "KB$kb" 'ok'
            } else {
                Write-Log ("KB$kb [" + $rc + "]") 'err'
            }
        } else {
            Write-Log "KB$kb" 'skip'
        }
    }
    Write-Log (T 'log_hide') 'warn'
}

function Remove-Feature([string]$name) {
    Write-Log ($name + ' ...')
    $rc = Run-Proc 'dism.exe' "/online /Disable-Feature /FeatureName:$name /NoRestart"
    if ($rc -eq 0 -or $rc -eq 3010) {
        Write-Log $name 'ok'
    } else {
        Write-Log ($name + ' [' + $rc + ']') 'warn'
    }
}

function Clean-Folder([string]$path) {
    if (Test-Path -LiteralPath $path) {
        Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
}

function Clean-WU {
    $wu = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $was = $false
    if ($wu -and $wu.Status -eq 'Running') { $was = $true }
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
    Clean-Folder ($env:SystemRoot + '\SoftwareDistribution\Download')
    if ($was) { Start-Service -Name wuauserv -ErrorAction SilentlyContinue }
}

function New-RestorePoint {
    Write-Log (T 'st_rp')
    $cmd = 'try { Enable-ComputerRestore -Drive ($env:SystemDrive + ''\''); Checkpoint-Computer -Description ''Win7 Debloat'' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop } catch { exit 1 }'
    $rc = Run-Proc 'powershell.exe' ('-NoProfile -ExecutionPolicy Bypass -Command "' + $cmd + '"')
    if ($rc -eq 0) { Write-Log (T 'log_rp_ok') 'ok'; return $true }
    Write-Log ((T 'log_rp_fail') + ' [' + $rc + ']') 'warn'
    return $false
}

# ============================================================
#  Groups (texts come from the language table: g<N>t / g<N>d)
# ============================================================
function Add-Group([int]$n, [bool]$def, [bool]$warn, [scriptblock]$action) {
    [void]$global:groups.Add(@{ N = $n; Def = $def; Warn = $warn; Action = $action })
}

Add-Group 1 $true $false {
    Remove-Updates
}

Add-Group 2 $true $false {
    $k = 'HKEY_LOCAL_MACHINE\SOFTWARE\'
    Set-Reg ($k + 'Microsoft\SQMClient\Windows') 'CEIPEnable' 0
    Set-Reg ($k + 'Policies\Microsoft\SQMClient\Windows') 'CEIPEnable' 0
    Set-Reg ($k + 'Microsoft\Windows\Windows Error Reporting') 'Disabled' 1
    Set-Reg ($k + 'Policies\Microsoft\Windows\Windows Error Reporting') 'Disabled' 1
    Set-Reg ($k + 'Policies\Microsoft\Windows\AppCompat') 'DisableInventory' 1
    Set-Reg ($k + 'Policies\Microsoft\Windows\AppCompat') 'AITEnable' 0
    Set-Reg ($k + 'Policies\Microsoft\Windows\Gwx') 'DisableGwx' 1
    Set-Reg ($k + 'Policies\Microsoft\Windows\WindowsUpdate') 'DisableOSUpgrade' 1
    Set-Reg ($k + 'Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade') 'ReservationsAllowed' 0
    Set-Reg ($k + 'Policies\Microsoft\Windows\HandwritingErrorReports') 'PreventHandwritingErrorReports' 1
    Set-Reg ($k + 'Policies\Microsoft\Windows\TabletPC') 'PreventHandwritingDataSharing' 1
    Set-Reg ($k + 'Policies\Microsoft\Windows NT\Printers') 'DisableWebPnPDownload' 1
}

Add-Group 3 $true $false {
    foreach ($s in 'Fax', 'RemoteRegistry', 'WMPNetworkSvc', 'HomeGroupListener', 'HomeGroupProvider', 'SSDPSRV', 'upnphost', 'WerSvc', 'DiagTrack', 'dmwappushservice') {
        Disable-Svc $s
    }
}

Add-Group 4 $true $false {
    $tasks = @(
        '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
        '\Microsoft\Windows\Application Experience\AitAgent',
        '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
        '\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask',
        '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
        '\Microsoft\Windows\Autochk\Proxy',
        '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
        '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
        '\Microsoft\Windows\Setup\gwx\launchtrayprocess',
        '\Microsoft\Windows\Setup\gwx\refreshgwxconfig',
        '\Microsoft\Windows\Setup\gwx\refreshgwxconfigandcontent'
    )
    foreach ($t in $tasks) { Disable-Task $t }
}

Add-Group 5 $false $false {
    foreach ($f in 'InboxGames', 'MediaCenter', 'TabletPCOC', 'WindowsGadgetPlatform', 'FaxServicesClientPackage', 'OpticalMediaDisc') {
        Remove-Feature $f
    }
}

Add-Group 6 $true $false {
    Clean-Folder $env:TEMP
    Write-Log '%TEMP%' 'ok'
    Clean-Folder ($env:SystemRoot + '\Temp')
    Write-Log 'Windows\Temp' 'ok'
    Clean-WU
    Write-Log 'SoftwareDistribution\Download' 'ok'
    Remove-Item -LiteralPath ($env:SystemRoot + '\MEMORY.DMP') -Force -ErrorAction SilentlyContinue
    Clean-Folder ($env:SystemRoot + '\Minidump')
    Write-Log 'MEMORY.DMP, Minidump' 'ok'
}

Add-Group 7 $false $false {
    $rc = Run-Proc 'powercfg.exe' '-h off'
    if ($rc -eq 0) { Write-Log 'powercfg -h off' 'ok' } else { Write-Log ('powercfg [' + $rc + ']') 'err' }
}

Add-Group 8 $false $true {
    Disable-Svc 'SysMain'
    $m = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
    Set-Reg $m 'EnableSuperfetch' 0
    Set-Reg $m 'EnablePrefetcher' 0
    Disable-Task '\Microsoft\Windows\Defrag\ScheduledDefrag'
}

Add-Group 9 $false $false {
    foreach ($s in 'TermService', 'SessionEnv', 'UmRdpService') { Disable-Svc $s }
    Set-Reg 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections' 1
}

Add-Group 10 $false $true {
    Write-Log 'dism /SPSuperseded ...'
    $rc = Run-Proc 'dism.exe' '/online /Cleanup-Image /SPSuperseded'
    if ($rc -eq 0 -or $rc -eq 3010) { Write-Log 'dism /SPSuperseded' 'ok' } else { Write-Log ('dism [' + $rc + ']') 'warn' }
}

# ============================================================
#  Run logic
# ============================================================
function Set-Busy([bool]$b) {
    $global:Busy = $b
    $global:pnl.Enabled = -not $b
    $global:btnRun.Enabled = -not $b
    $global:btnRec.Enabled = -not $b
    $global:btnNone.Enabled = -not $b
    $global:chkRP.Enabled = -not $b
    if ($b) { $global:form.Cursor = [System.Windows.Forms.Cursors]::AppStarting } else { $global:form.Cursor = [System.Windows.Forms.Cursors]::Default }
}

function Start-Run {
    $sel = @($global:groups | Where-Object { $_.Check.Checked })
    if ($sel.Count -eq 0) {
        [void](Show-Msg (T 'msg_nothing') 'OK' 'Information')
        return
    }
    $names = @($sel | ForEach-Object { '  - ' + (T ('g' + $_.N + 't')) })
    $text = (T 'msg_confirm_head') + "`r`n`r`n" + ($names -join "`r`n") + "`r`n`r`n" + (T 'msg_confirm_q')
    $ans = Show-Msg $text 'YesNo' 'Question'
    if ($ans -ne 'Yes') { return }

    Set-Busy $true
    $global:bar.Minimum = 0
    $global:bar.Maximum = $sel.Count
    $global:bar.Value = 0
    try {
        $drive = New-Object System.IO.DriveInfo($env:SystemDrive)
        $free0 = $drive.AvailableFreeSpace

        if ($global:chkRP.Checked) {
            $global:lblStatus.Text = (T 'st_rp')
            $okRP = New-RestorePoint
            if (-not $okRP) {
                $a2 = Show-Msg (T 'msg_rp_fail') 'YesNo' 'Warning'
                if ($a2 -ne 'Yes') { return }
            }
        }

        $i = 0
        foreach ($g in $sel) {
            $i++
            $title = T ('g' + $g.N + 't')
            $global:lblStatus.Text = $title
            Write-Log ''
            Write-Log ('=== ' + $title + ' ===')
            try { & $g.Action } catch { Write-Log $_.Exception.Message 'err' }
            $global:bar.Value = $i
            [System.Windows.Forms.Application]::DoEvents()
        }

        $delta = $drive.AvailableFreeSpace - $free0
        Write-Log ''
        Write-Log (T 'st_done') 'ok'
        if ($delta -gt 0) { Write-Log (T 'log_freed' ([math]::Round($delta / 1MB))) 'ok' }
        $global:lblStatus.Text = (T 'st_done')
    } finally {
        Set-Busy $false
    }

    $a3 = Show-Msg (T 'msg_reboot') 'YesNo' 'Question'
    if ($a3 -eq 'Yes') { [void](Run-Proc 'shutdown.exe' '/r /t 5') }
}

# ============================================================
#  Window
# ============================================================
$global:form = New-Object System.Windows.Forms.Form
$global:form.Text = 'Windows 7 Debloater'
$global:form.StartPosition = 'CenterScreen'
$global:form.FormBorderStyle = 'FixedSingle'
$global:form.MaximizeBox = $false
$global:form.ClientSize = Sz 720 656
$global:form.Font = New-Font 9 $false
$global:form.BackColor = [System.Drawing.Color]::White
try { $global:form.Icon = New-AppIcon } catch { }

# header
$hdr = New-Object System.Windows.Forms.Panel
$hdr.Location = Pt 0 0
$hdr.Size = Sz 720 64
$hdr.BackColor = Rgb 0 99 177
$t1 = New-Object System.Windows.Forms.Label
$t1.Text = 'Windows 7 Debloater'
$t1.Font = New-Font 16 $true
$t1.ForeColor = [System.Drawing.Color]::White
$t1.AutoSize = $true
$t1.Location = Pt 16 6
$t2 = New-Object System.Windows.Forms.Label
$t2.Text = (T 'app_sub')
$t2.ForeColor = Rgb 215 232 248
$t2.AutoSize = $true
$t2.Location = Pt 18 40
$hdr.Controls.Add($t1)
$hdr.Controls.Add($t2)
$global:form.Controls.Add($hdr)

# list of groups
$global:pnl = New-Object System.Windows.Forms.Panel
$global:pnl.Location = Pt 0 64
$global:pnl.Size = Sz 720 310
$global:pnl.AutoScroll = $true
$global:pnl.BackColor = [System.Drawing.Color]::White
$y = 10
foreach ($g in $global:groups) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = (T ('g' + $g.N + 't'))
    $cb.Checked = $g.Def
    $cb.Font = New-Font 9.5 $true
    $cb.AutoEllipsis = $true
    $cb.Location = Pt 18 $y
    $cb.Size = Sz 660 22

    $d = New-Object System.Windows.Forms.Label
    $d.Text = (T ('g' + $g.N + 'd'))
    $d.Font = New-Font 8.5 $false
    $d.AutoEllipsis = $true
    if ($g.Warn) { $d.ForeColor = Rgb 170 40 40 } else { $d.ForeColor = Rgb 110 110 110 }
    $d.Location = Pt 38 ($y + 22)
    $d.Size = Sz 640 18
    $d.Tag = $cb
    $d.Add_Click({ param($s, $e) $s.Tag.Checked = (-not $s.Tag.Checked) })

    $global:pnl.Controls.Add($cb)
    $global:pnl.Controls.Add($d)
    $g['Check'] = $cb
    $y += 46
}
$global:form.Controls.Add($global:pnl)

# toolbar (button widths follow the translated text)
$wRec = Fit-Width (T 'btn_rec') 100
$wNone = Fit-Width (T 'btn_none') 100
$xChk = 16 + $wRec + 8 + $wNone + 16

$global:btnRec = New-Object System.Windows.Forms.Button
$global:btnRec.Text = (T 'btn_rec')
$global:btnRec.Location = Pt 16 384
$global:btnRec.Size = Sz $wRec 28
$global:btnRec.FlatStyle = 'System'
$global:btnRec.Add_Click({ foreach ($g in $global:groups) { $g.Check.Checked = $g.Def } })
$global:form.Controls.Add($global:btnRec)

$global:btnNone = New-Object System.Windows.Forms.Button
$global:btnNone.Text = (T 'btn_none')
$global:btnNone.Location = Pt (16 + $wRec + 8) 384
$global:btnNone.Size = Sz $wNone 28
$global:btnNone.FlatStyle = 'System'
$global:btnNone.Add_Click({ foreach ($g in $global:groups) { $g.Check.Checked = $false } })
$global:form.Controls.Add($global:btnNone)

$global:chkRP = New-Object System.Windows.Forms.CheckBox
$global:chkRP.Text = (T 'chk_rp')
$global:chkRP.Checked = $true
$global:chkRP.AutoEllipsis = $true
$global:chkRP.Location = Pt $xChk 387
$global:chkRP.Size = Sz (704 - $xChk) 22
$global:form.Controls.Add($global:chkRP)

# progress + log
$global:bar = New-Object System.Windows.Forms.ProgressBar
$global:bar.Location = Pt 16 422
$global:bar.Size = Sz 688 14
$global:bar.Style = 'Continuous'
$global:form.Controls.Add($global:bar)

$global:txtLog = New-Object System.Windows.Forms.TextBox
$global:txtLog.Multiline = $true
$global:txtLog.ReadOnly = $true
$global:txtLog.ScrollBars = 'Vertical'
$global:txtLog.Location = Pt 16 444
$global:txtLog.Size = Sz 688 150
$global:txtLog.Font = New-Object System.Drawing.Font('Consolas', [single]8.5)
$global:txtLog.BackColor = Rgb 30 30 30
$global:txtLog.ForeColor = Rgb 220 220 220
$global:form.Controls.Add($global:txtLog)

# bottom bar
$global:btnRun = New-Object System.Windows.Forms.Button
$global:btnRun.Text = (T 'btn_run')
$global:btnRun.Font = New-Font 10.5 $true
$global:btnRun.Location = Pt 16 606
$global:btnRun.Size = Sz 200 38
$global:btnRun.FlatStyle = 'Flat'
$global:btnRun.FlatAppearance.BorderSize = 0
$global:btnRun.BackColor = Rgb 0 99 177
$global:btnRun.ForeColor = [System.Drawing.Color]::White
$global:btnRun.Add_Click({ Start-Run })
$global:form.Controls.Add($global:btnRun)

$global:lblStatus = New-Object System.Windows.Forms.Label
$global:lblStatus.Text = (T 'st_ready')
$global:lblStatus.ForeColor = Rgb 110 110 110
$global:lblStatus.AutoEllipsis = $true
$global:lblStatus.Location = Pt 230 616
$global:lblStatus.Size = Sz 350 20
$global:form.Controls.Add($global:lblStatus)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = (T 'btn_exit')
$btnExit.Location = Pt 594 606
$btnExit.Size = Sz 110 38
$btnExit.FlatStyle = 'System'
$btnExit.Add_Click({ $global:form.Close() })
$global:form.Controls.Add($btnExit)

$global:form.Add_FormClosing({ param($s, $e) if ($global:Busy) { $e.Cancel = $true } })

# first messages
$v = [Environment]::OSVersion.Version
if ($v.Major -ne 6 -or $v.Minor -ne 1) { Write-Log (T 'log_notwin7' $v.ToString()) 'warn' }
Write-Log (T 'app_sub')

[void]$global:form.ShowDialog()
