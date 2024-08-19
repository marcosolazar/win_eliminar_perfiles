# Función para listar perfiles de usuario
function Listar-Perfiles {
    $profiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }
    $profiles | ForEach-Object {
        [PSCustomObject]@{
            "Nombre de Usuario" = $_.LocalPath.Split("\")[-1]
            "Almacenamiento"            = "{0:N2} GB" -f ($_.Size / 1GB)
            "Ultimo Uso"        = $_.LastUseTime
            "Ruta del Perfil"   = $_.LocalPath
            "SID"               = $_.SID
        }
    }
}

# Listar los perfiles
$perfiles = Listar-Perfiles
$perfiles | Format-Table -AutoSize

# Preguntar al usuario si quiere eliminar algún perfil
do {
    $usuarioAEliminar = Read-Host "Introduce el nombre del perfil que quieres eliminar o 'salir' para terminar"
    if ($usuarioAEliminar -ne 'salir') {
        $perfil = $perfiles | Where-Object { $_.'Nombre de Usuario' -eq $usuarioAEliminar }
        if ($perfil) {
            $confirmacion = Read-Host "�Estas seguro de que quieres eliminar el perfil de usuario '$usuarioAEliminar'? (S/N)"
            if ($confirmacion -eq 'S') {
                $perfilRuta = $perfil.'Ruta del Perfil'
                $perfilSID = $perfil.SID
                Write-Host "Eliminando perfil de usuario $usuarioAEliminar ..."
                try {
                    # Eliminar el perfil de usuario del sistema de archivos
                    Remove-Item -Path $perfilRuta -Recurse -Force
                    Write-Host "Carpeta de perfil eliminada correctamente." -ForegroundColor Green
                    
                    # Eliminar la entrada WMI
                    $perfilWMI = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.SID -eq $perfilSID }
                    $perfilWMI.Delete()
                    Write-Host "Registro WMI del perfil eliminado correctamente." -ForegroundColor Green
                } catch {
                    Write-Host "Error al eliminar el perfil: $_" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Perfil no encontrado. Intenta de nuevo." -ForegroundColor Yellow
        }
    }
} while ($usuarioAEliminar -ne 'salir')

Write-Host "Script finalizado."