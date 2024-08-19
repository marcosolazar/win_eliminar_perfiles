function Listar-Perfiles {
    $profiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }
    $profiles | ForEach-Object {
        [PSCustomObject]@{
            "Nombre de Usuario" = $_.LocalPath.Split("\")[-1]
            "Almacenamiento"    = "{0:N2} GB" -f ($_.Size / 1GB)
            "Ultimo Uso"        = $_.LastUseTime
            "Ruta del Perfil"   = $_.LocalPath
            "SID"               = $_.SID
        }
    }
}

function Eliminar-Perfil {
    param (
        [string]$usuarioAEliminar,
        [string]$perfilRuta,
        [string]$perfilSID
    )
    
    Write-Host "Eliminando perfil de usuario $usuarioAEliminar ..."
    try {
        # Eliminar el perfil de usuario del sistema de archivos
        Remove-Item -Path $perfilRuta -Recurse -Force -ErrorAction Stop
        Write-Host "Carpeta de perfil eliminada correctamente." -ForegroundColor Green
        
        # Eliminar la entrada WMI
        $perfilWMI = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.SID -eq $perfilSID }
        $perfilWMI.Delete()
        Write-Host "Registro WMI del perfil eliminado correctamente." -ForegroundColor Green
        
        # Limpieza de registros en el Registro (Opcional)
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$perfilSID"
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Entradas del Registro del perfil eliminadas correctamente." -ForegroundColor Green

    } catch {
        Write-Host "Error al eliminar el perfil: $_" -ForegroundColor Red
    }
}

# Listar los perfiles
$perfiles = Listar-Perfiles
$perfiles | Format-Table -AutoSize

# Preguntar al usuario si quiere eliminar todos los perfiles excepto el administrador
$eliminarTodos = Read-Host "Queres eliminar todos los perfiles excepto el del administrador? (S/N)"

if ($eliminarTodos -eq 'S') {
    $perfiles | Where-Object { $_.'Nombre de Usuario' -ne 'Administrador' } | ForEach-Object {
        Eliminar-Perfil -usuarioAEliminar $_.'Nombre de Usuario' -perfilRuta $_.'Ruta del Perfil' -perfilSID $_.SID
    }
} else {
    do {
        $usuarioAEliminar = Read-Host "Introduce el nombre del perfil que quieres eliminar o 'salir' para terminar"
        if ($usuarioAEliminar -ne 'salir') {
            $perfil = $perfiles | Where-Object { $_.'Nombre de Usuario' -eq $usuarioAEliminar }
            if ($perfil) {
                $confirmacion = Read-Host "Estas seguro de que queres eliminar el perfil de usuario '$usuarioAEliminar'? (S/N)"
                if ($confirmacion -eq 'S') {
                    Eliminar-Perfil -usuarioAEliminar $usuarioAEliminar -perfilRuta $perfil.'Ruta del Perfil' -perfilSID $perfil.SID
                }
            } else {
                Write-Host "Perfil no encontrado. Intenta de nuevo." -ForegroundColor Yellow
            }
        }
    } while ($usuarioAEliminar -ne 'salir')
}

Write-Host "Script finalizado."
