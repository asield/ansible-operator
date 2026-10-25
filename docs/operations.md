# Operación de una instancia Koios

Ejemplos con la instancia `koios` del namespace `awx`.

## Acceso

- Usuario inicial `admin`; contraseña en el Secret `koios-admin-password` (clave
  `password`). Se genera una sola vez y sobrevive al borrado de la plataforma.
- Sin Ingress: `kubectl -n awx port-forward svc/koios-gateway 8080:80` y
  <http://localhost:8080> (con `public_base_url` ajustado a esa URL).
- La API del controller solo acepta peticiones a través del gateway.

## Estado

```sh
kubectl -n awx get koiosplatform koios -o jsonpath='{.status}' | jq
kubectl -n awx logs deploy/awx-operator-controller-manager --tail=100
```

`status.conditions` lleva `Running`, `Successful` y `Failure`. El operador
reconcilia cada 5 minutos aunque no haya cambios.

## Backup

```yaml
apiVersion: platform.koioss.com/v1alpha1
kind: KoiosPlatformBackup
metadata: {name: koios-backup, namespace: awx}
spec:
  deployment_name: koios
  clean_backup_on_delete: true   # borrar el CR borra también sus PVC
```

Crea un PVC por componente (gateway y controller) con el volcado de su base, sus
Secrets y el spec de la plataforma. `status` registra los PVC y la suma sha256 de cada
fichero. Los dos volcados no forman una instantánea única (igual que en AAP).

## Restore

```yaml
apiVersion: platform.koioss.com/v1alpha1
kind: KoiosPlatformRestore
metadata: {name: koios-restore, namespace: awx}
spec:
  deployment_name: koios2          # plataforma nueva; no puede existir
  backup_name: koios-backup
  spec_overrides:
    public_base_url: https://koios2.example.com
    ingress: {type: ingress, hostname: koios2.example.com, ingress_class: nginx, tls_secret: koios2-tls}
```

El restore crea siempre una plataforma **nueva**, también en el mismo namespace, y no
modifica la de origen. Se rechaza si ya existen objetos `<destino>-*` (incluidos los que
retiene una plataforma borrada). La clave de servicio del controller se rota.

## Actualización

Aplicar una versión nueva de este repositorio actualiza el operador; el operador
actualiza después las imágenes de las plataformas que no las fijan en su spec.
Haz un backup antes. PostgreSQL no cambia de versión mayor de forma automática.

## Borrado y desinstalación

Como en AAP, la plataforma no tiene finalizer y el operador no purga datos:

```sh
kubectl -n awx delete koiosplatform koios
```

Kubernetes borra en cascada el controller, el gateway, la UI, Redis y PostgreSQL,
pero **conserva** el PVC `data-koios-postgres-0` y las credenciales de recuperación
(admin, cifrado de campos, bases de datos, `secret-key` del controller). Recrear una
`KoiosPlatform` con el mismo nombre las reutiliza y recupera los datos.

Para desinstalar del todo, después de borrar la plataforma:

```sh
kubectl -n awx delete pvc data-koios-postgres-0
kubectl -n awx get secret -o name | grep '^secret/koios-' | grep -v '^secret/koios-quay-pull$' \
  | xargs -r kubectl -n awx delete
```

Para retirar también el operador: `kubectl delete -k operator/` borra el operador, su
RBAC, las CRDs **y el namespace `awx` con todo lo que quede dentro** (otras
plataformas, backups y sus PVC incluidos).

Los backups (`KoiosPlatformBackup`) y sus PVC son independientes de la plataforma.

## Imágenes y entornos desconectados

Precedencia de cada imagen: campo del spec > variable `RELATED_IMAGE_KOIOS_*` del
Deployment del operador > valor de la versión del operador.

| Variable | Imagen |
|---|---|
| `RELATED_IMAGE_KOIOS_CONTROLLER` | controller (AWX) |
| `RELATED_IMAGE_KOIOS_EE` | EE de control plane y EE por defecto |
| `RELATED_IMAGE_KOIOS_GATEWAY` | gateway (Jewel) |
| `RELATED_IMAGE_KOIOS_UI` | UI |
| `RELATED_IMAGE_KOIOS_ENVOY` | Envoy del gateway |
| `RELATED_IMAGE_KOIOS_POSTGRES` | PostgreSQL |
| `RELATED_IMAGE_KOIOS_REDIS` | Redis |

Valores: referencia completa (`registro/repositorio@sha256:…` o `:tag`). Ejemplo de
parche para un registro espejo:

```yaml
patches:
  - target: {kind: Deployment, name: awx-operator-controller-manager}
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value: {name: RELATED_IMAGE_KOIOS_CONTROLLER, value: mirror.example.com/koios/koios-awx@sha256:…}
```

Un controller integrado desde un AWX existente conserva sus propias imágenes.
